import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart'; // For date formatting

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sara MVP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

// Data class for a transcript item
class TranscriptItem {
  final String who;
  final String text;
  TranscriptItem(this.who, this.text);
}

// Mock NLU Service
class NluService {
  String parse(String text) {
    text = text.toLowerCase();
    if (text.contains("time")) {
      return "get_time";
    } else if (text.contains("weather")) {
      return "get_weather";
    }
    return "unknown";
  }
}

// Mock Action Service
class ActionService {
  final FlutterTts ttsEngine;
  ActionService(this.ttsEngine);

  Future<String> execute(String intent) async {
    String response;
    switch (intent) {
      case "get_time":
        final now = DateTime.now();
        response = "The current time is ${DateFormat.jm().format(now)}.";
        break;
      case "get_weather":
        response = "It's sunny today in Mountain View.";
        // In a real app, you would call a weather API here.
        break;
      default:
        response = "I'm sorry, I don't understand that.";
    }
    await ttsEngine.speak(response);
    return response;
  }
}


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final NluService _nluService = NluService();
  late final ActionService _actionService;

  bool _isListening = false;
  final List<TranscriptItem> _transcripts = [];

  @override
  void initState() {
    super.initState();
    _actionService = ActionService(_flutterTts);
    _initSpeech();
  }

  /// This has to happen only once per app
  void _initSpeech() async {
    await _speechToText.initialize();
    await Permission.microphone.request();
    setState(() {});
  }

  void _toggleListening() {
    if (_isListening) {
      _speechToText.stop();
      setState(() {
        _isListening = false;
      });
    } else {
      _speechToText.listen(onResult: _onSpeechResult);
      setState(() {
        _isListening = true;
        _transcripts.insert(0, TranscriptItem("Sara", "Listening..."));
      });
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    // The listen callback is invoked on every speech event,
    // including for interim results. We only want to process the final result.
    if (result.finalResult) {
      setState(() {
        // remove "Listening..." message
        if (_transcripts.isNotEmpty && _transcripts.first.text == "Listening...") {
          _transcripts.removeAt(0);
        }
      });
      _processUserUtterance(result.recognizedWords);
    }
  }

  Future<void> _processUserUtterance(String text) async {
    if (text.isEmpty) return;

    setState(() {
      _transcripts.insert(0, TranscriptItem("You", text));
    });

    final intent = _nluService.parse(text);
    final response = await _actionService.execute(intent);

    setState(() {
      _transcripts.insert(0, TranscriptItem("Sara", response));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Sara — MVP"),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              reverse: true, // To show latest messages at the bottom
              padding: const EdgeInsets.all(8.0),
              itemCount: _transcripts.length,
              itemBuilder: (context, index) {
                final item = _transcripts[index];
                return TranscriptCard(item: item);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _processUserUtterance("what time is it"),
                  child: const Text("Time"),
                ),
                ElevatedButton(
                  onPressed: () => _processUserUtterance("what's the weather"),
                  child: const Text("Weather"),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleListening,
        tooltip: 'Listen',
        child: Icon(_isListening ? Icons.mic_off : Icons.mic),
      ),
    );
  }

  @override
  void dispose() {
    _speechToText.stop();
    _flutterTts.stop();
    super.dispose();
  }
}

class TranscriptCard extends StatelessWidget {
  const TranscriptCard({
    super.key,
    required this.item,
  });

  final TranscriptItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${item.who}: ",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(item.text, style: Theme.of(context).textTheme.bodyLarge)),
          ],
        ),
      ),
    );
  }
}
