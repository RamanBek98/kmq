import 'package:flutter/material.dart';
import 'models.dart';
import 'Multiplayer.dart';
import 'package:firebase_database/firebase_database.dart';
import 'database.dart';
import 'dart:async';


class PreGameLobbyScreen extends StatefulWidget {
  final String roomId;
  final String currentUserId;

  PreGameLobbyScreen({required this.roomId, required this.currentUserId});

  @override
  _PreGameLobbyScreenState createState() => _PreGameLobbyScreenState();
}

class _PreGameLobbyScreenState extends State<PreGameLobbyScreen> {
  final database = FirebaseDatabase.instance.reference();
  final DatabaseService db = DatabaseService();
  String hostId = '';
  String roomName = '';
  String hostName = '';
  List<String> players = [];  // This list will hold the UIDs of the players.
  List<Map<String, dynamic>> videoData = [];  // Add a field to store video data
  late StreamSubscription _gameRoomStatusSubscription;


  @override
  void initState() {
    super.initState();

    // Initialize the StreamSubscription
    _gameRoomStatusSubscription = database.child('gameRooms').child(widget.roomId).onValue.listen((DatabaseEvent event) {      if (event.snapshot.value is Map) {
      var data = Map<String, dynamic>.from(event.snapshot.value as Map);

      // Update UI with new data
      setState(() {
        hostId = data['hostId'] ?? '';
        roomName = data['roomId'] ?? '';
        hostName = data['hostName'] ?? '';
        players = List<String>.from(data['players'] ?? []);
      });

      // Check for game start
      if (data['status'] == 'started') {
        // Navigate to MultiplayerGameScreen for all players
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (context) => MultiplayerGameScreen(roomId: widget.roomId),
        ));
      }
    }
    });

    // Additional initialization logic if needed
    _fetchGameData();
  }


  Future<void> _fetchGameData() async {
    DatabaseEvent event = await database.child('gameRooms').child(widget.roomId).once();
    DataSnapshot snapshot = event.snapshot;

    Map<String, dynamic>? data;

    if (snapshot.value is Map<String, dynamic>) {
      data = snapshot.value as Map<String, dynamic>;
    } else {
      print('Unexpected data format: ${snapshot.value}');
      return;
    }

    GameRoom room = GameRoom.fromMap(data);
    setState(() {
      hostId = room.hostId;
      roomName = room.roomId;
      hostName = room.hostName;
      players = room.players;
    });
  }

  void onLeaveRoomButtonPressed() {
    String roomId = widget.roomId;
    String playerId = widget.currentUserId; // Use the current user's ID
    db.leaveRoom(roomId, playerId).then((_) {
      Navigator.pop(context);
    }).catchError((error) {
      print("Failed to leave room: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(title: Text('Pre-Game Lobby')),
        body: StreamBuilder<DatabaseEvent>(
            stream: database.child('gameRooms').child(widget.roomId).onValue,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                return Center(child: Text('No Data Available'));
              }

              var data = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
              var room = GameRoom.fromMap(data);

              return Column(
                children: [
                  Text(
                    room.roomId,
                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: players.length,
                      itemBuilder: (context, index) {
                        String playerUid = players[index];

                        Future<UserModel> fetchPlayerDetails(String uid) async {
                          String username = (await db.getUsernameByUID(uid)) ?? 'Unknown';
                          String? profilePicturePath = await db.getProfilePictureByUID(uid);
                          return UserModel(uid: uid, username: username, profilePicturePath: profilePicturePath);
                        }

                        return FutureBuilder<UserModel>(
                          future: fetchPlayerDetails(playerUid),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.done) {
                              if (snapshot.hasData) {
                                UserModel player = snapshot.data!;

                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: ListTile(
                                    leading: Container(
                                      width: 70.0,
                                      height: 70.0,
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Positioned.fill(
                                            child: CircleAvatar(
                                              radius: 31.0,
                                              backgroundImage: player.profilePicturePath != null && player.profilePicturePath!.isNotEmpty
                                                  ? NetworkImage(player.profilePicturePath!) as ImageProvider<Object>
                                                  : AssetImage('assets/images/placeholder.jpg') as ImageProvider<Object>,
                                              backgroundColor: Colors.transparent,
                                            ),
                                          ),
                                          if (player.uid == hostId)
                                            Positioned(
                                              top: -6,
                                              right: 1,
                                              child: Transform.rotate(
                                                angle: 0.6,
                                                child: Text('👑', style: TextStyle(fontSize: 20)),
                                              ),
                                            )
                                        ],
                                      ),
                                    ),
                                    title: Text(player.username, style: TextStyle(fontSize: 22)),
                                  ),
                                );
                              } else {
                                return Center(child: CircularProgressIndicator());
                              }
                            } else {
                              return Center(child: CircularProgressIndicator());
                            }
                          },
                        );
                      },
                    ),
                  ),
                  ElevatedButton(
                    child: Text('Fetch Data'),
                    onPressed: () async {
                      await _fetchGameData();
                    },
                  ),
                  ElevatedButton(
                    child: Text('Start Game'),
                    onPressed: () {
                      // Compare the hostId with the current user's ID
                      if (hostId == widget.currentUserId) {
                        db.startGame(widget.roomId, 'CKsuPRFpC2s');
                        Navigator.push(context, MaterialPageRoute(
                            builder: (context) => MultiplayerGameScreen(roomId: widget.roomId)
                        ));
                      } else {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text("Wait!"),
                              content: Text("Please wait for the host to start the game."),
                              actions: [
                                TextButton(
                                  child: Text("OK"),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      }
                    },
                  ),

                  ElevatedButton(
                    onPressed: onLeaveRoomButtonPressed,
                    child: Text("Leave Room"),
                  ),
                ],
              );}),
      ),
    );
  }
}
