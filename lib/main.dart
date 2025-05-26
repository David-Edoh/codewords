import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:collection/collection.dart'; // For ListEquality

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Word Code Game',
      theme: ThemeData(
        // This is the theme of your application.
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  List<dynamic> _challenges = [];
  late Map<String, dynamic> _currentChallenge;
  List<String> _wordBank = [];
  List<String?> _solutionArea = [];
  List<String> _originalWordBank = [];
  bool _hasInitializedChallenge = false;
  List<String> _solutionSlotWords = [];

  Color _solutionAreaBorderColor = Colors.yellow[100]!;

  Future<List<dynamic>> _loadChallenges() async {
    final String response = await rootBundle.loadString('challenges.json');
    final data = await json.decode(response);
    return data;
  }

  // When a word is dropped into a specific slot (e.g., index 0)
  void _handleWordDrop(String word, int slotIndex) {
    setState(() {
      _solutionSlotWords[slotIndex] = word;
    });
  }

  // In your build method, to display the code snippet
  Widget _buildCodeSnippet() {
    String originalSnippet = _currentChallenge['code_snippet'];
    List<String> parts = originalSnippet.split(
      _currentChallenge['place_holder'],
    ); // Split by your placeholder

    List<InlineSpan> spans = [];
    for (int i = 0; i < parts.length; i++) {
      spans.add(
        TextSpan(
          text: parts[i],
          style: TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
      if (i < _solutionSlotWords.length) {
        spans.add(
          TextSpan(
            text:
                _solutionSlotWords[i].isEmpty
                    ? _currentChallenge['place_holder']
                    : _solutionSlotWords[i],
            style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ), // Optional styling
          ),
        );
      }
    }

    return RichText(
      text: TextSpan(
        children: spans,
        style: DefaultTextStyle.of(context).style, // Inherit default style
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Word Code Game'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: FutureBuilder(
        future: _loadChallenges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error loading challenges: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No challenges found.'));
          } else {
            _challenges = snapshot.data!;
            if (!_hasInitializedChallenge) {
              print("Initializing challenge...");
              _selectRandomChallenge();
              _hasInitializedChallenge = true;
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Challenge Description:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(_currentChallenge['description']),
                  const SizedBox(height: 20),
                  const Text(
                    'Code Snippet:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.grey[200],
                    width: double.infinity,
                    child: _buildCodeSnippet(),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Word Bank:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  // Placeholder for word bank
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children:
                        _wordBank.map((word) {
                          return Draggable<String>(
                            data: word,
                            feedback: Material(
                              elevation: 4.0,
                              child: Chip(
                                label: Text(word),
                                backgroundColor: Colors.blueAccent,
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.5,
                              child: Chip(
                                label: Text(word),
                                backgroundColor: Colors.grey,
                              ),
                            ),

                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                              child: Chip(label: Text(word)),
                            ),
                          );
                        }).toList(),
                  ),
                  // Add a clear solution button
                  ElevatedButton(
                    onPressed: _clearSolution,
                    child: const Text('Clear Solution'),
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    'Solution Area:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DragTarget<String>(
                    builder: (context, candidateData, rejectedData) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        child: buildSolutionAreaContent(),
                      );
                    },
                    onAcceptWithDetails: (data) {
                      print(data.data);
                      _addWordToSolution(data.data);
                    },
                    onWillAcceptWithDetails: (data) => true,
                  ),

                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        _checkSolution();
                      },
                      child: const Text('Check Solution'),
                    ),
                  ),
                ],
              ), // Removed redundant closing parenthesis
            );
          }
        },
      ),
    );
  }

  // Selects a random challenge from the loaded challenges
  void _selectRandomChallenge() {
    final random = Random();
    _currentChallenge = _challenges[random.nextInt(_challenges.length)];
    _wordBank = List<String>.from(_currentChallenge['words']);
    _originalWordBank = List<String>.from(_wordBank);
    _solutionArea = List<String?>.filled(
      _currentChallenge['solution'].length,
      null,
    );
    _solutionSlotWords = List<String>.filled(
      _currentChallenge['solution'].length,
      "___",
    );
    _solutionAreaBorderColor = Colors.yellow[100]!; // Reset border color
  }

  // Builds the visual representation of the solution area
  Widget buildSolutionAreaContent() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: _solutionAreaBorderColor, width: 2.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      width: double.infinity,
      height: 100,
      child: Row(
        children:
            _solutionArea.asMap().entries.map((entry) {
              final index = entry.key;
              final word = entry.value;
              return Expanded(
                child: DragTarget<String>(
                  builder: (context, candidateData, rejectedData) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color:
                          word == null
                              ? Colors.grey[300]
                              : Colors.lightGreen[200],
                      child: Padding(
                        // margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.all(8.0),
                        child: Center(child: Text(word ?? 'Drag here')),
                      ),
                    ); // Changed color for filled slots
                  },
                  onAcceptWithDetails: (data) {
                    print("Accepting word: ${data.data}");
                    _addWordToSolutionAtIndex(data.data, index);
                  },
                ),
              );
            }).toList(),
      ),
    );
  }

  // Added a function to build the outer container with animation
  Widget buildSolutionArea() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500), // Animation duration
      child: buildSolutionAreaContent(),
    );
  }

  // Adds a word to the solution area at the first available null spot
  void _addWordToSolution(String word) {
    print("Adding word to solution: $word");
    setState(() {
      final index = _solutionArea.indexOf(null);
      if (index != -1) {
        _solutionArea[index] = word;
        _wordBank.remove(word);
      }
    });
  }

  // Adds a word to the solution area at a specific index (for drag and drop onto specific slots)
  void _addWordToSolutionAtIndex(String word, int index) {
    print("Adding word to solution at index $index: $word");
    _handleWordDrop(word, index);
    setState(() {
      if (_solutionArea[index] != null) {
        // If there's already a word, return it to the word bank
        _wordBank.add(_solutionArea[index]!);
      }
      _solutionArea[index] = word;
      _wordBank.remove(word);
    });
  }

  // Clears all words from the solution area and returns them to the word bank
  void _clearSolution() {
    setState(() {
      _wordBank = List<String>.from(_originalWordBank); // Reset word bank
      _solutionArea = List<String?>.filled(
        _currentChallenge['solution'].length,
        null,
      ); // Clear solution area
      _solutionAreaBorderColor = Colors.blue[100]!; // Reset border color
    });
  }

  // Checks if the user's solution is correct
  void _checkSolution() {
    final userSolution = _solutionArea.whereType<String>().toList();
    final isCorrect = const ListEquality().equals(
      userSolution,
      _currentChallenge['solution'],
    );
    setState(() {
      _solutionAreaBorderColor =
          isCorrect ? Colors.green[300]! : Colors.red[300]!;
    });

    if (isCorrect) {
      _selectRandomChallenge(); // Load a new challenge on success
    }
  }
}
