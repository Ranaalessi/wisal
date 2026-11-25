// Server address is set at build time so it is not stored in the source code.
// Example: flutter run --dart-define=WISAL_SERVER_URL=http://<your-server>:5000
const String wesalServerBaseUrl = String.fromEnvironment(
  'WISAL_SERVER_URL',
  defaultValue: 'http://localhost:5000',
);

final String wesalWebSocketUrl =
    '${wesalServerBaseUrl.replaceFirst('http', 'ws')}/ws/sign_language/';