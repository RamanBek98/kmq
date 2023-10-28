import 'package:flutter/material.dart';
import 'models.dart';
import 'Multiplayer.dart';
import 'package:firebase_database/firebase_database.dart';
import 'database.dart';

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

  @override
  void initState() {
    super.initState();

    database.child('gameRooms').child(widget.roomId).onValue.listen((event) {
      Map<String, dynamic>? data;
      if (event.snapshot.value is Map<String, dynamic>) {
        data = event.snapshot.value as Map<String, dynamic>;

        // Check each key-value pair
        if (data['players'] is! List) {
          print('Error: players key is not a list.');
          return;
        }

        if (data['hostId'] is! String) {
          print('Error: hostId key is not a string.');
          return;
        }

        if (data['roomId'] is! String) {
          print('Error: roomId key is not a string.');
          return;
        }

        if (data['hostName'] is! String) {
          print('Error: hostName key is not a string.');
          return;
        }

        // Convert players list
        List<String> playerList = (data['players'] as List).cast<String>();

        setState(() {
          hostId = data?['hostId'] ?? '';
          roomName = data?['roomId'] ?? '';
          hostName = data?['hostName'] ?? '';
          players = playerList;
        });

      } else {
        print('Unexpected data type: ${event.snapshot.value.runtimeType}');
        print('Unexpected data format: ${event.snapshot.value}');
        return;
      }
    });
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
        body: Column(
          children: [
            Text(
              roomName,
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
                    String username = await db.getUsernameByUID(uid);
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
                                        backgroundImage: (player.profilePicturePath != null && player.profilePicturePath!.isNotEmpty)
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
                if (hostName == widget.currentUserId) {
                  db.startGame(widget.roomId, 'RDJ3RCss03v1k');
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
        ),
      ),
    );
  }
}
