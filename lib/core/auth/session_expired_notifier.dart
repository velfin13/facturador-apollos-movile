import 'dart:async';

import 'package:injectable/injectable.dart';

/// Notifica a la app cuando la sesión expiró y no pudo refrescarse.
/// El interceptor de Dio lo llama; la app escucha para forzar logout.
@lazySingleton
class SessionExpiredNotifier {
  final _controller = StreamController<void>.broadcast();

  Stream<void> get onSessionExpired => _controller.stream;

  void notify() {
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }

  @disposeMethod
  void dispose() {
    _controller.close();
  }
}
