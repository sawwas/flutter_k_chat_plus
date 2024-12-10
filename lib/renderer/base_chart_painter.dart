import 'dart:math';
import 'package:flutter/material.dart'
    show
        Canvas,
        Color,
        CustomPainter,
        FontFeature,
        FontWeight,
        Rect,
        Size,
        TextSpan,
        TextStyle;
import 'package:k_chart_plus_deeping/utils/date_format_util.dart';
import '../chart_style.dart' show ChartStyle;
import '../entity/k_line_entity.dart';
import '../k_chart_widget.dart';
import 'base_dimension.dart';
export 'package:flutter/material.dart'
    show Color, required, TextStyle, Rect, Canvas, Size, CustomPainter;

/// A base class for rendering chart components.
///
/// This class provides common functionality for painting charts,
/// such as rendering styles, data, and helper methods.
///
/// BaseChartPainter
/// Purpose: This abstract class serves as the base for specific chart painters
/// (e.g., candlestick chart, line chart). It handles common chart drawing logic like calculating values,
/// drawing the background, grid, and axes.
abstract class BaseChartPainter extends CustomPainter {
  static double maxScrollX = 0.0;

  ///A list of KLineEntity objects representing the chart data.
  List<KLineEntity>? datas; // data of chart
  ///An enum indicating the type of main chart (e.g., MA, BOLL).
  MainState mainState;

  ///A set of enums indicating the types of secondary indicators to display (e.g., MACD, KDJ).
  Set<SecondaryState> secondaryStateLi;

  ///A boolean to control the visibility of the volume chart.
  bool volHidden;
  bool isTapShowInfoDialog;

  ///Values for zooming and scrolling the chart horizontally.
  double scaleX = 1.0, scrollX = 0.0, selectX;

  ///Variables related to long-press interactions.
  bool isLongPress = false;
  bool isOnTap;
  bool isLine;

  /// Rectangle box of main chart
  late Rect mMainRect;

  /// Rectangle box of the vol chart
  Rect? mVolRect;

  /// Secondary list support
  List<RenderRect> mSecondaryRectList = [];
  late double mDisplayHeight, mWidth;

  // padding
  double mTopPadding = 30.0, mBottomPadding = 20.0, mChildPadding = 12.0;

  // grid: rows - columns
  int mGridRows = 4, mGridColumns = 4;
  int mStartIndex = 0, mStopIndex = 0;
  double mMainMaxValue = double.minPositive, mMainMinValue = double.maxFinite;
  double mVolMaxValue = double.minPositive, mVolMinValue = double.maxFinite;
  double mTranslateX = double.minPositive;
  int mMainMaxIndex = 0, mMainMinIndex = 0;
  double mMainHighMaxValue = double.minPositive,
      mMainLowMinValue = double.maxFinite;
  int mItemCount = 0;
  double mDataLen = 0.0; // the data occupies the total length of the screen
  ///chart style
  final ChartStyle chartStyle;
  late double mPointWidth;

  // format time
  List<String> mFormats = [yyyy, '-', mm, '-', dd, ' ', hH, ':', nn];
  double xFrontPadding;

  /// base dimension
  final BaseDimension baseDimension;

  /// constructor BaseChartPainter
  ///
  BaseChartPainter(
    this.chartStyle, {
    this.datas,
    required this.scaleX,
    required this.scrollX,
    required this.isLongPress,
    required this.selectX,
    required this.xFrontPadding,
    required this.baseDimension,
    this.isOnTap = false,
    this.mainState = MainState.mA,
    this.volHidden = false,
    this.isTapShowInfoDialog = false,
    this.secondaryStateLi = const <SecondaryState>{},
    this.isLine = false,
  }) {
    mItemCount = datas?.length ?? 0;
    mPointWidth = chartStyle.pointWidth;
    mTopPadding = chartStyle.topPadding;
    mBottomPadding = chartStyle.bottomPadding;
    mChildPadding = chartStyle.childPadding;
    mGridRows = chartStyle.gridRows;
    mGridColumns = chartStyle.gridColumns;
    mDataLen = mItemCount * mPointWidth;
    initFormats();
  }

  /// init format time
  void initFormats() {
    if (chartStyle.dateTimeFormat != null) {
      mFormats = chartStyle.dateTimeFormat!;
      return;
    }

    if (mItemCount < 2) {
      mFormats = [yyyy, '-', mm, '-', dd, ' ', hH, ':', nn];
      return;
    }

    int firstTime = datas!.first.time ?? 0;
    int secondTime = datas![1].time ?? 0;
    int time = secondTime - firstTime;
    time ~/= 1000;
    // monthly line
    if (time >= 24 * 60 * 60 * 28) {
      mFormats = [yy, '-', mm];
    } else if (time >= 24 * 60 * 60) {
      // daily line
      mFormats = [yy, '-', mm, '-', dd];
    } else {
      // hour line
      mFormats = [mm, '-', dd, ' ', hH, ':', nn];
    }
  }

