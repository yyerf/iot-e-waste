import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/services/firebase_service.dart';
import '../../../../core/services/mqtt_service.dart';
import '../../../../core/models/sensor_data.dart';
import '../../../../shared/presentation/widgets/sensor_card.dart';
import '../../../../shared/presentation/widgets/chart_widget.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  String? selectedCarId;

  @override
  Widget build(BuildContext context) {
    final userCars = ref.watch(userCarsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(userCarsProvider);
            },
          ),
        ],
      ),
      body: userCars.when(
        data: (cars) {
          if (cars.isEmpty) {
            return const _EmptyDashboard();
          }
          
          // Select first car if none selected
          selectedCarId ??= cars.first.id;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CarSelector(
                  cars: cars,
                  selectedCarId: selectedCarId!,
                  onCarSelected: (carId) {
                    setState(() {
                      selectedCarId = carId;
                    });
                  },
                ),
                const SizedBox(height: 20),
                _RealTimeMonitoring(carId: selectedCarId!),
                const SizedBox(height: 20),
                _HealthOverview(carId: selectedCarId!),
                const SizedBox(height: 20),
                _RecentAlerts(carId: selectedCarId!),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(userCarsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_car,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            'No Cars Registered',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          const Text(
            'Add your first car to start monitoring',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to add car page
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Car'),
          ),
        ],
      ),
    );
  }
}

class _CarSelector extends StatelessWidget {
  final List cars;
  final String selectedCarId;
  final Function(String) onCarSelected;

  const _CarSelector({
    required this.cars,
    required this.selectedCarId,
    required this.onCarSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Vehicle',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedCarId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: cars.map((car) {
                return DropdownMenuItem<String>(
                  value: car.id,
                  child: Text(car.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  onCarSelected(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RealTimeMonitoring extends ConsumerWidget {
  final String carId;

  const _RealTimeMonitoring({required this.carId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensorDataStream = ref.watch(sensorDataStreamProvider(carId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sensors, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Real-time Monitoring',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const Text('Live'),
              ],
            ),
            const SizedBox(height: 16),
            sensorDataStream.when(
              data: (sensorData) => _buildSensorGrid(context, sensorData),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text('Error: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorGrid(BuildContext context, SensorData latestData) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        SensorCard(
          title: 'Voltage',
          value: '${latestData.sensorType == 'voltage' ? latestData.value.toStringAsFixed(1) : '--'}',
          unit: 'V',
          icon: Icons.flash_on,
          color: _getVoltageColor(latestData.sensorType == 'voltage' ? latestData.value : 0),
        ),
        SensorCard(
          title: 'Temperature',
          value: '${latestData.sensorType == 'temperature' ? latestData.value.toStringAsFixed(1) : '--'}',
          unit: '°C',
          icon: Icons.thermostat,
          color: _getTemperatureColor(latestData.sensorType == 'temperature' ? latestData.value : 0),
        ),
        SensorCard(
          title: 'Battery',
          value: '${latestData.sensorType == 'battery' ? latestData.value.toStringAsFixed(0) : '--'}',
          unit: '%',
          icon: Icons.battery_std,
          color: _getBatteryColor(latestData.sensorType == 'battery' ? latestData.value : 0),
        ),
        SensorCard(
          title: 'Alternator',
          value: '${latestData.sensorType == 'alternator' ? latestData.value.toStringAsFixed(1) : '--'}',
          unit: 'A',
          icon: Icons.electrical_services,
          color: Colors.blue,
        ),
      ],
    );
  }

  Color _getVoltageColor(double voltage) {
    if (voltage < 11.5) return Colors.red;
    if (voltage < 12.0) return Colors.orange;
    return Colors.green;
  }

  Color _getTemperatureColor(double temperature) {
    if (temperature > 80) return Colors.red;
    if (temperature > 60) return Colors.orange;
    return Colors.green;
  }

  Color _getBatteryColor(double battery) {
    if (battery < 20) return Colors.red;
    if (battery < 50) return Colors.orange;
    return Colors.green;
  }
}

class _HealthOverview extends StatelessWidget {
  final String carId;

  const _HealthOverview({required this.carId});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Health Overview',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildHealthIndicator(
                    'Overall Health',
                    85,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildHealthIndicator(
                    'Battery Health',
                    72,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildHealthIndicator(
                    'Alternator',
                    90,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildHealthIndicator(
                    'Sensors',
                    95,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthIndicator(String title, int percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
        const SizedBox(height: 4),
        Text('$percentage%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _RecentAlerts extends StatelessWidget {
  final String carId;

  const _RecentAlerts({required this.carId});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Recent Alerts',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // Navigate to alerts page
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildAlertItem(
              'Low Battery Voltage',
              'Battery voltage dropped to 11.2V',
              '2 hours ago',
              Colors.red,
            ),
            _buildAlertItem(
              'High Temperature',
              'Engine temperature reached 85°C',
              '5 hours ago',
              Colors.orange,
            ),
            _buildAlertItem(
              'Maintenance Reminder',
              'Battery check due in 3 days',
              '1 day ago',
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertItem(String title, String description, String time, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
