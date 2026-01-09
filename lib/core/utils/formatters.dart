import 'package:intl/intl.dart';

/// Utility class for formatting numbers and currencies
class NumberFormatters {
  NumberFormatters._();

  static final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
  static final currencyWithCents = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
  static final percent = NumberFormat.percentPattern();
  static final percentOneDecimal = NumberFormat('#0.0%');
  static final compact = NumberFormat.compact();
  static final number = NumberFormat('#,##0');
  static final decimal = NumberFormat('#,##0.00');

  /// Format as currency with appropriate scale (K, M, B)
  static String formatCurrencyCompact(double value) {
    final absValue = value.abs();
    final prefix = value < 0 ? '-' : '';

    if (absValue >= 1000000000) {
      return '$prefix\$${(absValue / 1000000000).toStringAsFixed(1)}B';
    } else if (absValue >= 1000000) {
      return '$prefix\$${(absValue / 1000000).toStringAsFixed(1)}M';
    } else if (absValue >= 1000) {
      return '$prefix\$${(absValue / 1000).toStringAsFixed(0)}K';
    }
    return '$prefix\$${absValue.toStringAsFixed(0)}';
  }

  /// Format currency showing negatives in parentheses (accounting style)
  static String formatCurrencyAccounting(double value) {
    if (value < 0) {
      return '(\$${currency.format(value.abs()).substring(1)})';
    }
    return currency.format(value);
  }

  /// Format as percentage, handling null for N/A display
  static String formatPercentOrNA(double? value) {
    if (value == null) return 'N/A';
    return percentOneDecimal.format(value);
  }

  /// Format payback period
  static String formatPaybackPeriod(int months) {
    if (months >= 60) return '> 5 Years';
    final years = months / 12;
    return '${years.toStringAsFixed(1)} Years';
  }

  /// Parse currency string to double
  static double? parseCurrency(String value) {
    try {
      // Remove currency symbol, commas, and parentheses
      String cleaned = value
          .replaceAll('\$', '')
          .replaceAll(',', '')
          .replaceAll('(', '-')
          .replaceAll(')', '')
          .trim();

      if (cleaned.isEmpty || cleaned == '-') return 0;
      return double.parse(cleaned);
    } catch (e) {
      return null;
    }
  }
}

/// Date formatting utilities
class DateFormatters {
  DateFormatters._();

  static final shortDate = DateFormat('MM/dd/yyyy');
  static final longDate = DateFormat('MMMM d, yyyy');
  static final monthYear = DateFormat('MMM yyyy');
  static final isoDate = DateFormat('yyyy-MM-dd');
  static final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss');

  /// Get fiscal year from date (assuming calendar year = fiscal year)
  static int getFiscalYear(DateTime date) {
    return date.year;
  }

  /// Get month name abbreviation
  static String getMonthAbbr(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  /// Format as "MMM-YY" (e.g., "Jan-24")
  static String formatMonthYearShort(DateTime date) {
    return '${getMonthAbbr(date.month)}-${date.year.toString().substring(2)}';
  }
}
