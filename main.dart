import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(const MultiEsp32App());
}

class MultiEsp32App extends StatefulWidget {
  const MultiEsp32App({super.key});

  @override
  State<MultiEsp32App> createState() => _MultiEsp32AppState();
}

class _MultiEsp32AppState extends State<MultiEsp32App> {
  final TextEditingController _controller = TextEditingController();

  final List<String> esp32Urls = [];
  final List<List<FlSpot>> allDataPoints = [];
  final List<double> xValues = [];
  final List<Timer?> timers = [];

  @override
  void dispose() {
    for (final timer in timers) {
      timer?.cancel();
    }
    _controller.dispose();
    super.dispose();
  }

  void addEsp32(String url) {
    if (url.isEmpty) return;
    if (esp32Urls.contains(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL já adicionada')),
      );
      return;
    }

    setState(() {
      esp32Urls.add(url);
      allDataPoints.add(<FlSpot>[]);
      xValues.add(0);
      timers.add(null);
      final index = esp32Urls.length - 1;
      startFetching(index);
      _controller.clear();
    });
  }

  void removeEsp32(int index) {
    setState(() {
      timers[index]?.cancel();
      timers.removeAt(index);
      esp32Urls.removeAt(index);
      allDataPoints.removeAt(index);
      xValues.removeAt(index);
    });
  }

  void startFetching(int index) {
    timers[index]?.cancel();
    timers[index] = Timer.periodic(const Duration(seconds: 3), (_) {
      fetchData(index);
    });
  }

  Future<void> fetchData(int index) async {
    final url = esp32Urls[index];
    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode == 200) {
        final value = int.tryParse(response.body.trim());
        if (value != null && (value == 0 || value == 1)) {
          setState(() {
            allDataPoints[index].add(FlSpot(xValues[index], value.toDouble()));
            xValues[index] += 1;

            if (allDataPoints[index].length > 20) {
              allDataPoints[index].removeAt(0);
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Erro ao buscar dados do ESP32 $index: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Adicionar/Remover ESP32',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Scaffold(
        appBar: AppBar(title: const Text('Gerenciar ESP32')),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        labelText: 'URL do ESP32 (ex: http://192.168.1.100:8080/data)',
                      ),
                      keyboardType: TextInputType.url,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      addEsp32(_controller.text.trim());
                    },
                    child: const Text('Adicionar'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: esp32Urls.isEmpty
                    ? const Center(child: Text('Adicione URLs para começar'))
                    : ListView.builder(
                        itemCount: esp32Urls.length,
                        itemBuilder: (context, index) {
                          return Dismissible(
                            key: Key(esp32Urls[index]),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (direction) {
                              removeEsp32(index);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Servidor removido: ${esp32Urls[index]}')),
                              );
                            },
                            child: Esp32GraphCard(
                              esp32Index: index,
                              esp32Url: esp32Urls[index],
                              spots: allDataPoints[index],
                              color: Colors.primaries[index % Colors.primaries.length],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Esp32GraphCard extends StatelessWidget {
  final int esp32Index;
  final String esp32Url;
  final List<FlSpot> spots;
  final Color color;

  const Esp32GraphCard({
    super.key,
    required this.esp32Index,
    required this.esp32Url,
    required this.spots,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ESP32 ${esp32Index + 1}: $esp32Url',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minY: -0.5,
                  maxY: 1.5,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: false,
                      color: color,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, _) {
                          if (value == 0) return const Text('0');
                          if (value == 1) return const Text('1');
                          return const Text('');
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 5,
                        getTitlesWidget: (value, _) => Text(value.toInt().toString()),
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
