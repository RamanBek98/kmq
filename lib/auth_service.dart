import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';  // Import for Firebase Realtime Database
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.reference();  // Initialize Firebase Realtime Database
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> saveUserProfile(String uid, String username, [File? profilePicture]) async {
    String profilePictureURL = '';
    if (profilePicture != null) {
      TaskSnapshot snapshot = await _storage.ref('profile_pictures/$uid').putFile(profilePicture);
      profilePictureURL = await snapshot.ref.getDownloadURL();
    }

    // Save user data in Realtime Database
    await _dbRef.child('users/$uid').set({
      'username': username,
      'profilePicture': profilePictureURL,
      'uid': uid
    });

    print('UID: $uid');
    print('Username: $username');
    print('Profile Picture URL: $profilePictureURL');
  }

  User? get currentFirebaseUser => _auth.currentUser;

  // Register with email and password
  Future<Map<String, String>> registerWithEmailAndPassword(
      String email, String password, String username) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;

      // Removed username storage logic to ensure profile creation only happens in ProfileCreationScreen.

      return {'uid': user!.uid, 'error': ''};
    } on FirebaseAuthException catch (e) {
      print(e.code);
      return {'uid': '', 'error': _userFriendlyError(e.code)};
    } catch (e) {
      print(e.toString());
      return {'uid': '', 'error': 'An unknown error occurred.'};
    }
  }

  // Sign in with email and password
  Future<Map<String, String>> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;
      return {'uid': user!.uid, 'error': ''};
    } on FirebaseAuthException catch (e) {
      print(e.code);
      return {'uid': '', 'error': _userFriendlyError(e.code)};
    } catch (e) {
      print(e.toString());
      return {'uid': '', 'error': 'An unknown error occurred.'};
    }
  }

  // Sign out
  Future signOut() async {
    try {
      return await _auth.signOut();
    } catch (error) {
      print(error.toString());
      return null;
    }
  }

  // Provide user-friendly error messages
  String _userFriendlyError(String code) {
    switch (code) {
      case 'weak-password':
        return 'The password is too weak.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      default:
        return 'An error occurred.';
    }
  }
}

