import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'ProfileCreationScreen.dart';
import 'intermediate_screen.dart';
import 'database.dart';
import 'package:provider/provider.dart';
import 'package:kqduell/UserProvider.dart' hide DatabaseService;
import 'models.dart';


class SignInUp extends StatefulWidget {
  @override
  _SignInUpState createState() => _SignInUpState();
}

class _SignInUpState extends State<SignInUp> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool signUp = false;
  String _email = '';
  String _password = '';
  String _username = '';
  String _confirmPassword = '';
  String _error = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFB4C7),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 40),
                Image.asset(
                  'assets/images/logo.png',
                  height: 150,
                ),
                SizedBox(height: 20),
                Container(),
                TextFormField(
                  onChanged: (val) => setState(() => _email = val.trim()),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  validator: (val) => val!.isEmpty ? 'Enter an email' : null,
                ),
                SizedBox(height: 20),
                TextFormField(
                  onChanged: (val) => setState(() => _password = val),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  obscureText: true,
                  validator: (val) => val!.length < 6 ? 'Enter a password 6+ characters long' : null,
                ),
                SizedBox(height: 20),
                signUp
                    ? TextFormField(
                  onChanged: (val) => setState(() => _confirmPassword = val),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  obscureText: true,
                  validator: (val) => val != _password ? 'Passwords do not match' : null,
                )
                    : Container(),
                signUp ? SizedBox(height: 20) : Container(),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      dynamic result;
                      if (signUp) {
                        result = await _auth.registerWithEmailAndPassword(_email, _password, _username);
                        if (result['error'] == '') {
                          // After registering, navigate to the intermediate screen
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ProfileCreationScreen(uid: result['uid']!)));

                        }
                      } else {
                        result = await _auth.signInWithEmailAndPassword(_email, _password);
                        if (result['error'] == '') {
                          DatabaseService _databaseService = DatabaseService();
                          String username = (await _databaseService.getUsernameByUID(result['uid']!)) ?? 'Unknown';

    Provider.of<UserProvider>(context, listen: false).setUser(UserModel(uid: result['uid']!, username: username));

                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => IntermediateScreen()));
                        }
                      }
                      if (result['error'] != '' && this.mounted) {
                        setState(() => _error = result['error']);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_error),
                            duration: Duration(seconds: 3),
                          ),
                        );
                        if (this.mounted) {
                          setState(() => _error = '');
                        }
                      }
                    }
                  },
                  child: Text(signUp ? 'Sign Up' : 'Sign In'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                    primary: Color(0xFF6B3B6C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    textStyle: TextStyle(fontSize: 18),
                  ),
                ),
                SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    setState(() {
                      signUp = !signUp;
                    });
                  },
                  child: Text(
                    signUp ? 'Already have an account? Sign in' : 'Create an account',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

