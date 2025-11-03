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
        useMaterial3: true,
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
  HeadphonesInfo? _headphonesInfo;
  String _status = 'Unknown';
  String? _errorMessage;
  StreamSubscription<HeadphonesInfo?>? _eventSubscription;
  StreamSubscription<HeadphonesInfo?>? _periodicSubscription;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _checkHeadphones();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _periodicSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkHeadphones() async {
    setState(() {
      _errorMessage = null;
      _status = 'Checking...';
    });

    try {
      final headphonesInfo = await HeadphonesDetection.isHeadphonesConnected();
      setState(() {
        _headphonesInfo = headphonesInfo;
        if (headphonesInfo != null) {
          _status = 'Connected';
        } else {
          _status = 'Disconnected';
        }
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _status = 'Error';
      });
    }
  }

  void _startEventStream() {
    _stopListening();
    setState(() {
      _isListening = true;
    });

    _eventSubscription = HeadphonesDetection.headphonesStream.listen(
      (headphonesInfo) {
        setState(() {
          _headphonesInfo = headphonesInfo;
          if (headphonesInfo != null) {
            _status = 'Connected';
          } else {
            _status = 'Disconnected';
          }
          _errorMessage = null;
        });
      },
      onError: (error) {
        setState(() {
          _errorMessage = 'Stream error: $error';
        });
      },
    );
  }

  void _startPeriodicStream() {
    _stopListening();
    setState(() {
      _isListening = true;
    });

    _periodicSubscription = HeadphonesDetection.getPeriodicStream(
      interval: const Duration(seconds: 1),
    ).listen(
      (headphonesInfo) {
        setState(() {
          _headphonesInfo = headphonesInfo;
          if (headphonesInfo != null) {
            _status = 'Connected';
          } else {
            _status = 'Disconnected';
          }
          _errorMessage = null;
        });
      },
      onError: (error) {
        setState(() {
          _errorMessage = 'Stream error: $error';
        });
      },
    );
  }

  void _stopListening() {
    _eventSubscription?.cancel();
    _periodicSubscription?.cancel();
    setState(() {
      _isListening = false;
    });
  }

  String _getTypeDisplayName(String type) {
    switch (type) {
      case 'wired':
        return 'Wired Headphones';
      case 'bluetoothA2DP':
        return 'Bluetooth A2DP';
      case 'bluetoothSCO':
        return 'Bluetooth SCO';
      case 'bluetoothHFP':
        return 'Bluetooth HFP';
      case 'bluetoothLE':
        return 'Bluetooth LE';
      default:
        return type;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'wired':
        return Colors.blue;
      case 'bluetoothA2DP':
      case 'bluetoothSCO':
      case 'bluetoothHFP':
      case 'bluetoothLE':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _headphonesInfo != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 20),
            // Status Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isConnected
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
              ),
              child: Icon(
                isConnected ? Icons.headset : Icons.headset_off,
                size: 80,
                color: isConnected ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 24),

            // Status Text
            Text(
              _status,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isConnected ? Colors.green : Colors.red,
                  ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.red,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 32),

            // Device Info Card
            if (_headphonesInfo != null) ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Device Information',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Name', _headphonesInfo!.name, Icons.label),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Type',
                        _getTypeDisplayName(_headphonesInfo!.type),
                        Icons.cable,
                        color: _getTypeColor(_headphonesInfo!.type),
                      ),
                      if (_headphonesInfo!.metadata != null &&
                          _headphonesInfo!.metadata!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Divider(),
                        const SizedBox(height: 8),
                        Text(
                          'Metadata',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        ..._headphonesInfo!.metadata!.entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: _buildInfoRow(
                              entry.key,
                              entry.value.toString(),
                              Icons.settings,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ] else if (!_isListening) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.help_outline,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No headphones detected',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Connect your headphones to see device information',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Action Buttons
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _checkHeadphones,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Check Now'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                if (!_isListening) ...[
                  ElevatedButton.icon(
                    onPressed: _startEventStream,
                    icon: const Icon(Icons.stream),
                    label: const Text('Start Event Stream'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _startPeriodicStream,
                    icon: const Icon(Icons.timer),
                    label: const Text('Start Periodic Stream'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ] else ...[
                  OutlinedButton.icon(
                    onPressed: _stopListening,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop Listening'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (_isListening) ...[
              const SizedBox(height: 16),
              Text(
                'Listening for changes...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon,
      {Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color ?? Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