  /// paint chart
  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Rect.fromLTRB(0, 0, size.width, size.height));
    mDisplayHeight = size.height - mTopPadding - mBottomPadding;
    mWidth = size.width;
    initRect(size);
    calculateValue();

    ///An abstract method to be implemented by specific chart painters to draw the actual chart elements (e.g., candlesticks, lines).
    initChartRenderer();

    canvas.save();
    canvas.scale(1, 1);
    drawBg(canvas, size);
    drawGrid(canvas);
    if (datas != null && datas!.isNotEmpty) {
      drawChart(canvas, size);
      drawVerticalText(canvas);
      drawDate(canvas, size);

      drawText(canvas, datas!.last, 5);
      drawMaxAndMin(canvas);
      drawNowPrice(canvas);

      if (chartStyle.isLongFocus &&
          (isLongPress == true ||
              (isTapShowInfoDialog && longPressTriggered))) {
        drawCrossLineText(canvas, size);
      } else if (!chartStyle.isLongFocus &&
          (isLongPress == true || (isTapShowInfoDialog && isOnTap))) {
        drawCrossLineText(canvas, size);
      }
    }
    canvas.restore();
  }

  /// init chart renderer
  void initChartRenderer();

  /// draw the background of chart
  void drawBg(Canvas canvas, Size size);

  /// draw the grid of chart
  void drawGrid(canvas);

  /// draw chart
  void drawChart(Canvas canvas, Size size);

  /// draw vertical text
  void drawVerticalText(canvas);

  /// draw date
  void drawDate(Canvas canvas, Size size);

  /// draw text
  void drawText(Canvas canvas, KLineEntity data, double x);

  /// draw maximum and minimum values
  void drawMaxAndMin(Canvas canvas);

  /// draw the current price
  void drawNowPrice(Canvas canvas);

  /// draw cross line
  void drawCrossLine(Canvas canvas, Size size);

  /// draw text of the cross line
  void drawCrossLineText(Canvas canvas, Size size);

  /// init the rectangle box to draw chart
  void initRect(Size size) {
    double volHeight = baseDimension.mVolumeHeight;
    double secondaryHeight = baseDimension.mSecondaryHeight;

    double mainHeight = mDisplayHeight;
    mainHeight -= volHeight;
    mainHeight -= (secondaryHeight * secondaryStateLi.length);

    mMainRect = Rect.fromLTRB(0, mTopPadding, mWidth, mTopPadding + mainHeight);

    if (volHidden != true) {
      mVolRect = Rect.fromLTRB(0, mMainRect.bottom + mChildPadding, mWidth,
          mMainRect.bottom + volHeight);
    }

    mSecondaryRectList.clear();
    for (int i = 0; i < secondaryStateLi.length; ++i) {
      mSecondaryRectList.add(RenderRect(
        Rect.fromLTRB(
            0,
            mMainRect.bottom + volHeight + i * secondaryHeight + mChildPadding,
            mWidth,
            mMainRect.bottom +
                volHeight +
                i * secondaryHeight +
                secondaryHeight),
      ));
    }
  }

  /// calculate values
  /// Calculates maximum and minimum values, indices, and other data needed for drawing.
  calculateValue() {
    if (datas == null) {
      return;
    }
    if (datas!.isEmpty) {
      return;
    }
    maxScrollX = getMinTranslateX().abs();
    setTranslateXFromScrollX(scrollX);
    mStartIndex = indexOfTranslateX(xToTranslateX(0));
    mStopIndex = indexOfTranslateX(xToTranslateX(mWidth));
    for (int i = mStartIndex; i <= mStopIndex; i++) {
      var item = datas![i];
      getMainMaxMinValue(item, i);
      getVolMaxMinValue(item);
      for (int idx = 0; idx < mSecondaryRectList.length; ++idx) {
        getSecondaryMaxMinValue(idx, item);
      }
    }
  }

  /// compute maximum and minimum value
  void getMainMaxMinValue(KLineEntity item, int i) {
    double maxPrice, minPrice;
    if (mainState == MainState.mA) {
      maxPrice = max(item.high, _findMaxMA(item.maValueList ?? [0]));
      minPrice = min(item.low, _findMinMA(item.maValueList ?? [0]));
    } else if (mainState == MainState.bOLL) {
      maxPrice = max(item.up ?? 0, item.high);
      minPrice = min(item.dn ?? 0, item.low);
    } else {
      maxPrice = item.high;
      minPrice = item.low;
    }
    mMainMaxValue = max(mMainMaxValue, maxPrice);
    mMainMinValue = min(mMainMinValue, minPrice);

    if (mMainHighMaxValue < item.high) {
      mMainHighMaxValue = item.high;
      mMainMaxIndex = i;
    }
    if (mMainLowMinValue > item.low) {
      mMainLowMinValue = item.low;
      mMainMinIndex = i;
    }

    if (isLine == true) {
      mMainMaxValue = max(mMainMaxValue, item.close);
      mMainMinValue = min(mMainMinValue, item.close);
    }
  }

  // find maximum of the MA
  double _findMaxMA(List<double> a) {
    double result = double.minPositive;
    for (double i in a) {
      result = max(result, i);
    }
    return result;
  }

  // find minimum of the MA
  double _findMinMA(List<double> a) {
    double result = double.maxFinite;
    for (double i in a) {
      result = min(result, i == 0 ? double.maxFinite : i);
    }
    return result;
  }

  // get the maximum and minimum of the Vol value
  void getVolMaxMinValue(KLineEntity item) {
    mVolMaxValue = max(mVolMaxValue,
        max(item.vol, max(item.MA5Volume ?? 0, item.MA10Volume ?? 0)));
    mVolMinValue = min(mVolMinValue,
        min(item.vol, min(item.MA5Volume ?? 0, item.MA10Volume ?? 0)));
  }

  /// compute maximum and minimum of secondary value
  getSecondaryMaxMinValue(int index, KLineEntity item) {
    SecondaryState secondaryState = secondaryStateLi.elementAt(index);
    switch (secondaryState) {
      // MACD
      case SecondaryState.mACD:
        if (item.macd != null) {
          mSecondaryRectList[index].mMaxValue = max(
              mSecondaryRectList[index].mMaxValue,
              max(item.macd!, max(item.dif!, item.dea!)));
          mSecondaryRectList[index].mMinValue = min(
              mSecondaryRectList[index].mMinValue,
              min(item.macd!, min(item.dif!, item.dea!)));
        }
        break;
      // KDJ
      case SecondaryState.kDJ:
        if (item.d != null) {
          mSecondaryRectList[index].mMaxValue = max(
              mSecondaryRectList[index].mMaxValue,
              max(item.k!, max(item.d!, item.j!)));
          mSecondaryRectList[index].mMinValue = min(
              mSecondaryRectList[index].mMinValue,
              min(item.k!, min(item.d!, item.j!)));
        }
        break;
      // RSI
      case SecondaryState.rSI:
        if (item.rsi != null) {
          mSecondaryRectList[index].mMaxValue =
              max(mSecondaryRectList[index].mMaxValue, item.rsi!);
          mSecondaryRectList[index].mMinValue =
              min(mSecondaryRectList[index].mMinValue, item.rsi!);
        }
        break;
      // WR
      case SecondaryState.wR:
        mSecondaryRectList[index].mMaxValue = 0;
        mSecondaryRectList[index].mMinValue = -100;
        break;
      // CCI
      case SecondaryState.cCI:
        if (item.cci != null) {
          mSecondaryRectList[index].mMaxValue =
              max(mSecondaryRectList[index].mMaxValue, item.cci!);
          mSecondaryRectList[index].mMinValue =
              min(mSecondaryRectList[index].mMinValue, item.cci!);
        }
        break;
      // default:
      //   mSecondaryRectList[index].mMaxValue = 0;
      //   mSecondaryRectList[index].mMinValue = 0;
      //   break;
    }
  }

  // translate x
  double xToTranslateX(double x) => -mTranslateX + x / scaleX;

  int indexOfTranslateX(double translateX) =>
      _indexOfTranslateX(translateX, 0, mItemCount - 1);

  /// Using binary search for the index of the current value
  int _indexOfTranslateX(double translateX, int start, int end) {
    if (end == start || end == -1) {
      return start;
    }
    if (end - start == 1) {
      double startValue = getX(start);
      double endValue = getX(end);
      return (translateX - startValue).abs() < (translateX - endValue).abs()
          ? start
          : end;
    }
    int mid = start + (end - start) ~/ 2;
    double midValue = getX(mid);
    if (translateX < midValue) {
      return _indexOfTranslateX(translateX, start, mid);
    } else if (translateX > midValue) {
      return _indexOfTranslateX(translateX, mid, end);
    } else {
      return mid;
    }
  }

  /// Get x coordinate based on index
  /// + mPointWidth / 2 to prevent the first and last K-line from displaying incorrectly
  /// @param position index value
  double getX(int position) => position * mPointWidth + mPointWidth / 2;

  ///Methods for converting between screen coordinates and data indices.
  KLineEntity getItem(int position) {
    return datas![position];
    // if (datas != null) {
    //   return datas[position];
    // } else {
    //   return null;
    // }
  }

  /// scrollX convert to TranslateX
  void setTranslateXFromScrollX(double scrollX) =>
      mTranslateX = scrollX + getMinTranslateX();

  /// get the minimum value of translation
  double getMinTranslateX() {
    var x = -mDataLen + mWidth / scaleX - mPointWidth / 2 - xFrontPadding;
    return x >= 0 ? 0.0 : x;
  }

  /// calculate the value of x after long pressing and convert to [index]
  int calculateSelectedX(double selectX) {
    int mSelectedIndex = indexOfTranslateX(xToTranslateX(selectX));
    if (mSelectedIndex < mStartIndex) {
      mSelectedIndex = mStartIndex;
    }
    if (mSelectedIndex > mStopIndex) {
      mSelectedIndex = mStopIndex;
    }
    return mSelectedIndex;
  }

  /// translateX is converted to X in view
  double translateXtoX(double translateX) =>
      (translateX + mTranslateX) * scaleX;

  /// define text style
  TextStyle getTextStyle(Color color) {
    return TextStyle(fontSize: chartStyle.sizeText, color: color);
  }

  @override
  bool shouldRepaint(BaseChartPainter oldDelegate) {
    return true;
  }
}

