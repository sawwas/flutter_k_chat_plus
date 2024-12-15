import 'package:flutter/material.dart';
import 'package:k_chart_plus_deeping/k_chart_plus.dart';

class VolRenderer extends BaseChartRenderer<VolumeEntity> {
  late double mVolWidth;
  final ChartStyle chartStyle;
  final ChartColors chartColors;

  VolRenderer(Rect mainRect, double maxValue, double minValue,
      double topPadding, int fixedLength, this.chartStyle, this.chartColors)
      : super(
          chartRect: mainRect,
          maxValue: maxValue,
          minValue: minValue,
          topPadding: topPadding,
          fixedLength: fixedLength,
          gridColor: chartColors.gridColor,
        ) {
    mVolWidth = chartStyle.volWidth;
  }

  @override
  void drawChart(VolumeEntity lastPoint, VolumeEntity curPoint, double lastX,
      double curX, Size size, Canvas canvas) {
    if (chartStyle.volisDouble) {
      /// 双成交量
      double left =
          curPoint.vol * curPoint.open * 1.2 / (curPoint.close + curPoint.open);
      double right = curPoint.vol *
          (curPoint.close + curPoint.open - curPoint.open * 1.2) /
          (curPoint.close + curPoint.open);
      // double r = mVolWidth / 2;
      double topLeft = getVolY(left);
      double topRight = getVolY(right);
      double bottom = chartRect.bottom;
      if (curPoint.vol != 0) {
        canvas.drawRect(
            Rect.fromLTRB(curX - mVolWidth, topLeft, curX - 1, bottom),
            chartPaint
              ..color =
                  curPoint.close > curPoint.open || curPoint.open < curPoint.vol
                      ? chartColors.dnColor
                      : chartColors.upColor);

        canvas.drawRect(Rect.fromLTRB(curX - 1, topLeft, curX + 1, bottom),
            chartPaint..color = Colors.transparent);

        canvas.drawRect(
            Rect.fromLTRB(curX + 1, topRight, curX + mVolWidth, bottom),
            chartPaint
              ..color = curPoint.close > curPoint.open ||
                      curPoint.close >= curPoint.vol
                  ? chartColors.upColor
                  : chartColors.dnColor);
      }
    } else {
      /// 单成交量
      double r = mVolWidth / 2;
      double top = getVolY(curPoint.vol);
      double bottom = chartRect.bottom;
      if (curPoint.vol != 0) {
        canvas.drawRect(
            Rect.fromLTRB(curX - r, top, curX + r, bottom),
            chartPaint
              ..color = curPoint.close > curPoint.open
                  ? chartColors.upColor
                  : chartColors.dnColor);
      }
    }

    if (chartStyle.showMAVolume && lastPoint.MA5Volume != 0) {
      drawLine(lastPoint.MA5Volume, curPoint.MA5Volume, canvas, lastX, curX,
          chartColors.ma5Color);
    }

    if (chartStyle.showMAVolume && lastPoint.MA10Volume != 0) {
      drawLine(lastPoint.MA10Volume, curPoint.MA10Volume, canvas, lastX, curX,
          chartColors.ma10Color);
    }
  }

  double getVolY(double value) =>
      (maxValue - value) * (chartRect.height / maxValue) + chartRect.top;

  @override
  void drawText(Canvas canvas, VolumeEntity data, double x) {
    if (chartStyle.isShowStrategyTypeBottom) {
      TextSpan span = TextSpan(
        children: [
          /// 成交量
          TextSpan(
              text: "VOL:",
              // text: "VOL:${NumberUtil.format(data.vol)}    ",
              // style: getTextStyle(chartColors.volColor)),
              style: getTextStyle(
                  chartColors.infoWindowTitleColor.withValues(alpha: 0.5))),
          formatValueSpan(
              (double.tryParse('${data.vol}') ?? 0.0),
              getTextStyle(
                  chartColors.infoWindowTitleColor.withValues(alpha: 0.5))),
          if (data.MA5Volume.notNullOrZero && chartStyle.isShowBottomMa)
            TextSpan(
                text: "MA5:${NumberUtil.format(data.MA5Volume!)}    ",
                style: getTextStyle(chartColors.ma5Color)),
          if (data.MA10Volume.notNullOrZero && chartStyle.isShowBottomMa)
            TextSpan(
                text: "MA10:${NumberUtil.format(data.MA10Volume!)}    ",
                style: getTextStyle(chartColors.ma10Color)),
        ],
      );
      TextPainter tp =
          TextPainter(text: span, textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(x, chartRect.top - topPadding));
    }
  }

  @override
  void drawVerticalText(canvas, textStyle, int gridRows) {
    if (chartStyle.isShowStrategyTypeBottomForMaxVol) {
      TextSpan span = TextSpan(
          text: "\n\n\n${NumberUtil.format(maxValue)}", style: textStyle);
      TextPainter tp =
          TextPainter(text: span, textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas,
          Offset(chartRect.width - tp.width, chartRect.top - topPadding));
    }
  }

  @override
  void drawGrid(Canvas canvas, int gridRows, int gridColumns) {
    canvas.drawLine(Offset(0, chartRect.bottom),
        Offset(chartRect.width, chartRect.bottom), gridPaint);
    double columnSpace = chartRect.width / gridColumns;
    for (int i = 0; i <= columnSpace; i++) {
      //vol垂直线
      canvas.drawLine(Offset(columnSpace * i, chartRect.top - topPadding),
          Offset(columnSpace * i, chartRect.bottom), gridPaint);
    }
  }
}
