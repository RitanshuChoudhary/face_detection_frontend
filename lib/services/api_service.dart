import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

class APIService {
  final http.Client _client = http.Client();
  static final APIService _instance = APIService._internal();

  factory APIService() {
    return _instance;
  }

  APIService._internal();

  // Helper to get authorization headers
  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.keyAccessToken);
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // Handle Response and check for 401 token refresh
  Future<http.Response> _handleResponse(
    Future<http.Response> Function() requestFn, {
    bool includeAuth = true,
  }) async {
    try {
      final response = await requestFn();
      
      if (response.statusCode == 401 && includeAuth) {
        // Try refreshing token
        final isRefreshed = await refreshSessionToken();
        if (isRefreshed) {
          // Retry the request with new headers
          return await requestFn();
        }
      }
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // GET Request
  Future<http.Response> get(String endpoint, {bool includeAuth = true}) async {
    return _handleResponse(() async {
      final headers = await _getHeaders(includeAuth: includeAuth);
      final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
      return await _client.get(url, headers: headers);
    }, includeAuth: includeAuth);
  }

  // POST Request
  Future<http.Response> post(String endpoint, Map<String, dynamic>? body, {bool includeAuth = true}) async {
    return _handleResponse(() async {
      final headers = await _getHeaders(includeAuth: includeAuth);
      final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
      final encodedBody = body != null ? jsonEncode(body) : null;
      return await _client.post(url, headers: headers, body: encodedBody);
    }, includeAuth: includeAuth);
  }

  // DELETE Request
  Future<http.Response> delete(String endpoint, {bool includeAuth = true}) async {
    return _handleResponse(() async {
      final headers = await _getHeaders(includeAuth: includeAuth);
      final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
      return await _client.delete(url, headers: headers);
    }, includeAuth: includeAuth);
  }

  // Multipart POST for uploading multiple face images (Student Register Face)
  Future<http.Response> uploadMultipleFiles(
    String endpoint,
    List<File> files, {
    String fieldName = 'files',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.keyAccessToken);
    
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    final request = http.MultipartRequest('POST', url);
    
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    for (var file in files) {
      final stream = http.ByteStream(file.openRead());
      final length = await file.length();
      final multipartFile = http.MultipartFile(
        fieldName,
        stream,
        length,
        filename: file.path.split('/').last,
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(multipartFile);
    }

    final streamedResponse = await request.send();
    return await http.Response.fromStream(streamedResponse);
  }

  // Multipart POST for a single file (Attendance mark)
  Future<http.Response> uploadSingleFile(
    String endpoint,
    File file, {
    String fieldName = 'file',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.keyAccessToken);
    
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    final request = http.MultipartRequest('POST', url);
    
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final stream = http.ByteStream(file.openRead());
    final length = await file.length();
    final multipartFile = http.MultipartFile(
      fieldName,
      stream,
      length,
      filename: file.path.split('/').last,
      contentType: MediaType('image', 'jpeg'),
    );
    request.files.add(multipartFile);

    final streamedResponse = await request.send();
    return await http.Response.fromStream(streamedResponse);
  }

  // Multipart POST with fields and files
  Future<http.Response> uploadMultipart(
    String endpoint,
    Map<String, String> fields, {
    File? file,
    String fieldName = 'file',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.keyAccessToken);
    
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    final request = http.MultipartRequest('POST', url);
    
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Add fields
    request.fields.addAll(fields);

    // Add file if present
    if (file != null) {
      final stream = http.ByteStream(file.openRead());
      final length = await file.length();
      final multipartFile = http.MultipartFile(
        fieldName,
        stream,
        length,
        filename: file.path.split('/').last,
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(multipartFile);
    }

    final streamedResponse = await request.send();
    return await http.Response.fromStream(streamedResponse);
  }

  // Token refreshing routine
  Future<bool> refreshSessionToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString(AppConstants.keyRefreshToken);
    if (refreshToken == null) return false;

    try {
      final url = Uri.parse('${AppConstants.baseUrl}/auth/refresh');
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccess = data['access_token'];
        final newRefresh = data['refresh_token'];
        await prefs.setString(AppConstants.keyAccessToken, newAccess);
        await prefs.setString(AppConstants.keyRefreshToken, newRefresh);
        return true;
      } else {
        // Refresh token itself failed/expired, perform logout
        await prefs.remove(AppConstants.keyAccessToken);
        await prefs.remove(AppConstants.keyRefreshToken);
        await prefs.remove(AppConstants.keyUserData);
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
