import 'package:flutter/material.dart';
import 'dart:async'; // Import for Timer
import 'package:flutter/services.dart'; // Import for window size
import 'package:audioplayers/audioplayers.dart'; // Import the audioplayers package
import 'package:shared_preferences/shared_preferences.dart'; // Import for local storage

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
  List<TimerData> _savedTimers = []; // List to store saved timer durations
  String _timerName = ''; // Variable to store the timer name
  String _currentTimerName = ''; // Variable to store the currently loaded timer name

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

  void _saveTimer(String name, int duration) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _savedTimers.add(TimerData(name, duration)); // Store TimerData object
    await prefs.setStringList('savedTimers', _savedTimers.map((e) => e.toString()).toList());
  }

  void _loadSavedTimers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? timers = prefs.getStringList('savedTimers');
    if (timers != null) {
      _savedTimers = timers.map((e) => TimerData.fromString(e)).toList(); // Load TimerData objects
    }
  }

  void _showAddTimerDialog() {
    String durationInput = ''; // Variable to store the duration input

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Timer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Timer Name'),
                onChanged: (value) {
                  setState(() {
                    _timerName = value; // Update timer name
                  });
                },
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Duration (in minutes)'), // Change label to minutes
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  durationInput = value; // Capture the duration input
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Save the timer with the name and duration
                if (_timerName.isNotEmpty && durationInput.isNotEmpty) {
                  int durationInMinutes = int.parse(durationInput); // Parse the duration input
                  int durationInSeconds = durationInMinutes * 60; // Convert minutes to seconds
                  _saveTimer(_timerName, durationInSeconds); // Save the timer with name
                  Navigator.of(context).pop(); // Close the dialog
                }
              },
              child: Text('Save'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showSavedTimers() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Saved Timers'),
          content: SingleChildScrollView(
            child: ListBody(
              children: _savedTimers.map((timerData) {
                int durationInMinutes = timerData.duration ~/ 60; // Convert seconds to minutes for display
                return ListTile(
                  title: Text('${timerData.name}: $durationInMinutes minutes'), // Display name and duration
                  onTap: () {
                    // Start the timer with the selected duration
                    setState(() {
                      _remainingTime = timerData.duration; // Set remaining time to selected duration
                      _initialTime = timerData.duration; // Update initial time
                      _currentTimerName = timerData.name; // Set the current timer name
                      _isRunning = false; // Ensure timer is not running
                      _isFinished = false; // Reset finished state
                    });
                    Navigator.of(context).pop(); // Close the dialog
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _showAddTimerDialog(); // Show dialog to add a new timer
              },
              child: Text('Add Timer'), // Button to add a new timer
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadSavedTimers(); // Load saved timers when the widget is initialized
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
                        // Display the current timer name if available
                        if (_currentTimerName.isNotEmpty) 
                          Text(
                            _currentTimerName,
                            style: TextStyle(color: Colors.black, fontSize: 24), // Style for the timer name
                          ),
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
          ],
        ),
      ),
      floatingActionButton: Row( // Add a row for the buttons
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: _showSavedTimers, // Show saved timers
            child: Icon(Icons.library_books, color: Colors.blue), // Icon for library
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white, // Set background to white
              shape: CircleBorder(), // Optional: make the button circular
            ),
          ),
          SizedBox(width: 10), // Add some space between buttons
          ElevatedButton(
            onPressed: _resetTimer,
            child: Icon(Icons.refresh, color: Colors.red), // Set icon color to red
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white, // Set background to white
              shape: CircleBorder(), // Optional: make the button circular
            ),
          ),
        ],
      ),
    );
  }
}

class TimerData {
  String name;
  int duration; // Duration in seconds

  TimerData(this.name, this.duration);

  // Convert TimerData to a string for storage
  String toString() {
    return '$name:$duration'; // Format: name:duration
  }

  // Create TimerData from a string
  static TimerData fromString(String str) {
    final parts = str.split(':');
    return TimerData(parts[0], int.parse(parts[1]));
  }
}
