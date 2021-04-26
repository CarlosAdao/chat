


import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class TextComposer extends StatefulWidget {
  final Function({String text, File imgFile}) sendMenssage;

  TextComposer(this.sendMenssage);

  @override
  _TextComposerState createState() => _TextComposerState();
}

class _TextComposerState extends State<TextComposer> {
  bool _isComposing = false;
  final  TextEditingController _controller = TextEditingController();

  void _reset(){
    widget.sendMenssage(text: _controller.text);
    _controller.clear();
    setState(() {
      _isComposing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
              icon: Icon(
                Icons.photo_camera,
              ),
              onPressed: () async{
                final File imgf = await ImagePicker.pickImage(source: ImageSource.camera);

                if(imgf == null)
                  return;

                widget.sendMenssage(imgFile:imgf);
              }),
          Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration.collapsed(hintText: "envia uma message"),
                onChanged: (text){
                  setState(() {
                    _isComposing = text.isNotEmpty;
                  });
                },
                onSubmitted: (text){
                  _reset();
                },
          )),
          IconButton(icon: Icon(Icons.send), onPressed: _isComposing ? (){
            _reset();
          }: null)
        ],
      ),
    );
  }
}
