import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  late final Dio _dio;

  ApiService() {
    final String baseUrl = kIsWeb ? 'http://127.0.0.1:5000/api' : 'http://10.0.2.2:5000/api';
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));
  }

  // FUNGSI BARU: Filter penangkap error yang aman agar tidak crash
  String _handleError(DioException e) {
    if (e.response?.data is Map) {
      return e.response?.data['error'] ?? 'Terjadi kesalahan pada server';
    }
    return 'Server Error ${e.response?.statusCode}: Pastikan Database MySQL sudah diupdate.';
  }

  Future loginAdmin(String username, String password) async {
    try {
      final response = await _dio.post('/public/login', data: {
        'username': username,
        'password': password,
      });
      return response.data;
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future ambilTiket(int serviceId, String nama, String noTelp) async {
    try {
      final response = await _dio.post('/public/tickets', data: {
        'service_id': serviceId,
        'nama': nama,
        'no_telp': noTelp
      });
      return response.data;
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future panggilBerikutnya(int serviceId) async {
    try {
      final response = await _dio.post('/staff/queues/call-next', data: {'service_id': serviceId});
      return response.data;
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  Future getQueueStatus(int serviceId) async {
    try {
      final response = await _dio.get('/public/queues/status', queryParameters: {'service_id': serviceId});
      return response.data;
    } catch (e) {
      return {'waiting_count': 0, 'current_ticket': '-', 'total_count': 0};
    }
  }

  Future kelolaTiket(String ticketNumber, String action, String targetDate) async {
    try {
      final response = await _dio.post('/public/tickets/action', data: {
        'ticket_number': ticketNumber,
        'action': action,
        'target_date': targetDate,
        'service_id': 1
      });
      return response.data['new_ticket'];
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }
}