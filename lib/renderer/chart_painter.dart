import 'dart:async' show StreamSink;
import 'package:flutter/material.dart';
import 'package:k_chart_plus_deeping/utils/number_util.dart';
import '../entity/info_window_entity.dart';
import '../entity/k_line_entity.dart';
import '../k_chart_widget.dart';
import '../utils/date_format_util.dart';
import 'base_chart_painter.dart';
import 'base_chart_renderer.dart';
import 'base_dimension.dart';
import 'main_renderer.dart';
import 'secondary_renderer.dart';
import 'vol_renderer.dart';

class TrendLine {
  final Offset p1;
  final Offset p2;
  final double maxHeight;
  final double scale;

  TrendLine(this.p1, this.p2, this.maxHeight, this.scale);
}

double? trendLineX;

double getTrendLineX() {
  return trendLineX ?? 0;
}

class ChartPainter extends BaseChartPainter {
  final List<TrendLine> lines; //For TrendLine
  final bool isTrendLine; //For TrendLine
  bool isrecordingCord = false; //For TrendLine
  final double selectY; //For TrendLine
  static get maxScrollX => BaseChartPainter.maxScrollX;
  late BaseChartRenderer mMainRenderer;
  BaseChartRenderer? mVolRenderer;
  Set<BaseChartRenderer> mSecondaryRendererList = {};
  StreamSink<InfoWindowEntity?> sink;
  Color? upColor, dnColor;
  Color? ma5Color, ma10Color, ma30Color;
  Color? volColor;
  Color? macdColor, difColor, deaColor, jColor;
  int fixedLength;
  List<int> maDayList;
  final ChartColors chartColors;
  late Paint selectPointPaint, selectorBorderPaint, nowPricePaint;
  @override
  final ChartStyle chartStyle;
  final bool hideGrid;
  final bool showNowPrice;
  final VerticalTextAlignment verticalTextAlignment;
  @override
  final BaseDimension baseDimension;

  ChartPainter(
    this.chartStyle,
    this.chartColors, {
    required this.lines, //For TrendLine
    required this.isTrendLine, //For TrendLine
    required this.selectY, //For TrendLine
    required this.sink,
    required datas,
    required scaleX,
    required scrollX,
    required isLongPass,
    required selectX,
    required xFrontPadding,
    required this.baseDimension,
    isOnTap,
    isTapShowInfoDialog,
    required this.verticalTextAlignment,
    mainState,
    volHidden,
    secondaryStateLi,
    bool isLine = false,
    this.hideGrid = false,
    this.showNowPrice = true,
    this.fixedLength = 2,
    this.maDayList = const [5, 10, 20],
  }) : super(chartStyle,
            datas: datas,
            scaleX: scaleX,
            scrollX: scrollX,
            isLongPress: isLongPass,
            baseDimension: baseDimension,
            isOnTap: isOnTap,
            isTapShowInfoDialog: isTapShowInfoDialog,
            selectX: selectX,
            mainState: mainState,
            volHidden: volHidden,
            secondaryStateLi: secondaryStateLi,
            xFrontPadding: xFrontPadding,
            isLine: isLine) {
    selectPointPaint = Paint()
      ..isAntiAlias = true
      //EMA
      ..strokeWidth = 0.21
      ..color = chartColors.selectFillColor;
    selectorBorderPaint = Paint()
      ..isAntiAlias = true
      //EMA
      ..strokeWidth = 0.21
      ..style = PaintingStyle.stroke
      ..color = chartColors.selectBorderColor;
    nowPricePaint = Paint()
      ..strokeWidth = chartStyle.nowPriceLineWidth
      ..isAntiAlias = true;
  }

  @override
  void initChartRenderer() {
    if (datas != null && datas!.isNotEmpty) {
      var t = datas![0];
      fixedLength =
          NumberUtil.getMaxDecimalLength(t.open, t.close, t.high, t.low);
    }
    mMainRenderer = MainRenderer(
      mMainRect,
      mMainMaxValue,
      mMainMinValue,
      mTopPadding,
      mainState,
      isLine,
      fixedLength,
      chartStyle,
      chartColors,
      scaleX,
      verticalTextAlignment,
      maDayList,
    );
    if (mVolRect != null) {
      mVolRenderer = VolRenderer(mVolRect!, mVolMaxValue, mVolMinValue,
          mChildPadding, fixedLength, chartStyle, chartColors);
    }
    mSecondaryRendererList.clear();
    for (int i = 0; i < mSecondaryRectList.length; ++i) {
      mSecondaryRendererList.add(SecondaryRenderer(
        mSecondaryRectList[i].mRect,
        mSecondaryRectList[i].mMaxValue,
        mSecondaryRectList[i].mMinValue,
        mChildPadding,
        secondaryStateLi.elementAt(i),
        fixedLength,
        chartStyle,
        chartColors,
      ));
    }
  }

