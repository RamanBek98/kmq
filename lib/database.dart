import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'models.dart';

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
      Map<String, dynamic>? data;
      if(event.snapshot.value is Map) {
        data = Map.from(event.snapshot.value as Map).map((key, value) =>
            MapEntry<String, dynamic>(key.toString(), value));
      }

      data?.forEach((key, value) {
        rooms.add(GameRoom.fromMap(value));
      });
      return rooms;
    });
  }

  Future<String> getUsernameByUID(String uid) async {
    DatabaseEvent event = await database.child('users').child(uid).once();
    DataSnapshot snapshot = event.snapshot;

    if(snapshot.value is Map<String, dynamic>) {
      Map<String, dynamic> data = snapshot.value as Map<String, dynamic>;
      return data['username'] ?? '';
    }
    return '';
  }

  Future<List<Map<String, dynamic>>> fetchSongs() async {
    DatabaseEvent event = await database.child('Songs').once();
    DataSnapshot dataSnapshot = event.snapshot;

    if (dataSnapshot.value is Map<dynamic, dynamic>) {
      Map<dynamic, dynamic> songsMap = dataSnapshot.value as Map<dynamic, dynamic>;
      return songsMap.values.map((song) => song as Map<String, dynamic>).toList();
    } else {
      return [];
    }
  }

  Future<void> leaveRoom(String roomId, String uid) async {
    DataSnapshot snapshot = (await database.child('gameRooms').child(roomId).once()).snapshot;

    if (snapshot.value is Map<String, dynamic>) {
      List<String> currentPlayers = List<String>.from((snapshot.value as Map<String, dynamic>)['players'] ?? []);
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

    if (snapshot.value is Map<String, dynamic>) {
      return (snapshot.value as Map<String, dynamic>)['profilePicturePath'] as String?;
    }
    return null;
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
        gameStatus: 'Not Started'
    );

    Map<String, dynamic> roomData = newRoom.toJson();
    roomData['videoData'] = randomizedVideoData;
    await database.child('gameRooms').child(roomName).set(roomData);
    return true;
  }

  Future<void> joinRoom(String roomId, String uid) async {
    return database.child('gameRooms').child(roomId).child('players').push().set(uid);
  }

  Future<void> removeInactivePlayers() async {
    DataSnapshot activeRooms = (await database.child('gameRooms').orderByChild('status').equalTo('waiting').once()).snapshot;
    Map<String, dynamic>? roomsData = activeRooms.value as Map<String, dynamic>?;

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
