import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/attendance_session.dart';
import '../models/attendance_record.dart';
import '../services/api_service.dart';

class AttendanceProvider extends ChangeNotifier {
  final APIService _api = APIService();

  bool _isLoading = false;
  String? _errorMessage;

  AttendanceSession? _activeSession;
  List<AttendanceSession> _sessions = [];
  Map<String, dynamic>? _currentReport;
  List<AttendanceRecord> _sessionRecords = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AttendanceSession? get activeSession => _activeSession;
  List<AttendanceSession> get sessions => _sessions;
  Map<String, dynamic>? get currentReport => _currentReport;
  List<AttendanceRecord> get sessionRecords => _sessionRecords;

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  // ─── Active Session Control ──────────────────────────────────────────────────
  Future<bool> startSession(int classId, int subjectId) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final response = await _api.post('/attendance/start-session', {
        'class_id': classId,
        'subject_id': subjectId,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        _activeSession = AttendanceSession.fromJson(body);
        await fetchSessionReport(_activeSession!.id);
        _setLoading(false);
        return true;
      } else {
        final err = jsonDecode(response.body);
        _errorMessage = err['detail'] ?? 'Failed to initialize session.';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Network connection error initializing session.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> endActiveSession() async {
    if (_activeSession == null) return false;
    _setLoading(true);
    _errorMessage = null;
    try {
      final response = await _api.post('/attendance/end-session/${_activeSession!.id}', null);
      if (response.statusCode == 200) {
        _activeSession = null;
        _sessionRecords = [];
        _currentReport = null;
        _setLoading(false);
        return true;
      } else {
        final err = jsonDecode(response.body);
        _errorMessage = err['detail'] ?? 'Failed to close active session.';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection failed closing active session.';
      _setLoading(false);
      return false;
    }
  }

  // Fetch all sessions
  Future<void> fetchSessions({int? classId, bool activeOnly = false}) async {
    _errorMessage = null;
    try {
      String endpoint = '/attendance/sessions?active_only=$activeOnly';
      if (classId != null) {
        endpoint += '&class_id=$classId';
      }
      
      final response = await _api.get(endpoint);
      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        _sessions = body.map((item) => AttendanceSession.fromJson(item)).toList();
        
        // Find if there is an active session in the returned list
        final active = _sessions.firstWhere(
          (s) => s.isActive, 
          orElse: () => AttendanceSession(
            id: 0, classId: 0, className: '', subjectId: 0, subjectName: '', 
            teacherId: 0, teacherName: '', startTime: DateTime.now(), isActive: false
          )
        );
        if (active.id != 0) {
          _activeSession = active;
        } else {
          _activeSession = null;
        }
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Could not load previous sessions logs.';
    }
  }

  // ─── Face Verification ───────────────────────────────────────────────────────
  // Single Face Scan
  Future<Map<String, dynamic>> markSingleFace(int sessionId, File file) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final response = await _api.uploadSingleFile(
        '/attendance/mark-face?session_id=$sessionId',
        file,
        fieldName: 'file',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        // Refresh session report to update present roster
        await fetchSessionReport(sessionId);
        _setLoading(false);
        return body; // matched, roll_number, full_name, confidence, duplicate, message
      } else {
        final err = jsonDecode(response.body);
        _errorMessage = err['detail'] ?? 'Facial match failed.';
        _setLoading(false);
        return {'matched': false, 'message': _errorMessage};
      }
    } catch (e) {
      _errorMessage = 'Network timeout transferring scan data.';
      _setLoading(false);
      return {'matched': false, 'message': _errorMessage};
    }
  }

  // Classroom Group Face Scan
  Future<Map<String, dynamic>> markClassroomGroup(int sessionId, File file) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final response = await _api.uploadSingleFile(
        '/attendance/mark-classroom?session_id=$sessionId',
        file,
        fieldName: 'file',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        await fetchSessionReport(sessionId);
        _setLoading(false);
        return body; // faces_detected, matched_count, results
      } else {
        final err = jsonDecode(response.body);
        _errorMessage = err['detail'] ?? 'Classroom scan failed.';
        _setLoading(false);
        return {'faces_detected': 0, 'matched_count': 0, 'results': [], 'message': _errorMessage};
      }
    } catch (e) {
      _errorMessage = 'Connection failure sending classroom snapshot.';
      _setLoading(false);
      return {'faces_detected': 0, 'matched_count': 0, 'results': [], 'message': _errorMessage};
    }
  }

  // ─── Manual Marking Override ─────────────────────────────────────────────────
  Future<bool> markManualOverride(int studentId, int sessionId, String status) async {
    _errorMessage = null;
    try {
      final response = await _api.post('/attendance/mark-manual', {
        'student_id': studentId,
        'session_id': sessionId,
        'status': status, // 'present' or 'absent'
      });

      if (response.statusCode == 200) {
        await fetchSessionReport(sessionId);
        return true;
      } else {
        final err = jsonDecode(response.body);
        _errorMessage = err['detail'] ?? 'Failed to update attendance manually.';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection timeout saving manual status.';
      return false;
    }
  }

  // ─── Session Reports & Downloads ──────────────────────────────────────────────
  Future<void> fetchSessionReport(int sessionId) async {
    _errorMessage = null;
    try {
      final response = await _api.get('/attendance/reports/session/$sessionId');
      if (response.statusCode == 200) {
        _currentReport = jsonDecode(response.body);
        final List<dynamic> recordsJson = _currentReport!['records'] ?? [];
        _sessionRecords = recordsJson.map((item) {
          // Flatten standard JSON structures:
          Map<String, dynamic> flat = Map<String, dynamic>.from(item);
          flat['session_id'] = sessionId;
          return AttendanceRecord.fromJson(flat);
        }).toList();
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Could not load active session reports.';
    }
  }

  // Fetch Student Report Profile
  Future<Map<String, dynamic>?> fetchStudentAttendanceSummary(int studentId) async {
    _errorMessage = null;
    try {
      final response = await _api.get('/attendance/reports/student/$studentId');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      _errorMessage = 'Could not fetch student attendance percentage.';
    }
    return null;
  }

  // Export File as CSV, Excel, or PDF and trigger native Share Sheet
  Future<bool> exportAndShareReport(int sessionId, String format) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final response = await _api.get('/attendance/export/$sessionId?format=$format');
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        
        // Setup file extensions
        String ext = 'csv';
        String mimeType = 'text/csv';
        if (format == 'excel') {
          ext = 'xlsx';
          mimeType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
        } else if (format == 'pdf') {
          ext = 'pdf';
          mimeType = 'application/pdf';
        }

        // Write temporarily inside App Data and invoke Share Plus
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/attendance_session_$sessionId.$ext');
        await tempFile.writeAsBytes(bytes);
        
        await Share.shareXFiles(
          [XFile(tempFile.path, mimeType: mimeType)],
          subject: 'Face Track Attendance Session $sessionId Report',
        );
        _setLoading(false);
        return true;
      } else {
        _errorMessage = 'Export failed in server generation.';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'File sharing export failed.';
      _setLoading(false);
      return false;
    }
  }
}
