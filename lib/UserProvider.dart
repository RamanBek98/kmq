import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'auth_service.dart';
import 'models.dart';


class DatabaseService {
  final _database = FirebaseDatabase.instance.reference();

  Future<String> getUsernameByUID(String uid) async {
    DatabaseEvent event = await _database.child('users').child(uid).child('username').once();
    DataSnapshot snapshot = event.snapshot;
    return snapshot.value.toString();
  }

  Future<String?> getProfilePictureByUID(String uid) async {
    DatabaseEvent event = await _database.child('users').child(uid).child('profilePicture').once();  // Changed 'profilePicturePath' to 'profilePicture'
    DataSnapshot snapshot = event.snapshot;
    if (snapshot.value != null) {
      return snapshot.value.toString();
    }
    return null;
  }

}


// Add other methods as required...


class UserProvider with ChangeNotifier {
  UserModel? _currentUser;
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();

  UserModel? get currentUser => _currentUser;

  void setUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  void clearUser() {
    _currentUser = null;
    notifyListeners();
  }

  Future<void> fetchCurrentUser() async {
    var currentUser = _authService.currentFirebaseUser;
    if (currentUser != null) {
      String uid = currentUser.uid;
      String username = await _databaseService.getUsernameByUID(uid);
      String? profilePicturePath = await _databaseService.getProfilePictureByUID(uid);  // Fetch the profile picture path
      setUser(UserModel(uid: uid, username: username, profilePicturePath: profilePicturePath));
    }
  }

  Future<void> updateUserOnSignIn(String email, String password) async {
    var result = await _authService.signInWithEmailAndPassword(email, password);
    if (result['uid'] != '') {
      String username = await _databaseService.getUsernameByUID(result['uid']!);
      String? profilePicturePath = await _databaseService.getProfilePictureByUID(result['uid']!);  // Fetch the profile picture path
      setUser(UserModel(uid: result['uid']!, username: username, profilePicturePath: profilePicturePath));
    }
  }

  Future<void> updateUserOnSignUp(String email, String password, String username) async {
    var result = await _authService.registerWithEmailAndPassword(email, password, username);
    if (result['uid'] != '') {
      String? profilePicturePath = await _databaseService.getProfilePictureByUID(result['uid']!);  // Fetch the profile picture path
      setUser(UserModel(uid: result['uid']!, username: username, profilePicturePath: profilePicturePath));
    }
  }
}
