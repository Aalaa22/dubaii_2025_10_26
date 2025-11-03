class SmartSearchItem {
  final String itemType;
  final int totalAds;

  SmartSearchItem({required this.itemType, required this.totalAds});

  factory SmartSearchItem.fromJson(Map<String, dynamic> json) {
    return SmartSearchItem(
      itemType: (json['item_type'] ?? json['type'] ?? '').toString(),
      totalAds: int.tryParse((json['total_ads'] ?? json['count'] ?? 0).toString()) ?? 0,
    );
  }
}

class SmartSearchResponse {
  final String keyword;
  final List<SmartSearchItem> results;

  SmartSearchResponse({required this.keyword, required this.results});

  factory SmartSearchResponse.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      final rawResults = json['results'];
      final List<SmartSearchItem> items =
          rawResults is List ? rawResults.map((e) => SmartSearchItem.fromJson(e as Map<String, dynamic>)).toList() : [];
      return SmartSearchResponse(
        keyword: (json['keyword'] ?? '').toString(),
        results: items,
      );
    }
    // Fallback for unexpected format
    return SmartSearchResponse(keyword: '', results: const []);
  }
}