# 셋업 가이드

5분 안에 `flutter run`까지 도달하는 것을 목표로 합니다.

## 1. 사전 요구사항

| 도구 | 버전 |
|------|------|
| Flutter SDK | 3.10+ (3.35.4 검증) |
| Dart | Flutter 동봉 버전 |
| Android Studio | 에뮬레이터/SDK 관리용 |
| Java | Android Studio 동봉 JDK |

```bash
flutter --version
flutter doctor
```

## 2. 의존성 설치

```bash
cd studyreel
flutter pub get
```

## 3. API 키 발급 (2개)

| 키 | 발급처 | 용도 |
|----|--------|------|
| `YOUTUBE_API_KEY` | Google Cloud Console → YouTube Data API v3 | 학습 영상 검색 |
| `GEMINI_API_KEY` | Google AI Studio | (선택) 향후 AI 요약 확장용 |

> 현재 활성 기능은 YouTube 검색만 사용합니다. `GEMINI_API_KEY`는 비워도 앱이 동작합니다.

## 4. Firebase 연결

`android/app/google-services.json` 이 실제 프로젝트(`studyreel-53c70`) 자격증명으로 채워져 있어야 합니다.
재설정이 필요하면:

```bash
flutterfire configure --project=studyreel-53c70 --platforms=android --yes
```

## 5. 실행

```bash
flutter run \
  --dart-define=YOUTUBE_API_KEY=<your_youtube_key> \
  --dart-define=GEMINI_API_KEY=<your_gemini_key>
```

에뮬레이터가 없으면 Android Studio → **Device Manager → Create Virtual Device**
(⚠️ `Pre-Release` / `16 KB Page size` 이미지는 다운로드 깨짐 이슈가 있으니 **안정 버전 API 34/35/36**을 선택).

## 6. 한글 경로 빌드 이슈

프로젝트 경로에 한글이 포함되면 `impellerc.exe`가 크래시합니다.
`android/app/build.gradle.kts`에서 빌드 출력을 ASCII 경로로 리다이렉트해 우회합니다:

```kotlin
layout.buildDirectory.set(file("C:/temp/studyreel_build/app"))
```

따라서 `flutter build apk`는 "couldn't find apk" 메시지를 출력하지만,
APK는 `C:/temp/studyreel_build/app/outputs/flutter-apk/app-debug.apk` 에 정상 생성됩니다.
자세한 내용은 [`docs/deploy.md`](./deploy.md) 참조.
