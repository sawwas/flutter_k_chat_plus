import 'dart:math';

class NumberUtil {
  static String format(double n) {
    if (n >= 1000000000) {
      // 10亿及以上
      n /= 1000000000;
      return "${n.toStringAsFixed(2)}B";
    } else if (n >= 1000000) {
      // 100万至10亿
      n /= 1000000;
      return "${n.toStringAsFixed(2)}M";
    } else if (n >= 10000) {
      // 1万至100万
      n /= 10000;
      return "${n.toStringAsFixed(2)}W";
    } else if (n >= 1000) {
      // 1千至1万
      n /= 1000;
      return "${n.toStringAsFixed(2)}K";
    } else {
      return n.toStringAsFixed(4); // 1千以下
    }
  }

  static int getDecimalLength(double b) {
    String s = b.toString();
    int dotIndex = s.indexOf(".");
    if (dotIndex < 0) {
      return 0;
    } else {
      return s.length - dotIndex - 1;
    }
  }

  static int getMaxDecimalLength(double a, double b, double c, double d) {
    int result = max(getDecimalLength(a), getDecimalLength(b));
    result = max(result, getDecimalLength(c));
    result = max(result, getDecimalLength(d));
    return result;
  }

  static bool checkNotNullOrZero(double? a) {
    if (a == null || a == 0) {
      return false;
    } else if (a.abs().toStringAsFixed(4) == "0.0000") {
      return false;
    } else {
      return true;
    }
  }
}
