
import 'package:flutter/material.dart';
import 'package:material/project.dart';



void main() {
  runApp(const MyProject());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: Text("MyApp")),
          body: MyProject(),
        ),
    );
  }
}