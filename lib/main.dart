import 'dart:io';
import 'package:fileuploadshow/services.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  File? file;
  UploadTask? task;
  Future selectFile() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: false);
    if (result == null) return;
    final path = result.files.single.path!;
    setState(() {
      file = File(path);
    });
  }

  Future uploadFile() async {
    if (file == null) return;
    final fileName = basename(file!.path);
    final destination = 'files/$fileName';
    task = MyFirebaseStorage.uploadFile(destination, file!);
    setState(() {});

    if (task == null) return;
    final snapshot = await task!.whenComplete(() => {});
    final url = await snapshot.ref.getDownloadURL();
    print(url);
  }

  Widget UploadStatus(UploadTask task) => StreamBuilder<TaskSnapshot>(
      stream: task.snapshotEvents,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final snap = snapshot.data!;
          final progess = snap.bytesTransferred / snap.totalBytes;
          final uploadPercent = (progess * 100).toStringAsFixed(2);
          return Text("$uploadPercent %");
        } else {
          return Container();
        }
      });

  @override
  Widget build(BuildContext context) {
    final fileName = file != null ? basename(file!.path) : 'No file Selected';
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text("File Upload to Firebase"),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                  onPressed: () {
                    selectFile();
                  },
                  child: const Text("Select File")),
              Text(fileName),
              ElevatedButton(
                  onPressed: () {
                    uploadFile();
                  },
                  child: const Text("Upload File")),
              task != null ? UploadStatus(task!) : Container()
            ],
          ),
        ),
      ),
    );
  }
}
