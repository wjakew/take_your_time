import 'package:flutter/material.dart';
import 'dart:async'; // Import for Timer
import 'package:flutter/services.dart'; // Import for window size
import 'package:audioplayers/audioplayers.dart'; // Import the audioplayers package

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Set the window size to be square (e.g., 600x600)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  setWindowSize(600, 600);
  runApp(MyApp());
}

void setWindowSize(double width, double height) {
  // This function sets the window size for desktop applications to 600x600 pixels.
  // This implementation is specific for desktop platforms.
  // For Linux, you might need to use a specific library or method to set the window size.
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontFamily: 'Courier New'), // Set monospace font
          bodyMedium: TextStyle(fontFamily: 'Courier New'), // Set monospace font
          bodySmall: TextStyle(fontFamily: 'Courier New'), // Set monospace font
        ),
      ),
      home: PomodoroTimer(),
    );
  }
}

class PomodoroTimer extends StatefulWidget {
  @override
  _PomodoroTimerState createState() => _PomodoroTimerState();
}

class _PomodoroTimerState extends State<PomodoroTimer> {
  int _remainingTime = 1500; // Remaining time in seconds (25 minutes)
  int _initialTime = 1500; // Store the initial timer value
  bool _isRunning = false;
  bool _isFinished = false; // Track if the timer has finished
  Timer? _timer; // Timer variable
  final AudioPlayer _audioPlayer = AudioPlayer(); // Create an AudioPlayer instance

  // Gradient colors
  final List<Color> _gradientColors = [
    Color(0xFFeeaeca),
    Color(0xFF94bbe9),
  ];

  // Animation variables
  double _animationValue = 0.0;
  bool _isAnimatingForward = true; // Direction of the animation

  void _startPauseTimer() {
    setState(() {
      _isRunning = !_isRunning;
      if (_isRunning) {
        _initialTime = _remainingTime; // Save the current value when starting
        _startGradientAnimation(); // Start the gradient animation
      } else {
        _stopGradientAnimation(); // Stop the gradient animation
      }
    });

    if (_isRunning) {
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (_remainingTime > 0) {
          setState(() {
            _remainingTime--;
          });
        } else {
          _timer?.cancel(); // Cancel the timer
          _playFinishSound(); // Play sound when timer finishes
        }
      });
    } else {
      _timer?.cancel(); // Pause the timer
    }
  }

  void _resetTimer() {
    setState(() {
      _remainingTime = _initialTime; // Reset remaining time to the saved initial value
      _isRunning = false;
      _isFinished = false; // Reset finished state
      _stopGradientAnimation(); // Stop the animation
    });
    _timer?.cancel(); // Cancel the timer
  }

  void _addMinute() {
    setState(() {
      _initialTime += 60; // Update the initial time by adding 1 minute
      _remainingTime = _initialTime; // Set remaining time to the new initial time
      _remainingTime = (_remainingTime ~/ 60) * 60; // Set seconds to 00
    });
  }

  void _subtractMinute() {
    setState(() {
      if (_remainingTime > 60) {
        _remainingTime -= 60; // Subtract 1 minute (60 seconds)
        _initialTime -= 60; // Update the initial time as well
      } // Prevent going below 1 minute
    });
  }

  void _startGradientAnimation() {
    // Start a periodic timer to update the animation value
    Timer.periodic(Duration(milliseconds: 100), (timer) {
      if (_isRunning) {
        setState(() {
          if (_isAnimatingForward) {
            _animationValue += 0.01; // Increment the animation value
            if (_animationValue >= 1.0) {
              _isAnimatingForward = false; // Change direction
            }
          } else {
            _animationValue -= 0.01; // Decrement the animation value
            if (_animationValue <= 0.0) {
              _isAnimatingForward = true; // Change direction
            }
          }
        });
      } else {
        timer.cancel(); // Stop the timer if not running
      }
    });
  }

  void _stopGradientAnimation() {
    // Reset the animation value when stopping
    setState(() {
      _animationValue = 0.0;
      _isAnimatingForward = true; // Reset direction
    });
  }

  void _playFinishSound() async {
    await _audioPlayer.play(AssetSource('mixkit-software-interface-start-2574.mp3')); // Play the finish sound
    setState(() {
      _isFinished = true; // Set finished state to true
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [_animationValue, _animationValue + 0.5], // Create a moving effect
          ),
        ),
        child: Stack( // Use Stack to position the reset button
          children: [
            Center(
              child: _isFinished
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "You took your time",
                          style: TextStyle(color: Colors.green, fontSize: 36),
                        ),
                        SizedBox(height: 20),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove, color: Colors.black),
                              onPressed: _subtractMinute,
                            ),
                            Text(
                              '${(_remainingTime ~/ 60).toString().padLeft(2, '0')}:${(_remainingTime % 60).toString().padLeft(2, '0')}',
                              style: TextStyle(color: Colors.black, fontSize: 96),
                            ),
                            IconButton(
                              icon: Icon(Icons.add, color: Colors.black),
                              onPressed: _addMinute,
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: _startPauseTimer,
                              child: Icon(_isRunning ? Icons.pause : Icons.play_arrow, color: Colors.white), // Use play/pause icons
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green, // Set button color to green
                                shape: CircleBorder(), // Make the button circular
                                padding: EdgeInsets.all(40), // Set size to be twice as big
                              ),
                            ),
                            SizedBox(width: 10), // Add some space between buttons
                          ],
                        ),
                      ],
                    ),
            ),
            Positioned( // Position the reset button in the top right corner
              top: 20,
              right: 20,
              child: ElevatedButton(
                onPressed: _resetTimer,
                child: Icon(Icons.refresh, color: Colors.red), // Set icon color to red
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, // Set background to white
                  shape: CircleBorder(), // Optional: make the button circular
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
