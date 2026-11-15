// 안개골: 바람나침반 — concept preview. Shows the designed places and cast only (no story).
import { loadImage, extractFigure } from './sprite_extract.js';

const $ = s => document.querySelector(s);
const params = new URLSearchParams(location.search);
const STILL = params.get('still') === '1';
const VOL_KEY = 'angaegol.concept.bgm';
const wait = ms => new Promise(r => setTimeout(r, ms));
const store = {
  get(k, d) { try { const v = localStorage.getItem(k); return v === null ? d : JSON.parse(v); } catch { return d; } },
  set(k, v) { try { localStorage.setItem(k, JSON.stringify(v)); } catch {} },
};

// ---------- stage scaling (centred, letterboxed) ----------
const stage = $('#stage');
const fit = () => { stage.style.transform = `translate(-50%, -50%) scale(${Math.min(innerWidth / 1920, innerHeight / 1080)})`; };
addEventListener('resize', fit); fit();
if (STILL) document.body.classList.add('still');

const C = await (await fetch('data/concept.json')).json();
const ids = Object.keys(C.characters);

// ---------- sprites: canvas + alpha bbox, cached ----------
const cache = {};
function sprite(cid, pose) {
  const k = cid + ':' + pose;
  return cache[k] ||= (async () => {
    let cv;
    const f = C.files[cid];
    if (f) {
      cv = extractFigure(await loadImage(f.sheet), { rect: f.rects[pose], scale: f.scale, flood: f.flood, soft: f.soft });
    } else {
      const img = await loadImage(`assets/portraits/${cid}/${pose}.png`);
      cv = document.createElement('canvas'); cv.width = img.naturalWidth; cv.height = img.naturalHeight;
      cv.getContext('2d').drawImage(img, 0, 0);
    }
    const g = cv.getContext('2d', { willReadFrequently: true });
    const d = g.getImageData(0, 0, cv.width, cv.height).data;
    let x0 = cv.width, y0 = cv.height, x1 = 0, y1 = 0;
    for (let y = 0; y < cv.height; y += 2) for (let x = 0; x < cv.width; x += 2) if (d[(y * cv.width + x) * 4 + 3] > 40) {
      if (x < x0) x0 = x; if (x > x1) x1 = x; if (y < y0) y0 = y; if (y > y1) y1 = y;
    }
    // cropped figure (used by the cast page and tab faces)
    const crop = document.createElement('canvas'); crop.width = x1 - x0 + 1; crop.height = y1 - y0 + 1;
    crop.getContext('2d').drawImage(cv, x0, y0, crop.width, crop.height, 0, 0, crop.width, crop.height);
    return { url: f ? cv.toDataURL('image/png') : `assets/portraits/${cid}/${pose}.png`, w: cv.width, h: cv.height, bbox: [x0, y0, x1, y1], crop };
  })();
}
const cropUrl = {};
async function cropped(cid, pose) { const k = cid + ':' + pose; return cropUrl[k] ||= (await sprite(cid, pose)).crop.toDataURL('image/png'); }

// ---------- music ----------
const bgm = $('#bgm');
let vol = store.get(VOL_KEY, 60), muted = store.get(VOL_KEY + '.muted', false);
function applyVol() {
  bgm.volume = muted ? 0 : vol / 100;
  $('#soundBtn').classList.toggle('off', muted || vol === 0);
  syncSoundPrompt();
}
// Browsers may refuse playback (autoplay policy, or the first gesture not counting).
// play() is called synchronously inside every user gesture until it succeeds.
function tryPlay() {
  if (muted || vol === 0 || !bgm.paused) return;
  applyVol();
  const p = bgm.play();
  if (p) p.then(syncSoundPrompt, syncSoundPrompt);
}
bgm.addEventListener('playing', syncSoundPrompt);
bgm.addEventListener('pause', syncSoundPrompt);
// if music is not audible on a screen where it should be, make the ♪ button say so
function syncSoundPrompt() {
  const silent = bgm.paused || muted || vol === 0;
  $('#soundBtn').classList.toggle('prompt', silent && current !== 'gate');
}
for (const ev of ['pointerdown', 'keydown', 'touchend']) addEventListener(ev, e => { if (!e.target.closest?.('#soundBtn')) tryPlay(); }, true);
$('#soundBtn').addEventListener('click', e => {
  e.stopPropagation();
  if (bgm.paused || muted || vol === 0) {         // silent → turn music on, whatever the reason
    muted = false; store.set(VOL_KEY + '.muted', false);
    if (vol === 0) { vol = 60; store.set(VOL_KEY, vol); }
    applyVol(); bgm.play().then(syncSoundPrompt, syncSoundPrompt);
  } else toggleMute();
});
function toggleMute() { muted = !muted; store.set(VOL_KEY + '.muted', muted); applyVol(); if (!muted) tryPlay(); }