  @override
  void drawBg(Canvas canvas, Size size) {
    Paint mBgPaint = Paint()..color = chartColors.bgColor;
    Rect mainRect =
        Rect.fromLTRB(0, 0, mMainRect.width, mMainRect.height + mTopPadding);
    canvas.drawRect(mainRect, mBgPaint);

    if (mVolRect != null) {
      Rect volRect = Rect.fromLTRB(
          0, mVolRect!.top - mChildPadding, mVolRect!.width, mVolRect!.bottom);
      canvas.drawRect(volRect, mBgPaint);
    }

    for (int i = 0; i < mSecondaryRectList.length; ++i) {
      Rect? mSecondaryRect = mSecondaryRectList[i].mRect;
      Rect secondaryRect = Rect.fromLTRB(0, mSecondaryRect.top - mChildPadding,
          mSecondaryRect.width, mSecondaryRect.bottom);
      canvas.drawRect(secondaryRect, mBgPaint);
    }
    Rect dateRect =
        Rect.fromLTRB(0, size.height - mBottomPadding, size.width, size.height);
    canvas.drawRect(dateRect, mBgPaint);
  }

  @override
  void drawGrid(canvas) {
    if (!hideGrid) {
      mMainRenderer.drawGrid(canvas, mGridRows, mGridColumns);
      mVolRenderer?.drawGrid(canvas, mGridRows, mGridColumns);
      for (var element in mSecondaryRendererList) {
        element.drawGrid(canvas, mGridRows, mGridColumns);
      }
    }
  }

  @override
  void drawChart(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(mTranslateX * scaleX + chartStyle.leftPadding, 0.0);
    canvas.scale(scaleX, 1.0);
    for (int i = mStartIndex; datas != null && i <= mStopIndex; i++) {
      KLineEntity? curPoint = datas?[i];
      if (curPoint == null) continue;
      KLineEntity lastPoint = i == 0 ? curPoint : datas![i - 1];
      double curX = getX(i);
      double lastX = i == 0 ? curX : getX(i - 1);

      mMainRenderer.drawChart(lastPoint, curPoint, lastX, curX, size, canvas);
      mVolRenderer?.drawChart(lastPoint, curPoint, lastX, curX, size, canvas);
      for (var element in mSecondaryRendererList) {
        element.drawChart(lastPoint, curPoint, lastX, curX, size, canvas);
      }
    }

    if (chartStyle.isLongFocus &&
        ((isLongPress == true || (isTapShowInfoDialog && longPressTriggered)) &&
            isTrendLine == false)) {
      drawCrossLine(canvas, size);
    } else if (!chartStyle.isLongFocus &&
        ((isLongPress == true || (isTapShowInfoDialog && isOnTap)) &&
            isTrendLine == false)) {
      drawCrossLine(canvas, size);
    }
    if (isTrendLine == true) drawTrendLines(canvas, size);
    canvas.restore();
  }

  @override
  void drawVerticalText(canvas) {
    var textStyle = getTextStyle(chartColors.defaultTextColor);
    //EMA
    // if (!hideGrid || chartStyle.isNotPoint) {
    if (!hideGrid) {
      mMainRenderer.drawVerticalText(canvas, textStyle, mGridRows);
    }
    mVolRenderer?.drawVerticalText(canvas, textStyle, mGridRows);
    for (var element in mSecondaryRendererList) {
      element.drawVerticalText(canvas, textStyle, mGridRows);
    }
  }

