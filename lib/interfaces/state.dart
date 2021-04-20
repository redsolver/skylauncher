class ServiceState {
  final String name;
  ServiceState({this.name, bool noInit = false}) {
    if (noInit) {
      isInitialized = true;
    }
  }

  bool isInitialized = false;

  void markInitialized() {
    isInitialized = true;
  }

  void checkInitialized() {
    if (!isInitialized) {
      throw '${name}Service is not initialized. Try calling ${name}Service.init() in your main.dart';
    }
  }
}
