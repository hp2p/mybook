import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mybook/src/util.dart';

class EditSentenceScreen extends StatefulWidget {
  const EditSentenceScreen({Key? key, required this.box, required this.itemKey}) : super(key: key);
  final Box box;
  final int itemKey;

  @override
  State<EditSentenceScreen> createState() => _EditSentenceScreenState();
}

class _EditSentenceScreenState extends State<EditSentenceScreen> {
  final TextEditingController _sentenceController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();

  @override
  void dispose() {
    _sentenceController.dispose();
    _memoController.dispose();
    super.dispose();
  }  

  Future<void> _deleteItem(int itemKey) async {
    final value = widget.box.get(itemKey);
    final file = File(value['imagePath']);
    file.delete();    
    await widget.box.delete(itemKey);
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.box.get(widget.itemKey);
    if(value == null) {
        return Container();
    }
    final imagePath = value['imagePath'];
    _sentenceController.text = value['sentence'];
    _memoController.text = value['memo'];

    return Scaffold(
      appBar: AppBar(title: Text(safeSubstring(value['memo'], 32), style: const TextStyle(fontSize: 16))),
      
      body: SingleChildScrollView(        
        child: IntrinsicHeight(            
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [        
                  Container(
                    margin: const EdgeInsets.all(4),
                    child: ElevatedButton(
                      onPressed: () async {
                        _deleteItem(widget.itemKey);
                        Navigator.of(context).pop();
                      },                    
                      child: const Text('Delete')
                    ),
                  ),
                  const Spacer(),

                  Image.file(File(imagePath)),
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
                      autofocus: true,
                    )
                  ),
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
                      autofocus: true,
                    ),
                  )
              ],)
          )
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final value = widget.box.get(widget.itemKey);
          value['sentence'] = _sentenceController.text.trim();
          value['memo'] = _memoController.text.trim();
          value['datetime'] = DateTime.now();
          await widget.box.put(widget.itemKey, value);
          if(mounted) {
            Navigator.of(context).pop();
          }          
        },
        icon: const Icon(Icons.save),
        label: const Text('Update')
      ),
    );
  }
}