  @override
  void drawDate(Canvas canvas, Size size) {
    if (datas == null) {
      return;
    }

    double columnSpace = size.width / mGridColumns;
    double startX = getX(mStartIndex) - mPointWidth / 2;
    double stopX = getX(mStopIndex) + mPointWidth / 2;
    double x = 0.0;
    double y = 0.0;
    for (var i = 0; i <= mGridColumns; ++i) {
      double translateX = xToTranslateX(columnSpace * i);

      if (translateX >= startX && translateX <= stopX) {
        int index = indexOfTranslateX(translateX);

        if (datas?[index] == null) continue;
        TextPainter tp = getTextPainter(getDate(datas![index].time), null);
        y = size.height - (mBottomPadding - tp.height) / 2 - tp.height;
        x = columnSpace * i - tp.width / 2;
        // Prevent date text out of canvas
        if (x < 0) x = 0;
        if (x > size.width - tp.width) x = size.width - tp.width;
        tp.paint(canvas, Offset(x + chartStyle.leftPadding, y));
      }
    }

//    double translateX = xToTranslateX(0);
//    if (translateX >= startX && translateX <= stopX) {
//      TextPainter tp = getTextPainter(getDate(datas[mStartIndex].id));
//      tp.paint(canvas, Offset(0, y));
//    }
//    translateX = xToTranslateX(size.width);
//    if (translateX >= startX && translateX <= stopX) {
//      TextPainter tp = getTextPainter(getDate(datas[mStopIndex].id));
//      tp.paint(canvas, Offset(size.width - tp.width, y));
//    }
  }

  /// draw the cross line. when user focus
  @override
  void drawCrossLineText(Canvas canvas, Size size) {
    var index = calculateSelectedX(selectX);
    KLineEntity point = getItem(index);

    TextPainter tp = getTextPainter(point.close, chartColors.crossTextColor);
    double textHeight = tp.height;
    double textWidth = tp.width;

    double w1 = 5;
    double w2 = 3;
    double r = textHeight / 2 + w2;
    double y = getMainY(point.close);
    double x;
    bool isLeft = false;
    if (translateXtoX(getX(index)) < mWidth / 2) {
      isLeft = false;
      x = 1;
      if (chartStyle.isFocusCloseText) {
        Path path = Path();
        path.moveTo(x, y - r);
        path.lineTo(x, y + r);
        path.lineTo(textWidth + 2 * w1, y + r);
        path.lineTo(textWidth + 2 * w1 + w2, y);
        path.lineTo(textWidth + 2 * w1, y - r);
        path.close();
        canvas.drawPath(path, selectPointPaint);
        canvas.drawPath(path, selectorBorderPaint);
        tp.paint(canvas, Offset(x + w1, y - textHeight / 2));
      }
    } else {
      isLeft = true;
      x = mWidth - textWidth - 1 - 2 * w1 - w2;
      if (chartStyle.isFocusCloseText) {
        Path path = Path();
        path.moveTo(x, y);
        path.lineTo(x + w2, y + r);
        path.lineTo(mWidth - 2, y + r);
        path.lineTo(mWidth - 2, y - r);
        path.lineTo(x + w2, y - r);
        path.close();
        canvas.drawPath(path, selectPointPaint);
        canvas.drawPath(path, selectorBorderPaint);
        tp.paint(canvas, Offset(x + w1 + w2, y - textHeight / 2));
      }
    }

    TextPainter dateTp =
        getTextPainter(getDate(point.time), chartColors.crossTextColor);
    textWidth = dateTp.width;
    r = textHeight / 2;
    x = translateXtoX(getX(index));
    y = size.height - mBottomPadding;

    if (x < textWidth + 2 * w1) {
      x = 1 + textWidth / 2 + w1;
    } else if (mWidth - x < textWidth + 2 * w1) {
      x = mWidth - 1 - textWidth / 2 - w1;
    }
    double baseLine = textHeight / 2;
    canvas.drawRect(
        Rect.fromLTRB(x - textWidth / 2 - w1, y, x + textWidth / 2 + w1,
            y + baseLine + r),
        selectPointPaint);
    canvas.drawRect(
        Rect.fromLTRB(x - textWidth / 2 - w1, y, x + textWidth / 2 + w1,
            y + baseLine + r),
        selectorBorderPaint);

    dateTp.paint(canvas, Offset(x - textWidth / 2, y));
    //Long press to display the details of this data
    sink.add(InfoWindowEntity(point, isLeft: isLeft));
  }

  @override
  void drawText(Canvas canvas, KLineEntity data, double x) {
    //Long press to display the data in the press
    if (chartStyle.isLongFocus &&
        (isLongPress || (isTapShowInfoDialog && longPressTriggered))) {
      var index = calculateSelectedX(selectX);
      data = getItem(index);
    } else if (!chartStyle.isLongFocus &&
        (isLongPress || (isTapShowInfoDialog && isOnTap))) {
      var index = calculateSelectedX(selectX);
      data = getItem(index);
    }
    //Release to display the last data
    mMainRenderer.drawText(canvas, data, x);
    mVolRenderer?.drawText(canvas, data, x);
    for (var element in mSecondaryRendererList) {
      element.drawText(canvas, data, x);
    }
  }

