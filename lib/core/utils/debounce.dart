import 'dart:async';

/// Debounce simple para inputs de búsqueda (mismo comportamiento que el
/// `debounce(fn, 200)` del CRUD original).
Debouncer debounce(Duration wait, void Function() fn) => Debouncer(wait, fn);

class Debouncer {
  Debouncer(this.wait, this._fn);

  final Duration wait;
  final void Function() _fn;
  Timer? _timer;

  void call() {
    _timer?.cancel();
    _timer = Timer(wait, _fn);
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
