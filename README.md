# 판교캠 오늘의 메뉴 위젯

판교캠의 금주 중식·석식을 macOS 바탕화면에서 확인하는 WidgetKit 위젯입니다. [SKALA Lunch](https://skala-lunch.ewkimhyunsu11.workers.dev/) 사이트의 공개 API에서 식단을 직접 가져오므로 별도의 로그인이나 인증 정보가 필요하지 않습니다.

## 주요 기능

- 중식·석식과 후식 표시
- 좌우 버튼으로 금주의 다른 날짜 탐색
- 날짜 이동 버튼은 다른 페이지를 열지 않고 위젯 안에서만 동작
- 날짜가 바뀌면 오늘 메뉴로 자동 이동
- 15분마다 식단 자동 갱신
- 일시적인 네트워크 오류에는 마지막으로 받은 메뉴를 표시하고 1분 후 재시도
- macOS 기본 위젯 UI와 대형 위젯 크기 지원
- 사용자 계정, 쿠키, 토큰 등 개인정보 저장 없음

## 요구 사항

- macOS 14 이상
- 인터넷 연결

일반 설치에는 Xcode, Git, Apple Developer 계정이 필요하지 않습니다. Apple Silicon과 Intel Mac을 모두 지원합니다.

## 설치

터미널을 열고 다음 명령을 한 번 실행합니다.

```sh
/bin/zsh -c "$(curl -fsSL https://raw.githubusercontent.com/chaeeunwang/pangyo-menu-widget/main/scripts/install.sh)"
```

설치 스크립트는 GitHub Releases에서 사전 빌드된 최신 앱과 SHA-256 체크섬을 내려받아 검증합니다. 앱은 `~/Applications/PangyoMenu.app`에 설치되고 위젯 확장은 macOS에 자동 등록됩니다.

설치가 끝나도 별도의 앱 창은 열리지 않습니다.

원격 스크립트를 바로 실행하고 싶지 않다면 저장소의 **Code → Download ZIP**을 선택해 압축을 풀고, 해당 폴더에서 다음 명령을 실행해도 됩니다.

```sh
./scripts/install.sh
```

설치가 끝나면:

1. 바탕화면을 우클릭합니다.
2. **위젯 편집**을 선택합니다.
3. **오늘의 메뉴**를 검색합니다.
4. 위젯을 바탕화면에 추가합니다.

새 버전으로 업데이트할 때도 같은 설치 명령을 다시 실행하면 됩니다.

## 개발

개발과 소스 빌드에는 Xcode 16 이상이 필요합니다.

앱만 빌드하려면 다음 명령을 사용합니다.

```sh
./scripts/build-app.sh
```

빌드 결과는 `dist/PangyoMenu.app`에 생성됩니다.

직접 빌드한 앱을 설치하려면 다음 명령을 사용합니다.

```sh
./scripts/install-from-source.sh
```

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
scripts/install.sh            Release 다운로드·검증·설치
scripts/install-from-source.sh  소스 빌드·설치
scripts/package-release.sh    배포 ZIP과 체크섬 생성
```

## 데이터와 개인정보

식단 데이터는 다음 공개 엔드포인트에서 직접 읽습니다.

```text
https://skala-lunch.ewkimhyunsu11.workers.dev/api/menus/current
```

앱에는 Slack 연동 코드가 없으며 Slack 로그인, 워크스페이스 권한, API 토큰을 요구하지 않습니다. 일시적인 연결 오류에 대비해 최근 7일 이내에 성공적으로 받은 식단만 Mac의 위젯 전용 저장소에 보관합니다. 식단 사이트가 장기간 중단되거나 응답 형식을 변경하면 위젯에서 메뉴를 불러오지 못할 수 있습니다.

## 문제 해결

- 다운로드 오류가 발생하면 인터넷 연결과 [GitHub Releases](https://github.com/chaeeunwang/pangyo-menu-widget/releases)를 확인하세요.
- 위젯 목록에 보이지 않으면 `./scripts/install.sh`를 다시 실행한 뒤 위젯 편집 창을 다시 여세요.
- 이전 메뉴가 남아 있으면 위젯을 제거한 뒤 다시 추가하세요.
- 위젯이 빈 회색으로 보이면 설치 명령을 다시 실행해 중복 등록된 개발용 위젯을 정리하세요.
- 회사 보안 정책에 따라 외부 앱 실행이 차단되면 사내 보안 담당자에게 문의하세요.

## 배포와 보안

Release 앱은 GitHub Actions의 macOS 환경에서 빌드하고 임시(ad-hoc) 코드 서명합니다. 설치기는 HTTPS로 받은 ZIP의 SHA-256 체크섬과 앱 번들 식별자, 코드 서명을 모두 확인합니다. 현재 Apple Developer Program의 Developer ID 서명과 공증은 사용하지 않습니다.

설치기는 이 앱에 한해서만 다운로드 격리 속성을 제거합니다. 스크립트와 소스는 실행 전에 직접 검토할 수 있으며, 조직의 보안 정책이 미공증 앱을 차단하는 경우 설치하지 마세요.

## 라이선스

소스 코드는 [MIT License](LICENSE)로 배포합니다. 식단 데이터와 외부 사이트의 권리는 각 제공자에게 있습니다.
