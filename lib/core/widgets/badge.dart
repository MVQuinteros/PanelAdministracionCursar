import 'package:flutter/material.dart';

import '../theme/cursar_palette.dart';
import '../theme/tone.dart';

/// Reexportado para que los archivos que importan el badge tengan [Tone].
export '../theme/tone.dart';

/// Pill de estado, equivalente a `.badge` del CSS.
///
/// Se llama `StatusBadge` (y no `Badge`) para no chocar con el `Badge` de
/// Material 3, que está en `package:flutter/material.dart`.
///
/// Original: `padding 3px 9px`, `radius 999px`, `font-size 11.5px`, peso 600.
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.text, {super.key, this.tone = Tone.neutral});

  final String text;
  final Tone tone;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: tone.bg(p),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: tone.fg(p),
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
      ),
    );
  }
}
