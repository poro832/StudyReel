# StudyReel Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 관심사 기반 AI 학습 카드를 릴스 스타일로 소비하고, 관련 유튜브 쇼츠로 연결되는 Flutter 모바일 앱 MVP를 6주 안에 완성한다.

**Architecture:** Flutter 앱 → Firebase (Auth + Firestore + Cloud Functions) → Claude API (카드 생성) + YouTube Data API v3 (쇼츠 검색). Cloud Functions가 API 키를 보호하는 미들웨어 역할을 한다. 상태 관리는 Riverpod, 라우팅은 go_router를 사용한다.

**Tech Stack:** Flutter 3.x, Dart, Firebase (Auth/Firestore/Functions), Riverpod, go_router, url_launcher, Claude API (claude-sonnet-4-6), YouTube Data API v3, mocktail (테스트)

---

## 파일 구조 전체 맵

```
studyreel/
├── lib/
│   ├── main.dart                          # 앱 진입점, Firebase 초기화
│   ├── core/
│   │   ├── router.dart                    # go_router 라우트 정의
│   │   └── theme.dart                     # 다크 테마, 색상 상수
│   ├── data/
│   │   ├── models/
│   │   │   ├── study_card.dart            # 학습 카드 데이터 모델
│   │   │   └── youtube_short.dart         # 유튜브 쇼츠 데이터 모델
│   │   ├── repositories/
│   │   │   ├── card_repository.dart       # Firestore 카드 CRUD
│   │   │   └── auth_repository.dart       # Firebase Auth 래퍼
│   │   └── services/
│   │       └── youtube_service.dart       # YouTube API 호출
│   ├── domain/
│   │   ├── card_provider.dart             # 카드 피드 상태 (Riverpod)
│   │   ├── auth_provider.dart             # 로그인 상태 (Riverpod)
│   │   └── topic_provider.dart            # 관심사 선택 상태 (Riverpod)
│   └── presentation/
│       ├── onboarding/
│       │   └── onboarding_screen.dart     # 관심사 선택 화면
│       ├── feed/
│       │   ├── feed_screen.dart           # 메인 피드 (PageView)
│       │   └── card_widget.dart           # 개별 학습 카드 위젯
│       ├── detail/
│       │   └── card_detail_screen.dart    # 카드 상세 + 유튜브 목록
│       └── profile/
│           └── profile_screen.dart        # 프로필 + 관심사 수정
├── functions/
│   ├── index.js                           # Cloud Functions 진입점
│   ├── generateCards.js                   # Claude API 호출 함수
│   └── package.json
├── test/
│   ├── models/
│   │   └── study_card_test.dart
│   ├── repositories/
│   │   └── card_repository_test.dart
│   └── domain/
│       └── card_provider_test.dart
└── integration_test/
    └── feed_flow_test.dart                # 피드 스와이프 E2E
```

---

## Task 1: Flutter 프로젝트 초기화 & 의존성 설정 (10주차)

**Files:**
- Create: `studyreel/pubspec.yaml`
- Create: `studyreel/lib/main.dart`
- Create: `studyreel/lib/core/theme.dart`
- Create: `studyreel/lib/core/router.dart`

- [ ] **Step 1: Flutter 프로젝트 생성**

```bash
flutter create studyreel --org com.studyreel --platforms android,ios
cd studyreel
```

- [ ] **Step 2: pubspec.yaml에 의존성 추가**

`pubspec.yaml`의 `dependencies` 섹션을 다음으로 교체:

```yaml
dependencies:
  flutter:
    sdk: flutter
  # Firebase
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.0
  cloud_firestore: ^5.4.0
  cloud_functions: ^5.1.0
  google_sign_in: ^6.2.0
  # 상태 관리 & 라우팅
  flutter_riverpod: ^2.5.1
  go_router: ^14.2.0
  # 유틸리티
  url_launcher: ^6.3.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.4
  fake_cloud_firestore: ^3.0.3
  firebase_auth_mocks: ^0.14.0
```

- [ ] **Step 3: 의존성 설치**

```bash
flutter pub get
```

Expected: `Got dependencies!` 출력, 에러 없음

- [ ] **Step 4: 다크 테마 정의**

`lib/core/theme.dart`:

```dart
import 'package:flutter/material.dart';

const kBgColor     = Color(0xFF0F0F1A);
const kCardColor   = Color(0xFF1A1A2E);
const kPrimaryColor = Color(0xFF6C63FF);
const kTextGray    = Color(0xFFA0A0B0);
const kRedAccent   = Color(0xFFFF4444);

final appTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: kBgColor,
  colorScheme: const ColorScheme.dark(
    primary: kPrimaryColor,
    surface: kCardColor,
  ),
  fontFamily: 'Pretendard',
  useMaterial3: true,
);
```

- [ ] **Step 5: 라우터 정의**

`lib/core/router.dart`:

```dart
import 'package:go_router/go_router.dart';
import '../presentation/onboarding/onboarding_screen.dart';
import '../presentation/feed/feed_screen.dart';
import '../presentation/detail/card_detail_screen.dart';
import '../presentation/profile/profile_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/onboarding',
  routes: [
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/feed',       builder: (_, __) => const FeedScreen()),
    GoRoute(
      path: '/detail/:cardId',
      builder: (_, state) => CardDetailScreen(cardId: state.pathParameters['cardId']!),
    ),
    GoRoute(path: '/profile',    builder: (_, __) => const ProfileScreen()),
  ],
);
```

