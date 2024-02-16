import 'package:flutter/material.dart';
import 'package:kqduell/MultiplayerLobby.dart';
import 'package:kqduell/main.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'EndScreen.dart';
import 'intermediate_screen.dart';
import 'dart:async';
import 'package:kqduell/UserProvider.dart' hide DatabaseService;
import 'package:provider/provider.dart';
import 'database.dart';
import 'package:firebase_database/firebase_database.dart';
import 'models.dart';


final _formKey = GlobalKey<FormState>();






class MultiplayerGameScreen extends StatefulWidget {
  final String roomId;  // Add room ID
  final int gameLimit;
  final Duration gameDuration;


  MultiplayerGameScreen({
    required this.roomId,
    this.gameLimit = 10,
    this.gameDuration = const Duration(seconds: 20),
  });

  @override
  _MultiplayerGameScreenState createState() => _MultiplayerGameScreenState();
}
final _controllerCompleter = Completer<YoutubePlayerController>();

class _MultiplayerGameScreenState extends State<MultiplayerGameScreen> {
  Random _random = Random();
  final TextEditingController _textEditingController = TextEditingController();
  late YoutubePlayerController _controller;
  int _currentVideoIndex = 0;
  bool _canSkip = true;
  StreamSubscription? gameRoomSubscription;
  int _playCount = 0;
  bool _isFirstPlay = true;
  String _typedText = "";
  bool _isCovered = true;
  bool _skipAvailable = false;
  int _score = 0;
  bool _showPlayer = true;
  bool _allowInput = true;
  bool _guessLocked = false;
  Color _textFieldTextColor = Colors.black;
  bool _showSuggestions = false;
  bool _isLoading = true;
  int _round = 1;
  bool _showSuggestionsBox = false;
  String _gameStatus = "waiting"; // initial value set to 'waiting'
  bool _isControllerInitialized = false;
  bool _isInitialized = false;
  List<String> playerUids = []; // This list will hold the UIDs of the players.
  Map<String, UserModel> playerDetails = {}; // This map will hold the details of the players.


  List<Map<String, dynamic>> videoData = [];

  @override
  void initState() {
    super.initState();
    initializeController();
    listenToPlayerUpdates(widget.roomId); // This line remains to set up player updates listening.
  }




  Future<UserModel> fetchPlayerDetails(String uid) async {
    String username = (await DatabaseService().getUsernameByUID(uid)) ?? 'Unknown';
    String? profilePicturePath = await DatabaseService().getProfilePictureByUID(uid);
    return UserModel(uid: uid, username: username, profilePicturePath: profilePicturePath);
  }



  void initializeController() async {
    await _fetchVideoData();
    if (_isControllerInitialized) {
      _setupControllerListener();
    }
  }

  void _setupControllerListener() {
    setState(() {
      _isLoading = false;
      _isInitialized = true;
      _controller.addListener(_onPlayerStateChanged);
    });
  }



  Future<void> _fetchVideoData() async {
    {
      // Fetching songs from the Realtime Database
      DatabaseEvent songsEvent = await FirebaseDatabase.instance.ref('Songs').once();
      DataSnapshot dataSnapshot = songsEvent.snapshot;

      if (dataSnapshot.exists) {
        Map<dynamic, dynamic> songsMap = dataSnapshot.value as Map<dynamic, dynamic>;

        // Convert the songsMap to a list of Map<String, dynamic>
        List<Map<String, dynamic>> allVideoData = songsMap.values
            .where((song) => song is Map)
            .map((song) => Map<String, dynamic>.from(song as Map))
            .toList();

        // Randomize the order of the songs
        allVideoData.shuffle(Random());

        // Update your videoData list
        setState(() {
          videoData = allVideoData;

          // Initialize the YoutubePlayerController
          _controller = YoutubePlayerController(
            initialVideoId: videoData.isNotEmpty ? videoData[_currentVideoIndex]['videoid'] : 'default_video_id',
            flags: YoutubePlayerFlags(
                enableCaption: false,
                hideThumbnail: true,
                hideControls: true,
                autoPlay: false,
                mute: false,
                loop: false,
                forceHD: true
            ),
          );
          _controller.addListener(_onPlayerStateChanged);
          _isControllerInitialized = true;

          // Add a delay before calling play
          Future.delayed(Duration(milliseconds: 5500), () {
            if (videoData.isNotEmpty) {
              _controller.play();
            }

            // Complete the controllerCompleter here
            if (!_controllerCompleter.isCompleted) {
              _controllerCompleter.complete(_controller);
            }
          });
        });
      }
    }
  }





