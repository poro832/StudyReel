# 빌드 & 배포 가이드

> 본 프로젝트는 Cloud Functions를 사용하지 않으므로 `firebase deploy`가 필요 없습니다.
> 배포 = **APK 빌드 + 에뮬레이터/기기 설치**입니다. (사유: [ADR-0003](../.planning/decisions/ADR-0003-no-cloud-functions.md))

## 1. 디버그 APK 빌드

```bash
cd studyreel
flutter build apk --debug \
  --dart-define=YOUTUBE_API_KEY=<your_youtube_key> \
  --dart-define=GEMINI_API_KEY=<your_gemini_key>
```

⚠️ 한글 경로 우회로 인해 콘솔에 다음 메시지가 출력됩니다 — **정상입니다**:

```
Gradle build failed to produce an .apk file ...
```

실제 산출물 위치:

```
C:/temp/studyreel_build/app/outputs/flutter-apk/app-debug.apk
```

## 2. 릴리스 APK 빌드

```bash
flutter build apk --release \
  --dart-define=YOUTUBE_API_KEY=<your_youtube_key>
```

## 3. 에뮬레이터/기기 설치

```bash
# 설치 가능 기기 확인
adb devices

# BlueStacks 사용 시
adb connect 127.0.0.1:5555

# 설치 (기기가 여러 개면 -s 로 대상 지정)
adb -s 127.0.0.1:5555 install -r C:/temp/studyreel_build/app/outputs/flutter-apk/app-debug.apk
```

## 4. 배포 체크리스트

- [ ] `flutter analyze` — 에러/경고 0건
- [ ] `flutter test` — 전체 통과
- [ ] API 키 2종 `--dart-define` 주입 확인
- [ ] `google-services.json` 실제 자격증명인지 확인
- [ ] Firestore 보안 규칙 점검 (현재 테스트 모드 — 운영 전 강화 필요)
