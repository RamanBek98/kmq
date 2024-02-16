import 'package:flutter/material.dart';
import 'package:kqduell/main.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'EndScreen.dart';
import 'intermediate_screen.dart';

final _formKey = GlobalKey<FormState>();

class GameScreen extends StatefulWidget {
  final int gameLimit;
  final Duration gameDuration;  // Add this line
  GameScreen({this.gameLimit = 10, this.gameDuration = const Duration(seconds: 20)});
  @override
  _GameScreenState createState() => _GameScreenState();
}


class _GameScreenState extends State<GameScreen> {
  Random _random = Random();
  final TextEditingController _textEditingController = TextEditingController();
  late YoutubePlayerController _controller;
  int _currentVideoIndex = 0;
  bool _canSkip = true; // true means the skip button can be pressed.

  int _playCount = 0;
  bool _isFirstPlay = true;
  String _typedText = "";
  bool _isCovered = true;
  bool _skipAvailable = false; // Add this line
  int _score = 0;
  bool _showPlayer = true;
  bool _allowInput = true;
  bool _guessLocked = false;
  Color _textFieldTextColor = Colors.black;
  bool _showSuggestions = false;
  bool _isLoading = true;
  int _round = 1;
  bool _showSuggestionsBox = false;
  List<Map<String, dynamic>> _randomizeList(List<Map<String, dynamic>> list) {
    list.shuffle(_random);
    return list;
  }

  List<Map<String, dynamic>> videoData = [];

  @override
  void initState() {
    super.initState();
    _fetchVideoData().then((_) {
      setState(() {
        _isLoading = false;
      });
    });
  }

  Future<void> _fetchVideoData() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('Songs').get();
    List<Map<String, dynamic>> data = querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    videoData = _randomizeList(data);
    setState(() {
      videoData = data;
      _controller = YoutubePlayerController(
        initialVideoId: videoData[_currentVideoIndex]['videoid'],
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
    });
  }



  void _simulateVideoEnd() {
    if (!_canSkip) return;  // If cooldown is active, do nothing.

    // Set the current position to just before the threshold
    int newPosition = 75 + widget.gameDuration.inSeconds  ;
    _controller.seekTo(Duration(seconds: newPosition));

    // Start cooldown
    _canSkip = false;
    Future.delayed(Duration(seconds: 2), () {  // 5 seconds cooldown
      setState(() {
        _canSkip = true;
      });
    });
  }









  void _onPlayerStateChanged() {
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

    if (_controller.value.position.inSeconds >= 75 + widget.gameDuration.inSeconds ) {
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
          videoData.removeAt(_currentVideoIndex);
          _currentVideoIndex = _random.nextInt(videoData.length);
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
          //
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
    _controller.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return CustomScaffold(
        body: Stack(
          children: <Widget>[
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
                              // Centered Texts
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

                              // Top right arrow icon using Positioned
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Align(
                                  alignment: Alignment.topRight,
                                  child: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _showPlayer = false;
                                      });
                                      _controller.pause();
                                      Navigator.pop(context);
                                    },
                                    icon: Icon(Icons.reply, color: Colors.black),
                                    iconSize: 30.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),


                        Padding(
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
                                      child: Visibility(visible: _showPlayer,
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
                                        onPressed: _skipAvailable && _canSkip ? _simulateVideoEnd : null, // Check for both conditions
                                        child: Text("Skip"),
                                      ),
                                    ),

                                  ],
                                ),
                              ),
                            ],
                          ),
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
                              FocusScope.of(context).unfocus();setState(() {
                                _showSuggestionsBox = false;  });
                            },
                          ),
                        ),
                      ),
                  ]),
            ),
          ],
        ),
      );
    }
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