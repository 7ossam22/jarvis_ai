enum AppEnvironment { testing, production }

class Env {
  static const AppEnvironment environment = AppEnvironment.testing;
  static const String n8nBaseUrl = 'https://unimmerged-ching-personably.ngrok-free.dev';
  static const String n8nWebHookUrl = environment == AppEnvironment.production? "/webhook/jarvis": "/webhook-test/jarvis";
  static bool get isProduction => environment == AppEnvironment.production;
  static bool get isTesting => environment == AppEnvironment.testing;
}
