import 'package:advertising_app/data/web_services/api_service.dart';
import 'package:intl/intl.dart';

class PackageStats {
  final int totalAds;
  final int balance;
  const PackageStats({required this.totalAds, required this.balance});

  PackageStats copyWith({int? totalAds, int? balance}) =>
      PackageStats(totalAds: totalAds ?? this.totalAds, balance: balance ?? this.balance);
}

class UserPackageSummary {
  final PackageStats premiumStar;
  final PackageStats premium;
  final PackageStats featured;
  final String? contractExpire; // formatted as dd/MM/yyyy

  const UserPackageSummary({
    required this.premiumStar,
    required this.premium,
    required this.featured,
    this.contractExpire,
  });

  bool get isAllZero =>
      premiumStar.totalAds == 0 && premiumStar.balance == 0 &&
      premium.totalAds == 0 && premium.balance == 0 &&
      featured.totalAds == 0 && featured.balance == 0;
}

class UserPackagesRepository {
  final ApiService _apiService;
  UserPackagesRepository(this._apiService);

  Future<UserPackageSummary?> fetchUserPackages({String? token}) async {
    final response = await _apiService.get('/api/user-packages', token: token);

    // Initialize accumulators
    int premiumStarTotal = 0, premiumStarBalance = 0;
    int premiumTotal = 0, premiumBalance = 0;
    int featuredTotal = 0, featuredBalance = 0;
    DateTime? maxExpire;

    // Helper to normalize type labels
    String normalizeType(String? t) {
      final s = (t ?? '').toLowerCase().trim();
      if (s.isEmpty) return '';
      if (s.contains('star')) return 'premium_star';
      if (s.contains('premium') && !s.contains('star')) return 'premium';
      if (s.contains('featured')) return 'featured';
      // common explicit types
      if (s == 'premium_star' || s == 'premium-star' || s == 'premium star') return 'premium_star';
      if (s == 'premium') return 'premium';
      if (s == 'featured') return 'featured';
      return s; // fallback
    }

    int readInt(dynamic obj, List<String> keys) {
      if (obj is Map<String, dynamic>) {
        for (final k in keys) {
          final v = obj[k];
          if (v is int) return v;
          if (v is String) {
            final parsed = int.tryParse(v);
            if (parsed != null) return parsed;
          }
        }
      }
      return 0;
    }

    DateTime? readDate(dynamic obj, List<String> keys) {
      if (obj is Map<String, dynamic>) {
        for (final k in keys) {
          final v = obj[k];
          if (v is String && v.isNotEmpty) {
            try {
              // Try common formats
              return DateTime.parse(v);
            } catch (_) {
              continue;
            }
          }
        }
      }
      return null;
    }

    void accumulate(String type, int totalAds, int balance, DateTime? expire) {
      switch (type) {
        case 'premium_star':
          premiumStarTotal += totalAds;
          premiumStarBalance += balance;
          break;
        case 'premium':
          premiumTotal += totalAds;
          premiumBalance += balance;
          break;
        case 'featured':
          featuredTotal += totalAds;
          featuredBalance += balance;
          break;
      }
      if (expire != null) {
        if (maxExpire == null || expire.isAfter(maxExpire!)) {
          maxExpire = expire;
        }
      }
    }

    // Parse response shapes
    if (response is List) {
      if (response.isEmpty) return null; // empty -> hide table
      for (final item in response) {
        if (item is Map<String, dynamic>) {
          // Prefer nested 'details' map if present
          final expire = readDate(item, ['expire_date', 'contract_expires_at', 'expires_at', 'plan_expires_at', 'end_date']);
          if (item['details'] is Map<String, dynamic>) {
            final details = item['details'] as Map<String, dynamic>;
            for (final key in ['premium_star', 'premium', 'featured']) {
              final section = details[key];
              if (section is Map<String, dynamic>) {
                final totalAds = readInt(section, ['total_ads', 'total', 'ads_total', 'quota', 'allowed_ads']);
                final balance = readInt(section, ['balance', 'remaining', 'left', 'available', 'remaining_ads']);
                accumulate(key, totalAds, balance, expire);
              }
            }
          } else {
            // Fallback to flat item with type fields
            final type = normalizeType(
                item['type'] ?? item['plan_type'] ?? item['package_type'] ?? item['name'] ?? item['plan_name']);
            final totalAds = readInt(item, ['total_ads', 'total', 'ads_total', 'quota', 'allowed_ads']);
            final balance = readInt(item, ['balance', 'remaining', 'left', 'available', 'remaining_ads']);
            accumulate(type, totalAds, balance, expire);
          }
        }
      }
    } else if (response is Map<String, dynamic>) {
      // Could be { data: [...] } or direct keyed object
      if (response['data'] is List) {
        final list = response['data'] as List;
        if (list.isEmpty) return null;
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            // Prefer nested 'details' map as per expected API response
            final expire = readDate(item, ['expire_date', 'contract_expires_at', 'expires_at', 'plan_expires_at', 'end_date']);
            if (item['details'] is Map<String, dynamic>) {
              final details = item['details'] as Map<String, dynamic>;
              for (final key in ['premium_star', 'premium', 'featured']) {
                final section = details[key];
                if (section is Map<String, dynamic>) {
                  final totalAds = readInt(section, ['total_ads', 'total', 'ads_total', 'quota', 'allowed_ads']);
                  final balance = readInt(section, ['balance', 'remaining', 'left', 'available', 'remaining_ads']);
                  accumulate(key, totalAds, balance, expire);
                }
              }
            } else {
              // Fallback to flat item with type fields
              final type = normalizeType(
                  item['type'] ?? item['plan_type'] ?? item['package_type'] ?? item['name'] ?? item['plan_name']);
              final totalAds = readInt(item, ['total_ads', 'total', 'ads_total', 'quota', 'allowed_ads']);
              final balance = readInt(item, ['balance', 'remaining', 'left', 'available', 'remaining_ads']);
              accumulate(type, totalAds, balance, expire);
            }
          }
        }
      } else {
        // Keyed by types
        for (final key in ['premium_star', 'premium', 'featured']) {
          final section = response[key];
          if (section is Map<String, dynamic>) {
            final totalAds = readInt(section, ['total_ads', 'total', 'ads_total', 'quota', 'allowed_ads']);
            final balance = readInt(section, ['balance', 'remaining', 'left', 'available', 'remaining_ads']);
            final expire = readDate(section, ['expire_date', 'contract_expires_at', 'expires_at', 'plan_expires_at', 'end_date']);
            accumulate(key, totalAds, balance, expire);
          }
        }
      }
    } else {
      // Unexpected shape; return null to hide table rather than crash
      return null;
    }

    final summary = UserPackageSummary(
      premiumStar: PackageStats(totalAds: premiumStarTotal, balance: premiumStarBalance),
      premium: PackageStats(totalAds: premiumTotal, balance: premiumBalance),
      featured: PackageStats(totalAds: featuredTotal, balance: featuredBalance),
      contractExpire: maxExpire != null ? DateFormat('dd/MM/yyyy').format(maxExpire!) : null,
    );

    // If all counts zero and no expiry, consider it empty
    if (summary.isAllZero && maxExpire == null) return null;
    return summary;
  }
}