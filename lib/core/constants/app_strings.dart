class AppStrings {
  static const appName = 'J.A.R.V.I.S';
  static const appSubtitle = 'Just A Rather Very Intelligent System';

  static const wakeWord = 'jarvis';

  static const processingMessages = [
    'Still processing your request, sir.',
    'Working on it, give me a moment sir.',
    'Running calculations, sir.',
    'I am on it, sir. Please stand by.',
    'Processing in progress, sir.',
    'Almost there, sir.',
    'My systems are engaged, sir.',
  ];

  static const idleGreeting = 'At your service, sir.';
  static const listeningPrompt = 'Listening...';
  static const thinkingPrompt = 'Processing...';
  static const speakingPrompt = 'Speaking...';
  static const errorMessage = 'I encountered an issue, sir. Please try again.';
  static const connectionError =
      'Cannot reach the command center, sir. Check your n8n connection.';
  static const settingsTitle = 'System Configuration';
  static const n8nUrlHint = 'n8n Base URL (e.g. http://192.168.1.100:5678)';
  static const webhookPathHint = 'Webhook Path (e.g. /webhook/jarvis)';
  static const apiKeyHint = 'API Key (optional)';
}
