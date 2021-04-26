import 'dart:io';

import 'package:chat/components/text_composer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  FirebaseUser _currentUser;

  @override
  void initState() {
    FirebaseAuth.instance.onAuthStateChanged.listen((user) {
      _currentUser = user;
    });
  }

  Future<FirebaseUser> _getUser() async{
    if(_currentUser != null)
      return _currentUser;

    try{
        final GoogleSignInAccount googleSignInAccount = await googleSignIn.signIn();
        final GoogleSignInAuthentication googleSignInAuthentication = await googleSignInAccount.authentication;

        final AuthCredential credential = GoogleAuthProvider.getCredential(
            idToken: googleSignInAuthentication.idToken,
            accessToken: googleSignInAuthentication.accessToken
        );

        final AuthResult authResult = await FirebaseAuth.instance.signInWithCredential(credential);
        return authResult.user;

    }catch(error){
      return null;
    }
  }

  void _sendMessage({String text, File imgFile}) async{
    final FirebaseUser user = await _getUser();
    Map<String, dynamic> data = {};

    if(user == null){
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text("Não foi possivel fazer o login"),
        backgroundColor: Colors.red)
      );
    }


    data['uid']   = user.uid;
    data['name']   = user.displayName;
    data['photoUrl']   = user.photoUrl;

    if(imgFile != null){
      StorageUploadTask task = FirebaseStorage.instance.ref().child("img").child(
        DateTime.now().millisecondsSinceEpoch.toString()
      ).putFile(imgFile);

      StorageTaskSnapshot taskSnapshot = await task.onComplete;
      String url = await taskSnapshot.ref.getDownloadURL();
      data['imgUrl'] = url;
    }

    if(text != null){
      data['text'] = text;
    }

    Firestore.instance.collection("mensagens").add(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("Olá"),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(child: StreamBuilder(
            stream: Firestore.instance.collection("mensagens").snapshots(),
            builder: (context, snapshot){
              switch(snapshot.connectionState){
                case ConnectionState.none:
                case ConnectionState.waiting:
                  return Center(child: CircularProgressIndicator());
                default:
                  List<DocumentSnapshot> documents = snapshot.data.documents.reversed.toList();

                  return ListView.builder(
                      itemCount: documents.length,
                      reverse: true,
                      itemBuilder: (context, index){
                        return ListTile(
                          title: Text(documents[index].data['text'] != null ? documents[index].data['text'] :""),
                        );
                      }
                  );
              }
            },
          )),
          TextComposer(_sendMessage),
        ],
      ),
    );
  }
}