import 'package:dio/dio.dart';

import '../core/samseer_core.dart';
import '../model/http_call.dart';
import '../model/http_error.dart';
import '../model/http_request.dart';
import '../model/http_response.dart';

const String _kSamseerIdKey = '__samseer_id';

/// Dio [Interceptor] that records every request, response, and error to the
/// shared Samseer storage.
class SamseerDioInterceptor extends Interceptor {
  SamseerDioInterceptor(this._core);

  final SamseerCore _core;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final id = _core.nextId();
    options.extra[_kSamseerIdKey] = id;
    final call = SamseerHttpCall(
      id: id,
      method: options.method.toUpperCase(),
      uri: options.uri.toString(),
      endpoint: options.uri.path.isEmpty ? '/' : options.uri.path,
      server: options.uri.host,
      secure: options.uri.scheme == 'https',
      client: 'Dio',
      createdAt: DateTime.now(),
      request: SamseerHttpRequest(
        time: DateTime.now(),
        headers: Map<String, dynamic>.from(options.headers),
        queryParameters: Map<String, dynamic>.from(options.queryParameters),
        body: options.data,
        contentType: options.contentType,
        size: _estimateSize(options.data),
      ),
    );
    _core.addCall(call);
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final id = response.requestOptions.extra[_kSamseerIdKey] as int?;
    if (id != null) {
      _core.addResponse(
        id,
        SamseerHttpResponse(
          status: response.statusCode ?? 0,
          time: DateTime.now(),
          headers: _flattenHeaders(response.headers.map),
          body: response.data,
          size: _estimateSize(response.data),
        ),
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final id = err.requestOptions.extra[_kSamseerIdKey] as int?;
    if (id != null) {
      if (err.response != null) {
        _core.addResponse(
          id,
          SamseerHttpResponse(
            status: err.response!.statusCode ?? 0,
            time: DateTime.now(),
            headers: _flattenHeaders(err.response!.headers.map),
            body: err.response!.data,
            size: _estimateSize(err.response!.data),
          ),
        );
      }
      _core.addError(
        id,
        SamseerHttpError(
          message: err.message,
          error: err.error,
          stackTrace: err.stackTrace,
        ),
      );
    }
    handler.next(err);
  }

  static Map<String, dynamic> _flattenHeaders(Map<String, List<String>> headers) {
    return headers.map((k, v) => MapEntry(k, v.length == 1 ? v.first : v));
  }

  static int? _estimateSize(dynamic data) {
    if (data == null) return null;
    if (data is String) return data.length;
    if (data is List<int>) return data.length;
    if (data is Map || data is List) {
      try {
        return data.toString().length;
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
