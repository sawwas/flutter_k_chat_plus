import 'package:flutter/material.dart';

import '../entity/candle_entity.dart';
import '../k_chart_widget.dart' show MainState;
import 'base_chart_painter.dart';
import 'base_chart_renderer.dart';

enum VerticalTextAlignment { left, right }

//For TrendLine
double? trendLineMax;
double? trendLineScale;
double? trendLineContentRec;

class MainRenderer extends BaseChartRenderer<CandleEntity> {
  late double mCandleWidth;
  late double mCandleLineWidth;
  MainState state;
  bool isLine;

  //绘制的内容区域
  late Rect _contentRect;
  final double _contentPadding = 5.0;
  List<int> maDayList;

  //EMA
  List<int> emaValueList;
  final ChartStyle chartStyle;
  final ChartColors chartColors;
  final double mLineStrokeWidth = 1.0;
  double scaleX;
  late Paint mLinePaint;
  final VerticalTextAlignment verticalTextAlignment;

  MainRenderer(
    Rect mainRect,
    double maxValue,
    double minValue,
    double topPadding,
    this.state,
    this.isLine,
    int fixedLength,
    this.chartStyle,
    this.chartColors,
    this.scaleX,
    this.verticalTextAlignment,
    //EMA
    [
    this.maDayList = const [5, 10, 20],
    this.emaValueList = const [5, 10, 30, 60],
  ]) : super(
            chartRect: mainRect,
            maxValue: maxValue,
            minValue: minValue,
            topPadding: topPadding,
            fixedLength: fixedLength,
            gridColor: chartColors.gridColor) {
    mCandleWidth = chartStyle.candleWidth;
    mCandleLineWidth = chartStyle.candleLineWidth;
    mLinePaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = mLineStrokeWidth
      ..color = chartColors.kLineColor;
    _contentRect = Rect.fromLTRB(
        chartRect.left,
        chartRect.top + _contentPadding,
        chartRect.right,
        chartRect.bottom - _contentPadding);
    if (maxValue == minValue) {
      maxValue *= 1.5;
      minValue /= 2;
    }
    scaleY = _contentRect.height / (maxValue - minValue);
  }

  @override
  void drawText(Canvas canvas, CandleEntity data, double x) {
    if (isLine == true) return;
    TextSpan? span;
    if (state == MainState.mA) {
      // span = TextSpan(
      //   children: _createMATextSpan(data),
      // );
      String value = format((data.maValueList ?? [0])[0]);
      span = TextSpan(
        children: [
          TextSpan(
            children: _createMATextSpan(data),
          ),
          if (chartStyle.isShowEma && value.length <= 13)
            //EMA
            TextSpan(text: '\n'),
          if (chartStyle.isShowEma)
            TextSpan(
              children: _createEMATextSpan(data),
            ),
        ],
      );
    } else if (state == MainState.bOLL) {
      span = TextSpan(
        children: [
          if (data.up != 0)
            TextSpan(
                text: "BOLL:${format(data.mb)}    ",
                style: getTextStyle(chartColors.ma5Color)),
          if (data.mb != 0)
            TextSpan(
                text: "UB:${format(data.up)}    ",
                style: getTextStyle(chartColors.ma10Color)),
          if (data.dn != 0)
            TextSpan(
                text: "LB:${format(data.dn)}    ",
                style: getTextStyle(chartColors.ma30Color)),
        ],
      );
    }
    if (span == null) {
      return;
    }
    TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();
    if (chartStyle.isShowStrategyTypeTop) {
      tp.paint(canvas, Offset(x, chartRect.top - topPadding));
    }
  }

  List<InlineSpan> _createMATextSpan(CandleEntity data) {
    List<InlineSpan> result = [];
    for (int i = 0; i < (data.maValueList?.length ?? 0); i++) {
      if (data.maValueList?[i] != 0) {
        String value = format(data.maValueList![i]);
        //
        // var item = TextSpan(
        //     text: "MA${maDayList[i]}:$value    ",
        //     style: getTextStyle(chartColors.getMAColor(i)));

        //科学计算 下标
        List<InlineSpan> children = [];

        TextSpan span = TextSpan(
            text: "MA${maDayList[i]}:",
            style: getTextStyle(chartColors.getMAColor(i)));
        final spanS = formatValueSpan(
            (double.tryParse('${data.maValueList![i]}') ?? 0.0),
            getTextStyle(chartColors.getMAColor(i)));
        children.add(span);
        children.add(spanS);
        TextSpan? item = TextSpan(children: children);

        result.add(item);
        if (value.length > 13 && i > 0 && i % 1 == 0) {
          result.add(TextSpan(text: '\n'));
        }
      }
    }
    return result;
  }

//EMA
  List<InlineSpan> _createEMATextSpan(CandleEntity data) {
    List<InlineSpan> result = [];
    for (int i = 0; i < (data.emaValueList?.length ?? 0); i++) {
      if (data.emaValueList?[i] != 0) {
        // String value = '${format(data.emaValueList![i])}';
        String value = format(data.emaValueList![i]);
        // var item = TextSpan(
        //     text: "EMA${emaValueList[i]}:$value    ",
        //     style: getTextStyle(chartColors.getEMAColor(i)));

        //科学计算 下标
        List<InlineSpan> children = [];

        TextSpan span = TextSpan(
            text: "EMA${emaValueList[i]}:",
            style: getTextStyle(chartColors.getEMAColor(i)));
        final spanS = formatValueSpan(
            (double.tryParse('${data.emaValueList![i]}') ?? 0.0),
            getTextStyle(chartColors.getEMAColor(i)));
        children.add(span);
        children.add(spanS);
        TextSpan? item = TextSpan(children: children);

        if ((value.length > 13 && i > 0 && i % 2 == 0) ||
            (value.length <= 13 && i > 2)) {
          result.add(TextSpan(text: '\n'));
        }
        result.add(item);
        // if (i == 2) {
        //   result.add(TextSpan(text: '\n'));
        // }
      }
    }
    return result;
  }