  void _simulateVideoEnd() {
    if (!_isControllerInitialized || !_canSkip) return;

    if (!_canSkip) return;
    int newPosition = 75 + widget.gameDuration.inSeconds;
    _controller.seekTo(Duration(seconds: newPosition));
    _canSkip = false;
    Future.delayed(Duration(seconds: 2), () {
      (() {
        _canSkip = true;
      });
    });

    String roomId = widget.roomId;
    String playerId = Provider.of<UserProvider>(context, listen: false).currentUser?.uid ?? '';
    recordSkipAction(roomId, playerId); // Record the skip action
  }









  Future<void> leaveGameRoom(String roomId, String playerId) async {
    DatabaseReference roomRef = FirebaseDatabase.instance.ref('gameRooms/$roomId/players');

    try {
      // Fetch existing players data
      DataSnapshot snapshot = await roomRef.get();
      if (snapshot.exists && snapshot.value != null) {
        Map<String, dynamic> players = Map<String, dynamic>.from(snapshot.value as Map);

        // Remove the player
        players.removeWhere((key, value) => value["playerId"] == playerId);

        // Update the players data
        await roomRef.set(players);
      }
    } catch (e) {
      print('An error occurred while leaving the game room: $e');
      // Handle any other errors here
    }
  }


  Future<void> recordSkipAction(String roomId, String playerId) async {
    DatabaseReference skipRef = FirebaseDatabase.instance.ref('gameRooms/$roomId/skipActions');

    try {
      // Fetch existing skip data
      DataSnapshot snapshot = await skipRef.get();
      List<dynamic> skipActions = snapshot.exists && snapshot.value != null
          ? List<dynamic>.from(snapshot.value as List)
          : [];

      // Add the new skip action
      skipActions.add({'playerId': playerId, 'timestamp': DateTime.now().toIso8601String()});

      // Update the skip actions in the database
      await skipRef.set(skipActions);
    } catch (e) {
      print('An error occurred while recording the skip action: $e');
      // Handle any other errors here
    }
  }



