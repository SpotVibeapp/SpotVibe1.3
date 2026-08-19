import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spotvibe_app/providers/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defaults to dark mode when the user has not chosen a preference', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = ThemeProvider();

    expect(provider.themeMode, ThemeMode.dark);
    await provider.loadTheme();

    expect(provider.themeMode, ThemeMode.dark);
  });

  test('keeps a saved light-mode choice from the Profile toggle', () async {
    SharedPreferences.setMockInitialValues({'dark_mode': false});
    final provider = ThemeProvider();

    await provider.loadTheme();

    expect(provider.themeMode, ThemeMode.light);
  });
}
