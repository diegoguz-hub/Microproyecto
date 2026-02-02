import 'package:flutter/material.dart';
import 'dart:async';

void main() => runApp(const MemoryGameApp());

class MemoryGameApp extends StatelessWidget {
  const MemoryGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Memory Unimet',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const MemoryBoard(),
    );
  }
}

class MemoryBoard extends StatefulWidget {
  const MemoryBoard({super.key});

  @override
  State<MemoryBoard> createState() => _MemoryBoardState();
}

class _MemoryBoardState extends State<MemoryBoard> {
  // 18 pares de colores para un tablero de 36 cartas (6x6)
  final List<Color> _colors = [
    Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.orange, Colors.purple,
    Colors.pink, Colors.teal, Colors.cyan, Colors.brown, Colors.indigo, Colors.lime,
    Colors.amber, Colors.deepOrange, Colors.lightBlue, Colors.lightGreen, Colors.grey, Colors.black,
  ];
  
  late List<Color> _shuffledColors;
  late List<bool> _cardFliped;
  int? _firstIndex;
  bool _wait = false;
  int _attempts = 0; // Contador de intentos

  @override
  void initState() {
    super.initState();
    _setupGame();
  }

  void _setupGame() {
    setState(() {
      _shuffledColors = [..._colors, ..._colors]..shuffle();
      _cardFliped = List.generate(36, (index) => false);
      _firstIndex = null;
      _wait = false;
      _attempts = 0;
    });
  }

  void _onCardTap(int index) {
    if (_wait || _cardFliped[index]) return;

    setState(() {
      _cardFliped[index] = true;
    });

    if (_firstIndex == null) {
      _firstIndex = index;
    } else {
      _attempts++; // Incrementamos el intento cuando se voltea la segunda carta
      
      if (_shuffledColors[_firstIndex!] == _shuffledColors[index]) {
        _firstIndex = null;
        _checkWin();
      } else {
        _wait = true;
        Timer(const Duration(milliseconds: 800), () {
          setState(() {
            _cardFliped[_firstIndex!] = false;
            _cardFliped[index] = false;
            _firstIndex = null;
            _wait = false;
          });
        });
      }
    }
  }

  void _checkWin() {
    if (_cardFliped.every((bool flipped) => flipped)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("¡Ganaste!"),
          content: Text("Completaste el tablero en $_attempts intentos."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _setupGame();
              },
              child: const Text("Jugar de nuevo"),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("MetroMemory"),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text("Intentos: $_attempts", style: const TextStyle(fontSize: 18)),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6, // 6 columnas
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: 36, // 36 cartas en total
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _onCardTap(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _cardFliped[index] 
                          ? _shuffledColors[index] 
                          : const Color.fromARGB(255, 195, 104, 7), // Color de la carta boca abajo
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Center(
                      child: _cardFliped[index] 
                          ? null 
                          : const Icon(Icons.help_outline, color: Colors.white, size: 20),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _setupGame,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}