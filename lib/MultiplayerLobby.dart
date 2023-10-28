import 'package:flutter/material.dart';
import 'package:kqduell/PreGameLobby.dart';
import 'models.dart';
import 'package:provider/provider.dart';
import 'database.dart';
import 'UserProvider.dart' hide DatabaseService;
import 'dart:math';

class MultiplayerLobby extends StatefulWidget {
  @override
  _MultiplayerLobbyState createState() => _MultiplayerLobbyState();
}

class _MultiplayerLobbyState extends State<MultiplayerLobby> {
  final DatabaseService db = DatabaseService();

  List<Map<String, dynamic>> _randomizeList(List<Map<String, dynamic>> originalList) {
    var random = Random();
    List<Map<String, dynamic>> list = List<Map<String, dynamic>>.from(originalList);
    list.shuffle(random);
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<GameRoom>>(
              stream: db.getActiveRooms(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading game rooms: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                List<GameRoom> rooms = snapshot.data!;
                return ListView.builder(
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    GameRoom room = rooms[index];
                    final hostProfilePicturePath = room.hostProfilePicturePath;

                    return ListTile(
                      leading: Container(
                        width: 62.0,
                        height: 62.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.black,
                            width: 2.0,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 29.0,
                          backgroundImage: (hostProfilePicturePath != null && hostProfilePicturePath.isNotEmpty
                              ? NetworkImage(hostProfilePicturePath)
                              : AssetImage('assets/images/placeholder.jpg')) as ImageProvider<Object>?,
                        ),
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, // Align to the left
                        children: <Widget>[
                          Text('${room.roomId}'),  // Room name
                          Text(
                            '${room.hostName}',  // Host name
                            style: TextStyle(
                              fontSize: 14.0,  // Smaller font size
                              color: Colors.black54,  // Lighter shade of black
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text('${room.players.length} players'),
                      trailing: ElevatedButton(
                        child: Text('Join'),
                        onPressed: () async {
                          if (currentUser != null) {
                            await db.joinRoom(room.roomId, currentUser.uid);
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => PreGameLobbyScreen(roomId: room.roomId, currentUserId: currentUser.uid)
                            ));
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
          ElevatedButton(
            child: Text('Create Room'),
            onPressed: () async {
              TextEditingController roomNameController = TextEditingController();
              showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text("Enter Room Name"),
                      content: TextField(
                        controller: roomNameController,
                        decoration: InputDecoration(hintText: "Room Name"),
                      ),
                      actions: [
                        ElevatedButton(
                          child: Text("Cancel"),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                        ElevatedButton(
                          child: Text("Create"),
                          onPressed: () async {
                            String roomName = roomNameController.text;
                            if (currentUser != null) {
                              List<Map<String, dynamic>> data = await db.fetchSongs();
                              List<Map<String, dynamic>> randomizedVideoData = _randomizeList(data);
                              bool success = await db.createRoom(currentUser, roomName, randomizedVideoData);
                              if (success) {
                                Navigator.push(context, MaterialPageRoute(
                                    builder: (context) => PreGameLobbyScreen(roomId: roomName, currentUserId: currentUser.uid)
                                ));
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text('Room name already taken. Please choose another name.'),
                                ));
                              }
                            }
                          },
                        ),
                      ],
                    );
                  }
              );
            },
          ),
        ],
      ),
    );
  }
}
