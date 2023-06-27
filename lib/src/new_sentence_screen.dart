import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:mybook/main.dart';
import 'package:mybook/src/util.dart';


class NewSentenceScreen extends StatefulWidget {
  const NewSentenceScreen({Key? key, 
                            required this.box, 
                            required this.bookId,
                            required this.imagePath,
                            required this.imageText}) : super(key: key);
  final Box box;
  final String bookId;
  final String imagePath;
  final String imageText;

  @override
  State<NewSentenceScreen> createState() => _NewSentenceScreenState();
}

class _NewSentenceScreenState extends State<NewSentenceScreen> {

  final TextEditingController _sentenceController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();

  @override
  void initState() {       
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }  

  Future<void> _createItem(Map<String, dynamic> newItem, File croppedFile) async {
    final itemKey = await widget.box.add(newItem);
    
    final fileExtension = croppedFile.path.split('.').last;
    final destPath = '${appDocDir!.path}/${widget.bookId}/$itemKey.$fileExtension';
    await croppedFile.rename(destPath);  
    newItem['imagePath'] = destPath;
    
    await widget.box.put(itemKey, newItem);
  }

  @override
  Widget build(BuildContext context) {    
    final file = File(widget.imagePath);
    _sentenceController.text = widget.imageText;

    return Scaffold(
      appBar: AppBar(title: Text(safeSubstring(widget.imageText, 32), style: const TextStyle(fontSize: 16))),
      
      body: SingleChildScrollView(        
        child: IntrinsicHeight(            
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.end,

            children: [        

              Image.file(File(widget.imagePath)),
              const Spacer(),

              Card(
                color: Colors.green.shade100,
                margin: const EdgeInsets.only(left:16, top: 8, bottom: 8, right: 8),
                child: TextField(                    
                  textInputAction: TextInputAction.newline,
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  controller: _sentenceController,
                  decoration: const InputDecoration(labelText: 'What the author think.'),
                )),
              const Spacer(),

              Card(
                color: Colors.green.shade100,
                margin: const EdgeInsets.only(left:16, top: 8, bottom: 8, right: 8),
                child: TextField(
                  textInputAction: TextInputAction.newline,
                  keyboardType: TextInputType.multiline,            
                  maxLines: null,
                  controller: _memoController,                              
                  decoration: const InputDecoration(labelText: 'What do you think?'),
              )),
              const Spacer(),

              ElevatedButton(
                onPressed: () async {                   
                  await _createItem({
                    "imagePath": '',
                    "sentence" : _sentenceController.text.trim(),
                    "memo": _memoController.text.trim(),
                    "datetime" : DateTime.now()
                  }, file);                    
                  _sentenceController.text = '';
                  _memoController.text = '';
                  if(mounted) {
                    Navigator.of(context).pop();
                  }                  
                },
                child: const Text('Create New'),
              ),
          ],)
        )
      ),
    );
  }
}
