import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import "package:timezone/data/latest.dart" as tz;
import 'package:timezone/timezone.dart' as tz;

import 'src/book_screen.dart';




CameraDescription? firstCamera;
Directory? appDocDir;


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('Books_box'); 

  try {
    final cameras = await availableCameras().timeout(const Duration(seconds: 1));
    if(cameras.isNotEmpty) {
      firstCamera = cameras.first;
    }
  }
  on CameraException {
    print('No camera');
  }

  appDocDir = await getApplicationDocumentsDirectory();

  runApp(
    const MaterialApp( 
      title: 'MyBook',
      home: MyApp(),
    )
  );
}


class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'my Book',
      theme: ThemeData(
        primarySwatch: Colors.green,
        textTheme: Theme.of(context).textTheme.apply(fontSizeFactor: 1.35)
      ),
      home: const HomePage(),
    );
  }
}

/* https://www.kindacode.com/article/flutter-hive-database/ */

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage>  {  
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  List<Map<String, dynamic>> _items = [];

  final _booksBox = Hive.box('Books_box');

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();

  @override
  void initState() {
    super.initState();
    for(var key in _booksBox.keys) {
      Hive.openBox( _createBookId(key)  );
    }
    _refreshItems();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _authorController.dispose();
    super.dispose();
  }  

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if(state == AppLifecycleState.resumed) {
      FlutterAppBadger.removeBadge();
    }
  }

  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    final String? timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName!));
  }

  Future<void> _InitializeNotification() async {
    const DarwinInitializationSettings initializationSettingsIOS = 
      DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

    const AndroidInitializationSettings initializationSettingsAndroid = 
      AndroidInitializationSettings('lc_notification');

    const InitializationSettings initializationSettings = 
      InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

//https://dev-yakuza.posstree.com/ko/flutter/flutter_local_notifications/


  void _refreshItems() {
    final data = _booksBox.keys.map((key) {
      final value = _booksBox.get(key);
      return {"key": key, "name": value["name"], "author": value['author']};
    }).toList();

    setState(() {
      _items = data.reversed.toList();      
    });
  }

  String _createBookId(int key) {
    return 'Book${key}_box';
  }

  Future<void> _createItem(Map<String, dynamic> newItem) async {
    final key = await _booksBox.add(newItem);  
    final bookId = _createBookId(key);
    await Hive.openBox(bookId);
    await Directory('${appDocDir!.path}/$bookId').create();
    _refreshItems();
  }

  /*
  Map<String, dynamic> _readItem(int key) {
    final item = _booksBox.get(key);
    return item;
  } */
  
  Future<void> _updateItem(int itemKey, Map<String, dynamic> item) async {
    await _booksBox.put(itemKey, item);
    _refreshItems();
  }
  
  Future<bool?> _showMyDialog({required String title, required String message}) async {
    return showDialog<bool?>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),                
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteItem(int itemKey) async {    
    final value = _booksBox.get(itemKey);    
    final decision = await _showMyDialog( title: "Delete a Book", message: 'Do you want to delete "${value['name']}"');

    if(decision!) {
      //
      // to do : 
      // delete all images and contents of itemKey
      //
      await _booksBox.delete(itemKey);    
      final bookId = _createBookId(itemKey);
      final box = Hive.box(bookId);
      await box.clear();
      
      final dirPath = '${appDocDir!.path}/$bookId';
      final existsDir = await Directory(dirPath).exists();
      if(existsDir) {
        await Directory(dirPath).delete();
      }    
    }

    _refreshItems();
  }

  void _showForm(BuildContext ctx, int? itemKey) async {
    if (itemKey != null) {
      final existingItem = _items.firstWhere((element) => element['key'] == itemKey);
      _nameController.text = existingItem['name'];
      _authorController.text = existingItem['author'];
    }
    else {
      _nameController.text = '';
      _authorController.text = '';
    }

    showModalBottomSheet(
        context: ctx,
        elevation: 5,
        isScrollControlled: true,
        builder: (_) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            top: 15, left: 15, right: 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'Book Name'),
              ),
              const SizedBox(
                height: 10,
              ),
              TextField(
                controller: _authorController,                    
                decoration: const InputDecoration(hintText: 'Author'),
              ),
              const SizedBox(
                height: 20,
              ),
              ElevatedButton(
                onPressed: () async {                   
                  if (itemKey == null) {
                    _createItem({
                      "name": _nameController.text,
                      "author": _authorController.text
                    });
                  }
                  else {
                    _updateItem(itemKey, {
                      'name': _nameController.text.trim(),
                      'author': _authorController.text.trim()
                    });
                  }
                  
                  _nameController.text = '';
                  _authorController.text = '';

                  Navigator.of(context).pop(); // Close the bottom sheet
                },
                child: Text(itemKey == null ? 'Create New' : 'Update'),
              ),
              const SizedBox(
                height: 15,
              )
            ],
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('my Book'),
      ),
      body: _items.isEmpty
          ? const Center(
              child: Text(
                'No Data',
                style: TextStyle(fontSize: 30),
              ),
            )
          : ListView.builder(              
              itemCount: _items.length,
              itemBuilder: (_, index) {
                final currentItem = _items[index];
                return GestureDetector(
                  onTap: () {    
                    final bookId = _createBookId(_items[index]['key']);
                    Navigator.push(context,
                                   MaterialPageRoute(builder: (context) => 
                                     OneBook(box : Hive.box(bookId), 
                                             bookId : bookId, 
                                             bookTitle: currentItem['name'])),); 
                  },
                  child: Card(
                    color: Colors.green.shade100,
                    margin: const EdgeInsets.all(7),
                    elevation: 3,
                    child: ListTile(
                      title: Text(currentItem['name']),
                      subtitle: Text(currentItem['author']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [                          
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showForm(context, currentItem['key'])
                          ),                          
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteItem(currentItem['key']),
                          ),
                        ],
                      )),
                  )
                );
              }),
      // Add new item button
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }
}


