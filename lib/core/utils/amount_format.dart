import 'package:intl/intl.dart';

String formatAmount(int amount, {bool isEnglish = false}) {
  return NumberFormat.decimalPattern(isEnglish ? 'en' : 'ko').format(amount);
}
