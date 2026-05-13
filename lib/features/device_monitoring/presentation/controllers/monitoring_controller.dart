import 'package:flutter/material.dart';
import '../../data/local_db/database_helper.dart';

class MonitoringController extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get logs => _logs;
  bool get isLoading => _isLoading;

  Future<void> fetchLogs() async {
    _isLoading = true;
    notifyListeners();

    try {
      final database = await _db.database;
      _logs = await database.query('logs', orderBy: 'timestamp DESC', limit: 100);
    } catch (e) {
      debugPrint('Error fetching logs: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> clearLogs() async {
    final database = await _db.database;
    await database.delete('logs');
    _logs = [];
    notifyListeners();
  }
}
