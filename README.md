# 안개골: 바람나침반 — P0 첫 개발 단계

Godot 4 / GDScript로 만든 실행 가능한 마을 입구 프로토타입입니다. 첨부된 GAME_PRD.md와 AGENTS.md를 기준으로, 요청한 **메인 메뉴 → 포미 이동 → 마을 입구 → NPC 상호작용·대화**까지 구현했습니다. 전체 12~18분 데모가 아니라 첫 개발 단계입니다.


## 브라우저에서 바로 플레이

**https://oreum06.github.io/angaedemo/**

PC의 Chrome/Edge/Firefox 등 WebGL 2 지원 브라우저에서 실행하세요. 첫 실행은 약 51MB의 엔진·게임 데이터를 다운로드합니다. 키보드 조작이 필요하며, 모바일 터치 조작은 아직 지원하지 않습니다. 현재 플레이 범위는 마을 입구까지입니다.

로컬 Chromium에서 메뉴 시작, 이동, NPC 세 선택지, 선택 결과 대사, 일시정지를 실제 브라우저 입력으로 확인했으며 JavaScript/콘솔 오류는 0건입니다.

웹 빌드는 Godot 4.6.3의 Web export를 사용하며 `variant/thread_support=false`로 GitHub Pages의 기본 헤더 환경에서도 실행됩니다. `main`은 소스, `gh-pages`는 배포 파일입니다. `main` 수정만으로 웹 빌드가 자동 갱신되지는 않습니다.

재빌드: 같은 버전의 Export Templates 설치 후 `builds/web` 폴더를 만들고 아래 명령을 실행합니다.

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --export-release Web
python3 -m http.server 8765 --directory builds/web
```

브라우저에서 `http://localhost:8765`를 확인한 뒤 생성된 파일 전부를 `gh-pages` 브랜치 루트에 배포합니다. Pages의 배포 원본은 `gh-pages`, `/`입니다. HTML 파일을 파일 탐색기에서 직접 열면 실행되지 않습니다.

## 실행

검증 엔진: **Godot 4.6.3 stable**, Compatibility 렌더러. 외부 플러그인 없음.

1. ZIP을 풀고 Godot 프로젝트 관리자에서 `project.godot`를 가져옵니다.
2. 초기 리소스 import를 기다린 뒤 F6 대신 **F5**로 메인 메뉴부터 실행합니다.
3. `마을에 들어가기` → 도착 독백 → 주민 근처에서 대화 → 세 선택 중 하나 → 오른쪽 빵집 표지판 확인.
4. 빵집 표지판의 안내가 이번 단계의 끝입니다. Esc 메뉴에서 타이틀로 돌아가 다시 시작할 수 있습니다.

터미널에서는 프로젝트 폴더에서 실행합니다. Windows에서는 Godot 실행 파일의 실제 경로를 `godot` 대신 사용하세요.

```sh
godot --editor --path .
godot --path .
```

## 조작

| 키 | 동작 |
|---|---|
| WASD / 방향키 | 이동 |
| E / Enter | 가까운 대상 상호작용, 본문 즉시 표시, 다음 대사, 선택 확인 |
| 방향키 / WASD | 대화 선택지 이동 |
| 1 / 2 / 3 | 해당 선택 확인; 본문 출력 중에는 먼저 본문을 전부 표시 |
| 마우스 | 메뉴 및 선택지 클릭 |
| Esc | 일시정지 / 재개 |

대사 출력 중 확인을 누르면 현재 문장만 표시합니다. 다음 입력으로 진행합니다. 키 반복과 0.16~0.20초 내 중복 입력을 차단합니다. 대화·일시정지 중에는 이동할 수 없으며, 메뉴로 돌아가면 진행이 초기화됩니다. 저장/이어하기는 구현하지 않았습니다.

## 구현 내용 및 파일