  @override
  void drawMaxAndMin(Canvas canvas) {
    if (isLine == true) {
      return;
    }
    if (!chartStyle.isShowHighOrLowPoint) {
      return;
    }
    //plot maxima and minima
    double x = translateXtoX(getX(mMainMinIndex));
    double y = getMainY(mMainLowMinValue);
    if (x < mWidth / 2) {
      //draw right
      //EMA
      TextPainter tp = getTextPainter(
          // "── " + mMainLowMinValue.toStringAsFixed(fixedLength),
          //   "── " + formatValue(mMainLowMinValue),
          "── ",
          chartColors.minColor, addTextSpan: () {
        final realStyle = getTextStyle(chartColors.minColor);
        final span = formatValueSpan(
            (double.tryParse('$mMainLowMinValue') ?? 0.0), realStyle);

        return span;
      }, isLeft: true);
      tp.paint(canvas, Offset(x + chartStyle.leftPadding, y - tp.height / 2));
    } else {
      //EMA
      TextPainter tp = getTextPainter(
          // mMainLowMinValue.toStringAsFixed(fixedLength) + " ──",
          //   formatValue(mMainLowMinValue) + " ──",
          " ──",
          // "",
          chartColors.minColor, addTextSpan: () {
        final realStyle = getTextStyle(chartColors.minColor);
        final span = formatValueSpan(
            (double.tryParse('$mMainLowMinValue') ?? 0.0), realStyle);

        return span;
      }, isLeft: false);
      tp.paint(canvas,
          Offset(x + chartStyle.leftPadding - tp.width, y - tp.height / 2));
    }
    x = translateXtoX(getX(mMainMaxIndex));
    y = getMainY(mMainHighMaxValue);
    if (x < mWidth / 2) {
      //draw right
      //EMA
      TextPainter tp = getTextPainter(
          // "── " + mMainHighMaxValue.toStringAsFixed(fixedLength),
          //   "── " + formatValue(mMainHighMaxValue),
          "── ",
          chartColors.maxColor, addTextSpan: () {
        final realStyle = getTextStyle(chartColors.maxColor);
        TextSpan span = formatValueSpan(
            (double.tryParse('$mMainHighMaxValue') ?? 0.0), realStyle);

        return span;
      }, isLeft: true);
      tp.paint(canvas, Offset(x + chartStyle.leftPadding, y - tp.height / 2));
    } else {
      //EMA
      TextPainter tp = getTextPainter(
          // mMainHighMaxValue.toStringAsFixed(fixedLength) + " ──",
          //   formatValue(mMainHighMaxValue) + " ──",
          " ──",
          chartColors.maxColor, addTextSpan: () {
        final realStyle = getTextStyle(chartColors.maxColor);
        final span = formatValueSpan(
            (double.tryParse('$mMainHighMaxValue') ?? 0.0), realStyle);

        return span;
      }, isLeft: false);
      tp.paint(canvas,
          Offset(x + chartStyle.leftPadding - tp.width, y - tp.height / 2));
    }
  }

  @override
  void drawNowPrice(Canvas canvas) {
    if (!showNowPrice) {
      return;
    }

    if (datas == null) {
      return;
    }

    double value = datas!.last.close;
    double y = getMainY(value);

    //view display area boundary value drawing
    if (y > getMainY(mMainLowMinValue)) {
      y = getMainY(mMainLowMinValue);
    }

    if (y < getMainY(mMainHighMaxValue)) {
      y = getMainY(mMainHighMaxValue);
    }

    nowPricePaint.color = value >= datas!.last.open
        ? chartColors.nowPriceUpColor
        : chartColors.nowPriceDnColor;
    //first draw the horizontal line
    double startX = 0;
    final max = -mTranslateX + mWidth / scaleX;
    final space = chartStyle.nowPriceLineSpan + chartStyle.nowPriceLineLength;
    while (startX < max) {
      canvas.drawLine(Offset(startX, y),
          Offset(startX + chartStyle.nowPriceLineLength, y), nowPricePaint);
      startX += space;
    }
    //repaint the background and text
    TextPainter tp = getTextPainter(
      value.toStringAsFixed(fixedLength),
      chartColors.nowPriceTextColor,
    );

    double offsetX;
    switch (verticalTextAlignment) {
      case VerticalTextAlignment.left:
        offsetX = mWidth - tp.width;
        break;
      case VerticalTextAlignment.right:
        offsetX = 0;
        break;
    }

    double top = y - tp.height / 2;
    canvas.drawRect(
        Rect.fromLTRB(offsetX, top, offsetX + tp.width, top + tp.height),
        nowPricePaint);
    tp.paint(canvas, Offset(offsetX, top));
  }

