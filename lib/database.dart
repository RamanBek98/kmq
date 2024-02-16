import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'models.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';


final DatabaseReference database = FirebaseDatabase.instance.reference();

class DatabaseService {
  late Timer _timer;

  DatabaseService() {
    _timer = Timer.periodic(Duration(minutes: 1), (Timer t) => removeInactivePlayers());
  }

  Stream<List<GameRoom>> getActiveRooms() {
    return database.child('gameRooms')
        .orderByChild('status').equalTo('waiting')
        .onValue
        .map((event) {
      List<GameRoom> rooms = [];
      // Updated code
      if (event.snapshot.value is Map) {
        Map<dynamic, dynamic> dataSnapshot = event.snapshot.value as Map<dynamic, dynamic>;
        Map<String, dynamic> data = dataSnapshot.map((key, value) {
          return MapEntry(key as String, value);
        });

        data.forEach((key, value) {
          if (value is Map) {
            Map<String, dynamic> roomMap = value.cast<String, dynamic>();
            rooms.add(GameRoom.fromMap(roomMap));
          }
        });
      }
      return rooms;
    });
  }


  Future<String?> getUsernameByUID(String uid) async {
    DatabaseEvent event = await database.child('users').child(uid).once();
    DataSnapshot snapshot = event.snapshot;

    if(snapshot.value is Map) {
      Map<String, dynamic> data = (snapshot.value as Map).cast<String, dynamic>();
      return data['username'] as String?;  // Assuming 'username' is the key for the username in the database
    }
    return null;
  }


  Future<List<Map<String, dynamic>>> fetchSongs() async {
    DatabaseEvent event = await database.child('Songs').once();
    DataSnapshot dataSnapshot = event.snapshot;

    if (dataSnapshot.value is Map<dynamic, dynamic>) {
      Map<dynamic, dynamic> songsMap = dataSnapshot.value as Map<dynamic, dynamic>;

      // Convert the songsMap to a list of Map<String, dynamic>
      List<Map<String, dynamic>> songsList = songsMap.values
          .where((song) => song is Map)
          .map((song) => Map<String, dynamic>.from(song as Map))
          .toList();

      // Randomize the order of the songs
      songsList.shuffle(Random());

      return songsList;
    } else {
      // Handle the case where dataSnapshot.value is not a Map
      print('Songs data is not in the expected format.');
      return [];
    }
  }









  Future<void> leaveRoom(String roomId, String uid) async {
    DataSnapshot snapshot = (await database.child('gameRooms').child(roomId).once()).snapshot;

    if (snapshot.value is Map) {
      List<String> currentPlayers = List<String>.from(((snapshot.value as Map).cast<String, dynamic>())['players'] ?? []);
      currentPlayers.remove(uid);
      return await database.child('gameRooms').child(roomId).update({'players': currentPlayers});
    }
  }

  Future<void> updateCurrentVideoIndex(String roomId, int currentVideoIndex) async {
    return await database.child('gameRooms').child(roomId).update({'currentVideoIndex': currentVideoIndex});
  }

  Future<void> updatePlayerScore(String roomId, String uid, int newScore) async {
    // Note: This will need a different approach since player details are separated now.
    // This is just a placeholder. Actual implementation will depend on how you're storing scores.
    throw UnimplementedError("updatePlayerScore needs a new implementation based on the new database structure.");
  }

  Future<String?> getProfilePictureByUID(String uid) async {
    DatabaseEvent event = await database.child('users').child(uid).once();
    DataSnapshot snapshot = event.snapshot;

    if (snapshot.value is Map) {
      Map<String, dynamic> userData = (snapshot.value as Map).cast<String, dynamic>();
      return userData['profilePicture'] as String?; // Corrected to fetch 'profilePicture'
    }
    return null;
  }

  Future<UserModel> fetchPlayerDetails(String uid) async {
    String username = (await DatabaseService().getUsernameByUID(uid)) ?? 'Unknown';
    String? profilePicturePath = await DatabaseService().getProfilePictureByUID(uid);
    return UserModel(uid: uid, username: username, profilePicturePath: profilePicturePath);
  }

  Future<void> startGame(String roomId, String videoId) async {
    return await database.child('gameRooms').child(roomId).update({
      'status': 'started',
      'currentVideoId': videoId
    });
  }



  Future<bool> createRoom(UserModel user, String roomName, List<Map<String, dynamic>> randomizedVideoData) async {
    DatabaseEvent event = await database.child('gameRooms').child(roomName.toLowerCase()).once();
    DataSnapshot existingRoom = event.snapshot;
    Map<String, bool> initialSkipRequests = {user.uid: false};


    if (existingRoom.exists) {
      return false;
    }

    List<String> playersList = [user.uid]; // List of UIDs

    GameRoom newRoom = GameRoom(
        roomId: roomName,
        hostId: user.uid,
        hostName: user.username,
        hostProfilePicturePath: user.profilePicturePath,
        players: playersList,
        maxPlayers: 4,
        status: 'waiting',
        timestamp: DateTime.now(),
        currentRound: 0,
        currentVideoIndex: 0,
        gameStatus: 'Not Started',
      skipRequests: initialSkipRequests, // Add skipRequests to the new room

    );

    Map<String, dynamic> roomData = newRoom.toJson();
    roomData['videoData'] = randomizedVideoData;
    await database.child('gameRooms').child(roomName).set(roomData);
    return true;
  }



  Future<void> joinRoom(String roomId, String uid) async {
    // Fetch the current list of players
    DataSnapshot snapshot = (await database.child('gameRooms').child(roomId).child('players').once()).snapshot;

    List<String> currentPlayers;
    if (snapshot.exists && snapshot.value is List<dynamic>) {
      // If there are already players in the room and the value is a list
      currentPlayers = List<String>.from(snapshot.value as List<dynamic>);
    } else {
      // If no players are in the room or the value is not a list
      currentPlayers = [];
    }

    // Add the new player's UID to the list
    currentPlayers.add(uid);

    // Update the players list in the database
    await database.child('gameRooms').child(roomId).child('players').set(currentPlayers);
  }


  Future<void> removeInactivePlayers() async {
    DataSnapshot activeRooms = (await database.child('gameRooms').orderByChild('status').equalTo('waiting').once()).snapshot;
    Map<String, dynamic>? roomsData = (activeRooms.value as Map?)?.cast<String, dynamic>();

    if(roomsData != null) {
      for(var roomId in roomsData.keys) {
        var roomData = roomsData[roomId];
        List<String> players = List<String>.from(roomData['players'] ?? []);
        List<String> updatedPlayers = [];

        for (String playerUid in players) {
          String activityKey = "${roomId}_$playerUid";
          DatabaseEvent playerEvent = await database.child('playerActivity').child(activityKey).once();

          DateTime lastActive;
          if (playerEvent.snapshot.value is String) {
            lastActive = DateTime.parse(playerEvent.snapshot.value as String);
          } else {
            lastActive = DateTime.now();
          }

          if (DateTime.now().difference(lastActive).inMinutes < 3) {
            updatedPlayers.add(playerUid);
          }
        }

        if (updatedPlayers.isEmpty) {
          database.child('gameRooms').child(roomId).remove();
        } else {
          database.child('gameRooms').child(roomId).update({'players': updatedPlayers});
        }
      }
    }
  }


  void dispose() {
    _timer.cancel();
  }
}

Future<void> updatePlayerActivity(String roomId, String uid) async {
  String activityKey = "${roomId}_$uid";
  return database.child('playerActivity').child(activityKey).set(DateTime.now().toIso8601String());
}
