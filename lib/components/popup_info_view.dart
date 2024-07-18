import 'package:flutter/material.dart';
import 'package:k_chart_plus_deeping/chart_style.dart';
import 'package:k_chart_plus_deeping/chart_translations.dart';
import '../entity/k_line_entity.dart';
import '../renderer/base_chart_painter.dart';
import '../utils/date_format_util.dart';
// import '../utils/number_util.dart';

class PopupInfoView extends StatelessWidget {
  final KLineEntity entity;
  final double width;
  final ChartColors chartColors;
  final ChartTranslations chartTranslations;
  final bool materialInfoDialog;
  final List<String> timeFormat;
  final int fixedLength;

  const PopupInfoView({
    Key? key,
    required this.entity,
    required this.width,
    required this.chartColors,
    required this.chartTranslations,
    required this.materialInfoDialog,
    required this.timeFormat,
    required this.fixedLength,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: chartColors.selectFillColor,
        //背景颜色
        border: Border.all(color: chartColors.selectBorderColor, width: 0.5),
        borderRadius: BorderRadius.all(Radius.circular(5.0)),
      ),
      child: SizedBox(
        width: width,
        child: Padding(
          padding: EdgeInsets.fromLTRB(6.0, 3.0, 6.0, 0.0),
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    double upDown = entity.change ?? entity.close - entity.open;
    double upDownPercent = entity.ratio ?? (upDown / entity.open) * 100;
    final double? entityAmount = entity.amount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildItem(chartTranslations.date, getDate(entity.time)),
        //# 手指按压显示的图层数值，Change、Change% 拿掉，Open、High、Low、Close、Volume 也按照数据格式规则来显示，Date可以先不动
        //科学运算 下标
        _buildItem(
            chartTranslations.open, formatNumber(entity.open.toString())),
        // chartTranslations.open, entity.open.toStringAsFixed(fixedLength)),
        //# 手指按压显示的图层数值，Change、Change% 拿掉，Open、High、Low、Close、Volume 也按照数据格式规则来显示，Date可以先不动
        //科学运算 下标
        _buildItem(
            chartTranslations.high, formatNumber(entity.high.toString())),
        // chartTranslations.high, entity.high.toStringAsFixed(fixedLength)),
        //# 手指按压显示的图层数值，Change、Change% 拿掉，Open、High、Low、Close、Volume 也按照数据格式规则来显示，Date可以先不动
        //科学运算 下标
        _buildItem(chartTranslations.low, formatNumber(entity.low.toString())),
        // chartTranslations.low, entity.low.toStringAsFixed(fixedLength)),
        //# 手指按压显示的图层数值，Change、Change% 拿掉，Open、High、Low、Close、Volume 也按照数据格式规则来显示，Date可以先不动
        //科学运算 下标
        _buildItem(
            chartTranslations.close, formatNumber(entity.close.toString())),
        // chartTranslations.close, entity.close.toStringAsFixed(fixedLength)),
        if (chartTranslations.changeAmount.isNotEmpty)
          _buildColorItem(chartTranslations.changeAmount,
              upDown.toStringAsFixed(fixedLength), upDown > 0),
        if (chartTranslations.change.isNotEmpty)
          _buildColorItem(chartTranslations.change,
              '${upDownPercent.toStringAsFixed(2)}%', upDownPercent > 0),
        //# 手指按压显示的图层数值，Change、Change% 拿掉，Open、High、Low、Close、Volume 也按照数据格式规则来显示，Date可以先不动
        _buildItem(chartTranslations.vol, formatNumber(entity.vol.toString())),
        // _buildItem(chartTranslations.vol, NumberUtil.format(entity.vol)),
        if (entityAmount != null)
          _buildItem(chartTranslations.amount, entityAmount.toInt().toString()),
      ],
    );
  }

  Widget _buildColorItem(String label, String info, bool isUp) {
    if (isUp) {
      return _buildItem(label, '+$info',
          textColor: chartColors.infoWindowUpColor);
    }
    return _buildItem(label, info, textColor: chartColors.infoWindowDnColor);
  }

  Widget _buildItem(String label, String info, {Color? textColor}) {
    final infoWidget = Padding(
      padding: const EdgeInsets.only(bottom: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          if (label != "")
            Text(
              label,
              style: TextStyle(
                color: chartColors.infoWindowTitleColor,
                fontSize: chartColors.sizeText,
              ),
            ),
          Expanded(
              //科学计算 下标
              child: (double.tryParse('${info}') ?? -987654321) == -987654321
                  ? Text(
                      info,
                      style: TextStyle(
                          color: textColor ?? chartColors.infoWindowNormalColor,
                          fontSize: chartColors.sizeText),
                      textAlign: label == chartTranslations.date
                          ? TextAlign.left
                          : TextAlign.right,
                    )
                  : RichText(
                      textAlign: TextAlign.right,
                      text: formatValueSpan(
                          (double.tryParse('${info}') ?? 0.0),
                          TextStyle(
                              color: textColor ??
                                  chartColors.infoWindowNormalColor,
                              fontSize: chartColors.sizeText,
                              fontWeight: FontWeight.w700)),
                    )),
        ],
      ),
    );
    return materialInfoDialog
        ? Material(color: Colors.transparent, child: infoWidget)
        : infoWidget;
  }

  String getDate(int? date) => dateFormat(
        DateTime.fromMillisecondsSinceEpoch(
            date ?? DateTime.now().millisecondsSinceEpoch),
        timeFormat,
      );
}

//# 手指按压显示的图层数值，Change、Change% 拿掉，Open、High、Low、Close、Volume 也按照数据格式规则来显示，Date可以先不动
//# 数据格式规则
//
// 整数位非零的数字，保留2位小数，其中大于999的每三位用逗号分隔；
// 整数位是0的，显示4位有效数字； 其中0特别多的如果再当前位置显示不下，小数点后第一个0后显示角标，角标数字表示0的个数。
String formatNumber(String input) {
  double? num = double.tryParse(input);
  if (num == null) {
    return '0.00';
  }

  // 处理整数部分非零的情况
  if (num >= 1) {
    ///三位一取 逗号
    // return formatWithCommas(num);
    return '$num';
  }
  // 处理整数部分为零的情况
  else {
    return '$num';
    // return formatDecimal(num);
  }
}

String formatWithCommas(double num) {
  String formattedNumber = num.toStringAsFixed(2);
  List<String> parts = formattedNumber.split('.');
  String integerPart = parts[0];
  String decimalPart = parts.length > 1 ? parts[1] : '';
  String result = '';

  // 每三位用逗号分隔
  for (int i = 0; i < integerPart.length; i++) {
    result += integerPart[integerPart.length - 1 - i];
    if ((i + 1) % 3 == 0 && i != integerPart.length - 1) {
      result += ',';
    }
  }

  result = result.split('').reversed.join('');
  result += '.$decimalPart';

  return result;
}

String formatDecimal(double num) {
  String numStr = num.toStringAsExponential(4);
  List<String> parts = numStr.split('e');

  String base =
      parts[0].replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  int exponent = int.parse(parts[1]);

  if (exponent < -4) {
    String leadingZeros = '0' * (-exponent - 1);
    base = base.replaceFirst(RegExp(r'\.0*$'), '');
    return '$base${leadingZeros.length}';
  } else {
    return '$base' + 'e$exponent';
  }
}
