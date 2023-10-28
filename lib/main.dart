
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'sign_in_up.dart';
import 'intermediate_screen.dart';
import 'UserProvider.dart';
import 'package:flutter/services.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final userProvider = UserProvider();
  await userProvider.fetchCurrentUser();  // Fetch the current user on app startup

  runApp(
    ChangeNotifierProvider.value(
      value: userProvider,
      child: MyApp(),
    ),
  );
}



class MyApp extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, AsyncSnapshot snapshot) {
        // Check for errors
        if (snapshot.hasError) {
          // In case of error with Firebase initialization, return an empty Container or you may return an error message.
          return Container();
        }

        // Once complete, show your application
        if (snapshot.connectionState == ConnectionState.done) {
          // Check if the user is already authenticated
          if (FirebaseAuth.instance.currentUser != null) {
            return MaterialApp(
              home: IntermediateScreen(),
              theme: ThemeData(
                primaryColor: Color(0xFF6B3B6C),
                scaffoldBackgroundColor: Color(0xFFFFB4C7),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    backgroundColor: Color(0xFF6B3B6C),
                    primary: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50.0),
                    ),
                  ),
                ),
              ),
            );
          } else {
            return MaterialApp(
              home: SignInUp(),
              theme: ThemeData(
                primaryColor: Color(0xFF6B3B6C),
                scaffoldBackgroundColor: Color(0xFFFFB4C7),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    backgroundColor: Color(0xFF6B3B6C),
                    primary: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50.0),
                    ),
                  ),
                ),
              ),
            );
          }
        }

        // Otherwise, show something whilst waiting for initialization to complete
        return Container(); // you can replace it with your own widget
      },
    );
  }
}

class CustomScaffold extends StatelessWidget {
  final Widget body;
  final Color backgroundColor;
  final PreferredSizeWidget? appBar;
  final bool resizeToAvoidBottomInset;

  CustomScaffold({
    required this.body,
    this.backgroundColor = Colors.white, // default color
    this.appBar,
    this.resizeToAvoidBottomInset = true, // default value
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: body,
        backgroundColor: backgroundColor,
        appBar: appBar,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        // add other properties as needed
      ),
    );
  }
}

