# استخدام الـ Localization Extension

## كيفية الاستخدام

### الطريقة القديمة (Verbose):
```dart
import 'package:flutter/material.dart';
import '../generated/l10n.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = S.of(context)!;
    
    return Column(
      children: [
        Text(s.back),
        Text(s.home),
        Text(s.login),
      ],
    );
  }
}
```

### الطريقة الجديدة (Clean & Simple):
```dart
import 'package:flutter/material.dart';
import '../core/utils/l10n_ext.dart'; // استيراد الـ Extension

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(context.l10n.back),
        Text(context.l10n.home),
        Text(context.l10n.login),
      ],
    );
  }
}
```

## المميزات:

1. **أقصر وأنظف**: `context.l10n` بدلاً من `S.of(context)!`
2. **أكثر أماناً**: مش محتاج `!` (null assertion)
3. **سهل القراءة**: الكود بيبقى أكثر وضوحاً
4. **متوافق مع الكود القديم**: ممكن تستخدم الاتنين مع بعض

## مثال عملي من المشروع:

```dart
// قبل:
Text(S.of(context)!.errorLabel(authProvider.profileError ?? ''))

// بعد:
import '../core/utils/l10n_ext.dart';
Text(context.l10n.errorLabel(authProvider.profileError ?? ''))
```

## نصيحة للفريق:

اعملوا import للـ Extension في كل ملف هتستخدموا فيه الترجمة، وابدأوا استخدام `context.l10n` 
بدلاً من `S.of(context)` في كل الكود الجديد!