- [ ] **Step 6: main.dart 작성**

`lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme.dart';
import 'core/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ProviderScope(child: StudyReelApp()));
}

class StudyReelApp extends StatelessWidget {
  const StudyReelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'StudyReel',
      theme: appTheme,
      routerConfig: appRouter,
    );
  }
}
```

- [ ] **Step 7: 빌드 확인**

```bash
flutter run
```

Expected: 앱이 실행되고 흰 화면 또는 onboarding 라우트로 이동

- [ ] **Step 8: 커밋**

```bash
git add studyreel/
git commit -m "feat: Flutter 프로젝트 초기화 및 의존성 설정"
```

---

## Task 2: Firebase 초기화 & Google 로그인 (10주차)

**Files:**
- Create: `studyreel/lib/data/repositories/auth_repository.dart`
- Create: `studyreel/lib/domain/auth_provider.dart`
- Create: `studyreel/test/repositories/auth_repository_test.dart`

> **사전 작업**: Firebase Console에서 프로젝트 생성 후 `flutterfire configure` 실행 → `firebase_options.dart` 자동 생성

- [ ] **Step 1: FlutterFire CLI로 Firebase 연결**

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=YOUR_FIREBASE_PROJECT_ID
```

Expected: `lib/firebase_options.dart` 파일 생성됨

- [ ] **Step 2: main.dart에 firebase_options 적용**

`lib/main.dart`의 `Firebase.initializeApp()` 라인을 수정:

```dart
import 'firebase_options.dart';
// ...
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

- [ ] **Step 3: 실패 테스트 작성**

`test/repositories/auth_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:google_sign_in_mocks/google_sign_in_mocks.dart';
import 'package:studyreel/data/repositories/auth_repository.dart';

void main() {
  group('AuthRepository', () {
    late MockFirebaseAuth mockAuth;
    late MockGoogleSignIn mockGoogleSignIn;
    late AuthRepository repo;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockGoogleSignIn = MockGoogleSignIn();
      repo = AuthRepository(auth: mockAuth, googleSignIn: mockGoogleSignIn);
    });

    test('signInWithGoogle returns user on success', () async {
      final user = await repo.signInWithGoogle();
      expect(user, isNotNull);
    });

    test('signOut clears current user', () async {
      await repo.signInWithGoogle();
      await repo.signOut();
      expect(repo.currentUser, isNull);
    });
  });
}
```

- [ ] **Step 4: 테스트 실행 — 실패 확인**

```bash
flutter test test/repositories/auth_repository_test.dart
```

Expected: FAIL — `AuthRepository` 클래스 없음

- [ ] **Step 5: AuthRepository 구현**

`lib/data/repositories/auth_repository.dart`:

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthRepository({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final result = await _auth.signInWithCredential(credential);
    return result.user;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
```

- [ ] **Step 6: 테스트 실행 — 통과 확인**

```bash
flutter test test/repositories/auth_repository_test.dart
```

Expected: PASS (2 tests)

- [ ] **Step 7: Riverpod Provider 작성**

`lib/domain/auth_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);

final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges,
);
```

- [ ] **Step 8: 커밋**

```bash
git add studyreel/
git commit -m "feat: Firebase Auth & Google 로그인 구현"
```

---

## Task 3: 온보딩 화면 — 관심사 선택 (10주차)

**Files:**
- Create: `studyreel/lib/domain/topic_provider.dart`
- Create: `studyreel/lib/presentation/onboarding/onboarding_screen.dart`
- Create: `studyreel/test/domain/topic_provider_test.dart`

- [ ] **Step 1: 실패 테스트 작성**

`test/domain/topic_provider_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studyreel/domain/topic_provider.dart';

void main() {
  group('TopicNotifier', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('초기 상태: 선택된 토픽 없음', () {
      final topics = container.read(selectedTopicsProvider);
      expect(topics, isEmpty);
    });

    test('토픽 토글: 추가', () {
      container.read(selectedTopicsProvider.notifier).toggle('컴퓨터과학');
      expect(container.read(selectedTopicsProvider), contains('컴퓨터과학'));
    });

    test('토픽 토글: 이미 있으면 제거', () {
      final notifier = container.read(selectedTopicsProvider.notifier);
      notifier.toggle('컴퓨터과학');
      notifier.toggle('컴퓨터과학');
      expect(container.read(selectedTopicsProvider), isEmpty);
    });

    test('isValid: 3개 이상 선택 시 true', () {
      final notifier = container.read(selectedTopicsProvider.notifier);
      notifier.toggle('A');
      notifier.toggle('B');
      notifier.toggle('C');
      expect(container.read(selectedTopicsProvider.notifier).isValid, isTrue);
    });
  });
}
```

- [ ] **Step 2: 테스트 실행 — 실패 확인**

```bash
flutter test test/domain/topic_provider_test.dart
```

Expected: FAIL

- [ ] **Step 3: TopicNotifier 구현**

`lib/domain/topic_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

