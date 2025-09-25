import 'package:flutter/material.dart';
import 'dart:developer';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:flutter_image/pages/gps.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  XFile? image;
  final ImagePicker picker = ImagePicker();
  File? savedFile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera')),
      body: Center(
        child: Column(
          children: [
            FilledButton(
              onPressed: () async {
                image = await picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  log(image!.path.toString());
                } else {
                  log('No Image');
                }
              },
              child: const Text('Gallery'),
            ),
            FilledButton(
              onPressed: () async {
                image = await picker.pickImage(source: ImageSource.camera);
                if (image != null) {
                  log(image!.path.toString());
                  setState(() {});
                } else {
                  log('No Image');
                }
              },
              child: const Text('Camera'),
            ),

            FilledButton(
              onPressed: () async {
                final Directory tempDir =
                    await getApplicationDocumentsDirectory();
                if (image != null) {
                  savedFile = File('${tempDir.path}/${image!.name}');
                  image!.saveTo(savedFile!.path);
                  log(savedFile!.path.toString());
                  setState(() {});
                }
              },
              child: const Text('Save'),
            ),
            (savedFile != null)
                ? Image.file(File(savedFile!.path))
                : Container(),
            FilledButton(
              onPressed: onPressed,
              child: const Text('gps'),
            )
          ],
        ),
      ),
    );
  }

  void onPressed() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const GPSandMapPage()));
  }
}
