import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? "YOUR_CLIENT_ID.apps.googleusercontent.com" : null,
    scopes: ['email'],
  );

  /// **Metode Login dengan Google**
  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        print("⚠️ Untuk Web, gunakan tombol GIS!");
        return null; // Login Web harus lewat widget GIS, bukan langsung sign-in
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        UserCredential userCredential = await _auth.signInWithCredential(
          credential,
        );
        return userCredential.user;
      }
    } catch (e) {
      print("❌ Error signing in with Google: $e");
      return null;
    }
  }

  /// **Logout dari Google**
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// **Cek User yang sedang login**
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}
