import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/classroom.dart';
import '../models/subject.dart';
import '../models/student.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AdminProvider extends ChangeNotifier {
  final APIService _api = APIService();

  bool _isLoading = false;
  bool _isTeachersLoading = false;
  bool _isClassesLoading = false;
  bool _isSubjectsLoading = false;
  bool _isStudentsLoading = false;
  bool _isTrackingLoading = false;
  String? _errorMessage;

  // Cache lists
  List<User> _teachers = [];
  List<Classroom> _classes = [];
  List<Subject> _subjects = [];
  List<Student> _students = [];
  Map<String, dynamic> _dashboardStats = {};
  List<dynamic> _trackedTeachers = [];
  List<dynamic> _trackedClasses = [];

  bool get isLoading => _isLoading;
  bool get isTeachersLoading => _isTeachersLoading;
  bool get isClassesLoading => _isClassesLoading;
  bool get isSubjectsLoading => _isSubjectsLoading;
  bool get isStudentsLoading => _isStudentsLoading;
  bool get isTrackingLoading => _isTrackingLoading;
  String? get errorMessage => _errorMessage;
  List<User> get teachers => _teachers;
  List<Classroom> get classes => _classes;
  List<Subject> get subjects => _subjects;
  List<Student> get students => _students;
  Map<String, dynamic> get dashboardStats => _dashboardStats;
  List<dynamic> get trackedTeachers => _trackedTeachers;
  List<dynamic> get trackedClasses => _trackedClasses;

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  // ─── Dashboard Stats ────────────────────────────────────────────────────────
  Future<void> fetchDashboardStats() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final response = await _api.get('/admin/dashboard');
      if (response.statusCode == 200) {
        _dashboardStats = jsonDecode(response.body);
      } else {
        _errorMessage = 'Failed to load dashboard metrics.';
      }
    } catch (e) {
      _errorMessage = 'Connection issue fetching dashboard stats.';
    }
    _setLoading(false);
  }

  // ─── Teachers ───────────────────────────────────────────────────────────────
  Future<void> fetchTeachers() async {
    _isTeachersLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _api.get('/admin/teachers');
      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        _teachers = body.map((item) {
          // Sometimes teacher response nests under "user": {id, email, full_name, role}
          if (item['user'] != null) {
            return User(
              id: item['id'],
              name: item['user']['full_name'] ?? '',
              email: item['user']['email'] ?? '',
              role: 'teacher',
              teacherId: item['id'],
            );
          }
          return User(
            id: item['id'] ?? 0,
            name: item['full_name'] ?? '',
            email: item['email'] ?? '',
            role: 'teacher',
          );
        }).toList();
      }
    } catch (e) {
      _errorMessage = 'Failed to retrieve teachers list.';
    }
    _isTeachersLoading = false;
    notifyListeners();
  }

  Future<bool> createTeacher(String name, String email, String password, String employeeId, String phone, {int? classId}) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final response = await _api.post('/admin/teachers', {
        'email': email,
        'password': password,
        'full_name': name,
        'employee_id': employeeId.isNotEmpty ? employeeId : null,
        'phone': phone.isNotEmpty ? phone : null,
        'class_id': classId,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchTeachers();
        _setLoading(false);
        return true;
      } else {
        final err = jsonDecode(response.body);
        _errorMessage = err['detail'] ?? 'Failed to register teacher.';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Network error. Could not create teacher.';
      _setLoading(false);
      return false;
    }
  }

  // ─── Classes ────────────────────────────────────────────────────────────────
  Future<void> fetchClasses() async {
    _isClassesLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _api.get('/admin/classes');
      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        _classes = body.map((item) => Classroom(
          id: item['id'] ?? 0,
          name: item['class_name'] ?? '',
        )).toList();
      }
    } catch (e) {
      _errorMessage = 'Failed to load classes list.';
    }
    _isClassesLoading = false;
    notifyListeners();
  }

  Future<bool> createClass(String className, String section) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final response = await _api.post('/admin/classes', {
        'class_name': className,
        'section': section.isNotEmpty ? section : null,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchClasses();
        _setLoading(false);
        return true;
      } else {
        final err = jsonDecode(response.body);
        _errorMessage = err['detail'] ?? 'Failed to create class.';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Network error. Could not create class.';
      _setLoading(false);
      return false;
    }
  }

  // ─── Subjects ───────────────────────────────────────────────────────────────
  Future<void> fetchSubjects() async {
    _isSubjectsLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _api.get('/admin/subjects');
      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        _subjects = body.map((item) => Subject(
          id: item['id'] ?? 0,
          name: item['subject_name'] ?? '',
          code: item['subject_code'] ?? '',
        )).toList();
      }
    } catch (e) {
      _errorMessage = 'Failed to load subjects list.';
    }
    _isSubjectsLoading = false;
    notifyListeners();
  }

  Future<bool> createSubject(String subjectName, String code) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final response = await _api.post('/admin/subjects', {
        'subject_name': subjectName,
        'subject_code': code.isNotEmpty ? code : null,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchSubjects();
        _setLoading(false);
        return true;
      } else {
        final err = jsonDecode(response.body);
        _errorMessage = err['detail'] ?? 'Failed to create subject.';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Network error. Could not create subject.';
      _setLoading(false);
      return false;
    }
  }

  // ─── Students CRUD & Face Enrollment ─────────────────────────────────────────
  Future<void> fetchStudents() async {
    _isStudentsLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _api.get('/students/');
      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        _students = body.map((item) {
          // Normalize responses where user data is nested:
          // "id": 1, "roll_number": "101", "class_id": 2, "user": {"full_name": "...", "email": "..."}
          Map<String, dynamic> flatJson = Map<String, dynamic>.from(item);
          if (item['user'] != null) {
            flatJson['name'] = item['user']['full_name'];
            flatJson['email'] = item['user']['email'];
          }
          // The backend could return a lists of face mappings or similar. We inspect and parse:
          flatJson['has_face_registered'] = item['face_registered'] ?? (item['face_image_url'] != null);
          flatJson['face_images'] = item['face_image_url'] != null ? [item['face_image_url']] : [];
          return Student.fromJson(flatJson);
        }).toList();
      }
    } catch (e) {
      _errorMessage = 'Failed to load students list.';
    }
    _isStudentsLoading = false;
    notifyListeners();
  }

  Future<bool> createStudent(String name, String email, String password, String rollNumber, int classId) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final response = await _api.post('/students/', {
        'email': email,
        'password': password,
        'full_name': name,
        'roll_number': rollNumber,
        'class_id': classId,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchStudents();
        _setLoading(false);
        return true;
      } else {
        final err = jsonDecode(response.body);
        _errorMessage = err['detail'] ?? 'Failed to enroll student.';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Network error. Could not enroll student.';
      _setLoading(false);
      return false;
    }
  }

  // Unified Student face capture registration
  Future<bool> registerStudentWithFace({
    required String name,
    required String email,
    required String password,
    required String rollNumber,
    required int classId,
    String? phone,
    required File faceFile,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final response = await _api.uploadMultipart(
        '/students/register-with-face',
        {
          'email': email,
          'password': password,
          'full_name': name,
          'roll_number': rollNumber,
          'class_id': classId.toString(),
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        },
        file: faceFile,
        fieldName: 'file',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchStudents();
        _setLoading(false);
        return true;
      } else {
        final err = jsonDecode(response.body);
        _errorMessage = err['detail'] ?? 'Failed to register student with face.';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Network error. Could not register student with face.';
      _setLoading(false);
      return false;
    }
  }

  // Multipart request: Register student faces
  Future<bool> registerStudentFaces(int studentId, List<File> faceFiles) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final response = await _api.uploadMultipleFiles(
        '/students/$studentId/register-face',
        faceFiles,
        fieldName: 'files',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchStudents();
        _setLoading(false);
        return true;
      } else {
        final err = jsonDecode(response.body);
        _errorMessage = err['detail'] ?? 'Failed to upload and train face features.';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Network timeout transferring image bytes.';
      _setLoading(false);
      return false;
    }
  }

  // Clear student faces
  Future<bool> deleteStudentFaces(int studentId) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final response = await _api.delete('/students/$studentId/face');
      if (response.statusCode == 200) {
        await fetchStudents();
        _setLoading(false);
        return true;
      } else {
        final err = jsonDecode(response.body);
        _errorMessage = err['detail'] ?? 'Failed to delete student face metadata.';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to delete face records.';
      _setLoading(false);
      return false;
    }
  }

  // Fetch Admin Tracking metrics
  Future<void> fetchTrackingData() async {
    _isTrackingLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final tRes = await _api.get('/admin/tracking/teachers');
      if (tRes.statusCode == 200) {
        _trackedTeachers = jsonDecode(tRes.body);
      }
      
      final cRes = await _api.get('/admin/tracking/classes');
      if (cRes.statusCode == 200) {
        _trackedClasses = jsonDecode(cRes.body);
      }
    } catch (e) {
      _errorMessage = 'Failed to load tracking analytics.';
    }
    _isTrackingLoading = false;
    notifyListeners();
  }
}
