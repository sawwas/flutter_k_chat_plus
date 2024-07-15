import 'dart:math';
import 'package:flutter/material.dart'
    show Color, TextStyle, Rect, Canvas, Size, CustomPainter;
import 'package:k_chart_plus/utils/date_format_util.dart';
import '../chart_style.dart' show ChartStyle;
import '../entity/k_line_entity.dart';
import '../k_chart_widget.dart';
import 'base_dimension.dart';
export 'package:flutter/material.dart'
    show Color, required, TextStyle, Rect, Canvas, Size, CustomPainter;

/// BaseChartPainter
abstract class BaseChartPainter extends CustomPainter {
  static double maxScrollX = 0.0;
  List<KLineEntity>? datas; // data of chart
  MainState mainState;

  Set<SecondaryState> secondaryStateLi;

  bool volHidden;
  bool isTapShowInfoDialog;
  double scaleX = 1.0, scrollX = 0.0, selectX;
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
  final ChartStyle chartStyle;
  late double mPointWidth;
  // format time
  List<String> mFormats = [yyyy, '-', mm, '-', dd, ' ', HH, ':', nn];
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
    this.mainState = MainState.MA,
    this.volHidden = false,
    this.isTapShowInfoDialog = false,
    this.secondaryStateLi = const <SecondaryState>{},
    this.isLine = false,
  }) {
    mItemCount = datas?.length ?? 0;
    mPointWidth = this.chartStyle.pointWidth;
    mTopPadding = this.chartStyle.topPadding;
    mBottomPadding = this.chartStyle.bottomPadding;
    mChildPadding = this.chartStyle.childPadding;
    mGridRows = this.chartStyle.gridRows;
    mGridColumns = this.chartStyle.gridColumns;
    mDataLen = mItemCount * mPointWidth;
    initFormats();
  }

  /// init format time
  void initFormats() {
    if (this.chartStyle.dateTimeFormat != null) {
      mFormats = this.chartStyle.dateTimeFormat!;
      return;
    }

    if (mItemCount < 2) {
      mFormats = [yyyy, '-', mm, '-', dd, ' ', HH, ':', nn];
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
      mFormats = [mm, '-', dd, ' ', HH, ':', nn];
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

      if (isLongPress == true || (isTapShowInfoDialog && isOnTap)) {
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
  calculateValue() {
    if (datas == null) return;
    if (datas!.isEmpty) return;
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
    if (mainState == MainState.MA) {
      maxPrice = max(item.high, _findMaxMA(item.maValueList ?? [0]));
      minPrice = min(item.low, _findMinMA(item.maValueList ?? [0]));
    } else if (mainState == MainState.BOLL) {
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

  // compute maximum and minimum of secondary value
  getSecondaryMaxMinValue(int index, KLineEntity item) {
    SecondaryState secondaryState = secondaryStateLi.elementAt(index);
    switch (secondaryState) {
      // MACD
      case SecondaryState.MACD:
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
      case SecondaryState.KDJ:
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
      case SecondaryState.RSI:
        if (item.rsi != null) {
          mSecondaryRectList[index].mMaxValue =
              max(mSecondaryRectList[index].mMaxValue, item.rsi!);
          mSecondaryRectList[index].mMinValue =
              min(mSecondaryRectList[index].mMinValue, item.rsi!);
        }
        break;
      // WR
      case SecondaryState.WR:
        mSecondaryRectList[index].mMaxValue = 0;
        mSecondaryRectList[index].mMinValue = -100;
        break;
      // CCI
      case SecondaryState.CCI:
        if (item.cci != null) {
          mSecondaryRectList[index].mMaxValue =
              max(mSecondaryRectList[index].mMaxValue, item.cci!);
          mSecondaryRectList[index].mMinValue =
              min(mSecondaryRectList[index].mMinValue, item.cci!);
        }
        break;
      default:
        mSecondaryRectList[index].mMaxValue = 0;
        mSecondaryRectList[index].mMinValue = 0;
        break;
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
    return TextStyle(fontSize: 10.0, color: color);
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
