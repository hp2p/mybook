import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_crop/image_crop.dart';



class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    super.key,
    required this.camera    
  }); 
  final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  final cropKey = GlobalKey<CropState>();

  @override
  void initState() {    
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.max,
    );
    
    _initializeControllerFuture = _controller.initialize();
    
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Take a picture')),
      // You must wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner until the
      // controller has finished initializing.
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            final size = MediaQuery.of(context).size;
            final deviceRatio = size.width / size.height;
            
            return Center(
              child: AspectRatio(
                aspectRatio: deviceRatio,
                child: CameraPreview(_controller)
              )              
            );
          } else {
            // Otherwise, display a loading indicator.
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),      
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            await _initializeControllerFuture;
            final image = await _controller.takePicture();
            
            if (mounted) {
              Navigator.pop(context, image.path);
            }          
          } 
          catch (e) {
            print(e);
          }
        },
        child: const Icon(Icons.camera_alt),        
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndTop
    );
  }
}
