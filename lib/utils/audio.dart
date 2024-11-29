import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:mic_stream/mic_stream.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:projects/utils/globals.dart' as globals;
import 'package:permission_handler/permission_handler.dart';

class LiveAudioPage extends StatefulWidget {
  @override
  _LiveAudioPageState createState() => _LiveAudioPageState();
}

class _LiveAudioPageState extends State<LiveAudioPage>
    with SingleTickerProviderStateMixin {
  late WebSocketChannel _channel;
  late Stream<List<int>> _microphoneStream;
  AudioPlayer _audioPlayer = AudioPlayer();
  List<double> _waveform = [];
  bool _isRecording = false;
  late AnimationController _animationController;
  final List<int> _audioBuffer = [];

  @override
  void initState() {
    super.initState();
    _requestMicrophonePermission();
    _setupWebSocket();
    _startRecording();

    // Initialize animation controller for reactive effects
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  Future<void> _requestMicrophonePermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
      if (!status.isGranted) {
        throw Exception('Microphone permission is not granted');
      }
    }
  }

  void _setupWebSocket() {
    _channel = WebSocketChannel.connect(
      Uri.parse(globals.wsAudioURL),
    );

    _channel.stream.listen((data) async {
      if (data is Uint8List) {
        // Play backend audio response
        print(data);
        await _audioPlayer.play(BytesSource(data));
      } else if (data is String) {
        // Handle text-based backend responses
        var response = json.decode(data);
        if (response.containsKey('transcription')) {
          print('Transcription: ${response['transcription']}');
        }
      }
    }, onError: (error) {
      print('WebSocket error: $error');
    }, onDone: () {
      print('WebSocket connection closed');
    });
  }

  void _startRecording() async {
    if (_isRecording) return;
    setState(() => _isRecording = true);

    _microphoneStream = await MicStream.microphone(
      audioSource: AudioSource.DEFAULT,
      sampleRate: 16000, // Ensure this matches the backend expectation
      channelConfig: ChannelConfig.CHANNEL_IN_MONO,
      audioFormat: AudioFormat.ENCODING_PCM_16BIT,
    );

    _microphoneStream.listen((audioData) {
      // Update waveform visualization
      final amplitude = audioData.map((e) => e.toDouble()).toList();
      setState(() {
        _waveform = amplitude.take(100).toList();
      });

      // Buffer audio data
      _audioBuffer.addAll(audioData);

      // Send buffered audio data to backend if buffer is large enough
      if (_audioBuffer.length > 16000) {
        // Adjust buffer size as needed
        _channel.sink.add(Uint8List.fromList(_audioBuffer));
        _audioBuffer.clear();
      }
    }, onError: (error) {
      print('Microphone stream error: $error');
    });
  }

  void _stopRecording() {
    if (!_isRecording) return;
    setState(() => _isRecording = false);
    _channel.sink.close();
  }

  @override
  void dispose() {
    _stopRecording();
    _audioPlayer.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Live Audio Streaming'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Text(
            'Streaming Live Audio',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Center(
              child: CustomPaint(
                painter: CircularWaveformPainter(_waveform, Colors.white),
                child: const SizedBox(
                  height: 200,
                  width: double.infinity,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final List<double> waveform;
  final double animationValue;

  WaveformPainter(this.waveform, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.deepPurple, Colors.blueAccent],
        stops: [0.0, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final path = Path();
    for (int i = 0; i < waveform.length; i++) {
      final x = (i / waveform.length) * size.width;
      final y =
          size.height / 2 + waveform[i] * (size.height / 2) * animationValue;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CircularWaveformPainter extends CustomPainter {
  final List<double> waveform;
  final Color color;

  CircularWaveformPainter(this.waveform, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.3; // Adjust to scale the inner circle

    for (int i = 0; i < waveform.length; i++) {
      final angle = (i / waveform.length) * 2 * pi;
      final lineLength = radius + waveform[i] * (size.width * 0.15);
      final x = center.dx + lineLength * cos(angle);
      final y = center.dy + lineLength * sin(angle);

      canvas.drawCircle(
          Offset(x, y), 2.0, paint); // Use circles for radial points
    }

    // Draw inner circle for aesthetics
    final innerPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, radius, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CircularWaveformPage extends StatefulWidget {
  @override
  _CircularWaveformPageState createState() => _CircularWaveformPageState();
}

class _CircularWaveformPageState extends State<CircularWaveformPage> {
  List<double> _waveform =
      List.generate(100, (index) => 0); // Placeholder waveform

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CustomPaint(
          painter: CircularWaveformPainter(_waveform, Colors.white),
          child: const SizedBox(
            height: 300,
            width: 300,
          ),
        ),
      ),
    );
  }
}
