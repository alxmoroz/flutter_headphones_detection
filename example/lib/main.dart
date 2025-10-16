import 'dart:async';

import 'package:flutter/material.dart';
import 'package:headphones_detection/headphones_detection.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Headphones Detection Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Headphones Detection Example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isConnected = false;
  String _status = 'Unknown';
  StreamSubscription<bool>? _subscription;

  @override
  void initState() {
    super.initState();
    _checkHeadphones();
    _startListening();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _checkHeadphones() async {
    try {
      final isConnected = await HeadphonesDetection.isHeadphonesConnected();
      setState(() {
        _isConnected = isConnected;
        _status = isConnected ? 'Connected' : 'Disconnected';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  void _startListening() {
    _subscription = HeadphonesDetection.getPeriodicStream(interval: const Duration(seconds: 1)).listen((connected) {
      setState(() {
        _isConnected = connected;
        _status = connected ? 'Connected' : 'Disconnected';
      });
    });
  }

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
            Icon(
              _isConnected ? Icons.headset : Icons.headset_off,
              size: 100,
              color: _isConnected ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 20),
            Text(
              'Status: $_status',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _checkHeadphones,
              child: const Text('Check Now'),
            ),
          ],
        ),
      ),
    );
  }
}
