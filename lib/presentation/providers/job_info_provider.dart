// lib/presentation/providers/job_info_provider.dart
import 'package:flutter/material.dart';
import 'package:advertising_app/data/web_services/api_service.dart';

class JobInfoProvider extends ChangeNotifier {
  final ApiService _apiService;

  JobInfoProvider() : _apiService = ApiService();

  bool _isLoading = false;
  String? _error;
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  List<String> _categoryTypes = [];
  List<String> _sectionTypes = [];
  Map<String, String> _categoryImages = {};

  List<String> get categoryTypes => _categoryTypes;
  List<String> get sectionTypes => _sectionTypes;
  Map<String, String> get categoryImages => _categoryImages;

  Future<void> fetchJobAdValues() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      print('🔍 Fetching job ad values from: /api/jobs_ad_values');
      // Public data - no token required for browsing job categories
      final response = await _apiService.get('/api/jobs_ad_values');
      
      print('📥 API Response type: ${response.runtimeType}');
      print('📥 API Response: $response');
      
      if (response is Map<String, dynamic>) {
        // Check if response has success and data structure
        if (response['success'] == true && response['data'] is List) {
          final dataList = response['data'] as List;
          
          for (var item in dataList) {
            if (item is Map<String, dynamic>) {
              final fieldName = item['field_name']?.toString();
              final options = item['options'];
              
              if (fieldName == 'category_type' && options is List) {
                _categoryTypes = options.map((option) => option.toString()).toList();
                print('📋 Category types loaded: ${_categoryTypes.length} items - $_categoryTypes');
              } else if (fieldName == 'section_type' && options is List) {
                _sectionTypes = options.map((option) => option.toString()).toList();
                print('📋 Section types loaded: ${_sectionTypes.length} items - $_sectionTypes');
              }
            }
          }
        } else {
          print('⚠️ API response missing success or data field');
          _error = 'Invalid API response structure';
        }
        
        // Check if we got the data we need
        if (_categoryTypes.isEmpty) {
          print('⚠️ No category types found in API response');
        }
        
        if (_sectionTypes.isEmpty) {
          print('⚠️ No section types found in API response');
        }
        
      } else {
        print('⚠️ Unexpected response format from API');
        _error = 'Invalid response format from server';
      }

      // جلب صور الفئات
      await _fetchCategoryImages();
      
    } catch (e) {
      _error = e.toString();
      print('❌ Error fetching job ad values: $e');
      
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchCategoryImages() async {
    try {
      print('🔍 Fetching job category images from: /api/job-category-images');
      // Public data - no token required for browsing job category images
      final response = await _apiService.get('/api/job-category-images');
      
      print('📥 Category Images Response: $response');
      
      if (response is Map<String, dynamic> && response['success'] == true && response['data'] is Map) {
        final Map<String, dynamic> data = response['data'];
        _categoryImages.clear();

        data.forEach((key, value) {
          if (value is Map && value.containsKey('image')) {
            _categoryImages[key] = value['image'];
          }
        });
        
        print('📋 Category images loaded: $_categoryImages');
      } else {
        print('⚠️ Failed to parse job category images');
      }
    } catch (e) {
      print('❌ Error fetching category images: $e');
    }
  }
}