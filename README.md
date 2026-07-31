# 판교캠 오늘의 메뉴 위젯

판교캠의 금주 중식·석식을 macOS 바탕화면에서 확인하는 WidgetKit 위젯입니다. [SKALA Lunch](https://skala-lunch.ewkimhyunsu11.workers.dev/) 사이트의 공개 API에서 식단을 직접 가져오므로 별도의 로그인이나 인증 정보가 필요하지 않습니다.

## 주요 기능

- 중식·석식과 후식 표시
- 좌우 버튼으로 금주의 다른 날짜 탐색
- 날짜가 바뀌면 오늘 메뉴로 자동 이동
- 15분마다 식단 자동 갱신
- macOS 기본 위젯 UI와 대형 위젯 크기 지원
- 사용자 계정, 쿠키, 토큰 등 개인정보 저장 없음

## 요구 사항

- macOS 14 이상
- Xcode 16 이상
- 인터넷 연결

Apple Developer Program 유료 멤버십은 필요하지 않습니다. 각 사용자의 Mac에서 소스를 직접 빌드하고 로컬 서명하여 설치합니다.

## 설치

1. 이 저장소를 `git clone`하거나 GitHub의 **Code → Download ZIP**으로 내려받습니다.
2. 터미널에서 프로젝트 폴더로 이동합니다.
3. 다음 명령을 실행합니다.

```sh
./scripts/install.sh
```

설치 스크립트는 앱을 빌드한 뒤 `~/Applications/PangyoMenu.app`에 설치하고 위젯 확장을 macOS에 등록합니다.

설치가 끝나면:

1. 바탕화면을 우클릭합니다.
2. **위젯 편집**을 선택합니다.
3. **오늘의 메뉴**를 검색합니다.
4. 대형 위젯을 바탕화면에 추가합니다.

## 개발

앱만 빌드하려면 다음 명령을 사용합니다.

```sh
./scripts/build-app.sh
```

빌드 결과는 `dist/PangyoMenu.app`에 생성됩니다.

사이트 API 응답 파싱과 날짜 처리를 테스트하려면 다음 명령을 사용합니다.

```sh
swift test
```

Xcode에서 작업하려면 `PangyoMenuWidget.xcodeproj`를 열고 `MenuWidgetHost` 스킴을 선택합니다.

## 프로젝트 구조

```text
Sources/MenuWidgetCore/       식단 API 클라이언트와 공용 모델
WidgetExtension/              WidgetKit 위젯 UI와 타임라인
WidgetHost/                   설치 후 안내용 macOS 앱
Tests/MenuWidgetCoreTests/    API 응답 및 날짜 처리 테스트
scripts/build-app.sh          로컬 빌드
scripts/install.sh            빌드·설치·위젯 등록
```

## 데이터와 개인정보

식단 데이터는 다음 공개 엔드포인트에서 직접 읽습니다.

```text
https://skala-lunch.ewkimhyunsu11.workers.dev/api/menus/current
```

앱에는 Slack 연동 코드가 없으며 Slack 로그인, 워크스페이스 권한, API 토큰을 요구하지 않습니다. 식단 사이트가 중단되거나 응답 형식을 변경하면 위젯에서 메뉴를 불러오지 못할 수 있습니다.

## 문제 해결

- `xcode-select` 관련 오류가 나오면 Xcode를 한 번 실행한 뒤 다시 설치해보세요.
- 위젯 목록에 보이지 않으면 `./scripts/install.sh`를 다시 실행한 뒤 위젯 편집 창을 다시 여세요.
- 이전 메뉴가 남아 있으면 위젯을 제거한 뒤 다시 추가하세요.

## 배포 참고

이 저장소의 기본 배포 방식은 소스 빌드입니다. GitHub Releases에 미공증 `.app` 파일을 그대로 올리면 다른 Mac의 Gatekeeper가 실행을 제한할 수 있습니다. 서명된 바이너리를 배포하려면 Apple Developer Program의 Developer ID와 공증 절차가 필요합니다.

## 라이선스

소스 코드는 [MIT License](LICENSE)로 배포합니다. 식단 데이터와 외부 사이트의 권리는 각 제공자에게 있습니다.
