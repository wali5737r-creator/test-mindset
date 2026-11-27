import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/app_config.dart';

/// Teacher authentication (email/password or Google) and the teacher
/// profile doc at `teachers/{uid}`. Students never use this service -
/// the student flow works with no login at all.
class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  CollectionReference<Map<String, dynamic>> get _teachersRef =>
      _db.collection(AppConfig.teachersCollection);

  /// Creates the Firebase Auth user AND the `teachers/{uid}` profile doc.
  Future<void> register({
    required String name,
    required String institute,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user!;
    await _teachersRef.doc(user.uid).set(<String, dynamic>{
      'name': name.trim(),
      'institute': institute.trim(),
      'email': email.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    await user.updateDisplayName(name.trim());
  }

  Future<void> login({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Signs in with Google. Returns false when the user cancels the
  /// account picker (the caller treats that as a silent no-op); on
  /// success returns true. A first-time Google sign-in also creates the
  /// `teachers/{uid}` profile doc, with the same shape register() uses.
  Future<bool> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      return false;
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user!;
    final doc = await _teachersRef.doc(user.uid).get();
    if (!doc.exists) {
      await _teachersRef.doc(user.uid).set(<String, dynamic>{
        'name': user.displayName ?? '',
        'institute': '',
        'email': user.email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return true;
  }

  Future<void> logout() async {
    // Also sign out of Google so the account picker is offered again
    // next time; ignore failures (e.g. the session was email/password).
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Not signed in with Google - nothing to clear.
    }
    await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// The signed-in teacher's profile doc, or null if it does not exist.
  Future<Map<String, dynamic>?> teacherProfile(String uid) async {
    final doc = await _teachersRef.doc(uid).get();
    return doc.data();
  }

  /// Turns Firebase errors into short, plain-English messages for snackbars.
  static String friendlyError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'That email address does not look valid.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'user-not-found':
          return 'No account found for this email.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Wrong email or password.';
        case 'email-already-in-use':
          return 'An account with this email already exists. Try logging in.';
        case 'weak-password':
          return 'Password is too weak. Use at least 6 characters.';
        case 'network-request-failed':
          return 'Network problem. Check your internet and try again.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a little and try again.';
        default:
          return error.message ?? 'Authentication failed. Please try again.';
      }
    }
    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        return 'Permission denied. Please check the Firebase setup.';
      }
      if (error.code == 'unavailable') {
        return 'Network problem. Check your internet and try again.';
      }
      return error.message ?? 'Something went wrong. Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}
