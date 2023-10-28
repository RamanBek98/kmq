import 'package:flutter/material.dart';
import 'package:kqduell/Multiplayer.dart';
import 'package:kqduell/main.dart';
import 'Singleplayer.dart';
import 'sign_in_up.dart';
import 'package:kqduell/intermediate_screen.dart';
import 'package:kqduell/MultiplayerLobby.dart';
import 'package:kqduell/UserProvider.dart';
import 'package:provider/provider.dart';

class IntermediateScreen extends StatelessWidget {
  final int rounds = 10;
  final Duration duration = Duration(seconds: 10);
  final List<Duration> durationOptions = List<Duration>.generate(
    13,
        (index) => Duration(seconds: (index + 1) * 5),
  );
  final List<int> roundsOptions = List<int>.generate(
    12,
        (index) => (index + 1) * 5,
  );

  Future<void> showSettingsDialog(BuildContext context, int rounds, Duration duration) async {
    int tempRounds = rounds;
    Duration tempDuration = duration;

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              contentPadding: EdgeInsets.all(0),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Settings', style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.black),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Rounds'),
                        SizedBox(height: 10),
                        DropdownButton<int>(
                          value: tempRounds,
                          items: roundsOptions.map((int value) {
                            return DropdownMenuItem<int>(
                              value: value,
                              child: Text('$value'),
                            );
                          }).toList(),
                          onChanged: (int? newValue) {
                            setState(() {
                              if (newValue != null) {
                                tempRounds = newValue;
                              }
                            });
                          },
                        ),
                        SizedBox(height: 20),
                        Text('Seconds'),
                        SizedBox(height: 10),
                        DropdownButton<Duration>(
                          value: tempDuration,
                          items: durationOptions.map((Duration value) {
                            return DropdownMenuItem<Duration>(
                              value: value,
                              child: Text('${value.inSeconds} seconds'),
                            );
                          }).toList(),
                          onChanged: (Duration? newValue) {
                            setState(() {
                              if (newValue != null) {
                                tempDuration = newValue;
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    // setState is not available here; you'll need to pass the new values to the calling function if required.
                    Navigator.of(context).pop();
                  },
                  child: Text('Apply Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final username = userProvider.currentUser?.username;

    return Scaffold(
      appBar: AppBar(
        title: Text(username ?? 'Not logged in'),
      ),
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Image.asset(
              'assets/images/Background.png',
              fit: BoxFit.cover,
              height: double.infinity,
              width: double.infinity,
              alignment: Alignment.center,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Spacer(flex: 1),
                  Text(
                    'Get ready for the game!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
                  Spacer(flex: 2),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GameScreen(
                              gameLimit: rounds,
                              gameDuration: duration,
                            ),
                          ),
                        );
                      },
                      child: Text('Singleplayer'),
                      style: ElevatedButton.styleFrom(
                        primary: Color(0xFF6B3B6C),
                        onPrimary: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        textStyle: TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  Spacer(flex: 1),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MultiplayerLobby(),
                          ),
                        );
                      },
                      child: Text('Multiplayer'),
                      style: ElevatedButton.styleFrom(
                        primary: Color(0xFF6B3B6C),
                        onPrimary: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        textStyle: TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  Spacer(flex: 1),
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        await showSettingsDialog(context, rounds, duration);
                      },
                      child: Text('Settings'),
                      style: ElevatedButton.styleFrom(
                        primary: Color(0xFF6B3B6C),
                        onPrimary: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        textStyle: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  Spacer(flex: 1),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SignInUp(),
                          ),
                        );
                      },
                      child: Text(
                        'Back to Login',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  Spacer(flex: 1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
