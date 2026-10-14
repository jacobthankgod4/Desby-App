/// Non-web stub. Every operation is a no-op.
String readUrlHash() => '';

String getUrlPath() => '/';

void replaceUrlHash(String hash) {}

void pushUrlHash(String hash) {}

void listenToPopState(void Function(String hash) onPop) {}
