class ApiConfig {
  ApiConfig._();

  /// Base URL for the InvenTrack API.
  /// Reads from the environment variable `INVENTRACK_API_URL` at compile time,
  /// falling back to `http://localhost:8000`.
  static const String baseUrl = String.fromEnvironment(
    'INVENTRACK_API_URL',
    defaultValue: 'http://localhost:8000',
  );

  /// Default timeout duration for HTTP requests.
  static const Duration timeout = Duration(seconds: 15);
}
