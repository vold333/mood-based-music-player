import 'package:flutter/material.dart';

import '../../app/theme/soul_tokens.dart';

/// Text field decoration for fields that sit on a solid sheet or dialog
/// (category name, category filter): a soft ocean fill, a clear outline and a
/// Soul Purple outline while focused.
///
/// The All Songs search field does not use this; it sits inside a glass pill.
InputDecoration glassFieldDecoration(
  BuildContext context, {
  String? labelText,
  String? hintText,
  Widget? prefixIcon,
  bool isDense = false,
}) {
  final scheme = Theme.of(context).colorScheme;

  OutlineInputBorder border(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    hintStyle: TextStyle(color: scheme.onSurfaceVariant),
    prefixIcon: prefixIcon,
    isDense: isDense,
    filled: true,
    fillColor: scheme.surface,
    border: border(scheme.outline, 1),
    enabledBorder: border(scheme.outline, 1),
    focusedBorder: border(context.soul.accentText, 2),
  );
}