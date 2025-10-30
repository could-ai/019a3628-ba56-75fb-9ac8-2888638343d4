import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  PermissionStatus _microphoneStatus = PermissionStatus.denied;
  PermissionStatus _locationStatus = PermissionStatus.denied;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final micStatus = await Permission.microphone.status;
    final locStatus = await Permission.location.status;
    setState(() {
      _microphoneStatus = micStatus;
      _locationStatus = locStatus;
    });
  }

  Future<void> _requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    setState(() {
      _microphoneStatus = status;
    });
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    setState(() {
      _locationStatus = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Flutter Permissions Demo"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'This app demonstrates how to request permissions in Flutter.',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Microphone Permission:', style: TextStyle(fontSize: 16)),
                  Text(
                    _microphoneStatus.name,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _getStatusColor(_microphoneStatus)),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: _requestMicrophonePermission,
                child: const Text('Request Microphone'),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Location Permission:', style: TextStyle(fontSize: 16)),
                  Text(
                    _locationStatus.name,
                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _getStatusColor(_locationStatus)),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: _requestLocationPermission,
                child: const Text('Request Location'),
              ),
               const SizedBox(height: 24),
               const Text(
                'Note: The INTERNET permission is typically included by default in Flutter apps and does not require a runtime prompt.',
                textAlign: TextAlign.center,
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return Colors.green;
      case PermissionStatus.denied:
        return Colors.orange;
      case PermissionStatus.permanentlyDenied:
      case PermissionStatus.restricted:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
