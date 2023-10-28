import 'package:flutter/material.dart';
import 'package:kqduell/main.dart';
import 'intermediate_screen.dart';

class EndScreen extends StatelessWidget {
  final int score;

  EndScreen({required this.score});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFFFFB4C7), Color(0xFF6B3B6C)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Spacer(flex: 2),
                Text(
                  'Thanks for playing!\nYour score: $score',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                  textAlign: TextAlign.center,
                ),
                Spacer(flex: 2),
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints.tightFor(width: 200),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => IntermediateScreen(),
                          ),
                        );
                      },
                      child: Text('Play Again!'),
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
                ),
                Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
