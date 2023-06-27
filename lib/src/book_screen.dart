import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'package:mybook/main.dart';
import 'package:mybook/src/camera_screen.dart';
import 'package:mybook/src/edit_sentence_screen.dart';
import 'package:mybook/src/new_sentence_screen.dart';


class OneBook extends StatefulWidget {
  const OneBook({Key? key, required this.box, required this.bookId, required this.bookTitle}) : super(key: key);
  final Box box;
  final String bookId;
  final String bookTitle;

  @override
  OneBookState createState() => OneBookState();
}

class OneBookState extends State<OneBook> {
  List<Map<String, dynamic>> _items = [];
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.korean);

  @override
  void initState() {
    super.initState();
    _refreshItems();
  }

  @override
  void dispose() {
    super.dispose();
  }  

  void _refreshItems() {    
    final data = widget.box.keys.map((key) {
      final value = widget.box.get(key);
      return {"key": key, 
              "imagePath": value["imagePath"], 
              "sentence": value['sentence'], 
              "memo": value['memo'], 
              "datetime": value['datetime']};
    }).toList();

    setState(() {
      _items = data.reversed.toList();      
    });
  }

  _showImage(String fileName) {
    //return Image.file(File(fileName));
    return File(fileName).existsSync() ? Image.file(File(fileName)) : const Text('No Image');
  }

  _shareSentence(BuildContext context, String imagePath, String sentence, String memo) async {
    final box = context.findRenderObject() as RenderBox?;
    final textToShare = '"$sentence"\n\nFrom [${widget.bookTitle}]\n\n# $memo';
    await Share.share(textToShare,
      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.bookTitle),
      ),
      body: _items.isEmpty ? 
        const Center(
          child: Text(
            'No Entry',
            style: TextStyle(fontSize: 30),
          ),
        )
        : ListView.builder(              
          itemCount: _items.length,
          itemBuilder: (_, index) {
            final currentItem = _items[index];
            return GestureDetector(              
              onTap: () async {                
                await Navigator.push(context,
                  MaterialPageRoute(builder: (context) => EditSentenceScreen( box: widget.box, itemKey: currentItem['key'])) );
                _refreshItems();
              },
              child: Container(
                
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(width: 3))
                ),
                
                child: Column(                
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [                    
                    _showImage(currentItem['imagePath']),
                    const SizedBox(height: 15),
                  
                    Text(currentItem['sentence']),
                    const SizedBox(height: 15),
                    const Divider(thickness: 2),

                    Row(children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [Text(currentItem['memo']),
                                     Text(DateFormat('yyyy-MM-dd kk:mm').format(currentItem['datetime']), 
                                       style: const TextStyle(fontStyle: FontStyle.italic),)
                          ]
                        )
                      ),
                      IconButton( icon: const Icon(Icons.share, size: 24),
                            onPressed: () => _shareSentence(context, 
                                                            currentItem['imagePath'], 
                                                            currentItem['sentence'], 
                                                            currentItem['memo']) ),
                      ],
                    ),


                  ],
                )  
              )
            );
          }
        ),
      
      floatingActionButton: firstCamera != null ? FloatingActionButton(

        onPressed: () async {          
          final result = await Navigator.push(context,
            MaterialPageRoute(builder: (context) => TakePictureScreen( camera: firstCamera! ))
          );

          if(result != null) {
            final tr = await _textRecognizer.processImage(InputImage.fromFilePath(result));

            if(mounted) {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => 
                NewSentenceScreen( box: widget.box, bookId: widget.bookId, imagePath: result, imageText: tr.text )) );
            }                                                                              
          }
          else {
            if(mounted) {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => 
                NewSentenceScreen( box: widget.box, bookId: widget.bookId, imagePath: '', imageText: '' )) );
            }
          }
          _refreshItems();
        },
        child: const Icon(Icons.add, size: 48),
      ) : null,
    );
  }
}


