import 'dart:async';
import 'package:dio/dio.dart';
import 'package:simple_dio_cache_interceptor/simple_dio_cache_interceptor.dart';

// Custom in-memory storage
class InMemoryCacheStorage implements CacheStorage {
  final _store = <String, String>{};

  @override
  Future<String?> get(String key) async => _store[key];

  @override
  Future<void> set(String key, String value) async {
    _store[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _store.remove(key);
  }
}

void main() async {
  final dio = Dio();
  final storage = InMemoryCacheStorage();
  final cacheInterceptor = CacheInterceptor(storage);

  dio.interceptors.add(cacheInterceptor);

  const url = 'https://jsonplaceholder.typicode.com/todos/1';

  // --- First call: fetch from network and cache it
  final startTime1 = DateTime.now();
  final response1 = await dio.get(
    url,
    options: Options(headers: {
      'X-Cache-Duration': Duration(minutes: 10),
    }),
  );
  final endTime1 = DateTime.now();

  print('\n--- First network call ---');
  print('Data: ${response1.data}');
  print('Duration: ${endTime1.difference(startTime1).inMilliseconds}ms');

  // Simulate delay between requests
  await Future.delayed(Duration(seconds: 1));

  // --- Second call: should return cached response
  final startTime2 = DateTime.now();
  final response2 = await dio.get(
    url,
    options: Options(headers: {
      'X-Cache-Duration': Duration(minutes: 10),
    }),
  );
  final endTime2 = DateTime.now();

  print('\n--- Second call (from cache) ---');
  print('Data: ${response2.data}');
  print('Duration: ${endTime2.difference(startTime2).inMilliseconds}ms');

  // Simulate delay
  await Future.delayed(Duration(seconds: 1));

  // --- Third call: force bypass cache using Duration.zero
  final startTime3 = DateTime.now();
  final response3 = await dio.get(
    url,
    options: Options(headers: {
      'X-Cache-Duration': Duration.zero,
    }),
  );
  final endTime3 = DateTime.now();

  print('\n--- Third call (cache bypassed) ---');
  print('Data: ${response3.data}');
  print('Duration: ${endTime3.difference(startTime3).inMilliseconds}ms');

  // Simulate delay
  await Future.delayed(Duration(seconds: 1));

  // --- Fourth call: should return from newly cached response
  final startTime4 = DateTime.now();
  final response4 = await dio.get(
    url,
    options: Options(headers: {
      'X-Cache-Duration': Duration(minutes: 10),
    }),
  );
  final endTime4 = DateTime.now();

  print('\n--- Fourth call (new cache) ---');
  print('Data: ${response4.data}');
  print('Duration: ${endTime4.difference(startTime4).inMilliseconds}ms');
}