- `project.godot`, `scenes/main_menu.tscn`, `scripts/ui/main_menu.gd`: 프로젝트, 한글 타이틀과 새 게임/종료.
- `scenes/characters/pomi.tscn`, `scripts/world/pomi.gd`: CharacterBody2D, 정규화 이동, 발 위치 충돌, 이동 시 임시 걷기 표현.
- `scenes/maps/village_entrance.tscn`, `scripts/world/entrance_art.gd`: 버스 정류장, 길, 담장, 빵집 표지판의 임시 도형 맵.
- `scenes/world.tscn`, `scripts/world/world.gd`: 물리 장애물, 가까운 대상 선정, E 표시, HUD, 일시정지/메뉴 복귀.
- `scripts/world/resident.gd`: 이름을 확정하지 않은 쉬고 있는 주민과 과일 임시 그림. 과일을 주우면 그림 변경.
- `scripts/systems/dialogue_manager.gd`, `scripts/ui/dialogue_box.gd`: JSON 로드, 참조 검증, 이름·본문·독백 스타일, 선택지, 조건·플래그 처리.
- `data/dialogue/entrance.json`: 도착 독백, 과일 세 분기, 선택별 후속 독백, 재대화, 선행 조건 미충족 안내, 범위 종료 안내.
- `scripts/autoload/game_state.gd`, `scripts/systems/quest_manager.gd`: 상태, ARRIVAL → BAKERY, 목표 표시. 이후 단계의 필수 플래그는 기본값만 선언.
- `tests/`: Godot 안에서 입력과 물리·씬 전환을 실행하는 테스트.
- `verification/`: 실행 로그와 실제 렌더링 화면 5장.

대사는 고유 ID로 관리합니다. `speaker`, `text`, `style`, `next`, `set`, `choices`를 사용하며, 선택지의 `when`은 플래그 값의 일치 조건입니다. `set`은 노드에 진입하거나 선택을 확정할 때 처리하므로 글자를 빨리 표시해도 플래그가 누락되지 않습니다. 종료 노드의 `next`는 빈 문자열입니다. 대사를 추가하면 통합 테스트와 화면 검사를 다시 수행하세요.

## 실제 검증 결과

검증 환경: Godot 4.6.3 stable / Linux.

| 검증 | 결과 |
|---|---|
| 이동 기반 구현 후 headless import 및 실행 | 통과 |
| 첫 단계 물리 검증 | 메뉴 생성, 이동, 담장 충돌 3개 통과 |
| 최종 editor headless import/parse | 스크립트/리소스 오류 없음 |
| 최종 headless 통합 실행 | 37개 통과, 실패 0 |
| 실제 X11/OpenGL Compatibility 그래픽 통합 실행 | 42개 통과, 실패 0; 화면 저장 포함 |
| 화면 육안 확인 | 타이틀, 한글 독백, 세 선택지, 일시정지 UI 확인 |
| Windows export | 시도했으나 템플릿 부재로 실패; EXE 없음 |

그래픽 검증은 가상 X11 디스플레이와 Mesa llvmpipe 소프트웨어 렌더러에서 **실제 Godot 창과 렌더링**으로 실행했습니다. 공유 데스크톱 조작 도구가 없어 사용자 데스크톱에서 직접 키를 누른 검증은 아닙니다. Godot InputEvent를 주입하여 실제 입력 처리, 물리 프레임, UI, 씬 전환을 테스트했습니다. Windows 실기기 테스트는 하지 않았습니다. 드라이버의 V-Sync 변경 미지원 경고 1건은 있으며 스크립트 오류는 없습니다.

검증 항목: 메뉴에서 Enter 시작, 시작 입력의 독백 관통 방지, 대화 중 이동 차단, 반복/빠른 입력 차단, 본문 표시와 다음 대사 분리, 대화 후 이동 재개, 담장/맵 경계/NPC 충돌, 거리별 E 표시, 선택지 이동·확정, 3개 분기 모두 BAKERY 도달, 선택 플래그 보존, 재대화, 순서가 잘못된 표지판 안내, 단계 경계 안내, 대화 도중 일시정지·재개, 메뉴 복귀 및 새 게임 초기화.

