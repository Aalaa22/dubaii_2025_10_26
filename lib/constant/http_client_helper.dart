import 'dart:io';

class HttpClientHelper {
  static HttpClient? _httpClient;

  /// Get a custom HTTP client that bypasses SSL certificate verification
  /// This is for development purposes only and should not be used in production
  static HttpClient getHttpClient() {
    if (_httpClient == null) {
      _httpClient = HttpClient();
      // Bypass SSL certificate verification for development
      _httpClient!.badCertificateCallback = (X509Certificate cert, String host, int port) {
        // Log the certificate issue for debugging
        print('⚠️ SSL Certificate Warning for $host:$port');
        print('Certificate subject: ${cert.subject}');
        print('Certificate issuer: ${cert.issuer}');
        
        // Allow all certificates in development
        // In production, you should properly validate certificates
        return true;
      };
    }
    return _httpClient!;
  }

  /// Dispose the HTTP client
  static void dispose() {
    _httpClient?.close();
    _httpClient = null;
  }
}