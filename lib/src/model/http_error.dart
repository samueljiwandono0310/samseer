import 'package:flutter/foundation.dart';

@immutable
class SamseerHttpError {
  const SamseerHttpError({
    this.message,
    this.error,
    this.stackTrace,
  });

  final String? message;
  final Object? error;
  final StackTrace? stackTrace;

  Map<String, dynamic> toJson() => {
        'message': message,
        'error': error?.toString(),
        'stackTrace': stackTrace?.toString(),
      };
}