const kAvailableTopics = [
  '컴퓨터과학', '수학', '영어', '역사',
  '과학', '경제', '디자인', '심리학',
];

class TopicNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void toggle(String topic) {
    if (state.contains(topic)) {
      state = {...state}..remove(topic);
    } else {
      state = {...state, topic};
    }
  }

  bool get isValid => state.length >= 3;
}

final selectedTopicsProvider =
    NotifierProvider<TopicNotifier, Set<String>>(TopicNotifier.new);
```

- [ ] **Step 4: 테스트 실행 — 통과 확인**

```bash
flutter test test/domain/topic_provider_test.dart
```

Expected: PASS (4 tests)

- [ ] **Step 5: 온보딩 화면 UI 구현**

`lib/presentation/onboarding/onboarding_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../domain/topic_provider.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedTopicsProvider);
    final notifier = ref.read(selectedTopicsProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Text('StudyReel',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor)),
              const SizedBox(height: 32),
              const Text('어떤 걸\n배우고 싶나요?',
                  style: TextStyle(
                      fontSize: 32, fontWeight: FontWeight.bold, height: 1.3)),
              const SizedBox(height: 12),
              const Text('3개 이상 선택해 주세요.',
                  style: TextStyle(color: kTextGray)),
              const SizedBox(height: 32),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: kAvailableTopics.map((topic) {
                  final isSelected = selected.contains(topic);
                  return GestureDetector(
                    onTap: () => notifier.toggle(topic),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? kPrimaryColor.withOpacity(0.25)
                            : kCardColor,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isSelected ? kPrimaryColor : Colors.white24,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(topic,
                          style: TextStyle(
                              color: isSelected ? kPrimaryColor : kTextGray,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal)),
                    ),
                  );
                }).toList(),
              ),
              const Spacer(),
              Text('${selected.length}개 선택됨',
                  style: const TextStyle(color: kTextGray),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: notifier.isValid
                      ? () => context.go('/feed')
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    disabledBackgroundColor: kPrimaryColor.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('시작하기 →',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: 빌드 & 수동 확인**

```bash
flutter run
```

확인 사항: 토픽 칩 탭 시 색상 변경, 3개 이상 선택 시 버튼 활성화, 버튼 탭 시 `/feed` 이동

- [ ] **Step 7: 커밋**

```bash
git add studyreel/
git commit -m "feat: 온보딩 화면 — 관심사 선택 UI"
```

---

## Task 4: Cloud Functions + Claude API 카드 생성 (11주차)

**Files:**
- Create: `studyreel/functions/index.js`
- Create: `studyreel/functions/generateCards.js`
- Create: `studyreel/functions/package.json`

- [ ] **Step 1: Firebase Functions 초기화**

```bash
cd studyreel
firebase init functions  # JavaScript 선택, ESLint 스킵
```

- [ ] **Step 2: Anthropic SDK 설치**

```bash
cd functions
npm install @anthropic-ai/sdk
```

- [ ] **Step 3: generateCards.js 작성**

`functions/generateCards.js`:

```javascript
const Anthropic = require("@anthropic-ai/sdk");

const client = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

/**
 * topics: string[] — 선택된 관심사 목록
 * count: number — 생성할 카드 수 (기본 5)
 * returns: StudyCard[]
 */
async function generateCards(topics, count = 5) {
  const topicStr = topics.join(", ");

  const message = await client.messages.create({
    model: "claude-sonnet-4-6",
    max_tokens: 2048,
    messages: [
      {
        role: "user",
        content: `다음 관심사 분야에서 대학생이 2분 안에 읽을 수 있는 학습 카드 ${count}개를 JSON 배열로 생성하세요.
관심사: ${topicStr}

각 카드는 다음 형식을 따르세요:
{
  "id": "고유 UUID",
  "topic": "분야명",
  "title": "개념 제목 (15자 이내)",
  "oneLiner": "한 줄 설명 (30자 이내)",
  "points": ["핵심 포인트 1", "핵심 포인트 2", "핵심 포인트 3"],
  "keywords": ["검색 키워드1", "검색 키워드2"]
}

JSON 배열만 반환하세요. 다른 텍스트 없이.`,
      },
    ],
  });

  const raw = message.content[0].text.trim();
  return JSON.parse(raw);
}

module.exports = { generateCards };
```

- [ ] **Step 4: Cloud Function 엔드포인트 작성**

`functions/index.js`:

```javascript
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { generateCards } = require("./generateCards");

const anthropicKey = defineSecret("ANTHROPIC_API_KEY");

exports.generateStudyCards = onCall(
  { secrets: [anthropicKey] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "로그인이 필요합니다.");
    }

    const { topics, count = 5 } = request.data;

    if (!topics || !Array.isArray(topics) || topics.length < 1) {
      throw new HttpsError("invalid-argument", "topics 배열이 필요합니다.");
    }

    try {
      const cards = await generateCards(topics, count);
      return { cards };
    } catch (e) {
      throw new HttpsError("internal", `카드 생성 실패: ${e.message}`);
    }
  }
);
```

- [ ] **Step 5: API 키 시크릿 등록**

```bash
firebase functions:secrets:set ANTHROPIC_API_KEY
# 프롬프트에 Anthropic API 키 입력
```

- [ ] **Step 6: 로컬 에뮬레이터로 테스트**

```bash
firebase emulators:start --only functions
```

별도 터미널에서:
```bash
curl -X POST http://localhost:5001/YOUR_PROJECT/us-central1/generateStudyCards \
  -H "Content-Type: application/json" \
  -d '{"data":{"topics":["컴퓨터과학","수학"]}}'
```

Expected: `{"result":{"cards":[...]}}` 형태 JSON 반환

- [ ] **Step 7: 배포**

```bash
firebase deploy --only functions
```

Expected: `Deploy complete!`

- [ ] **Step 8: 커밋**

```bash
git add functions/
git commit -m "feat: Cloud Functions + Claude API 카드 생성 함수"
```

---

## Task 5: Firestore 카드 모델 & CardRepository (11주차)

**Files:**
- Create: `studyreel/lib/data/models/study_card.dart`
- Create: `studyreel/lib/data/repositories/card_repository.dart`
- Create: `studyreel/lib/domain/card_provider.dart`
- Create: `studyreel/test/models/study_card_test.dart`
- Create: `studyreel/test/repositories/card_repository_test.dart`

- [ ] **Step 1: StudyCard 모델 실패 테스트**

`test/models/study_card_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:studyreel/data/models/study_card.dart';

void main() {
  group('StudyCard', () {
    final sampleJson = {
      'id': 'card-1',
      'topic': '컴퓨터과학',
      'title': '재귀함수',
      'oneLiner': '자기 자신을 호출하는 함수',
      'points': ['Base Case 필요', '스택 사용', '트리 탐색에 활용'],
      'keywords': ['재귀', 'recursion'],
    };

    test('fromJson 파싱 정상', () {
      final card = StudyCard.fromJson(sampleJson);
      expect(card.id, 'card-1');
      expect(card.points.length, 3);
    });

    test('toJson 직렬화 정상', () {
      final card = StudyCard.fromJson(sampleJson);
      expect(card.toJson()['title'], '재귀함수');
    });
  });
}
```

- [ ] **Step 2: 테스트 실행 — 실패 확인**

```bash
flutter test test/models/study_card_test.dart
```

Expected: FAIL

- [ ] **Step 3: StudyCard 모델 구현**

`lib/data/models/study_card.dart`:

```dart
class StudyCard {
  final String id;
  final String topic;
  final String title;
  final String oneLiner;
  final List<String> points;
  final List<String> keywords;

  const StudyCard({
    required this.id,
    required this.topic,
    required this.title,
    required this.oneLiner,
    required this.points,
    required this.keywords,
  });

  factory StudyCard.fromJson(Map<String, dynamic> json) => StudyCard(
        id: json['id'] as String,
        topic: json['topic'] as String,
        title: json['title'] as String,
        oneLiner: json['oneLiner'] as String,
        points: List<String>.from(json['points'] as List),
        keywords: List<String>.from(json['keywords'] as List),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'topic': topic,
        'title': title,
        'oneLiner': oneLiner,
        'points': points,
        'keywords': keywords,
      };
}
```

- [ ] **Step 4: 모델 테스트 통과 확인**

```bash
flutter test test/models/study_card_test.dart
```

Expected: PASS (2 tests)

- [ ] **Step 5: CardRepository 실패 테스트**

`test/repositories/card_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:studyreel/data/repositories/card_repository.dart';
import 'package:studyreel/data/models/study_card.dart';

void main() {
  group('CardRepository', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;
    late CardRepository repo;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockAuth = MockFirebaseAuth(signedIn: true);
      repo = CardRepository(firestore: fakeFirestore, auth: mockAuth);
    });

    test('saveCards — Firestore에 카드 저장', () async {
      final cards = [
        StudyCard(
          id: 'c1', topic: '수학', title: '미적분',
          oneLiner: '변화율', points: ['a', 'b', 'c'], keywords: ['calculus'],
        ),
      ];
      await repo.saveCards(cards);
      final snap = await fakeFirestore
          .collection('users')
          .doc(mockAuth.currentUser!.uid)
          .collection('cards')
          .get();
      expect(snap.docs.length, 1);
    });

    test('loadCards — 저장된 카드 불러오기', () async {
      final cards = [
        StudyCard(
          id: 'c2', topic: '역사', title: '조선시대',
          oneLiner: '500년 왕조', points: ['a', 'b', 'c'], keywords: ['조선'],
        ),
      ];
      await repo.saveCards(cards);
      final loaded = await repo.loadCards();
      expect(loaded.first.id, 'c2');
    });
  });
}
```

- [ ] **Step 6: CardRepository 구현**

`lib/data/repositories/card_repository.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/study_card.dart';

class CardRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CardRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _cardsRef => _firestore
      .collection('users')
      .doc(_auth.currentUser!.uid)
      .collection('cards');

  Future<void> saveCards(List<StudyCard> cards) async {
    final batch = _firestore.batch();
    for (final card in cards) {
      batch.set(_cardsRef.doc(card.id), card.toJson());
    }
    await batch.commit();
  }

  Future<List<StudyCard>> loadCards() async {
    final snap = await _cardsRef.orderBy(FieldPath.documentId).get();
    return snap.docs.map((d) => StudyCard.fromJson(d.data())).toList();
  }

  Future<List<StudyCard>> fetchAndSaveCards(List<String> topics) async {
    final callable = FirebaseFunctions.instance.httpsCallable('generateStudyCards');
    final result = await callable.call({'topics': topics, 'count': 5});
    final raw = List<Map<String, dynamic>>.from(result.data['cards'] as List);
    final cards = raw.map(StudyCard.fromJson).toList();
    await saveCards(cards);
    return cards;
  }
}
```

- [ ] **Step 7: 레포지토리 테스트 통과 확인**

```bash
flutter test test/repositories/card_repository_test.dart
```

Expected: PASS (2 tests)

- [ ] **Step 8: CardProvider 작성**

`lib/domain/card_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/card_repository.dart';
import '../data/models/study_card.dart';

final cardRepositoryProvider = Provider<CardRepository>(
  (ref) => CardRepository(),
);

// 마지막으로 로드된 카드 목록을 전역 캐시로 보관 (상세 화면에서 접근)
final cachedCardsProvider = StateProvider<List<StudyCard>>((_) => []);

final cardFeedProvider = FutureProvider.family<List<StudyCard>, List<String>>(
  (ref, topics) async {
    final repo = ref.read(cardRepositoryProvider);
    final cached = await repo.loadCards();
    final cards = cached.isNotEmpty ? cached : await repo.fetchAndSaveCards(topics);
    ref.read(cachedCardsProvider.notifier).state = cards;
    return cards;
  },
);
```

- [ ] **Step 9: 커밋**

```bash
git add studyreel/
git commit -m "feat: StudyCard 모델, CardRepository, CardProvider 구현"
```

---

## Task 6: 메인 피드 UI — 스와이프 카드 (12주차)

**Files:**
- Create: `studyreel/lib/presentation/feed/card_widget.dart`
- Create: `studyreel/lib/presentation/feed/feed_screen.dart`

- [ ] **Step 1: CardWidget 구현**

`lib/presentation/feed/card_widget.dart`:

```dart
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/models/study_card.dart';

class CardWidget extends StatelessWidget {
  final StudyCard card;
  final VoidCallback onTap;

  const CardWidget({super.key, required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 토픽 태그
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(card.topic,
                    style: const TextStyle(
                        color: kPrimaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ),
              const SizedBox(height: 20),
              // 개념 제목
              Text(card.title,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 8),
              Text(card.oneLiner,
                  style: const TextStyle(color: kTextGray, fontSize: 14)),
              const Divider(color: Colors.white12, height: 40),
              // 핵심 포인트
              ...card.points.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('✦ ',
                            style: TextStyle(
                                color: kPrimaryColor, fontSize: 12)),
                        Expanded(
                          child: Text(p,
                              style: const TextStyle(
                                  color: Color(0xFFD8D8E8), fontSize: 13,
                                  height: 1.5)),
                        ),
                      ],
                    ),
                  )),
              const Spacer(),
              // 유튜브 연결 버튼
              Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: kRedAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kRedAccent.withOpacity(0.5)),
                ),
                child: const Center(
                  child: Text('▶  관련 유튜브 쇼츠 보기',
                      style: TextStyle(color: Color(0xFFFF8080), fontSize: 14,
                          fontWeight: FontWeight.w500)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: FeedScreen 구현**

`lib/presentation/feed/feed_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../domain/card_provider.dart';
import '../../domain/topic_provider.dart';
import 'card_widget.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topics = ref.watch(selectedTopicsProvider).toList();
    final cardsAsync = ref.watch(cardFeedProvider(topics));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 탑 탭바
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Row(
                children: [
                  const Text('오늘의 학습',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                  const SizedBox(width: 20),
                  const Text('탐색',
                      style: TextStyle(fontSize: 16, color: kTextGray)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.push('/profile'),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: kPrimaryColor,
                      child: const Text('나',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // 카드 피드
            Expanded(
              child: cardsAsync.when(
                data: (cards) => PageView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: cards.length,
                  itemBuilder: (context, index) => CardWidget(
                    card: cards[index],
                    onTap: () => context.push('/detail/${cards[index].id}'),
                  ),
                ),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('카드를 불러오지 못했습니다.',
                          style: TextStyle(color: kTextGray)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(cardFeedProvider),
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: 수동 테스트 — 피드 동작 확인**

```bash
flutter run
```

확인 사항:
- 온보딩에서 관심사 선택 후 피드 진입 시 카드 로딩 스피너 표시
- 카드 생성 완료 후 세로 스와이프로 다음 카드 이동
- 카드 탭 시 `/detail/:id` 라우트 이동

- [ ] **Step 4: 커밋**

```bash
git add studyreel/lib/presentation/feed/
git commit -m "feat: 메인 피드 UI — PageView 스와이프 카드"
```

---

## Task 7: YouTube API + 카드 상세 화면 (13주차)

**Files:**
- Create: `studyreel/lib/data/models/youtube_short.dart`
- Create: `studyreel/lib/data/services/youtube_service.dart`
- Create: `studyreel/lib/presentation/detail/card_detail_screen.dart`
- Create: `studyreel/functions/searchYouTube.js`
- Modify: `studyreel/functions/index.js`

- [ ] **Step 1: YouTubeShort 모델 & YouTube Cloud Function**

`functions/searchYouTube.js`:

```javascript
const https = require("https");

/**
 * keywords: string[] — 검색 키워드
 * returns: YoutubeShort[]
 */
async function searchYouTubeShorts(keywords, apiKey) {
  const query = encodeURIComponent(keywords.join(" ") + " 쇼츠 설명");
  const url =
    `https://www.googleapis.com/youtube/v3/search` +
    `?part=snippet&q=${query}&type=video&videoDuration=short` +
    `&maxResults=3&key=${apiKey}`;

  return new Promise((resolve, reject) => {
    https.get(url, (res) => {
      let data = "";
      res.on("data", (chunk) => (data += chunk));
      res.on("end", () => {
        const json = JSON.parse(data);
        const shorts = (json.items || []).map((item) => ({
          videoId: item.id.videoId,
          title: item.snippet.title,
          channelTitle: item.snippet.channelTitle,
          thumbnailUrl: item.snippet.thumbnails.medium.url,
          url: `https://www.youtube.com/shorts/${item.id.videoId}`,
        }));
        resolve(shorts);
      });
      res.on("error", reject);
    });
  });
}

module.exports = { searchYouTubeShorts };
```

`functions/index.js`에 추가:

```javascript
const { searchYouTubeShorts } = require("./searchYouTube");
const youtubeKey = defineSecret("YOUTUBE_API_KEY");

exports.searchShorts = onCall(
  { secrets: [youtubeKey] },
  async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "로그인 필요");
    const { keywords } = request.data;
    if (!keywords || !Array.isArray(keywords))
      throw new HttpsError("invalid-argument", "keywords 배열 필요");
    try {
      const shorts = await searchYouTubeShorts(keywords, process.env.YOUTUBE_API_KEY);
      return { shorts };
    } catch (e) {
      throw new HttpsError("internal", `유튜브 검색 실패: ${e.message}`);
    }
  }
);
```

- [ ] **Step 2: YouTube API 키 등록**

```bash
firebase functions:secrets:set YOUTUBE_API_KEY
# Google Cloud Console에서 발급한 YouTube Data API v3 키 입력
```

- [ ] **Step 3: YouTubeShort 모델**

`lib/data/models/youtube_short.dart`:

```dart
class YoutubeShort {
  final String videoId;
  final String title;
  final String channelTitle;
  final String thumbnailUrl;
  final String url;

  const YoutubeShort({
    required this.videoId,
    required this.title,
    required this.channelTitle,
    required this.thumbnailUrl,
    required this.url,
  });

  factory YoutubeShort.fromJson(Map<String, dynamic> json) => YoutubeShort(
        videoId: json['videoId'] as String,
        title: json['title'] as String,
        channelTitle: json['channelTitle'] as String,
        thumbnailUrl: json['thumbnailUrl'] as String,
        url: json['url'] as String,
      );
}
```

- [ ] **Step 4: YouTubeService**

`lib/data/services/youtube_service.dart`:

```dart
import 'package:cloud_functions/cloud_functions.dart';
import '../models/youtube_short.dart';

class YoutubeService {
  final FirebaseFunctions _functions;

  YoutubeService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  Future<List<YoutubeShort>> searchShorts(List<String> keywords) async {
    final callable = _functions.httpsCallable('searchShorts');
    final result = await callable.call({'keywords': keywords});
    final raw = List<Map<String, dynamic>>.from(result.data['shorts'] as List);
    return raw.map(YoutubeShort.fromJson).toList();
  }
}
```

- [ ] **Step 5: 카드 상세 화면**

`lib/presentation/detail/card_detail_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../domain/card_provider.dart';
import '../../data/services/youtube_service.dart';
import '../../data/models/youtube_short.dart';

final _youtubeServiceProvider = Provider<YoutubeService>((ref) => YoutubeService());

final _shortsProvider = FutureProvider.family<List<YoutubeShort>, List<String>>(
  (ref, keywords) => ref.read(_youtubeServiceProvider).searchShorts(keywords),
);

class CardDetailScreen extends ConsumerWidget {
  final String cardId;
  const CardDetailScreen({super.key, required this.cardId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // cachedCardsProvider에서 이미 로드된 카드 조회 (동기, 빠름)
    final cards = ref.watch(cachedCardsProvider);

    if (cards.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final allCardsAsync = AsyncValue.data(cards);

    return allCardsAsync.when(
      data: (cards) {
        final card = cards.firstWhere((c) => c.id == cardId);
        final shortsAsync = ref.watch(_shortsProvider(card.keywords));

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 뒤로가기
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: kCardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 토픽 태그
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(card.topic,
                        style: const TextStyle(color: kPrimaryColor, fontSize: 12)),
                  ),
                  const SizedBox(height: 16),
                  Text(card.title,
                      style: const TextStyle(
                          fontSize: 34, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(card.oneLiner,
                      style: const TextStyle(color: kTextGray, fontSize: 15)),
                  const SizedBox(height: 24),
                  // AI 요약 박스
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: kCardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('AI 요약',
                            style: TextStyle(color: kPrimaryColor, fontSize: 12)),
                        const SizedBox(height: 8),
                        ...card.points.map((p) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text('• $p',
                                  style: const TextStyle(
                                      color: Color(0xFFD8D8E8),
                                      fontSize: 13,
                                      height: 1.6)),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text('관련 유튜브 쇼츠',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  // 유튜브 쇼츠 목록
                  shortsAsync.when(
                    data: (shorts) => Column(
                      children: shorts.map((s) => _ShortCard(short: s)).toList(),
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const Text('쇼츠를 불러올 수 없습니다.',
                        style: TextStyle(color: kTextGray)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
          body: Center(child: Text('오류: $e'))),
    );
  }
}

class _ShortCard extends StatelessWidget {
  final YoutubeShort short;
  const _ShortCard({required this.short});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(short.url),
          mode: LaunchMode.externalApplication),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            // 썸네일
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(short.thumbnailUrl,
                  width: 80, height: 52, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(short.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(short.channelTitle,
                      style: const TextStyle(color: kTextGray, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.play_arrow, color: kRedAccent, size: 20),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Functions 재배포**

```bash
firebase deploy --only functions
```

- [ ] **Step 7: 수동 테스트**

```bash
flutter run
```

확인 사항:
- 카드 탭 시 상세 화면 이동
- AI 요약 박스에 핵심 포인트 3개 표시
- 유튜브 쇼츠 3개 카드 목록 표시
- 쇼츠 카드 탭 시 YouTube 앱으로 이동

- [ ] **Step 8: 커밋**

```bash
git add studyreel/ functions/
git commit -m "feat: YouTube API 연동 + 카드 상세 화면"
```

---

## Task 8: 검색/탐색 화면 (14주차 전반)

**Files:**
- Create: `studyreel/lib/presentation/explore/explore_screen.dart`
- Modify: `studyreel/lib/core/router.dart`

- [ ] **Step 1: ExploreScreen 구현**

`lib/presentation/explore/explore_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../domain/card_provider.dart';
import '../../domain/topic_provider.dart';

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(cachedCardsProvider);

    // 토픽별로 카드 그룹화
    final Map<String, List> byTopic = {};
    for (final card in cards) {
      byTopic.putIfAbsent(card.topic, () => []).add(card);
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Text('탐색',
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            // 토픽 필터 칩
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: kAvailableTopics.map((t) {
                  final isActive = byTopic.containsKey(t);
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isActive
                          ? kPrimaryColor.withOpacity(0.2)
                          : kCardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive ? kPrimaryColor : Colors.white12,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(t,
                        style: TextStyle(
                            fontSize: 13,
                            color: isActive ? kPrimaryColor : kTextGray)),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            // 카드 목록
            Expanded(
              child: cards.isEmpty
                  ? const Center(
                      child: Text('카드를 먼저 피드에서 불러오세요.',
                          style: TextStyle(color: kTextGray)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: cards.length,
                      itemBuilder: (context, index) {
                        final card = cards[index];
                        return GestureDetector(
                          onTap: () => context.push('/detail/${card.id}'),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: kCardColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(card.topic,
                                          style: const TextStyle(
                                              color: kPrimaryColor,
                                              fontSize: 11)),
                                      const SizedBox(height: 4),
                                      Text(card.title,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15)),
                                      const SizedBox(height: 2),
                                      Text(card.oneLiner,
                                          style: const TextStyle(
                                              color: kTextGray, fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right,
                                    color: kTextGray, size: 18),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 라우터에 /explore 추가**

`lib/core/router.dart`에 추가:

```dart
import '../presentation/explore/explore_screen.dart';
// routes 배열에 추가:
GoRoute(path: '/explore', builder: (_, __) => const ExploreScreen()),
```

- [ ] **Step 3: FeedScreen 탭바 — "탐색" 탭 연결**

`lib/presentation/feed/feed_screen.dart`의 "탐색" 텍스트 위젯을 GestureDetector로 감싸기:

```dart
GestureDetector(
  onTap: () => context.push('/explore'),
  child: const Text('탐색',
      style: TextStyle(fontSize: 16, color: kTextGray)),
),
```

- [ ] **Step 4: 수동 테스트**

```bash
flutter run
```

확인: 피드 탭바에서 "탐색" 탭 → 전체 카드 목록 → 카드 탭 시 상세 이동

- [ ] **Step 5: 커밋**

```bash
git add studyreel/lib/presentation/explore/
git commit -m "feat: 검색/탐색 화면 — 토픽별 카드 브라우징"
```

---

## Task 9: 프로필 화면 & 전체 테스트 (14주차 후반)

**Files:**
- Create: `studyreel/lib/presentation/profile/profile_screen.dart`
- Create: `studyreel/integration_test/feed_flow_test.dart`

- [ ] **Step 1: 프로필 화면**

`lib/presentation/profile/profile_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../domain/auth_provider.dart';
import '../../domain/topic_provider.dart';
import '../../domain/card_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final topics = ref.watch(selectedTopicsProvider);
    final cardsAsync = ref.watch(cardFeedProvider(topics.toList()));

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Row(
                children: [
                  const BackButton(color: Colors.white),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      await ref.read(authRepositoryProvider).signOut();
                      if (context.mounted) context.go('/onboarding');
                    },
                    child: const Text('로그아웃',
                        style: TextStyle(color: kTextGray)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 사용자 정보
              CircleAvatar(
                radius: 32,
                backgroundColor: kPrimaryColor,
                child: Text(
                  user?.displayName?.substring(0, 1) ?? '나',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              Text(user?.displayName ?? '사용자',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(user?.email ?? '',
                  style: const TextStyle(color: kTextGray, fontSize: 13)),
              const SizedBox(height: 32),
              // 오늘 학습 통계
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kCardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: cardsAsync.when(
                  data: (cards) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(value: '${cards.length}', label: '총 카드'),
                      _StatItem(value: '${topics.length}', label: '관심사'),
                    ],
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Text('불러오기 실패'),
                ),
              ),
              const SizedBox(height: 32),
              // 관심사 수정
              const Text('관심사',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: topics.map((t) => Chip(
                      label: Text(t,
                          style: const TextStyle(color: kPrimaryColor)),
                      backgroundColor: kPrimaryColor.withOpacity(0.15),
                      side: BorderSide(color: kPrimaryColor.withOpacity(0.4)),
                    )).toList(),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/onboarding'),
                child: const Text('관심사 변경',
                    style: TextStyle(color: kPrimaryColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(color: kTextGray, fontSize: 12)),
      ],
    );
  }
}
```

- [ ] **Step 2: E2E 통합 테스트 작성**

`integration_test/feed_flow_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:studyreel/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('온보딩 → 피드 진입 흐름', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // 온보딩 화면 확인
    expect(find.text('어떤 걸'), findsOneWidget);

    // 토픽 3개 선택
    await tester.tap(find.text('컴퓨터과학'));
    await tester.tap(find.text('수학'));
    await tester.tap(find.text('영어'));
    await tester.pumpAndSettle();

    // 시작하기 버튼 활성화 확인
    expect(find.text('3개 선택됨'), findsOneWidget);

    // 시작하기 탭
    await tester.tap(find.text('시작하기 →'));
    await tester.pumpAndSettle();

    // 피드 화면 진입 확인
    expect(find.text('오늘의 학습'), findsOneWidget);
  });
}
```

- [ ] **Step 3: 전체 단위 테스트 실행**

```bash
flutter test
```

Expected: PASS (모든 테스트)

- [ ] **Step 4: 통합 테스트 실행 (실기기 또는 에뮬레이터)**

```bash
flutter test integration_test/feed_flow_test.dart
```

Expected: PASS

- [ ] **Step 5: 최종 커밋**

```bash
git add studyreel/
git commit -m "feat: 프로필 화면 & E2E 통합 테스트 완성"
```

---

## Task 10: 문서 완비 (15주차)

**Files:**
- Create: `studyreel/docs/setup.md`
- Create: `studyreel/docs/deploy.md`
- Create: `studyreel/docs/testing.md`
- Create: `studyreel/docs/architecture.md`
- Create: `studyreel/.planning/00-vision.md`
- Create: `studyreel/.planning/01-requirements.md`
- Create: `studyreel/.planning/02-wbs.md`
- Create: `studyreel/.planning/04-schedule.md`
- Create: `studyreel/.planning/decisions/ADR-0001-flutter.md`
- Create: `studyreel/.planning/decisions/ADR-0002-firebase.md`
- Create: `studyreel/.planning/decisions/ADR-0003-claude-api.md`
- Create: `studyreel/AGENTS.md`
- Create: `studyreel/README.md`
- Create: `studyreel/BONUS.md`

- [ ] **Step 1: docs/setup.md 작성** — `flutter run`까지 5분 안에 따라할 수 있도록

- [ ] **Step 2: docs/deploy.md 작성** — `firebase deploy` 전체 절차

- [ ] **Step 3: docs/testing.md 작성** — `flutter test` / `flutter test integration_test/` 실행 방법

- [ ] **Step 4: docs/architecture.md 작성** — Mermaid 아키텍처 다이어그램 포함

- [ ] **Step 5: .planning/ 문서 3종 생성** — 부트스트랩 프롬프트(`05-bootstrap-prompt.md`) 1단계 실행

- [ ] **Step 6: ADR 3개 작성** — Flutter, Firebase, Claude API 선택 이유 각 1개

- [ ] **Step 7: AGENTS.md 작성** — 에이전트 운영 헌법

- [ ] **Step 8: README.md 완성** — 프로젝트 설명, 빌드/실행 명령

- [ ] **Step 9: BONUS.md 작성** — 가산점 A/B/C 항목 정리

- [ ] **Step 10: 최종 커밋 & 태그**

```bash
git add .
git commit -m "docs: 발표 전 문서 완비 (setup/deploy/testing/ADR/AGENTS)"
git tag v1.0.0-final
```

---

## 전체 테스트 실행 명령 요약

```bash
# 단위 + 통합 테스트 전체
flutter test

# UI E2E 테스트 (에뮬레이터 필요)
flutter test integration_test/

# 빌드 확인
flutter build apk --release
```