// ---------- screens ----------
const screens = ['gate', 'title', 'places', 'cast'];
let current = 'gate';
function show(name) {
  current = name;
  for (const s of screens) $('#' + s).classList.toggle('hidden', s !== name);
  document.body.className = (STILL ? 'still ' : '') + 'at-' + name;
  $('#soundBtn').classList.toggle('hidden', name === 'gate');
  if (name === 'title') focusTitle(0);
  syncSoundPrompt();
}
async function go(name, before) {
  if (STILL) { await before?.(); show(name); return; }
  $('#fader').classList.add('on'); await wait(450);
  await before?.(); show(name);
  $('#fader').classList.remove('on');
}

// gate
// the gate un-mutes: a visitor who presses "start" expects to hear the title music
$('#gateBtn').addEventListener('click', () => { muted = false; store.set(VOL_KEY + '.muted', false); if (vol === 0) vol = 60; tryPlay(); go('title'); });

// title
const titleBtns = [...document.querySelectorAll('.title-menu button')];
let tf = 0;
function focusTitle(i) { tf = (i + titleBtns.length) % titleBtns.length; titleBtns.forEach((b, k) => b.classList.toggle('focus', k === tf)); }
titleBtns.forEach((b, i) => { b.addEventListener('click', () => titleAct(b.dataset.act)); b.addEventListener('mouseenter', () => focusTitle(i)); });
function titleAct(a) {
  if (a === 'places') go('places', () => showPlace(0, true));
  if (a === 'cast') go('cast', () => showCast(ids[0], null, true));
  if (a === 'settings') openSettings();
}

// ---------- places ----------
let pi = 0, bgFront = $('#bgA'), bgBack = $('#bgB'), charEls = {};
const dots = $('#dots');
C.places.forEach((p, i) => { const b = document.createElement('button'); b.setAttribute('aria-label', p.name); b.addEventListener('click', e => { e.stopPropagation(); showPlace(i); }); dots.append(b); });
async function showPlace(i, instant) {
  pi = (i + C.places.length) % C.places.length;
  const p = C.places[pi];
  // background crossfade
  const t = bgBack; t.style.backgroundImage = `url("${p.file}")`;
  await loadImage(p.file).catch(() => {});
  if (instant || STILL) { t.style.transition = bgFront.style.transition = 'none'; requestAnimationFrame(() => { t.style.transition = bgFront.style.transition = ''; }); }
  t.classList.add('on'); bgFront.classList.remove('on'); [bgFront, bgBack] = [t, bgFront];
  $('#places').dataset.tod = p.tod || '';
  // plate
  $('#plateNo').textContent = String(pi + 1).padStart(2, '0') + ' / ' + String(C.places.length).padStart(2, '0');
  $('#plateTime').textContent = p.time;
  $('#plateName').textContent = p.name;
  $('#plateCast').innerHTML = Object.keys(p.cast).map(c => `<span class="chip ${c === 'pomi' ? 'lead' : ''}">${C.characters[c].name}</span>`).join('');
  [...dots.children].forEach((d, k) => d.classList.toggle('on', k === pi));
  // characters: shared foot baseline, real-height proportions
  const entries = Object.entries(p.cast);
  const pos = entries.length === 1 ? ['center'] : ['left', 'right'];
  const want = Object.fromEntries(entries.map(([c, pose], k) => [c, { pose, pos: pos[k] }]));
  for (const [c, e] of Object.entries(charEls)) if (!want[c]) { delete charEls[c]; e.remove(); }
  await Promise.all(Object.entries(want).map(async ([c, w]) => {
    let e = charEls[c];
    if (!e) { e = document.createElement('div'); e.className = 'char' + (STILL ? '' : ' enter'); charEls[c] = e; $('#chars').append(e); }
    const sp = await sprite(c, w.pose);
    const S = C.stage, [x0, y0, x1, y1] = sp.bbox, s = C.characters[c].heightCm * S.pxPerCm / (y1 - y0);
    Object.assign(e.style, { left: S.positions[w.pos] - (x0 + x1) / 2 * s + 'px', top: S.baseline - y1 * s + 'px', width: sp.w * s + 'px', height: sp.h * s + 'px' });
    e.innerHTML = `<img src="${sp.url}" alt="${C.characters[c].name}">`;
  }));
}
let uiHidden = false;
function toggleUI(h) { uiHidden = h; $('#placeUi').classList.toggle('off', h); $('#hideHint').classList.toggle('hidden', !h || STILL); }
document.querySelectorAll('#places [data-act]').forEach(b => b.addEventListener('click', e => {
  e.stopPropagation();
  const a = b.dataset.act;
  if (a === 'prev') showPlace(pi - 1); if (a === 'next') showPlace(pi + 1);
  if (a === 'hide') toggleUI(true); if (a === 'home') go('title');
}));
$('#places').addEventListener('click', () => { if (uiHidden) toggleUI(false); });

