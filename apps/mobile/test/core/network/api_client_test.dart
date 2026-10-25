import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medliva/core/network/api_client.dart';
import 'package:medliva/core/storage/token_storage.dart';
import 'package:mocktail/mocktail.dart';

class MockTokenStorage extends Mock implements TokenStorage;

class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter(this._handler);

  final Future<ResponseBody> Function(RequestOptions options) _handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(Map<String, dynamic> body, int statusCode) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  late MockTokenStorage tokenStorage;

  setUp(() {
    tokenStorage = MockTokenStorage();
  });

  group('ApiClient interceptor', () {
    test(
      '401 renews the Supabase session once and retries the request',
      () async {
        var currentAccess = 'expired_access';
        when(() => tokenStorage.getAccessToken())
            .thenAnswer((_) async => currentAccess);
        when(() => tokenStorage.refreshAccessToken()).thenAnswer((_) async {
          currentAccess = 'new_access';
          return 'new_access';
        });

        var mainCallCount = 0;
        var unauthorizedCalled = false;

        final mainDio =
            Dio(BaseOptions(baseUrl: 'http://localhost:8000/api/v1'))
              ..httpClientAdapter = _FakeHttpClientAdapter((options) async {
                mainCallCount++;
                if (mainCallCount == 1) {
                  expect(
                    options.headers['Authorization'],
                    'Bearer expired_access',
                  );
                  return _jsonResponse({
                    'error': {
                      'code': 'UNAUTHORIZED',
                      'message': 'Token expired',
                    },
                  }, 401);
                }
                expect(options.headers['Authorization'], 'Bearer new_access');
                return _jsonResponse({
                  'id': 'u1',
                  'phone': '+201012345678',
                }, 200);
              });

        final client = ApiClient(
          tokenStorage: tokenStorage,
          dio: mainDio,
          onUnauthorized: () async {
            unauthorizedCalled = true;
          },
        );

        final response = await client.dio.get<Map<String, dynamic>>('/me');

        expect(response.statusCode, 200);
        expect(response.data?['id'], 'u1');
        expect(mainCallCount, 2);
        expect(unauthorizedCalled, isFalse);
        verify(() => tokenStorage.refreshAccessToken()).called(1);
      },
    );

    test(
      'session renewal failure clears the local session and calls logout',
      () async {
        when(() => tokenStorage.getAccessToken())
            .thenAnswer((_) async => 'expired_access');
        when(() => tokenStorage.refreshAccessToken())
            .thenThrow(Exception('session expired'));
        when(() => tokenStorage.clearTokens()).thenAnswer((_) async {});

        var unauthorizedCalled = false;

        final mainDio =
            Dio(BaseOptions(baseUrl: 'http://localhost:8000/api/v1'))
              ..httpClientAdapter = _FakeHttpClientAdapter((options) async {
                return _jsonResponse({
                  'error': {
                    'code': 'UNAUTHORIZED',
                    'message': 'Session expired',
                  },
                }, 401);
              });

        final client = ApiClient(
          tokenStorage: tokenStorage,
          dio: mainDio,
          onUnauthorized: () async {
            unauthorizedCalled = true;
          },
        );

        await expectLater(
          () => client.dio.get<Map<String, dynamic>>('/me'),
          throwsA(
            isA<DioException>().having(
              (e) => e.error,
              'error',
              isA<ApiException>()
                  .having((a) => a.statusCode, 'statusCode', 401)
                  .having((a) => a.code, 'code', 'UNAUTHORIZED')
                  .having((a) => a.message, 'message', 'Session expired'),
            ),
          ),
        );

        expect(unauthorizedCalled, isTrue);
        verify(() => tokenStorage.clearTokens()).called(1);
      },
    );
  });
}