  //For TrendLine
  // void drawTrendLines(Canvas canvas, Size size) {
  //   var index = calculateSelectedX(selectX);
  //   Paint paintY = Paint()
  //     ..color = chartColors.trendLineColor
  //     ..strokeWidth = 1
  //     ..isAntiAlias = true;
  //   double x = getX(index);
  //   trendLineX = x;
  //
  //   double y = selectY;
  //   // getMainY(point.close);
  //
  //   // K-line chart vertical line
  //   canvas.drawLine(Offset(x, mTopPadding),
  //       Offset(x, size.height - mBottomPadding), paintY);
  //   Paint paintX = Paint()
  //     ..color = chartColors.trendLineColor
  //     ..strokeWidth = 1
  //     ..isAntiAlias = true;
  //   Paint paint = Paint()
  //     ..color = chartColors.trendLineColor
  //     ..strokeWidth = 1.0
  //     ..style = PaintingStyle.stroke
  //     ..strokeCap = StrokeCap.round;
  //   canvas.drawLine(Offset(-mTranslateX, y),
  //       Offset(-mTranslateX + mWidth / scaleX, y), paintX);
  //   if (scaleX >= 1) {
  //     canvas.drawOval(
  //       Rect.fromCenter(
  //           center: Offset(x, y), height: 15.0 * scaleX, width: 15.0),
  //       paint,
  //     );
  //   } else {
  //     canvas.drawOval(
  //       Rect.fromCenter(
  //           center: Offset(x, y), height: 10.0, width: 10.0 / scaleX),
  //       paint,
  //     );
  //   }
  //   if (lines.isNotEmpty) {
  //     lines.forEach((element) {
  //       var y1 = -((element.p1.dy - 35) / element.scale) + element.maxHeight;
  //       var y2 = -((element.p2.dy - 35) / element.scale) + element.maxHeight;
  //       var a = (trendLineMax! - y1) * trendLineScale! + trendLineContentRec!;
  //       var b = (trendLineMax! - y2) * trendLineScale! + trendLineContentRec!;
  //       var p1 = Offset(element.p1.dx, a);
  //       var p2 = Offset(element.p2.dx, b);
  //       canvas.drawLine(
  //           p1,
  //           element.p2 == Offset(-1, -1) ? Offset(x, y) : p2,
  //           Paint()
  //             ..color = Colors.yellow
  //             ..strokeWidth = 2);
  //     });
  //   }
  // }

  ///draw cross lines
  // void drawCrossLine(Canvas canvas, Size size) {
  //   var index = calculateSelectedX(selectX);
  //   KLineEntity point = getItem(index);
  //   Paint paintY = Paint()
  //     ..color = chartColors.vCrossColor
  //     ..strokeWidth = chartStyle.vCrossWidth
  //     ..isAntiAlias = true;
  //   double x = getX(index);
  //   double y = getMainY(point.close);
  //   // K-line chart vertical line
  //   canvas.drawLine(Offset(x, mTopPadding),
  //       Offset(x, size.height - mBottomPadding), paintY);
  //
  //   Paint paintX = Paint()
  //     ..color = chartColors.hCrossColor
  //     ..strokeWidth = chartStyle.hCrossWidth
  //     ..isAntiAlias = true;
  //   // K-line chart horizontal line
  //   canvas.drawLine(Offset(-mTranslateX, y),
  //       Offset(-mTranslateX + mWidth / scaleX, y), paintX);
  //   if (scaleX >= 1) {
  //     canvas.drawOval(
  //       Rect.fromCenter(center: Offset(x, y), height: 2.0 * scaleX, width: 2.0),
  //       paintX,
  //     );
  //   } else {
  //     canvas.drawOval(
  //       Rect.fromCenter(center: Offset(x, y), height: 2.0, width: 2.0 / scaleX),
  //       paintX,
  //     );
  //   }
  // }

