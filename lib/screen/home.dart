import 'dart:io';

import 'package:chat/components/chat_message.dart';
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
  bool _isLoading = false;

  @override
  void initState() {
    FirebaseAuth.instance.onAuthStateChanged.listen((user) {
      setState(() {
        _currentUser = user;
      });
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
    data['time']   = Timestamp.now();

    if(imgFile != null){
      StorageUploadTask task = FirebaseStorage.instance.ref().child("img").child(
        DateTime.now().millisecondsSinceEpoch.toString()
      ).putFile(imgFile);

      setState(() {
        _isLoading = true;
      });

      StorageTaskSnapshot taskSnapshot = await task.onComplete;
      String url = await taskSnapshot.ref.getDownloadURL();
      data['imgUrl'] = url;

      setState(() {
        _isLoading = false;
      });
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
        title: _currentUser != null ? Text(_currentUser.displayName) : Text("ChatApp"),
        elevation: 0,
        actions: [
          _currentUser != null ? IconButton(icon: Icon(Icons.exit_to_app), onPressed:(){
            FirebaseAuth.instance.signOut();
            googleSignIn.signIn();
            _scaffoldKey.currentState.showSnackBar(SnackBar(
                content: Text("logout realizado com sucesso!"))
            );

          }):Container()
        ],
      ),
      body: Column(
        children: [
          Expanded(child: StreamBuilder(
            stream: Firestore.instance.collection("mensagens").orderBy("time").snapshots(),
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
                        return ChatMessage(documents[index].data,
                            documents[index].data['uid' == _currentUser?.uid]);
                      }
                  );
              }
            },
          )),
          _isLoading ? LinearProgressIndicator() : Container(),
          TextComposer(_sendMessage),
        ],
      ),
    );
  }
}
