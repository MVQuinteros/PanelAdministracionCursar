import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/cursar_palette.dart';

/// Toast del panel: aparece abajo a la derecha, se va solo a los 4.2 s.
///
/// Reemplaza a `js/views/notify.js::toast`, que apilaba divs en
/// `#toast-region` (`.toast { position: fixed; right: 20px; bottom: 20px }`).
///
/// No se usa `SnackBar` porque `width` y `margin` son excluyentes entre sí
/// (`assert(width == null || margin == null)`), y el panel lo quiere anclado a
/// la derecha en todo momento. Con `Overlay` el anclaje es libre.
void toast(
  BuildContext context,
  String message, {
  ToastKind kind = ToastKind.info,
}) {
  // Se usa el overlay raíz: así el toast no desaparece al navegar (el de la
  // ruta saliente se desarma con ella).
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  final previous = _active;
  if (previous != null && previous.mounted) previous.remove();

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _ToastCard(
      message: message,
      kind: kind,
      onFinished: () {
        if (entry.mounted) entry.remove();
        if (identical(_active, entry)) _active = null;
      },
    ),
  );
  _active = entry;
  overlay.insert(entry);
}

/// Último toast vivo. Un panel como este muestra uno a la vez, igual que el
/// `hideCurrentSnackBar()` que hacía antes.
OverlayEntry? _active;

enum ToastKind { success, error, info }

class _ToastCard extends StatefulWidget {
  const _ToastCard({
    required this.message,
    required this.kind,
    required this.onFinished,
  });

  final String message;
  final ToastKind kind;

  /// Se dispara cuando terminó la animación de salida.
  final VoidCallback onFinished;

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard>
    with SingleTickerProviderStateMixin {
  static const _visibleFor = Duration(milliseconds: 4200);

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
    reverseDuration: const Duration(milliseconds: 140),
  );
  Timer? _timer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _c.forward();
    _timer = Timer(_visibleFor, _hide);
  }

  void _hide() {
    if (_closing) return;
    _closing = true;
    _timer?.cancel();
    _c.reverse().whenComplete(widget.onFinished);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (Color dot, Color border) = switch (widget.kind) {
      ToastKind.success => (p.success, p.success.withValues(alpha: 0.55)),
      ToastKind.error => (p.danger, p.danger.withValues(alpha: 0.55)),
      ToastKind.info => (p.accent, p.accent.withValues(alpha: 0.55)),
    };

    final curve = CurvedAnimation(
      parent: _c,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return Positioned(
      right: 20,
      // Por debajo del notch en mobile, como el `bottom: 20px` del CSS.
      bottom: 20 + MediaQuery.viewPaddingOf(context).bottom,
      // `320` a pelo se sale por la izquierda en pantallas de menos de 340px
      // (`right: 20` + `width: 320` = 340): el `Positioned` no recorta, deja la
      // tarjeta en `left: -20` y se come el punto de color y el borde. Se
      // clampa al ancho disponible menos los dos `right`.
      width: math.min(320, MediaQuery.sizeOf(context).width - 40),
      child: FadeTransition(
        opacity: curve,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.28),
            end: Offset.zero,
          ).animate(curve),
          child: GestureDetector(
            onTap: _hide,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: p.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: border),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: p.bgMain.withValues(alpha: 0.4),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: TextStyle(color: p.textPrimary, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
