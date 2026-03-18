# EmpowerSquareAddon

## 목차 Table of Contents

- [개요 Overview](#overview)
- [주요 기능 Features](#features)
- [프로젝트 구조 Project Structure](#project-structure)
- [로컬 설치 대상 Local Install Target](#local-install-target)
- [개발 Development](#development)
- [비고 Notes](#notes)

<a id="overview"></a>
## 개요 Overview

`EmpowerSquare`는 기원사의 강화(Empower) 주문 단계를 사각형 색상으로 보여주는 World of Warcraft 애드온입니다.

`EmpowerSquare` is a World of Warcraft addon that shows a stage-based square indicator for Evoker empower spells.

<a id="features"></a>
## 주요 기능 Features

- 현재 강화 단계에 맞는 사각형 인디케이터를 표시합니다.
- 고정 팔레트에서 단계별 색상을 설정할 수 있습니다.
- 서로 다른 단계에 같은 색이 중복 배정되지 않게 막습니다.
- 인디케이터 크기와 위치를 조정할 수 있습니다.
- 텍스트 라벨을 사각형 위에 배치해 감지 영역을 보호합니다.

- Displays a square indicator for the current empower stage.
- Uses configurable stage colors from a fixed palette.
- Prevents duplicate color assignments across stages.
- Includes size and position controls for the indicator.
- Keeps the label above the square to protect the detection area.

<a id="project-structure"></a>
## 프로젝트 구조 Project Structure

- [`EmpowerSquare/EmpowerSquare.toc`](./EmpowerSquare/EmpowerSquare.toc)
- [`EmpowerSquare/EmpowerSquare.lua`](./EmpowerSquare/EmpowerSquare.lua)
- [`scripts/sync_to_wow.sh`](./scripts/sync_to_wow.sh)

<a id="local-install-target"></a>
## 로컬 설치 대상 Local Install Target

동기화 스크립트는 아래 경로로 파일을 복사합니다.

The sync script copies files to the path below.

`/Applications/World of Warcraft/_retail_/Interface/AddOns/EmpowerSquare`

<a id="development"></a>
## 개발 Development

애드온 파일을 WoW AddOns 디렉터리로 동기화합니다.

Sync the addon files into the WoW AddOns directory.

```bash
./scripts/sync_to_wow.sh
```

게임 내 UI를 다시 불러옵니다.

Reload the UI in game.

```text
/reload
```

설정 창을 엽니다.

Open the addon settings.

```text
/es
```

<a id="notes"></a>
## 비고 Notes

- 이 애드온은 일반 캐스팅 추적이 아니라 강화 단계 가시성에 초점을 둡니다.
- 단계 색상은 설정 UI에서 직접 편집합니다.
- 이 저장소는 애드온 소스 파일과 로컬 동기화 스크립트만 포함합니다.

- The addon is intended for empower-stage visibility rather than generic cast tracking.
- Stage colors are edited in the addon settings UI.
- The project contains only addon source files and the local sync helper script.
