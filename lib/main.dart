import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart'; // Para el tiempo y la persistencia
import 'package:animate_do/animate_do.dart'; // Para las animaciones

void main() => runApp(const MemoryGameApp());


// Widget principal del juego
// Configura la paleta de colores y el color del fondo
class MemoryGameApp extends StatelessWidget {
  const MemoryGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Metro memory',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color.fromARGB(255, 178, 211, 233), 
      ),
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

  // Lista de las rutas de las imagenes para las cartas
  
  final List<String> _imagePaths = [
    'assets/IMGUNIMET.png', 'assets/IMGSAMAN.png', 'assets/IMGGRANIER.png', 'assets/IMGANIMAL.png',
    'assets/IMGCAPELLANIA.png', 'assets/IMGCIRCULO.PNG', 'assets/IMGCONO.png', 'assets/IMGEUGENIO.png',
    'assets/IMGFARMAGO.png', 'assets/IMGFCE.png', 'assets/IMGFORMULASAE.png', 'assets/IMGKIOSCO.png',
    'assets/IMGVITRAF.png', 'assets/IMGMOODLE.png', 'assets/IMGPITCH.png', 'assets/IMGVERDI.png',
    'assets/IMGVENDU.png', 'assets/IMGWAWA.png',
  ];

  late List<String> _shuffledImages; // Imagenes mezcladas
  late List<bool> _cardFliped; // Carta volteada o no
  int? _firstIndex; //Indice de la primera carta seleccionada
  bool _wait = false; // Bloquea clics adicionales mientras se procesa un error
  int _attempts = 0; // Numero de intentos

  Timer? _timer; // Cronometro
  int _secondsElapsed = 0; // Segundos transcurridos
  int _bestScore = 0; // Menor cantidad de intentos

  @override
  void initState() {
    super.initState();
    _loadBestScore(); // Carga el record desde la memoria local al iniciar
    _setupGame(); // Inicializar
  }

  @override
  void dispose() {
    _timer?.cancel(); // Detiene el cronometro
    super.dispose();
  }


  // Carga el record guardado en el dispositivo
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


  // Inicia el cronometro desde 0
  void _startTimer() {
    _timer?.cancel();
    _secondsElapsed = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _secondsElapsed++);
    });
  }

  // Mezcla las cartas y reinicia todo
  void _setupGame() {
    setState(() {
      _shuffledImages = [..._imagePaths, ..._imagePaths]..shuffle();
      _cardFliped = List.generate(36, (index) => false);
      _firstIndex = null;
      _wait = false;
      _attempts = 0;
      _startTimer();
    });
  }

  // Gestiona el estado y la validacion de las cartas volteadas.
  void _onCardTap(int index) {
    if (_wait || _cardFliped[index]) return;
    setState(() => _cardFliped[index] = true); // Voltear carta

    if (_firstIndex == null) {
      _firstIndex = index; // Guardar la primera carta
    } else {
      _attempts++; // Sumar un intento
      if (_shuffledImages[_firstIndex!] == _shuffledImages[index]) {
        _firstIndex = null; // Si son iguales se mantienen volteadas
        _checkWin();
      } else {
        _wait = true; // Si son distintas esperan y se voltean de nuevo
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

  // Verifica si todas las cartas estan volteadas para declarar Victoria
  void _checkWin() {
    if (_cardFliped.every((flipped) => flipped)) {
      _timer?.cancel();
      _saveBestScore();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => ZoomIn( 
          child: AlertDialog(
            title: const Text("¡Victoria Unimetana!"),
            content: Text("Intentos: $_attempts\nTiempo: $_secondsElapsed seg.\nMejor récord: $_bestScore"),
            actions: [
              TextButton(
                onPressed: () { Navigator.pop(context); _setupGame(); },
                child: const Text("Jugar de nuevo"),
              )
            ],
          ),
        ),
      );
    }
  }

  // Diseño
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FadeInDown(child: const Text("MetroMemory")), 
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Container(
            color: Colors.white.withOpacity(0.9),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text("Tiempo: $_secondsElapsed s", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
                Text("Intentos: $_attempts", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
                Text("Récord: ${_bestScore == 0 ? '-' : _bestScore}", style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              // Adaptacion fluida de la interfaz (Bonus)
              LayoutBuilder(builder: (context, constraints) {
                // Calcula el ancho del tablero para que sea comodo en cualquier pantalla
                double boardWidth = constraints.maxWidth > 600 ? 550 : constraints.maxWidth * 0.95;
                return ZoomIn( 
                  duration: const Duration(milliseconds: 800),
                  child: SizedBox(
                    width: boardWidth,
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(15),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: 36,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => _onCardTap(index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                color: _cardFliped[index] ? Colors.white : const Color(0xFFC36807), 
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
                              ),
                              child: _cardFliped[index]
                                  ? FadeIn(
                                      duration: const Duration(milliseconds: 400),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.asset(_shuffledImages[index], fit: BoxFit.contain),
                                      ),
                                    )
                                  : const Icon(Icons.help_outline, color: Colors.white, size: 20),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _setupGame,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
