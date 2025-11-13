import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class CustomHttpClient {
  static http.Client getClient() {
    HttpClient httpClient = HttpClient()
      ..badCertificateCallback = 
          ((X509Certificate cert, String host, int port) => true)
      ..connectionTimeout = const Duration(seconds: 30);
    
    return IOClient(httpClient);
  }
}