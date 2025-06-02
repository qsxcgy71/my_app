import 'package:flutter/material.dart';
import '../styles/app_text_styles.dart';
import '../services/device_info_service.dart';

class PlaceholderScreen extends StatefulWidget {
  final String title;
  
  const PlaceholderScreen({
    super.key,
    required this.title,
  });

  @override
  State<PlaceholderScreen> createState() => _PlaceholderScreenState();
}

class _PlaceholderScreenState extends State<PlaceholderScreen> {
  Map<String, dynamic>? _deviceInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    try {
      final info = await DeviceInfoService.getDeviceInfo();
      if (mounted) {
        setState(() {
          _deviceInfo = info;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading device info: $e');
      if (mounted) {
        setState(() {
          _deviceInfo = {'error': e.toString()};
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildInfoCard(String title, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(
          title,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          value,
          style: AppTextStyles.bodyMedium,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_deviceInfo == null || _deviceInfo!.containsKey('error')) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading device info',
              style: AppTextStyles.titleLarge,
            ),
            if (_deviceInfo?.containsKey('error') == true) ...[
              const SizedBox(height: 8),
              Text(
                _deviceInfo!['error'].toString(),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Device Information',
              style: AppTextStyles.titleLarge.copyWith(fontSize: 24),
            ),
          ),
          _buildInfoCard('Platform', _deviceInfo!['platform'] ?? 'Unknown'),
          if (_deviceInfo!['platform'] == 'Android') ...[
            _buildInfoCard('Model', _deviceInfo!['model'] ?? 'Unknown'),
            _buildInfoCard('Manufacturer', _deviceInfo!['manufacturer'] ?? 'Unknown'),
            _buildInfoCard('Brand', _deviceInfo!['brand'] ?? 'Unknown'),
            _buildInfoCard('Android Version', _deviceInfo!['androidVersion'] ?? 'Unknown'),
            _buildInfoCard('SDK Version', (_deviceInfo!['sdkInt'] ?? 'Unknown').toString()),
          ] else if (_deviceInfo!['platform'] == 'iOS') ...[
            _buildInfoCard('Name', _deviceInfo!['name'] ?? 'Unknown'),
            _buildInfoCard('Model', _deviceInfo!['model'] ?? 'Unknown'),
            _buildInfoCard('System Version', _deviceInfo!['systemVersion'] ?? 'Unknown'),
            _buildInfoCard('System Name', _deviceInfo!['systemName'] ?? 'Unknown'),
          ],
          _buildInfoCard(
            'Physical Device',
            (_deviceInfo!['isPhysicalDevice'] ?? false) ? 'Yes' : 'No',
          ),
        ],
      ),
    );
  }
} 