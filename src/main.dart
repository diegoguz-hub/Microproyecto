import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

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
  final List<Color> _colors = [
    Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.orange, Colors.purple,
    Colors.pink, Colors.teal, Colors.cyan, Colors.brown, Colors.indigo, Colors.lime,
    Colors.amber, Colors.deepOrange, Colors.lightBlue, Colors.lightGreen, Colors.grey, Colors.black,
  ];
  
  late List<Color> _shuffledColors;
  late List<bool> _cardFliped;
  int? _firstIndex;
  bool _wait = false;
  int _attempts = 0;
  
  // Variables de Requerimientos: Tiempo y Persistencia
  Timer? _timer;
  int _secondsElapsed = 0;
  int _bestScore = 0; 

  @override
  void initState() {
    super.initState();
    _loadBestScore();
    _setupGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Carga el récord guardado en el dispositivo
  Future<void> _loadBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bestScore = prefs.getInt('best_score') ?? 0;
    });
  }

  // Guarda el récord si los intentos actuales son menores al mejor puntaje
  Future<void> _saveBestScore() async {
    if (_bestScore == 0 || _attempts < _bestScore) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('best_score', _attempts);
      setState(() => _bestScore = _attempts);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsElapsed = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _secondsElapsed++);
    });
  }

  void _setupGame() {
    setState(() {
      _shuffledColors = [..._colors, ..._colors]..shuffle();
      _cardFliped = List.generate(36, (index) => false);
      _firstIndex = null;
      _wait = false;
      _attempts = 0;
      _startTimer();
    });
  }

  void _onCardTap(int index) {
    if (_wait || _cardFliped[index]) return;

    setState(() => _cardFliped[index] = true);

    if (_firstIndex == null) {
      _firstIndex = index;
    } else {
      _attempts++;
      if (_shuffledColors[_firstIndex!] == _shuffledColors[index]) {
        _firstIndex = null;
        _checkWin();
      } else {
        _wait = true;
        Timer(const Duration(milliseconds: 700), () {
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
    if (_cardFliped.every((flipped) => flipped)) {
      _timer?.cancel();
      _saveBestScore();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("¡Victoria Unimetana!"),
          content: Text("Intentos: $_attempts\nTiempo: $_secondsElapsed seg.\nMejor récord: $_bestScore"),
          actions: [
            TextButton(
              onPressed: () { Navigator.pop(context); _setupGame(); },
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
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Container(
            color: Colors.white.withOpacity(0.9),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  "Tiempo: $_secondsElapsed s", 
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)
                ),
                Text(
                  "Intentos: $_attempts", 
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)
                ),
                Text(
                  "Récord: ${_bestScore == 0 ? '-' : _bestScore}", 
                  style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 15)
                ),
              ],
            ),
          ),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(15),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        itemCount: 36,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _onCardTap(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: _cardFliped[index] ? _shuffledColors[index] : const Color(0xFFC36807),
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: _cardFliped[index] ? null : const Icon(Icons.help_outline, color: Colors.white),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _setupGame,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
