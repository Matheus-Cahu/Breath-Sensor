import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const SensobreathApp());
}

class SensobreathApp extends StatelessWidget {
  const SensobreathApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zéfiro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.grey,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class Sensor {
  String name;
  List<FlSpot> dataPoints = [];
  double xValue = 0;
  bool alerta = false;
  Timer? timer;
  bool isDummy;
  String? url;

  Sensor({required this.name, this.isDummy = true, this.url});
}

class FloatingAlert extends StatelessWidget {
  final String message;

  const FloatingAlert({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        margin: const EdgeInsets.only(top: 60, left: 16, right: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Sensor> sensors = [];

  // 🔥 Coloque o IP do servidor Flask aqui:
  final String espUrl = 'http://192.168.236.161:5000/aviso';

  @override
  void initState() {
    super.initState();

    // Sensor real (ESP ou Flask)
    addSensor('Sensor 1', isDummy: false, url: espUrl);

    // Sensores simulados
    addSensor('Sensor 2');
    addSensor('Sensor 3');
  }

  void addSensor(String name, {bool isDummy = true, String? url}) {
    final sensor = Sensor(name: name, isDummy: isDummy, url: url);

    sensor.timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (sensor.isDummy) {
        gerarDadosDummy(sensor);
      } else {
        buscarDadosDoESP(sensor);
      }
    });

    setState(() {
      sensors.add(sensor);
    });
  }

  void removeSensor(Sensor sensor) {
    sensor.timer?.cancel();
    setState(() {
      sensors.remove(sensor);
    });
  }

  List<FlSpot> gerarTransicaoSenoide({
    required double startX,
    required double endX,
    required double startY,
    required double endY,
    int steps = 10,
  }) {
    List<FlSpot> spots = [];
    for (int i = 0; i <= steps; i++) {
      double t = i / steps;
      double senoide = (1 - cos(pi * t)) / 2;
      double interpolatedY = startY + (endY - startY) * senoide;
      double interpolatedX = startX + (endX - startX) * t;
      spots.add(FlSpot(interpolatedX, interpolatedY));
    }
    return spots;
  }

  void gerarDadosDummy(Sensor sensor) {
    bool newStatus = Random().nextBool();
    double newY = newStatus ? 1 : 0;
    atualizarGrafico(sensor, newY);
  }

  Future<void> buscarDadosDoESP(Sensor sensor) async {
    try {
      final response = await http.get(Uri.parse(sensor.url!)).timeout(
            const Duration(seconds: 1),
          );

      print('Resposta do ESP: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final bool status = data['status'] ?? false;
        double newY = status ? 1 : 0;
        atualizarGrafico(sensor, newY);
      } else {
        throw Exception('Erro na resposta');
      }
    } catch (e) {
      print('Erro ao buscar dados do ESP: $e');
    }
  }

  void atualizarGrafico(Sensor sensor, double newY) {
    setState(() {
      if (sensor.dataPoints.isNotEmpty) {
        double lastX = sensor.xValue;
        double lastY = sensor.dataPoints.last.y;

        if (lastY != newY) {
          final transicao = gerarTransicaoSenoide(
            startX: lastX,
            endX: lastX + 1,
            startY: lastY,
            endY: newY,
            steps: 10,
          );
          sensor.dataPoints.addAll(transicao.skip(1));
        } else {
          sensor.dataPoints.add(FlSpot(lastX + 1, newY));
        }

        sensor.xValue = lastX + 1;
      } else {
        sensor.dataPoints.add(FlSpot(sensor.xValue, newY));
        sensor.xValue += 1;
      }

      if (sensor.dataPoints.length > 100) {
        sensor.dataPoints.removeAt(0);
      }

      final ultimos5 = sensor.dataPoints.reversed.take(15).toList();
      final todosInativos =
          ultimos5.length == 15 && ultimos5.every((p) => p.y == 0);
      sensor.alerta = todosInativos;
    });
  }

  Widget buildChart(Sensor sensor) {
    double range = 20;
    double maxX = sensor.xValue;
    double minX = (maxX - range) < 0 ? 0 : (maxX - range);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        color: Colors.black,
        child: LineChart(
          LineChartData(
            minY: -0.5,
            maxY: 1.5,
            minX: minX,
            maxX: maxX,
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  reservedSize: 40,
                  getTitlesWidget: (value, _) {
                    if (value == 1) {
                      return const Text('Ativo',
                          style: TextStyle(color: Colors.white, fontSize: 10));
                    }
                    if (value == 0) {
                      return const Text('Inativo',
                          style: TextStyle(color: Colors.white, fontSize: 10));
                    }
                    return const Text('',
                        style: TextStyle(color: Colors.white, fontSize: 10));
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 5,
                  reservedSize: 30,
                  getTitlesWidget: (value, _) {
                    return Text(
                      value.toInt().toString(),
                      style:
                          const TextStyle(color: Colors.white, fontSize: 10),
                    );
                  },
                ),
              ),
              topTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: FlGridData(
              show: true,
              horizontalInterval: 1,
              verticalInterval: 5,
              getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.white.withOpacity(0.2),
                strokeWidth: 1,
              ),
              getDrawingVerticalLine: (value) => FlLine(
                color: Colors.white.withOpacity(0.2),
                strokeWidth: 1,
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: sensor.dataPoints,
                isCurved: true,
                barWidth: 3,
                color: Colors.green,
                dotData: FlDotData(show: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var sensor in sensors) {
      sensor.timer?.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Zéfiro'),
            centerTitle: true,
          ),
          body: sensors.isEmpty
              ? const Center(child: Text('Nenhum sensor adicionado'))
              : ListView.builder(
                  itemCount: sensors.length,
                  itemBuilder: (context, index) {
                    final sensor = sensors[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sensor.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 250,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: buildChart(sensor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        for (var sensor in sensors)
          if (sensor.alerta)
            FloatingAlert(
                message:
                    '⚠️ Paciente "${sensor.name}" sem respirar pelos últimos 15 segundos!'),
      ],
    );
  }
}
