import 'package:chat/screen/home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  runApp(MyApp());
  // Firestore.instance.collection("mesagens").document().setData({
  //   "msg":"Como é que faz quando o amente quer ser algo mais",
  //   "from":"Desconhecido",
  //   "read":false
  // });
  
  // QuerySnapshot snapshot = await Firestore.instance.collection("mesagens").getDocuments();
  // snapshot.documents.forEach((element) {
  //     print(element.data);
  //     print(element.documentID);
  // });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(

        primarySwatch: Colors.blue,

        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Home()
    );
  }
}
