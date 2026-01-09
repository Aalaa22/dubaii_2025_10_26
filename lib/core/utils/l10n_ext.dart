import 'package:flutter/widgets.dart';
import '../../generated/l10n.dart';

/// Extension to simplify accessing localization in the app.
///
/// Instead of writing `S.of(context)!` everywhere,
/// you can now use `context.l10n` which is much cleaner.
///
/// Example:
/// ```dart
/// // Old way:
/// Text(S.of(context)!.back)
///
/// // New way:
/// Text(context.l10n.back)
/// ```
extension LocalizationContext on BuildContext {
  S get l10n => S.of(this);
}
