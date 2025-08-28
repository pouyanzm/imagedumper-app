import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/image_model.dart';

final dioProvider = Provider((ref) {
  Dio dio = Dio(BaseOptions(baseUrl: "http://192.168.0.3:3000/api"));
  dio.interceptors.clear();
  return dio;
});

final apiProvider = Provider((ref) => ApiService(ref.watch(dioProvider)));

class ApiService {
  final Dio _dio;
  ApiService(this._dio);

  /// Get latest image info from server
  Future<ImageModel?> getLatestImage() async {
    try {
      print('📡 Getting latest image from server...');

      final response = await _dio.get('/image');

      if (response.statusCode == 200) {
        print('✅ Latest image info received');
        return ImageModel.fromJson(response.data['image']);
      } else if (response.statusCode == 404) {
        print('ℹ️ No image found on server');
        return null;
      } else {
        print('❌ Failed to get image: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ API Error: $e');
      return null;
    }
  }
}