  @override
  void drawCrossLine(Canvas canvas, Size size) {
    var index = calculateSelectedX(selectX);
    KLineEntity point = getItem(index);
    Paint paintY = Paint()
      ..color = chartColors.vCrossColor
      ..strokeWidth = chartStyle.vCrossWidth
      ..isAntiAlias = true;
    double x = getX(index);
    double y = getMainY(point.close);

    // Draw vertical dashed line
    drawDashedLine(canvas, Offset(x, mTopPadding),
        Offset(x, size.height - mBottomPadding), paintY);

    Paint paintX = Paint()
      ..color = chartColors.hCrossColor
      ..strokeWidth = chartStyle.hCrossWidth
      ..isAntiAlias = true;

    // Draw horizontal dashed line
    drawDashedLine(canvas, Offset(-mTranslateX, y),
        Offset(-mTranslateX + mWidth / scaleX, y), paintX);

    if (scaleX >= 1) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), height: 2.0 * scaleX, width: 2.0),
        paintX,
      );
    } else {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), height: 2.0, width: 2.0 / scaleX),
        paintX,
      );
    }
  }

  void drawTrendLines(Canvas canvas, Size size) {
    var index = calculateSelectedX(selectX);
    Paint paintY = Paint()
      ..color = chartColors.trendLineColor
      ..strokeWidth = 1
      ..isAntiAlias = true;
    double x = getX(index);
    trendLineX = x;

    double y = selectY;

    drawDashedLine(canvas, Offset(x, mTopPadding),
        Offset(x, size.height - mBottomPadding), paintY);

    Paint paintX = Paint()
      ..color = chartColors.trendLineColor
      ..strokeWidth = 1
      ..isAntiAlias = true;

    drawDashedLine(canvas, Offset(-mTranslateX, y),
        Offset(-mTranslateX + mWidth / scaleX, y), paintX);

    Paint paint = Paint()
      ..color = chartColors.trendLineColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (scaleX >= 1) {
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(x, y), height: 15.0 * scaleX, width: 15.0),
        paint,
      );
    } else {
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(x, y), height: 10.0, width: 10.0 / scaleX),
        paint,
      );
    }
    if (lines.isNotEmpty) {
      for (var element in lines) {
        var y1 = -((element.p1.dy - 35) / element.scale) + element.maxHeight;
        var y2 = -((element.p2.dy - 35) / element.scale) + element.maxHeight;
        var a = (trendLineMax! - y1) * trendLineScale! + trendLineContentRec!;
        var b = (trendLineMax! - y2) * trendLineScale! + trendLineContentRec!;
        var p1 = Offset(element.p1.dx, a);
        var p2 = Offset(element.p2.dx, b);
        canvas.drawLine(
            p1,
            element.p2 == Offset(-1, -1) ? Offset(x, y) : p2,
            Paint()
              ..color = Colors.yellow
              ..strokeWidth = 2);
      }
    }
  }

  void drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const double dashWidth = 3;
    const double dashSpace = 2;
    double distance = (end - start).distance;
    double dashCount = (distance / (dashWidth + dashSpace)).floorToDouble();

    for (int i = 0; i < dashCount; ++i) {
      double startX = start.dx + (end.dx - start.dx) * (i / dashCount);
      double startY = start.dy + (end.dy - start.dy) * (i / dashCount);
      double endX = start.dx + (end.dx - start.dx) * ((i + 0.5) / dashCount);
      double endY = start.dy + (end.dy - start.dy) * ((i + 0.5) / dashCount);
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
  }

  TextPainter getTextPainter(text, color, {addTextSpan, isLeft}) {
    color ??= chartColors.defaultTextColor;

    TextSpan? spanAll;

    TextSpan span = TextSpan(text: "$text", style: getTextStyle(color));
    if (addTextSpan != null) {
      TextSpan spanS = addTextSpan();
      List<InlineSpan> children = [];
      if (isLeft != null && isLeft) {
        children.add(span);
        children.add(spanS);
      } else {
        children.add(spanS);
        children.add(span);
      }
      spanAll = TextSpan(children: children);
    } else {
      List<InlineSpan> children = [];
      children.add(span);
      spanAll = TextSpan(children: children);
    }
    TextPainter tp =
        TextPainter(text: spanAll, textDirection: TextDirection.ltr);
    tp.layout();
    return tp;
  }

  String getDate(int? date) => dateFormat(
        DateTime.fromMillisecondsSinceEpoch(
            date ?? DateTime.now().millisecondsSinceEpoch),
        mFormats,
      );

  double getMainY(double y) => mMainRenderer.getY(y);

  /// Whether the point is in the SecondaryRect
  // bool isInSecondaryRect(Offset point) {
  //   // return mSecondaryRect.contains(point) == true);
  //   return false;
  // }

  /// Whether the point is in MainRect
  bool isInMainRect(Offset point) {
    return mMainRect.contains(point);
  }
}