  void _onPlayerStateChanged() {
    if (!_isControllerInitialized) return;

    double currentPosition = _controller.value.position.inMilliseconds.toDouble();

    // Check if the video's current position is after the 78-second mark
    if (currentPosition >= (78 * 1000)) {
      setState(() {
        _skipAvailable = true; // Enable the skip button
      });
    } else {
      setState(() {
        _skipAvailable = false; // Disable the skip button
      });
    }

    if (currentPosition >= (75 * 1000) + widget.gameDuration.inMilliseconds -100 && _playCount == 1) {
      setState(() {
        _isCovered = true;
      });
    } else if (_playCount == 0) {
      setState(() {
        _isCovered = true;
      });
    } else {
      setState(() {
        _isCovered = false;
      });
    }

    if (_controller.value.position.inSeconds >= 75 + widget.gameDuration.inSeconds) {
      if (_playCount == 1) {
        _controller.pause();
        _playCount = 0;
        if (_typedText == videoData[_currentVideoIndex]['name']) {
          _score++;
        }
        _isFirstPlay = true;
        _guessLocked = false;
        setState(() {
          _allowInput = false;
          _showSuggestions = false;
          _textFieldTextColor = Colors.black;
          _typedText = "";
          _textEditingController.text = "";
        });

        if (_round < widget.gameLimit) {
          _round++;

          // Move to the next video index here
          _currentVideoIndex++;
          if (_currentVideoIndex >= videoData.length) {
            // Handle the end of the video list, maybe restart or show some end screen
            _currentVideoIndex = 0;  // Loop back to the start
          }
          _controller.load(videoData[_currentVideoIndex]['videoid']);
          _playCount = 0;

          _controller.seekTo(Duration(seconds: 75));
          Future.delayed(Duration(seconds: 2), () {
            setState(() {
              _controller.play();
              _allowInput = true;
            });
          });
        } else {
          _controller.pause();
          Future.delayed(Duration.zero, () {
            _controller.dispose();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => EndScreen(score: _score)),
            );
          });
        }

      } else {
        _controller.seekTo(Duration.zero);
        _playCount++;
        if (_isFirstPlay) {
          setState(() {
            _isFirstPlay = false;
            _guessLocked = false;
            _allowInput = false;
            _showSuggestions = false;
            if (_typedText == videoData[_currentVideoIndex]['name']) {
              _textFieldTextColor = Colors.green;
            } else {
              _textFieldTextColor = Colors.red;
            }
          });
        } else {
          setState(() {
            _guessLocked = false;
            _textFieldTextColor = Colors.black;
          });
        }
      }
    } else if (_controller.value.position.inSeconds == 0 && _playCount == 0) {
      _isFirstPlay = true;
      _allowInput = true;

      _controller.seekTo(Duration(seconds: 75));
      Future.delayed(Duration(seconds: 2), () {
        _controller.play();
      });
    }
  }






  void _onSubmit() {
    if (!_guessLocked && _allowInput) {
      _guessLocked = true;
      _textFieldTextColor = Colors.grey;
      _typedText = _textEditingController.text;
      _allowInput = false;
      setState(() {_showSuggestionsBox = false;});
    }
  }

  void _onSelection(String selection) {
    _textEditingController.text = selection;
  }

  @override
  void dispose() {
    if (_isControllerInitialized) {
      _controller.dispose();
    }

    super.dispose();
  }

  void listenToPlayerUpdates(String roomId) {
    gameRoomSubscription?.cancel(); // Cancel any existing subscription
    gameRoomSubscription = FirebaseDatabase.instance.ref('gameRooms/$roomId').onValue.listen((DatabaseEvent event) {
      if (event.snapshot.value is Map) {
        var data = Map<String, dynamic>.from(event.snapshot.value as Map);
        List<String> playerUids = List<String>.from(data['players'] ?? []);
        // Use Provider or a custom method to update player information
        Provider.of<PlayerDataNotifier>(context, listen: false).fetchAndUpdatePlayerDetails(playerUids);
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return CustomScaffold(
        body: Stack(
          children: <Widget>[ SkipActionListener(
            roomId: widget.roomId,
            onSkipAction: () {
              // Handle skip action, such as enabling a button or updating a state variable
              // This method will be called whenever a skip action is recorded in the database
            },
          ),
            Positioned.fill(
              child: Opacity(
                opacity: 0.3,
                child: Image.asset(
                  'assets/images/Background.png',
                  fit: BoxFit.fill,
                ),
              ),
            ),
            Center(child: CircularProgressIndicator()),
          ],
        ),
      );
    } else {
      return CustomScaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Color(0xFFFFB4C7),
        body: Stack(
          children: <Widget>[
            Positioned.fill(
              child: Opacity(
                opacity: 0.8,
                child: Image.asset(
                  'assets/images/game.jpg',
                  fit: BoxFit.fill,
                ),
              ),
            ),
            SafeArea(
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        margin: EdgeInsets.all(10),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(29),
                          color: Color(0xFF6B3B6C),
                        ),
                        child: Stack(
                          children: <Widget>[
                            Align(
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    _isCovered ? 'Guess the Song!' : videoData[_currentVideoIndex]['name'],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: _isCovered ? Colors.white : _textFieldTextColor,
                                    ),
                                  ),
                                  SizedBox(height: 1,),
                                  Text(
                                    'Score: $_score',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 1,),
                                  Text(
                                    'Round: $_round/${widget.gameLimit}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Align(
                                alignment: Alignment.topRight,
                                child: Align(
                                    alignment: Alignment.topRight,
                                    child: IconButton(
                                      onPressed: () async {
                                        String roomId = widget.roomId;
                                        String playerId = Provider.of<UserProvider>(context, listen: false).currentUser?.uid ?? '';

                                        // Dispose or pause the video player here if needed
                                        // Example: _controller.pause();

                                        // Leave game room logic (Firebase operations)
                                        await leaveGameRoom(roomId, playerId);

                                        // Delay the navigation for a smoother transition
                                        await Future.delayed(Duration(milliseconds: 300));

                                        // Navigate to the MultiplayerLobby screen
                                        Navigator.pushReplacement(
                                          context,
                                          PageRouteBuilder(
                                            pageBuilder: (context, animation, secondaryAnimation) => MultiplayerLobby(),
                                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                              var begin = 0.0;
                                              var end = 1.0;
                                              var tween = Tween(begin: begin, end: end);
                                              var fadeAnimation = animation.drive(tween);

                                              return FadeTransition(
                                                opacity: fadeAnimation,
                                                child: child,
                                              );
                                            },
                                          ),
                                        );
                                      },
                                      icon: Icon(Icons.reply, color: Colors.black),
                                      iconSize: 30.0,
                                    )

                                ),
                              ),

                            )],
                        ),
                      ), Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Container(
                                    height: 200.0,
                                    child: Visibility(
                                      visible: _showPlayer && _isControllerInitialized,

                                      child: YoutubePlayer(
                                        controller: _controller,
                                        aspectRatio: 16 / 9,
                                        showVideoProgressIndicator: true,
                                      ),
                                    ),
                                  ),
                                  if (_isCovered)
                                    Container(
                                      height: 200.0,
                                      color: Colors.black.withOpacity(1),
                                    ),
                                  Positioned(
                                    bottom: 8,
                                    left: 240,
                                    child: ElevatedButton(
                                      style: ButtonStyle(
                                        backgroundColor: MaterialStateProperty.all<Color>(Color(0xFF6C045E).withOpacity(0.5)),
                                      ),
                                      onPressed: _skipAvailable && _canSkip ? _simulateVideoEnd : null,
                                      child: Text("Skip"),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Consumer<PlayerDataNotifier>(
                        builder: (context, playerDataNotifier, child) {
                          return Container(
                            // Layout code for player information
                            child: Row(
                              children: playerDataNotifier.playerDetails.entries.map((entry) {
                                return PlayerInfoWidget(
                                  username: entry.value.username,
                                  profilePicUrl: entry.value.profilePicturePath,
                                  score: 0, // This should be dynamically updated based on the game logic
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),

                      Expanded(
                        child: SizedBox.shrink(),
                      ),
                      Container(
                        padding: EdgeInsets.all(6.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          color: Color(0xFF6B3B6C),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child:TextField(
                                  onChanged: (String text) {
                                    if (_allowInput) {
                                      setState(() {
                                        _typedText = text;
                                        _textFieldTextColor = Colors.black;
                                        _showSuggestions = text.isNotEmpty;
                                        _showSuggestionsBox = text.isNotEmpty;
                                      });
                                    }
                                  },
                                  controller: _textEditingController,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: EdgeInsets.symmetric(vertical: 1),
                                    hintText: "Type your guess",
                                    hintStyle: TextStyle(color: Colors.grey),
                                  ),
                                  enabled: _allowInput,
                                  textAlign: TextAlign.center,
                                  style: TextStyle( fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                    color: _textFieldTextColor,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              ElevatedButton(
                                style: ButtonStyle(
                                  backgroundColor: MaterialStateProperty.all<Color>(Color(0xFF6C045E)),
                                ),
                                onPressed: _onSubmit,
                                child: Text("Submit"),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_showSuggestions && _showSuggestionsBox)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 200,
                        child: SuggestionsBox(
                          typedText: _typedText,
                          suggestions: videoData.map((video) => video['name'] as String).toList(),
                          onSelection: (String selectedId) {
                            _textEditingController.text = selectedId;
                            FocusScope.of(context).unfocus();
                            setState(() {
                              _showSuggestionsBox = false;
                            });
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

}

class PlayerDataNotifier extends ChangeNotifier {
  Map<String, UserModel> playerDetails = {};

  final DatabaseService _databaseService = DatabaseService();

  void fetchAndUpdatePlayerDetails(List<String> playerUids) async {
    Map<String, UserModel> newDetails = {};
    bool hasChanged = false;
    for (String uid in playerUids) {
      UserModel details = await _databaseService.fetchPlayerDetails(uid);
      if (playerDetails[uid] != details) {
        hasChanged = true;
      }
      newDetails[uid] = details;
    }
    if (hasChanged) {
      playerDetails = newDetails;
      notifyListeners();
    }
  }
}

class PlayerInfoWidget extends StatelessWidget {
  final String username;
  final String? profilePicUrl;  // This can be null if the user doesn't have a profile picture.
  final int score;

  const PlayerInfoWidget({
    Key? key,
    required this.username,
    this.profilePicUrl,
    required this.score,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ImageProvider backgroundImage;
    if (profilePicUrl != null) {
      backgroundImage = NetworkImage(profilePicUrl!);
    } else {
      backgroundImage = AssetImage('assets/default-avatar.png');
    }

    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 20,
            backgroundImage: backgroundImage,
          ),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(username, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("Score: $score", style: TextStyle(fontSize: 14)),
            ],
          ),
        ],
      ),
    );

  }
}














class SuggestionsBox extends StatelessWidget {
  final String typedText;
  final List<String> suggestions;
  final ValueChanged<String> onSelection;

  const SuggestionsBox({
    Key? key,
    required this.typedText,
    required this.suggestions,
    required this.onSelection,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.5,
        child: Card(
          color: Colors.transparent,
          child: ListView.builder(
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              if (suggestions[index].toLowerCase().contains(typedText.toLowerCase())) {
                return ListTile(
                  title: Text(
                    suggestions[index],
                    style: TextStyle(fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  onTap: () => onSelection(suggestions[index]),
                );
              } else {
                return Container();
              }
            },
          ),
        ),
      ),
    );
  }
}

class SkipActionListener extends StatefulWidget {
  final String roomId;
  final VoidCallback onSkipAction;

  const SkipActionListener({
    Key? key,
    required this.roomId,
    required this.onSkipAction,
  }) : super(key: key);

  @override
  State<SkipActionListener> createState() => _SkipActionListenerState();
}

class _SkipActionListenerState extends State<SkipActionListener> {
  late StreamSubscription skipActionSubscription;

  @override
  void initState() {
    super.initState();
    final skipRef = FirebaseDatabase.instance.ref('gameRooms/${widget.roomId}/skipActions');
    skipActionSubscription = skipRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        // Trigger the callback when a skip action is detected
        widget.onSkipAction();
      }
    });
  }

  @override
  void dispose() {
    skipActionSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This widget does not need to build any UI itself; it's just for listening to skip actions.
    return Container();
  }
}

