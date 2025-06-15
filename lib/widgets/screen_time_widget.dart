import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/ai_agent_service.dart';

class ScreenTimeWidget extends StatefulWidget {
  const ScreenTimeWidget({super.key});

  @override
  State<ScreenTimeWidget> createState() => _ScreenTimeWidgetState();
}

class _ScreenTimeWidgetState extends State<ScreenTimeWidget> {
  final AIAgentService _aiAgent = AIAgentService();
  Map<String, dynamic>? _screenTimeData;
  bool _isLoading = false;
  bool _hasPermissions = false;
  bool _isSupported = false;

  @override
  void initState() {
    super.initState();
    _initializeScreenTime();
  }

  Future<void> _initializeScreenTime() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _isSupported = _aiAgent.isScreenTimeSupported();
      if (_isSupported) {
        _hasPermissions = await _aiAgent.hasScreenTimePermissions();
        if (_hasPermissions) {
          await _loadScreenTimeData();
        }
      }
    } catch (e) {
      print('Error initializing screen time: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadScreenTimeData() async {
    try {
      final data = await _aiAgent.getTodayScreenTimeAnalysis();
      setState(() {
        _screenTimeData = data;
      });
    } catch (e) {
      print('Error loading screen time data: $e');
    }
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final granted = await _aiAgent.requestScreenTimePermissions();
      setState(() {
        _hasPermissions = granted;
      });

      if (granted) {
        await _loadScreenTimeData();
      }
    } catch (e) {
      print('Error requesting permissions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error requesting permissions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.phone_android, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Screen Time Today',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (!_isSupported) {
      return _buildUnsupportedMessage();
    }

    if (!_hasPermissions) {
      return _buildPermissionRequest();
    }

    if (_screenTimeData == null) {
      return _buildLoadingOrError();
    }

    return _buildScreenTimeDisplay();
  }

  Widget _buildUnsupportedMessage() {
    return Column(
      children: [
        const Icon(
          Icons.info_outline,
          size: 48,
          color: Colors.grey,
        ),
        const SizedBox(height: 16),
        Text(
          _aiAgent.getScreenTimeSupportMessage(),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildPermissionRequest() {
    return Column(
      children: [
        const Icon(
          Icons.security,
          size: 48,
          color: Colors.orange,
        ),
        const SizedBox(height: 16),
        const Text(
          'Screen Time Permissions Required',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _aiAgent.getScreenTimeSupportMessage(),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _requestPermissions,
          icon: const Icon(Icons.settings),
          label: const Text('Grant Permission'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingOrError() {
    return const Column(
      children: [
        Icon(
          Icons.hourglass_empty,
          size: 48,
          color: Colors.grey,
        ),
        SizedBox(height: 16),
        Text(
          'Loading screen time data...',
          style: TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildScreenTimeDisplay() {
    final data = _screenTimeData!;
    final totalHours = data['totalHours'] as double;
    final category = data['category'] as String;
    final topApps = data['topApps'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Total screen time
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getCategoryColor(category).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getCategoryColor(category).withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getCategoryIcon(category),
                color: _getCategoryColor(category),
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${totalHours.toStringAsFixed(1)} hours',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getCategoryDescription(category),
                      style: TextStyle(
                        color: _getCategoryColor(category),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Top apps (if available)
        if (topApps.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Top Apps',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...topApps.take(3).map((app) => _buildAppUsageItem(app)),
        ],
        
        // Refresh button
        const SizedBox(height: 16),
        Center(
          child: TextButton.icon(
            onPressed: _isLoading ? null : _loadScreenTimeData,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ),
      ],
    );
  }

  Widget _buildAppUsageItem(dynamic app) {
    final name = app['name'] as String;
    final hours = app['hours'] as double;
    final icon = app['icon'] as List<int>?;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // App icon or fallback
          SizedBox(
            width: 24,
            height: 24,
            child: icon != null && icon.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.memory(
                      Uint8List.fromList(icon),
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.apps, size: 20, color: Colors.grey);
                      },
                    ),
                  )
                : const Icon(Icons.apps, size: 20, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name.length > 25 ? '${name.substring(0, 25)}...' : name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${hours.toStringAsFixed(1)}h',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'high':
        return Colors.red;
      case 'moderate':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'high':
        return Icons.warning;
      case 'moderate':
        return Icons.info;
      case 'low':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  String _getCategoryDescription(String category) {
    switch (category) {
      case 'high':
        return 'High usage - consider taking breaks';
      case 'moderate':
        return 'Moderate usage - good balance';
      case 'low':
        return 'Low usage - excellent balance';
      default:
        return 'Unknown usage level';
    }
  }
}