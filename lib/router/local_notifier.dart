import 'package:flutter/material.dart';

/// Notifier class to handle locale changes and notify listeners.
class LocaleChangeNotifier extends ChangeNotifier {
  Locale _locale;

  // Set initial locale to English by default
  LocaleChangeNotifier({Locale initialLocale = const Locale('en')}) : _locale = initialLocale;

  /// Returns the current locale.
  Locale get locale => _locale;

  /// Sets the new locale and notifies all the listeners.
  /// This is the missing method.
  void changeLocale(Locale newLocale) {
    if (_locale == newLocale) return; // Do nothing if locale is the same

    _locale = newLocale;
    notifyListeners();
  }
}