import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';
// import 'package:unyx_mobile/src/constants/app_constants.dart';
// import 'package:web3dart/web3dart.dart';

//科学计数 下标
extension DecimalExtension on Decimal {
  bool get isNegative => compareTo(Decimal.zero) < 0;

  bool get isZero {
    return compareTo(Decimal.zero) == 0;
  }

  String fixed(int fractionDigits) {
    String result;
    if (this > Decimal.fromInt(-1) && this < Decimal.one) {
      result = toStringAsPrecisionNoRound(fractionDigits);
    } else {
      result = toStringAsFixedNoRound(fractionDigits);
    }
    if (result.indexOf('.') > 0) {
      return result
          .replaceAll(RegExp(r'0+?$'), '')
          .replaceAll(RegExp(r'[.]$'), '');
    }
    return result;
  }

  String toStringAsPrecisionNoRound(int precision) {
    assert(precision > 0);

    if (this == Decimal.zero) {
      return <String>[
        '0',
        if (precision > 1) '.',
        for (var i = 1; i < precision; i++) '0',
      ].join();
    }

    final limit = Decimal.ten.pow(precision).toDecimal();

    var shift = Decimal.one;
    final absValue = abs();
    var pad = 0;
    while (absValue * shift < limit) {
      pad++;
      shift *= Decimal.ten;
    }
    while (absValue * shift >= limit) {
      pad--;
      shift = (shift / Decimal.ten).toDecimal();
    }
    final value = ((this * shift).floor() / shift).toDecimal();
    return pad <= 0 ? value.toString() : value.toStringAsFixed(pad);
  }

  String toStringAsFixedNoRound(int fractionDigits) {
    assert(fractionDigits >= 0);
    if (fractionDigits == 0) return floor().toBigInt().toString();
    final value = floor(scale: fractionDigits);
    final intPart = value.toBigInt().abs();
    final decimalPart =
        (Decimal.one + value.abs() - intPart.toDecimal()).shift(fractionDigits);
    return '${value < Decimal.zero ? '-' : ''}$intPart.${decimalPart.toString().substring(1)}';
  }

  // EtherAmount get etherAmount {
  //   return EtherAmount.fromBase10String(EtherUnit.wei, shift(AppConstants.ethDecimal).toString());
  // }
  // EtherAmount get etherAmountInWei {
  //   return EtherAmount.fromBase10String(EtherUnit.wei, toString());
  // }

  String dollarValue([int fixedLength = 2]) {
    return '\$${NumberFormat("#,##0.${'#' * fixedLength}").format(double.tryParse(fixed(fixedLength)))}';
  }

  String get dollarValueParsed {
    if (this >= Decimal.fromInt(1000000000)) {
      return '${(this / Decimal.fromInt(1000000000)).toDecimal().dollarValue(2)}B';
    }
    if (this >= Decimal.fromInt(1000000)) {
      return '${(this / Decimal.fromInt(1000000)).toDecimal().dollarValue(2)}M';
    }
    if (this >= Decimal.fromInt(1000)) {
      return '${(this / Decimal.fromInt(1000)).toDecimal().dollarValue(2)}K';
    }
    return dollarValue(2);
  }
}
