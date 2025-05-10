# Dio Cache Interceptor

This repository demonstrates how to use a custom cache interceptor with the [Dio](https://pub.dev/packages/dio) package to cache HTTP responses in memory. It includes an example of how to configure a Dio instance to cache responses for a specified duration and bypass the cache when necessary.

## Features

- **Custom Cache Storage**: An in-memory storage for caching the responses.
- **Cache Expiration**: Cached responses are only returned if they haven't expired, as specified by the duration.
- **Cache Bypass**: Allows for bypassing the cache with a zero-duration setting.
- **Easy Integration with Dio**: Simple setup for caching HTTP requests using Dio interceptors.

## Components

### 1. `example/dio_cache_interceptor_example.dart`

This is the main entry point that demonstrates how to use the cache interceptor with Dio.

- It makes multiple HTTP requests to the same URL.
- The first request fetches data from the network and caches it.
- The second request returns the cached response.
- The third request forces a bypass of the cache.
- The fourth request demonstrates fetching the data again from the cache after bypassing.

### 2. `lib/src/cache_interceptor.dart`

This file contains the implementation of the `CacheInterceptor`, which intercepts the HTTP requests and manages caching logic.

- **`_getCachedResponse`**: Retrieves the cached response if it's available and not expired.
- **`_saveResponseToCache`**: Saves the HTTP response to the cache storage.
- **`onRequest`**: Checks if a cached response is available before making a network request.
- **`onResponse`**: Saves the response to the cache after a successful request.
- **`onError`**: Handles errors in the request lifecycle.

### 3. `InMemoryCacheStorage` Class

A simple custom cache storage implementation that keeps cached responses in memory (using a `Map<String, String>`). This class implements the `CacheStorage` interface, allowing for storing, retrieving, and removing cached responses.

## Installation

1. **Add Dio and Dio Cache Interceptor to your `pubspec.yaml`**:

   ```yaml
   dependencies:
     dio: ^5.0.0
     simple_dio_cache_interceptor: ^1.0.0
   ```

2. **Install dependencies**:

   Run the following command to install the dependencies:

   ```bash
   flutter pub get
   ```

## Usage

1. **Import necessary packages**:

   ```dart
   import 'package:dio/dio.dart';
   import 'package:simple_dio_cache_interceptor/simple_dio_cache_interceptor.dart';
   ```

2. **Create the Dio instance with the cache interceptor**:

   ```dart
   final dio = Dio();
   final storage = InMemoryCacheStorage();
   final cacheInterceptor = CacheInterceptor(storage);
   dio.interceptors.add(cacheInterceptor);
   ```

3. **Make HTTP requests**:

   You can now make HTTP requests with caching enabled. The `X-Cache-Duration` header determines how long the cache is valid for.

   ```dart
   final response = await dio.get(
     'https://jsonplaceholder.typicode.com/todos/1',
     options: Options(
       headers: {'X-Cache-Duration': Duration(minutes: 10)},
     ),
   );
   ```

4. **Simulate Cache Bypass**:

   To bypass the cache for a request, set the `X-Cache-Duration` header to `Duration.zero`.

   ```dart
   final response = await dio.get(
     'https://jsonplaceholder.typicode.com/todos/1',
     options: Options(
       headers: {'X-Cache-Duration': Duration.zero},
     ),
   );
   ```

## Example Output

```
--- First network call ---
Data: {userId: 1, id: 1, title: "delectus aut autem", completed: false}
Duration: 100ms

--- Second call (from cache) ---
Data: {userId: 1, id: 1, title: "delectus aut autem", completed: false}
Duration: 10ms

--- Third call (cache bypassed) ---
Data: {userId: 1, id: 1, title: "delectus aut autem", completed: false}
Duration: 110ms

--- Fourth call (new cache) ---
Data: {userId: 1, id: 1, title: "delectus aut autem", completed: false}
Duration: 100ms
```

## How it works

- **Cache Duration**: When the `X-Cache-Duration` header is set in a request, the cache will only return the response if it hasn't expired based on the given duration.
- **Cache Bypass**: Setting the `X-Cache-Duration` to `Duration.zero` forces the request to bypass the cache and always fetch the data from the network.
- **In-Memory Cache**: The cache is stored in memory and will be lost when the app is closed. You can replace `InMemoryCacheStorage` with another storage solution, such as SQLite or SharedPreferences, for persistent caching.

## Note

This example demonstrates a basic cache usage. If you need more advanced control over your request caching, such as controlling cache strategies, automatic cache expiration, or additional features, check out [dio_cache_interceptor](https://pub.dev/packages/dio_cache_interceptor).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
