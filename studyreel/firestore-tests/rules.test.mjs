// StudyReel Firestore 보안 규칙 통합 테스트
// Firebase 에뮬레이터에서 firestore.rules 를 로드해 검증한다:
//  - 로그인 사용자는 자신의 users/{uid} 및 하위만 읽기/쓰기 가능
//  - 다른 사용자 데이터는 거부
//  - 미인증 접근은 거부
//
// 실행: studyreel/ 에서
//   firebase emulators:exec --only firestore --project demo-studyreel \
//     "node --test firestore-tests/rules.test.mjs"

import { readFileSync } from 'node:fs';
import { test, before, after, beforeEach } from 'node:test';
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc } from 'firebase/firestore';

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-studyreel',
    firestore: {
      rules: readFileSync('firestore.rules', 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });
});

after(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

function aliceDb() {
  return testEnv.authenticatedContext('alice').firestore();
}

test('로그인 사용자는 자신의 users 문서(토픽)를 읽고 쓸 수 있다', async () => {
  const db = aliceDb();
  await assertSucceeds(setDoc(doc(db, 'users/alice'), { topics: ['수학'] }));
  await assertSucceeds(getDoc(doc(db, 'users/alice')));
});

test('로그인 사용자는 자신의 하위 컬렉션에 접근할 수 있다', async () => {
  const db = aliceDb();
  await assertSucceeds(
    setDoc(doc(db, 'users/alice/youtube_videos/v1'), { videoId: 'v1' }),
  );
  await assertSucceeds(
    setDoc(doc(db, 'users/alice/watch_history/v1'), { videoId: 'v1' }),
  );
  await assertSucceeds(
    setDoc(doc(db, 'users/alice/meta/streak'), { currentStreak: 3 }),
  );
});

test('다른 사용자의 데이터는 읽거나 쓸 수 없다', async () => {
  const db = aliceDb();
  await assertFails(getDoc(doc(db, 'users/bob')));
  await assertFails(setDoc(doc(db, 'users/bob'), { topics: ['해킹'] }));
  await assertFails(
    getDoc(doc(db, 'users/bob/watch_history/v1')),
  );
  await assertFails(
    setDoc(doc(db, 'users/bob/youtube_videos/v1'), { videoId: 'x' }),
  );
});

test('미인증 사용자는 어떤 데이터에도 접근할 수 없다', async () => {
  const anon = testEnv.unauthenticatedContext().firestore();
  await assertFails(getDoc(doc(anon, 'users/alice')));
  await assertFails(setDoc(doc(anon, 'users/alice'), { topics: ['x'] }));
  await assertFails(getDoc(doc(anon, 'users/alice/watch_history/v1')));
});
