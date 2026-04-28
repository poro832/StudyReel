import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:google_sign_in_mocks/google_sign_in_mocks.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:studyreel/data/repositories/auth_repository.dart';

class _StubGoogleSignIn extends MockGoogleSignIn {
  @override
  Future<GoogleSignInAccount?> signOut() async => null;
}

void main() {
  group('AuthRepository', () {
    late MockFirebaseAuth mockAuth;
    late _StubGoogleSignIn mockGoogleSignIn;
    late AuthRepository repo;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockGoogleSignIn = _StubGoogleSignIn();
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