  // 添加EMA计算函数
  //EMA
  List<double> calculateEMA(List<double> prices, int period) {
    List<double> ema = [];
    double multiplier = 2 / (period + 1);

    double sum = 0;
    for (int i = 0; i < period; i++) {
      sum += prices[i];
    }
    ema.add(sum / period);

    for (int i = period; i < prices.length; i++) {
      double value = (prices[i] - ema.last) * multiplier + ema.last;
      ema.add(value);
    }

    return ema;
  }

  @override
  void drawChart(CandleEntity lastPoint, CandleEntity curPoint, double lastX,
      double curX, Size size, Canvas canvas) {
    if (isLine) {
      drawPolyline(lastPoint.close, curPoint.close, canvas, lastX, curX);
    } else {
      drawCandle(curPoint, canvas, curX);
      if (state == MainState.mA) {
        drawMaLine(lastPoint, curPoint, canvas, lastX, curX);
        //// 新增EMA绘制逻辑
        //EMA
        if (chartStyle.isShowEma) {
          drawEmaLine(lastPoint, curPoint, canvas, lastX, curX);
        }
      } else if (state == MainState.bOLL) {
        drawBollLine(lastPoint, curPoint, canvas, lastX, curX);
      }
    }
  }

  // 实现EMA绘制函数
  //EMA
  void drawEmaLine(CandleEntity lastPoint, CandleEntity curPoint, Canvas canvas,
      double lastX, double curX) {
    for (int i = 0; i < (curPoint.emaValueList?.length ?? 0); i++) {
      if (i == 4) {
        break;
      }
      if (lastPoint.emaValueList?[i] != 0) {
        drawLine(lastPoint.emaValueList?[i], curPoint.emaValueList?[i], canvas,
            lastX, curX, chartColors.getEMAColor(i));
      }
    }
  }

  Shader? mLineFillShader;
  Path? mLinePath, mLineFillPath;
  Paint mLineFillPaint = Paint()
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

//画折线图
  drawPolyline(double lastPrice, double curPrice, Canvas canvas, double lastX,
      double curX) {
//    drawLine(lastPrice + 100, curPrice + 100, canvas, lastX, curX, ChartColors.kLineColor);
    mLinePath ??= Path();

//    if (lastX == curX) {
//      mLinePath.moveTo(lastX, getY(lastPrice));
//    } else {
////      mLinePath.lineTo(curX, getY(curPrice));
//      mLinePath.cubicTo(
//          (lastX + curX) / 2, getY(lastPrice), (lastX + curX) / 2, getY(curPrice), curX, getY(curPrice));
//    }
    if (lastX == curX) lastX = 0; //起点位置填充
    mLinePath!.moveTo(lastX, getY(lastPrice));
    mLinePath!.cubicTo((lastX + curX) / 2, getY(lastPrice), (lastX + curX) / 2,
        getY(curPrice), curX, getY(curPrice));

    //画阴影
    mLineFillShader ??= LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      tileMode: TileMode.clamp,
      colors: [chartColors.lineFillColor, chartColors.lineFillInsideColor],
    ).createShader(Rect.fromLTRB(
        chartRect.left, chartRect.top, chartRect.right, chartRect.bottom));
    mLineFillPaint.shader = mLineFillShader;

    mLineFillPath ??= Path();

    mLineFillPath!.moveTo(lastX, chartRect.height + chartRect.top);
    mLineFillPath!.lineTo(lastX, getY(lastPrice));
    mLineFillPath!.cubicTo((lastX + curX) / 2, getY(lastPrice),
        (lastX + curX) / 2, getY(curPrice), curX, getY(curPrice));
    mLineFillPath!.lineTo(curX, chartRect.height + chartRect.top);
    mLineFillPath!.close();

    canvas.drawPath(mLineFillPath!, mLineFillPaint);
    mLineFillPath!.reset();