// ---------- cast ----------
let ci = 0;
const tabs = $('#castTabs');
for (const [i, c] of ids.entries()) {
  const b = document.createElement('button'); b.setAttribute('aria-label', C.characters[c].name);
  b.addEventListener('click', () => showCast(c));
  tabs.append(b);
  const first = Object.keys(C.characters[c].poses)[0];
  cropped(c, first).then(u => { b.innerHTML = `<img src="${u}" alt="">`; });
}
async function showCast(cid, pose, instant) {
  ci = ids.indexOf(cid);
  const ch = C.characters[cid];
  pose ||= Object.keys(ch.poses)[0];
  const home = C.places.find(p => p.id === ch.home) || C.places[0];
  $('#castBg').style.backgroundImage = `url("${home.file}")`;
  $('#castEn').textContent = ch.en;
  $('#castName').textContent = ch.name;
  $('#castRole').textContent = ch.role;
  $('#castPoses').innerHTML = '';
  for (const [k, label] of Object.entries(ch.poses)) {
    const b = document.createElement('button'); b.textContent = label; b.classList.toggle('on', k === pose);
    b.addEventListener('click', () => showCast(cid, k)); $('#castPoses').append(b);
  }
  [...tabs.children].forEach((b, k) => b.classList.toggle('on', k === ci));
  const url = await cropped(cid, pose);
  // scale by real height so the cast reads at true relative size
  const h = Math.round(1010 * ch.heightCm / 175);
  $('#castFigure').innerHTML = `<img src="${url}" alt="${ch.name}" style="height:${h}px">`;
}

// ---------- settings ----------
function openSettings() { $('#optBgm').value = vol; $('#optBgmOut').textContent = vol; $('#setOverlay').classList.remove('hidden'); $('#optBgm').focus(); }
function closeSettings() { $('#setOverlay').classList.add('hidden'); stage.focus(); }
$('#optBgm').addEventListener('input', e => { vol = +e.target.value; $('#optBgmOut').textContent = vol; store.set(VOL_KEY, vol); if (vol > 0 && muted) { muted = false; store.set(VOL_KEY + '.muted', false); } applyVol(); });
$('#optFull').addEventListener('click', () => document.fullscreenElement ? document.exitFullscreen() : document.documentElement.requestFullscreen?.());
document.querySelectorAll('[data-close]').forEach(b => b.addEventListener('click', closeSettings));
$('#setOverlay').addEventListener('click', e => { if (e.target.id === 'setOverlay') closeSettings(); });

// ---------- keyboard ----------
addEventListener('keydown', e => {
  if (!$('#setOverlay').classList.contains('hidden')) { if (e.key === 'Escape') closeSettings(); return; }
  if (e.key.toLowerCase() === 'm' && current !== 'gate') return toggleMute();
  if (current === 'gate' && (e.key === 'Enter' || e.key === ' ')) { e.preventDefault(); return $('#gateBtn').click(); }
  if (current === 'title') {
    if (e.key === 'ArrowDown') { focusTitle(tf + 1); e.preventDefault(); }
    else if (e.key === 'ArrowUp') { focusTitle(tf - 1); e.preventDefault(); }
    else if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); titleBtns[tf].click(); }
    return;
  }
  if (e.key === 'Escape') { if (uiHidden) return toggleUI(false); return go('title'); }
  if (current === 'places') {
    if (e.key === 'ArrowRight' || e.key === 'Enter' || e.key === ' ') { e.preventDefault(); showPlace(pi + 1); }
    if (e.key === 'ArrowLeft') showPlace(pi - 1);
    if (e.key.toLowerCase() === 'h') toggleUI(!uiHidden);
  }
  if (current === 'cast') {
    if (e.key === 'ArrowRight' || e.key === 'ArrowDown') showCast(ids[(ci + 1) % ids.length]);
    if (e.key === 'ArrowLeft' || e.key === 'ArrowUp') showCast(ids[(ci - 1 + ids.length) % ids.length]);
  }
});

// ---------- boot (?screen=title|places|cast&i=<n>&c=<id>&pose=<k>&ui=0&still=1) ----------
await document.fonts.ready;
applyVol();
const sc = params.get('screen');
if (sc === 'places') { await showPlace(+(params.get('i') || 0), true); show('places'); if (params.get('ui') === '0') toggleUI(true); }
else if (sc === 'cast') { await showCast(params.get('c') || ids[0], params.get('pose'), true); show('cast'); }
else if (sc === 'title') show('title');
else show('gate');
if (params.get('overlay') === 'set') openSettings();
document.body.dataset.ready = '1';
