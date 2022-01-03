import 'package:flutter/material.dart';

class PickerPage extends StatefulWidget {
  const PickerPage({Key? key}) : super(key: key);

  @override
  PickerPageState createState() => PickerPageState();
}

class PickerPageState extends State<PickerPage> {
  @override
  Widget build(BuildContext context) {
    return const Material(
      child: Scaffold(
        body: Text('test'),
      ),
    );
  }
}