재현 명령:

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . res://tests/stage1.tscn
godot --headless --path . res://tests/integration.tscn
# 화면이 있는 환경: 실제 창을 열고 검증 후 종료, verification/*.png 갱신
godot --path . res://tests/integration.tscn
```

테스트 실패 시 종료 코드 1, 통과 시 0입니다. 클라우드처럼 홈 디렉터리가 읽기 전용이면 `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_CACHE_HOME`을 쓰기 가능한 임시 경로로 지정합니다. 일반 PC에서는 필요 없습니다.

## Windows 내보내기

`export_presets.cfg`에 Windows Desktop x86_64 설정과 JSON 포함 필터를 제공합니다. 이 환경에는 4.6.3용 `windows_debug_x86_64.exe` / `windows_release_x86_64.exe` 템플릿이 없어 export가 실패했습니다. `verification/windows-export.log`에 원인을 보존했습니다. **Windows 빌드 성공으로 간주하지 않습니다.**

1. 프로젝트와 같은 버전의 Godot에서 Editor → Manage Export Templates로 템플릿을 설치합니다.
2. Project → Export → Windows Desktop을 선택합니다.
3. `builds/windows/` 폴더를 만든 뒤 내보냅니다. 또는:

```sh
godot --headless --path . --export-release "Windows Desktop" builds/windows/Angaegol.exe
```

4. 생성된 `.exe`와 `.pck`를 함께 배포하고 실제 Windows에서 메뉴~과일 분기~메뉴 복귀를 다시 확인합니다. 현재 프로젝트는 실행 파일 아이콘 수정과 코드 서명을 사용하지 않습니다.

## 에셋 교체 규격

완성 캐릭터 시트는 제공된 ZIP에 없었습니다. 임시 도형으로 구현했으며 원본 시트를 잘라 쓰지 않았습니다. 포미 외모는 어두운 묶은 머리, 베이지 코트, 가죽가방의 기본 실루엣만 반영했습니다.

- 내부 화면 1280×720, 16:9, `canvas_items` 확대. 1920×1080에서 비례 확대 가능.
- 캐릭터: `assets/characters/pomi/` 등 PRD 경로에 투명 PNG 배치. 권장 프레임 64×80px, 발 기준 `(32,72)`, 네 방향 idle/walk 각 4프레임. 현재 도형의 발 원점 `(0,0)`에 맞춰 Sprite2D/AnimatedSprite2D 위치 조정. 충돌 반경 12px는 그림과 독립 유지.
- 주민: `assets/characters/resident/`에 같은 규격. 임시 익명 주민이며 신규 확정 인물 설정이 아님.
- 배경: `assets/backgrounds/`의 1280×720 PNG 또는 32px 타일. 배경 그림과 StaticBody2D 충돌은 별도로 조정. 현재 나무는 배경 장식으로 통과 가능, 정류장·담장·주민·맵 경계는 충돌함.
- UI: `assets/ui/`, 필요 시 9-slice PNG. 본문 기본 23px, 이름 21px. 긴 대사 수정 후 3선택지 레이아웃 확인 필요.
- 폰트: `assets/fonts/NotoSansKR.otf`에 Noto Sans CJK KR Regular 포함. 원 배포 라이선스는 같은 폴더의 `LICENSE.txt`. 모든 한글 조합을 포함하는 폰트라 대사 추가 시 폰트 재생성이 필요 없음.
- 향후 오디오: `assets/audio/bgm/` OGG, `assets/audio/sfx/` WAV 권장. 이번 첫 단계는 무음이며 기본 오디오는 후속 P0 작업.

이동 속도는 `pomi.gd`의 export 변수 `speed`, 상호작용 거리는 `world.gd`의 `interaction_distance`로 조정합니다. 충돌 레이어 이름은 project.godot의 Scenery=1, Pomi=2이며, 포미 씬의 collision_layer/mask에서 분리합니다.

## 범위 및 다음 단계

- 완료: P0 첫 개발 단계와 그 검증에 필요한 대화/선택/상태 기반, ACT 1 과일 사건.
- 다음: 빵집 맵과 마루 대화, 손님 요청, 배달 수락을 연결한 뒤 다시 실제 실행 검증.
- 이후: 광장 배달 2건 → 산책 선택 → 숲 예고/엔딩 → 오디오·완성 아트.
- 미구현: 빵집/광장/산책길, 전체 15분 흐름, 엔딩, 저장, 오디오, 완성 아트, Windows 실행 검증.
- 전제: 정류장에서 주민·표지판이 보이는 한 화면 지형은 데모 구현용 임시 배치. 포미의 방문 이유, 나침반의 능력, 숲속 소년 정체 등 미확정 세계관은 추가하지 않았습니다. 소렌을 주인공으로 바꾸거나 새 확정 주민을 만들지 않았습니다.
