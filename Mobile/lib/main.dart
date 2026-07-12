import 'package:flutter/material.dart';

import 'core/config/app_environment.dart';

void main() {
  AppEnvironment.setUp(Env.DEV);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final config = AppEnvironment.current;

    return MaterialApp(
      title: config.appName,
      debugShowCheckedModeBanner: config.env == Env.DEV,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
      ),
      home: Scaffold(
        body: Center(
          child: Text('${config.appName}\n${config.baseUrl}'),
        ),
      ),
    );
  }
}
