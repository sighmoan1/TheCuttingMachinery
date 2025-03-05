// We need to use some tools, so we get them from other places.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

// We're making a special box that can play sounds called MeditationPlayer.
class MeditationPlayer extends StatefulWidget {
  // This box needs to know where the sound is, so we'll store its address.
  final String audioUrl;
  // We'll set up the box with the sound's address.
  const MeditationPlayer({Key? key, required this.audioUrl}) : super(key: key);
  // We need a helper to manage the box, so we create one.
  @override
  _MeditationPlayerState createState() => _MeditationPlayerState();
}

// The helper will handle the box and remember things for us.
class _MeditationPlayerState extends State<MeditationPlayer> {
  // The helper needs a tool to play the sound.
  late AudioPlayer _audioPlayer;
  // It will also remember if the sound is playing or not, if it's loading,
  // where the sound is at, how long the sound is, and how fast it plays.
  bool _isPlaying = false;
  bool _loading = true;
  int _position = 0;
  int _duration = 0;
  double _speed = 1.0;
  // We need a way to tell the helper when to move the sound back or forward.
  final _seekSubject = BehaviorSubject<int>();
  // The helper can change the numbers into a format that's easy to read.
  String _formatDuration(Duration duration) {
    return "${duration.inMinutes.toString().padLeft(2, '0')}:"
        "${(duration.inSeconds % 60).toString().padLeft(2, '0')}";
  }

  // When the helper starts, it will set up the sound-playing tool.
  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initAudio();
    _initSeeking();
  }

  // The helper will get the sound ready to play and listen for changes.
  Future<void> _initializeAudioPlayer(String audioUrl) async {
    await _audioPlayer.setAsset(audioUrl);
    _audioPlayer.positionStream.listen((position) {
      setState(() {
        _position = position.inMilliseconds;
      });
    });
    // When the sound's length is known, the helper will remember it.
    _audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        setState(() {
          _duration = duration.inMilliseconds;
          _loading = false;
        });
      }
    });
    // The sound will start playing automatically.
    _audioPlayer.play();
    // The helper will remember if the sound is playing or not.
    _audioPlayer.playingStream.listen((playing) {
      setState(() {
        _isPlaying = playing;
      });
    });
  }

  // The helper will set up the sound to play.
  Future<void> _initAudio() async {
    await _initializeAudioPlayer(widget.audioUrl);
  }

  // The helper will set up the back and forward buttons.
  void _initSeeking() {
    _seekSubject.stream
        .debounceTime(Duration(milliseconds: 500))
        .listen((position) async {
      await _audioPlayer.seek(Duration(milliseconds: position));
    });
  }

  // If the sound's address changes, the helper will load the new sound.
  @override
  void didUpdateWidget(MeditationPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioUrl != widget.audioUrl) {
      // If there was a sound playing, stop it.
      _audioPlayer.stop();
      _loading = true;
      // Load and set up the new sound.
      _initializeAudioPlayer(widget.audioUrl);
    }
  }

  // When the helper is no longer needed, it will clean up its tools.
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // When the helper is no longer needed, it will clean up its tools.
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // If the sound is still loading, show a spinning circle.
        if (_loading)
          CircularProgressIndicator()
        else
          // Otherwise, show a play or pause button to control the sound.
          IconButton(
            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white),
            iconSize: 32.0,
            onPressed: () {
              if (_isPlaying) {
                _audioPlayer.pause();
              } else {
                _audioPlayer.play();
              }
            },
          ),
        // Show buttons to change the speed of the sound.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            "1x",
            "1.5x",
            "2x",
            "3x",
          ].map((text) {
            return InkWell(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(text, style: TextStyle(color: Colors.white)),
              ),
              onTap: () {
                setState(() {
                  // Change the speed based on the button tapped.
                  _speed = double.parse(text.substring(0, text.length - 1));
                  _audioPlayer.setSpeed(_speed);
                });
              },
            );
          }).toList(),
        ),
        // Show the current position and total length of the sound.
        Text(
          "${_formatDuration(Duration(milliseconds: _position))} / "
          "${_formatDuration(Duration(milliseconds: _duration))}",
          style: TextStyle(color: Colors.white),
        ),
        // Show a slider to control the position of the sound.
        Slider(
          value: _position.toDouble(),
          min: 0,
          max: _duration.toDouble(),
          onChanged: (double value) {
            setState(() {
              _position = value.toInt();
            });
            _seekSubject.add(_position);
          },
          activeColor: Colors.white,
          inactiveColor: Colors.grey,
        ),
      ],
    );
  }
}
