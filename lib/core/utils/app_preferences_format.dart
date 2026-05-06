import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';

extension AppPreferencesFormatX on BuildContext {
  SettingsProvider get appSettings => watch<SettingsProvider>();

  bool get isEnglish => appSettings.isEnglish;

  Locale get appLocale => Locale(isEnglish ? 'en' : 'ko');

  String tr(String ko, String en) => isEnglish ? en : ko;

  String formatCurrency(int amount, {bool compact = false}) {
    final currency = appSettings.currency;
    final locale = isEnglish ? 'en_US' : 'ko_KR';
    final symbol = switch (currency) {
      'USD' => '\$',
      'JPY' => '¥',
      _ => '₩',
    };

    if (compact) {
      return NumberFormat.compactCurrency(
        locale: locale,
        symbol: symbol,
        decimalDigits: currency == 'USD' ? 1 : 0,
      ).format(amount);
    }

    return NumberFormat.currency(
      locale: locale,
      symbol: symbol,
      decimalDigits: 0,
    ).format(amount);
  }

  String formatMonthYear(DateTime date) {
    if (isEnglish) return DateFormat('MMMM yyyy', 'en_US').format(date);
    return '${date.year}년 ${date.month}월';
  }

  String formatFullDate(DateTime date) {
    if (isEnglish) return DateFormat('MMM d, yyyy', 'en_US').format(date);
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  String formatDueDay(int dueDay) =>
      isEnglish ? 'Day $dueDay every month' : '매월 $dueDay일';
}