    canvas.drawPath(mLinePath!,
        mLinePaint..strokeWidth = (mLineStrokeWidth / scaleX).clamp(0.1, 1.0));
    mLinePath!.reset();
  }

  void drawMaLine(CandleEntity lastPoint, CandleEntity curPoint, Canvas canvas,
      double lastX, double curX) {
    for (int i = 0; i < (curPoint.maValueList?.length ?? 0); i++) {
      if (i == 3) {
        break;
      }
      if (lastPoint.maValueList?[i] != 0) {
        drawLine(lastPoint.maValueList?[i], curPoint.maValueList?[i], canvas,
            lastX, curX, chartColors.getMAColor(i));
      }
    }
  }

  void drawBollLine(CandleEntity lastPoint, CandleEntity curPoint,
      Canvas canvas, double lastX, double curX) {
    if (lastPoint.up != 0) {
      drawLine(lastPoint.up, curPoint.up, canvas, lastX, curX,
          chartColors.ma10Color);
    }
    if (lastPoint.mb != 0) {
      drawLine(
          lastPoint.mb, curPoint.mb, canvas, lastX, curX, chartColors.ma5Color);
    }
    if (lastPoint.dn != 0) {
      drawLine(lastPoint.dn, curPoint.dn, canvas, lastX, curX,
          chartColors.ma30Color);
    }
  }

  void drawCandle(CandleEntity curPoint, Canvas canvas, double curX) {
    var high = getY(curPoint.high);
    var low = getY(curPoint.low);
    var open = getY(curPoint.open);
    var close = getY(curPoint.close);
    double r = mCandleWidth / 2;
    double lineR = mCandleLineWidth / 2;
    if (open >= close) {
      // 实体高度>= CandleLineWidth
      if (open - close < mCandleLineWidth) {
        open = close + mCandleLineWidth;
      }
      chartPaint.color = chartColors.upColor;
      canvas.drawRect(
          Rect.fromLTRB(curX - r, close, curX + r, open), chartPaint);
      canvas.drawRect(
          Rect.fromLTRB(curX - lineR, high, curX + lineR, low), chartPaint);
    } else if (close > open) {
      // 实体高度>= CandleLineWidth
      if (close - open < mCandleLineWidth) {
        open = close - mCandleLineWidth;
      }
      chartPaint.color = chartColors.dnColor;
      canvas.drawRect(
          Rect.fromLTRB(curX - r, open, curX + r, close), chartPaint);
      canvas.drawRect(
          Rect.fromLTRB(curX - lineR, high, curX + lineR, low), chartPaint);
    }
  }

  @override
  void drawVerticalText(canvas, textStyle, int gridRows) {
    double rowSpace = chartRect.height / gridRows;
    for (var i = 0; i <= gridRows; ++i) {
      double value = (gridRows - i) * rowSpace / scaleY + minValue;

      // TextSpan span = TextSpan(
      //     text: "${format(value, isNotPoint: chartStyle.isNotPoint)}",
      //     style: textStyle);

      //右侧文字科学计数
      final realStyle = getTextStyle(chartColors.maxColor);
      TextSpan span = formatValueSpan(value, realStyle);

      TextPainter tp =
          TextPainter(text: span, textDirection: TextDirection.ltr);
      tp.layout();

      double offsetX;
      switch (verticalTextAlignment) {
        case VerticalTextAlignment.left:
          offsetX = 0;
          break;
        case VerticalTextAlignment.right:
          offsetX = chartRect.width - tp.width - chartStyle.rightPadding;
          break;
      }

      if (i == 0 && chartStyle.isShowLeftTopicPoint) {
        tp.paint(canvas, Offset(offsetX, topPadding));
      } else {
        if (chartStyle.isShowLeftTopicPoint || i > 0) {
          tp.paint(
              canvas, Offset(offsetX, rowSpace * i - tp.height + topPadding));
        }
      }
    }
  }

  @override
  void drawGrid(Canvas canvas, int gridRows, int gridColumns) {
//    final int gridRows = 4, gridColumns = 4;
    double rowSpace = chartRect.height / gridRows;
    for (int i = 0; i <= gridRows; i++) {
      canvas.drawLine(Offset(0, rowSpace * i + topPadding),
          Offset(chartRect.width, rowSpace * i + topPadding), gridPaint);
    }
    double columnSpace = chartRect.width / gridColumns;
    for (int i = 0; i <= columnSpace; i++) {
      canvas.drawLine(Offset(columnSpace * i, topPadding / 3),
          Offset(columnSpace * i, chartRect.bottom), gridPaint);
    }
  }

  @override
  double getY(double y) {
    //For TrendLine
    updateTrendLineData();
    return (maxValue - y) * scaleY + _contentRect.top;
  }

  void updateTrendLineData() {
    trendLineMax = maxValue;
    trendLineScale = scaleY;
    trendLineContentRec = _contentRect.top;
  }
}