/// Render Rectangle
class RenderRect {
  Rect mRect;
  double mMaxValue = double.minPositive, mMinValue = double.maxFinite;

  RenderRect(this.mRect);
}

//# 科学下标
TextSpan formatValueSpan(double? value, TextStyle style) {
  if (value == 0.00) {
    return TextSpan(text: ' 0.00', style: style);
    // return TextSpan(text: '\$ 0.00', style: style);
  }

  String dollarValue(double value, int decimals) {
    return value.toStringAsFixed(decimals);
    // return '\$' + value.toStringAsFixed(decimals);
  }

  if (value != null && value < 0.01) {
    final temp = value.toStringAsFixed(8).split('.');
    if (temp.length != 2) {
      return TextSpan(text: dollarValue(value, 2), style: style);
    }
    var index = 0;
    for (; index < temp[1].length; index++) {
      if (temp[1][index] != '0') {
        break;
      }
    }
    final remain = temp[1].replaceRange(0, index, '');
    return TextSpan(
      text: '0.0',
      // text: '\$0.0',
      children: [
        ///	•	FontFeature.alternativeFractions(): 使用替代分数样式。
        // 	•	FontFeature.caseSensitiveForms(): 使用大小写敏感表单样式。
        // 	•	FontFeature.characterVariant(int value): 使用字符变体。
        // 	•	FontFeature.contextualAlternates(): 使用上下文替代样式。
        // 	•	FontFeature.denominator(): 使用分母样式。
        // 	•	FontFeature.fractions(): 使用分数样式。
        // 	•	FontFeature.historicalForms(): 使用历史表单样式。
        // 	•	FontFeature.liningFigures(): 使用等线数字。
        // 	•	FontFeature.localeAware(value): 使用特定语言环境的字体特性。
        // 	•	FontFeature.notationalForms(int value): 使用符号表单。
        // 	•	FontFeature.numerators(): 使用分子样式。
        // 	•	FontFeature.ordinalForms(): 使用序数样式。
        // 	•	FontFeature.proportionalFigures(): 使用比例数字。
        // 	•	FontFeature.scientificInferiors(): 使用科学下标样式。
        // 	•	FontFeature.slashedZero(): 使用带斜线的零。
        TextSpan(
          text: '$index',
          style: style.copyWith(
              fontFeatures: [
                FontFeature.oldstyleFigures(),
                FontFeature.scientificInferiors(),
              ],
              fontSize: style.fontSize == null ? null : style.fontSize! - 3,
              fontWeight: FontWeight.w900), // 调整行高以模拟偏移效果
        ),
        // WidgetSpan(
        //   child: Transform.translate(
        //     offset: Offset(0, 0),
        //     child: Text(
        //       '$index',
        //       style: style.copyWith(
        //           fontWeight: FontWeight.w900,
        //           textBaseline: TextBaseline.ideographic,
        //           fontSize:
        //               style.fontSize == null ? null : style.fontSize! - 3,
        //          ),
        //     ),
        //   ),
        // ),
        TextSpan(
            text: remain.substring(0, min(remain.length, 4)), style: style),
      ],
      style: style,
    );
  }

  String realValueStr = '-';
  if (value != null) {
    if (value >= 1000000000) {
      realValueStr = '${dollarValue(value / 1000000000, 2)}B';
    } else if (value >= 1000000) {
      realValueStr = '${dollarValue(value / 1000000, 2)}M';
    } else if (value >= 1000) {
      realValueStr = '${dollarValue(value / 1000, 2)}K';
    } else {
      realValueStr = dollarValue(value, 2);
    }
  }
  return TextSpan(text: realValueStr, style: style);
}
