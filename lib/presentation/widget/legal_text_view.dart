import 'package:flutter/material.dart';

enum LegalContentType { terms, privacy }

class LegalTextView extends StatelessWidget {
  final LegalContentType type;
  const LegalTextView({super.key, required this.type});

  static Future<void> show(BuildContext context, LegalContentType type) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LegalTextView(type: type)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final String title = switch (type) {
      LegalContentType.terms => isArabic ? 'الشروط والأحكام' : 'Terms & Conditions',
      LegalContentType.privacy => isArabic ? 'الخصوصية والأمان' : 'Privacy & Security',
    };

    final String content = switch (type) {
      LegalContentType.terms => isArabic ? _termsAr : _termsEn,
      LegalContentType.privacy => isArabic ? _privacyAr : _privacyEn,
    };

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Text(
                content,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const String _termsEn = '''
Welcome to DubiSale. These Terms & Conditions govern your use of the app. By using DubiSale, you agree to the following:

1) Use of Service: DubiSale provides a marketplace to browse, post, and manage listings. You are responsible for the content you submit and its accuracy.
2) Accounts & Security: Keep your login credentials secure. You are responsible for activity under your account.
3) Content Guidelines: Do not post illegal, misleading, harmful, or infringing content. We may remove content that violates policies.
4) Payments: If applicable, paid features or packages are processed via secure channels. Refunds follow the policy stated within the app.
5) Location & Data: Some features may use your location and profile data to improve relevance. See Privacy for details.
6) Prohibited Use: No spamming, scraping, reverse engineering, or misuse of the platform.
7) Liability: DubiSale is not liable for user-generated content or transactions between users; always verify before purchase.
8) Changes: We may update these terms. Continued use means you accept the updated terms.
9) Contact: For support or policy inquiries, use the Contact Us section in Settings.

By continuing, you confirm that you have read and agree to these terms.''';

const String _termsAr = '''
مرحبًا بك في DubiSale. تُنظِّم هذه الشروط والأحكام استخدامك للتطبيق. باستخدامك للتطبيق فإنك توافق على ما يلي:

1) استخدام الخدمة: يوفّر DubiSale سوقًا لعرض الإعلانات وتصفحها وإدارتها. أنت مسؤول عن دقة المحتوى الذي تُقدّمه.
2) الحساب والأمان: احفظ بيانات دخولك بأمان. أنت مسؤول عن أي نشاط يتم عبر حسابك.
3) سياسات المحتوى: يُمنع نشر محتوى مخالف أو مضلّل أو مضرّ أو منتهك للحقوق. قد نحذف أي محتوى يخالف السياسات.
4) المدفوعات: إن وُجدت ميزات مدفوعة، تُعالَج المدفوعات عبر قنوات آمنة. تُطبّق سياسة الاسترجاع الموضّحة داخل التطبيق.
5) الموقع والبيانات: قد تستخدم بعض الميزات موقعك وبيانات ملفك لتحسين التجربة. راجع سياسة الخصوصية للتفاصيل.
6) الاستخدام المحظور: يُمنع الإزعاج (Spam) أو جمع البيانات أو محاولة الهندسة العكسية أو إساءة استخدام المنصة.
7) المسؤولية: لا يتحمّل DubiSale مسؤولية المحتوى المُنشأ من المستخدمين أو المعاملات بينهم؛ تحقّق دائمًا قبل الشراء.
8) التغييرات: قد نقوم بتحديث هذه الشروط. استمرارك في الاستخدام يعني قبولك للتحديثات.
9) التواصل: لأي استفسار أو دعم، استخدم قسم "تواصل معنا" ضمن الإعدادات.

باستمرار الاستخدام، فأنت تؤكد أنك قرأت هذه الشروط ووافقت عليها.''';

const String _privacyEn = '''
Privacy & Security Policy

• Data We Collect: Basic profile information (e.g., name, phone), optional location data, and usage analytics to improve your experience.
• How We Use Data: To authenticate, personalize listings, enable contact between buyers and sellers, and maintain platform security.
• Location: If enabled, your location helps surface nearby results. You can disable location at any time.
• Storage & Security: We use secure storage and encryption where appropriate. Your token should be kept confidential.
• Sharing: We do not sell your personal data. Limited sharing may occur to deliver core functionality (e.g., maps, messaging), subject to their policies.
• Your Choices: You can update or delete profile data, and revoke permissions (like location) from system settings.
• Changes: We may update this policy. Continued use constitutes acceptance of any changes.

For questions, please use the Contact Us section in Settings.''';

const String _privacyAr = '''
سياسة الخصوصية والأمان

• البيانات التي نجمعها: معلومات أساسية من الملف الشخصي (مثل الاسم والهاتف)، بيانات الموقع اختيارياً، وتحليلات استخدام لتحسين تجربتك.
• كيفية استخدام البيانات: للمصادقة، وتخصيص النتائج، وتمكين التواصل بين البائع والمشتري، والحفاظ على أمان المنصة.
• الموقع: إذا تم تفعيله، يساعد موقعك في عرض النتائج القريبة. يمكنك إيقافه في أي وقت.
• التخزين والأمان: نستخدم التخزين الآمن والتشفير عند الحاجة. ينبغي الحفاظ على سرية رمز الدخول (Token).
• المشاركة: لا نقوم ببيع بياناتك الشخصية. قد تتم مشاركة محدودة لتقديم وظائف أساسية (مثل الخرائط والرسائل) وفقًا لسياسات مزوّدي الخدمات.
• خياراتك: يمكنك تحديث أو حذف بيانات ملفك، وإلغاء الأذونات (مثل الموقع) من إعدادات النظام.
• التغييرات: قد نقوم بتحديث هذه السياسة. استمرار الاستخدام يعني قبولك لأي تغييرات.

للاستفسارات، يُرجى استخدام قسم "تواصل معنا" ضمن الإعدادات.''';