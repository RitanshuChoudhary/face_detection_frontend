import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import '../../../config/constants.dart';
import 'controllers/monitoring_controller.dart';

class MonitoringDashboardScreen extends StatefulWidget {
  const MonitoringDashboardScreen({super.key});

  @override
  State<MonitoringDashboardScreen> createState() => _MonitoringDashboardScreenState();
}

class _MonitoringDashboardScreenState extends State<MonitoringDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MonitoringController>().fetchLogs();
    });
  }

  Future<void> _requestPermissions() async {
    // 1. Standard Permissions
    await [
      Permission.sms,
      Permission.phone,
      Permission.ignoreBatteryOptimizations,
      Permission.notification,
    ].request();

    // 2. Notification Listener Access (Special System Page)
    bool isGranted = await NotificationListenerService.isPermissionGranted();
    if (!isGranted) {
      await NotificationListenerService.requestPermission();
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissions requested. Ensure Notification Access is enabled in System Settings.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<MonitoringController>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Monitoring Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.fetchLogs(),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => controller.clearLogs(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header / Stats
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            decoration: BoxDecoration(
              color: AppConstants.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Background Service: Active',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.primary),
                    ),
                    ElevatedButton.icon(
                      onPressed: _requestPermissions,
                      icon: const Icon(Icons.security, size: 18),
                      label: const Text('Setup Access'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'This hub tracks incoming WhatsApp/SMS messages for personal archival.',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Logs List
          Expanded(
            child: controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : controller.logs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 64, color: Colors.grey.withOpacity(0.3)),
                            const SizedBox(height: 16),
                            const Text('No data captured yet.'),
                            const Text('Ensure permissions are granted and service is running.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppConstants.padding),
                        itemCount: controller.logs.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final log = controller.logs[index];
                          final type = log['type'] ?? 'N/A';
                          final sender = log['sender'] ?? 'Unknown';
                          final content = log['content'] ?? '';
                          final time = DateTime.parse(log['timestamp']).toLocal();

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getTypeColor(type).withOpacity(0.1),
                              child: Icon(_getTypeIcon(type), color: _getTypeColor(type), size: 20),
                            ),
                            title: Text(sender, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(content, maxLines: 2, overflow: TextOverflow.ellipsis),
                            trailing: Text(
                              '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                              style: theme.textTheme.bodySmall,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'SMS': return Icons.sms;
      case 'WHATSAPP': return Icons.chat;
      case 'NOTIFICATION': return Icons.notifications;
      default: return Icons.info;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'SMS': return Colors.blue;
      case 'WHATSAPP': return Colors.green;
      case 'NOTIFICATION': return Colors.orange;
      default: return Colors.grey;
    }
  }
}
