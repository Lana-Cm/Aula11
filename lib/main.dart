import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  runApp(const SensorApp());
}

class SensorApp extends StatelessWidget {
  const SensorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aula 11 - Sensores',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const SensorHomePage(),
    );
  }
}

class SensorHomePage extends StatefulWidget {
  const SensorHomePage({super.key});

  @override
  State<SensorHomePage> createState() => _SensorHomePageState();
}

class _SensorHomePageState extends State<SensorHomePage>
    with WidgetsBindingObserver {
  StreamSubscription<AccelerometerEvent>? _subscription;

  double _x = 0;
  double _y = 0;
  double _z = 0;
  bool _isListening = false;
  String _status = 'Aguardando leitura do acelerômetro...';

  @override
  void initState() {
    super.initState();
    // Registra o observador para escutar o ciclo de vida (segundo plano / primeiro plano)
    WidgetsBinding.instance.addObserver(this);
    _startSensor();
  }

  void _startSensor() {
    if (_isListening) return;

    _subscription =
        accelerometerEventStream(
          samplingPeriod: SensorInterval.normalInterval,
        ).listen(
          (event) {
            if (!mounted) return;

            setState(() {
              _x = event.x;
              _y = event.y;
              _z = event.z;
              _status = _buildStatusMessage(event.x, event.y);
            });
          },
          onError: (error) {
            if (!mounted) return;
            setState(() {
              _status = 'Não foi possível ler o acelerômetro: $error';
            });
          },
        );

    setState(() {
      _isListening = true;
      _status = 'Lendo o acelerômetro...';
    });
  }

  Future<void> _stopSensor() async {
    await _subscription?.cancel();
    _subscription = null;

    if (!mounted) return;

    setState(() {
      _isListening = false;
      _status = 'Leitura pausada.';
    });
  }

  String _buildStatusMessage(double x, double y) {
    final horizontalTilt = x.abs();
    final verticalTilt = y.abs();

    // Tolerância pequena para considerar nivelado
    if (horizontalTilt < 1.2 && verticalTilt < 1.2) {
      return 'Quase nivelado. Tente manter a bolha no centro.';
    }

    if (horizontalTilt > verticalTilt) {
      return x > 0 ? 'Inclinado para a esquerda.' : 'Inclinado para a direita.';
    }

    return y > 0 ? 'Inclinado para baixo.' : 'Inclinado para cima.';
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Controla o comportamento ao sair/voltar para o app
    if (state == AppLifecycleState.resumed) {
      _startSensor();
    } else {
      _stopSensor();
    }
  }

  @override
  void dispose() {
    // Remove o observer e cancela a assinatura para evitar vazamento de memória (Memory Leak)
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Lógica para calcular o movimento da bolha dentro de um espaço de 200x200
    // A gravidade na terra é ~9.8. Dividimos por ela para normalizar entre -1 e 1.
    final double normalizedX = (_x / 9.8).clamp(-1.0, 1.0);
    final double normalizedY = (_y / 9.8).clamp(-1.0, 1.0);

    // Mapeia o valor normalizado para o tamanho do container (raio e margens internas consideradas)
    // Inverte-se o X porque ao inclinar para a esquerda, a bolha deve ir para a esquerda de quem olha.
    final double bubbleX = 100 + (-normalizedX * 80);
    final double bubbleY = 100 + (normalizedY * 80);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aula 11 - Nível Digital'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Painel de Valores dos Sensores
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Valores do Acelerômetro',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Divider(),
                    Text('Eixo X (Esquerda/Direita): ${_x.toStringAsFixed(2)}'),
                    Text('Eixo Y (Frente/Trás): ${_y.toStringAsFixed(2)}'),
                    Text('Eixo Z (Cima/Baixo): ${_z.toStringAsFixed(2)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Interface Visual do Nível (O Quadrado com a bolha)
            Center(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  border: Border.all(color: Colors.teal, width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    // Círculo central guia (Substitua o seu por este completo)
                    Center(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.teal.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    // A Bolha em movimento
                    Positioned(
                      left:
                          bubbleX -
                          20, // Desconto da metade do tamanho da bolha (40/2)
                      top: bubbleY - 20,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Texto de Status/Orientação
            Text(
              _status,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _status.contains('Quase nivelado')
                    ? Colors.green
                    : Colors.black87,
              ),
            ),
            const SizedBox(height: 24),

            // Botão para simular pausa manual se necessário
            ElevatedButton.icon(
              onPressed: _isListening ? _stopSensor : _startSensor,
              icon: Icon(_isListening ? Icons.pause : Icons.play_arrow),
              label: Text(_isListening ? 'Pausar Sensor' : 'Retomar Sensor'),
            ),
          ],
        ),
      ),
    );
  }
}
