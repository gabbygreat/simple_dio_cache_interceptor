import 'dart:convert';
import 'package:dio/dio.dart';
import 'storage_interface.dart';

class CacheInterceptor implements Interceptor {
  final CacheStorage storage;
  final String dataKey = 'data';
  final String timeStampKey = 'timestamp';

  CacheInterceptor(this.storage);

  Future<Response?> _getCachedResponse(
    RequestOptions options, {
    required Duration duration,
  }) async {
    try {
      final cacheKey = '${options.uri}';
      final cacheEntry = await storage.get(cacheKey);
      if (cacheEntry == null) return null;

      final Map<String, dynamic> decodedCache = jsonDecode(cacheEntry);
      final cachedTime = DateTime.tryParse(decodedCache[timeStampKey]);
      if (cachedTime == null) return null;

      final timeInterval = DateTime.now().difference(cachedTime);
      if (timeInterval > duration) {
        await storage.remove(cacheKey);
        return null;
      }

      return Response(
        requestOptions: options,
        data: decodedCache[dataKey],
        statusCode: 200,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveResponseToCache(Response response) async {
    final cacheKey = '${response.realUri}';
    final cacheEntry = jsonEncode({
      dataKey: response.data,
      timeStampKey: DateTime.now().toIso8601String(),
    });
    await storage.set(cacheKey, cacheEntry);
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final durationResolver = options.headers['X-Cache-Duration'];
    if (durationResolver is Duration) {
      // Skip cache completely if Duration is zero
      if (durationResolver == Duration.zero) {
        return handler.next(options);
      }
      final cached = await _getCachedResponse(
        options,
        duration: durationResolver,
      );
      if (cached != null) {
        return handler.resolve(cached);
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    await _saveResponseToCache(response);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err);
  }
}
