import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:simple_dio_cache_interceptor/src/cache_interceptor.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'mock.dart';

void main() {
  late Dio dio;
  late DioAdapter dioAdapter;
  late MockCacheStorage mockStorage;
  late CacheInterceptor cacheInterceptor;

  const cacheKey = 'https://example.com/test';
  const fakeResponseData = {'message': 'hello world'};

  String nowMinus(Duration d) => DateTime.now().subtract(d).toIso8601String();

  setUp(() {
    mockStorage = MockCacheStorage();
    cacheInterceptor = CacheInterceptor(mockStorage);

    dio = Dio();
    dio.interceptors.add(cacheInterceptor);

    dioAdapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = dioAdapter;

    when(() => mockStorage.set(any(), any())).thenAnswer((_) async {});
  });

  test('should return cached response if not expired', () async {
    final timestamp = nowMinus(Duration(minutes: 5));
    final cacheData = jsonEncode({
      'data': fakeResponseData,
      'timestamp': timestamp,
    });

    when(() => mockStorage.get(any())).thenAnswer((_) async => cacheData);

    final response = await dio.get(
      cacheKey,
      options: Options(headers: {
        'X-Cache-Duration': const Duration(minutes: 10),
      }),
    );

    expect(response.data, fakeResponseData);
    expect(response.statusCode, 200);
    verify(() => mockStorage.get(any())).called(1);
  });

  test('should ignore cache if expired and call real endpoint', () async {
    final timestamp = nowMinus(Duration(days: 1));
    final cacheData = jsonEncode({
      'data': fakeResponseData,
      'timestamp': timestamp,
    });

    when(() => mockStorage.get(any())).thenAnswer((_) async => cacheData);
    when(() => mockStorage.remove(any())).thenAnswer((_) async {});

    dioAdapter.onGet(
      cacheKey,
      (request) => request.reply(200, {'message': 'fresh'}),
    );

    final response = await dio.get(
      cacheKey,
      options: Options(headers: {
        'X-Cache-Duration': const Duration(hours: 1),
      }),
    );

    expect(response.data['message'], 'fresh');
    expect(response.statusCode, 200);
    verify(() => mockStorage.get(any())).called(1);
    verify(() => mockStorage.remove(any())).called(1);
  });

  test('should cache fresh response if no cache is present', () async {
    when(() => mockStorage.get(any())).thenAnswer((_) async => null);
    when(() => mockStorage.set(any(), any())).thenAnswer((_) async {});

    dioAdapter.onGet(
      cacheKey,
      (request) => request.reply(200, fakeResponseData),
    );

    final response = await dio.get(
      cacheKey,
      options: Options(headers: {
        'X-Cache-Duration': const Duration(minutes: 5),
      }),
    );

    expect(response.data, fakeResponseData);
    expect(response.statusCode, 200);
    verify(() => mockStorage.get(any())).called(1);
    verify(() => mockStorage.set(any(), any())).called(1);
  });

  test('should bypass cache if Duration.zero is used', () async {
    when(() => mockStorage.get(any())).thenAnswer((_) async {
      throw Exception('Should not access cache');
    });

    dioAdapter.onGet(
      cacheKey,
      (request) => request.reply(200, {'message': 'no cache'}),
    );

    final response = await dio.get(
      cacheKey,
      options: Options(headers: {
        'X-Cache-Duration': Duration.zero,
      }),
    );

    expect(response.data['message'], 'no cache');
    expect(response.statusCode, 200);
  });
}
