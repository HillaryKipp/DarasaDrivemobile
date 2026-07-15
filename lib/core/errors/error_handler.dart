import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'app_exception.dart';

String getErrorMessage(Object? error) {
  if (error == null) return 'An unknown error occurred';

  if (error is AppException) {
    return error.message;
  }

  if (error is SocketException) {
    return 'No internet connection. Please check your network settings.';
  }

  if (error is http.ClientException) {
    if (error.message.contains('Failed host lookup')) {
      return 'No internet connection. Please check your network settings.';
    }
    return 'Network error: ${error.message}';
  }

  if (error is TimeoutException) {
    return 'Connection timed out. Please try again.';
  }

  if (error is PostgrestException) {
    // Handle common Supabase DB errors
    if (error.code == '42P01') return 'Database table not found.';
    if (error.code == '23505') return 'This record already exists.';
    return error.message;
  }

  if (error is AuthException) {
    return error.message;
  }

  if (error is FormatException) {
    return 'Received invalid data from the server.';
  }

  if (error is HttpException) {
    return 'Server error occurred. Please try again later.';
  }

  // Fallback for string errors or unknown objects
  final errorStr = error.toString();
  if (errorStr.contains('SocketException') || errorStr.contains('Failed host lookup')) {
    return 'No internet connection. Please check your network settings.';
  }

  return 'Something went wrong. Please try again.';
}
