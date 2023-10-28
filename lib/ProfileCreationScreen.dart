import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kqduell/intermediate_screen.dart';
import 'auth_service.dart';
import 'dart:io';

class ProfileCreationScreen extends StatefulWidget {
  final String uid;

  ProfileCreationScreen({required this.uid});

  @override
  _ProfileCreationScreenState createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends State<ProfileCreationScreen> {
  final AuthService _auth = AuthService();
  String _username = '';
  XFile? _profilePicture;  // Updated type to XFile

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _profilePicture = pickedImage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFB4C7),
      appBar: AppBar(title: Text('Complete Your Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              onChanged: (value) => _username = value,
              decoration: InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            CircleAvatar(
              radius: 50,
              backgroundImage: _profilePicture != null
                  ? FileImage(File(_profilePicture!.path))
                  : null, // Placeholder image if needed
              child: IconButton(
                icon: Icon(Icons.camera_alt),
                onPressed: _pickImage,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (_username.isNotEmpty) {
                  await _auth.saveUserProfile(widget.uid, _username, _profilePicture != null ? File(_profilePicture!.path) : null);
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => IntermediateScreen()));
                }
              },
              child: Text('Complete Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
