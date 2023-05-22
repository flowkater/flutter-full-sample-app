import 'package:actual/common/const/data.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CustomInterceptor extends Interceptor {
  final FlutterSecureStorage storage;

  CustomInterceptor({required this.storage});

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    print('[REQUEST] [${options.method}] ${options.uri}');

    if (options.headers['accessToken'] == 'true') {
      options.headers.remove('accessToken');

      final token = await storage.read(key: ACCESS_TOKEN_KEY);

      options.headers.addAll({
        'Authorization': 'Bearer $token',
      });
    }

    if (options.headers['refreshToken'] == 'true') {
      options.headers.remove('refreshToken');

      final token = await storage.read(key: REFRESH_TOKEN_KEY);

      options.headers.addAll({
        'Authorization': 'Bearer $token',
      });
    }

    super.onRequest(options, handler);
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) async {
    // 401 에러가 났을때
    // 토큰을 재발급 받는 시도를 하고 토큰이 재발급되면
    // 다시 새로운 토큰을 요청한다.
    print('[ERROR] [${err.requestOptions.method}] ${err.requestOptions.uri}');

    final refreshToken = await storage.read(key: REFRESH_TOKEN_KEY);

    if (refreshToken == null) {
      return handler.reject(err);
    }

    final isStatus401 = err.response?.statusCode == 401;
    final isPathRefresh = err.requestOptions.path == '/auth/token';

    // 토큰 재발급 요청이 아니고 401 에러가 났을때
    if (isStatus401 && !isPathRefresh) {
      final dio = Dio();

      try {
        final resp = await dio.post(
          '$hostIp/auth/token',
          options: Options(headers: {
            'Authorization': 'Bearer $refreshToken',
          }),
        );

        final accessToken = resp.data['accessToken'];

        final options = err.requestOptions;

        options.headers.addAll({
          'Authorization': 'Bearer $accessToken',
        });

        await storage.write(key: ACCESS_TOKEN_KEY, value: accessToken);

        final response = await dio.fetch(options);

        return handler.resolve(response);
      } on DioError catch (e) {
        return handler.reject(e);
      }
    }

    return handler.reject(err);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print(
        '[RESPONSE] [${response.requestOptions.method}] ${response.requestOptions.uri}');

    super.onResponse(response, handler);
  }
}
