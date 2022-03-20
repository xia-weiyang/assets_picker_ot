import 'dart:io';

import 'package:assets_picker_ot/assets_picker_ot.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _fileList = <File>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_con) {
                  return PickerPage(
                    maxSelected: 3,
                    overMaxSelected: (context) {
                      debugPrint('最多选择3张图片');
                    },
                  );
                })).then((value) {
                  _fileList.clear();
                  if (value is List<File>) {
                    setState(() {
                      _fileList.addAll(value);
                    });
                  }
                });
              },
              child: const Text('从相册选取'),
            ),
            ..._fileList.map((it) {
              return Image.file(
                it,
                fit: BoxFit.cover,
                width: 100,
                height: 100,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
