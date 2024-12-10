import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:k_chart_plus_deeping/chart_translations.dart';
import 'package:k_chart_plus_deeping/components/popup_info_view.dart';
import 'package:k_chart_plus_deeping/k_chart_plus.dart';
import 'renderer/base_dimension.dart';

enum MainState { mA, bOLL, nONE }

// enum SecondaryState { MACD, KDJ, RSI, WR, CCI, NONE }
enum SecondaryState { mACD, kDJ, rSI, wR, cCI } //no support NONE

class TimeFormat {
  static const List<String> yearMONTHDAY = [yyyy, '-', mm, '-', dd];
  static const List<String> yearMONTHDAYWITHHOUR = [
    yyyy,
    '-',
    mm,
    '-',
    dd,
    ' ',
    hH,
    ':',
    nn
  ];
}

class KChartWidget extends StatefulWidget {
  final List<KLineEntity>? datas;
  final MainState mainState;
  final bool volHidden;
  final Set<SecondaryState> secondaryStateLi;

  // final Function()? onSecondaryTap;
  final bool isLine;
  final bool
      isTapShowInfoDialog; //Whether to enable click to display detailed data
  final bool hideGrid;
  final bool showNowPrice;
  final bool showInfoDialog;
  final bool materialInfoDialog; // Material Style Information Popup
  final ChartTranslations chartTranslations;
  final List<String> timeFormat;
  final double mBaseHeight;

  // It will be called when the screen scrolls to the end.
  // If true, it will be scrolled to the end of the right side of the screen.
  // If it is false, it will be scrolled to the end of the left side of the screen.
  final Function(bool)? onLoadMore;

  final int fixedLength;
  final List<int> maDayList;
  final int flingTime;
  final double flingRatio;
  final Curve flingCurve;
  final Function(bool)? isOnDrag;
  final ChartColors chartColors;
  final ChartStyle chartStyle;
  final VerticalTextAlignment verticalTextAlignment;
  final bool isTrendLine;
  final double xFrontPadding;
  final int isLongFocusDurationTime;

  KChartWidget(this.datas, this.chartStyle, this.chartColors,
      {required this.isTrendLine,
      this.xFrontPadding = 100,
      this.mainState = MainState.mA,
      this.secondaryStateLi = const <SecondaryState>{},
      // this.onSecondaryTap,
      this.volHidden = false,
      this.isLine = false,
      this.isTapShowInfoDialog = false,
      this.hideGrid = false,
      this.showNowPrice = true,
      this.showInfoDialog = true,
      this.materialInfoDialog = true,
      this.chartTranslations = const ChartTranslations(),
      this.timeFormat = TimeFormat.yearMONTHDAY,
      this.onLoadMore,
      this.fixedLength = 2,
      this.maDayList = const [5, 10, 20],
      this.flingTime = 600,
      this.flingRatio = 0.5,
      this.flingCurve = Curves.decelerate,
      this.isOnDrag,
      this.verticalTextAlignment = VerticalTextAlignment.left,
      this.mBaseHeight = 360,
      //# 十字光标长按 / 短按切换 0.5秒后才触发
      this.isLongFocusDurationTime = 500});

  @override
  State<StatefulWidget> createState() => KChartWidgetState();
}

bool longPressTriggered = false;

class KChartWidgetState extends State<KChartWidget>
    with TickerProviderStateMixin {
  final StreamController<InfoWindowEntity?> mInfoWindowStream =
      StreamController<InfoWindowEntity?>.broadcast();
  double mScaleX = 1.0, mScrollX = 0.0, mSelectX = 0.0;
  double mHeight = 0, mWidth = 0;
  AnimationController? _controller;
  Animation<double>? aniX;

  //For TrendLine
  List<TrendLine> lines = [];
  double? changeinXposition;
  double? changeinYposition;
  double mSelectY = 0.0;
  bool waitingForOtherPairofCords = false;
  bool enableCordRecord = false;

  double getMinScrollX() {
    return mScaleX;
  }

  double _lastScale = 1.0;
  bool isScale = false, isDrag = false, isLongPress = false, isOnTap = false;

  int pointerCount = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    mInfoWindowStream.sink.close();
    mInfoWindowStream.close();
    _controller?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  DateTime? _longPressStartTime;
  Timer? _timer;

  @override
  Widget build(BuildContext context) {
    if (widget.datas != null && widget.datas!.isEmpty) {
      mScrollX = mSelectX = 0.0;
      mScaleX = 1.0;
    }
    final BaseDimension baseDimension = BaseDimension(
      mBaseHeight: widget.mBaseHeight,
      volHidden: widget.volHidden,
      secondaryStateLi: widget.secondaryStateLi,
    );
    final painter = ChartPainter(
      widget.chartStyle,
      widget.chartColors,
      baseDimension: baseDimension,
      lines: lines,
      //For TrendLine
      sink: mInfoWindowStream.sink,
      xFrontPadding: widget.xFrontPadding,
      isTrendLine: widget.isTrendLine,
      //For TrendLine
      selectY: mSelectY,
      //For TrendLine
      datas: widget.datas,
      scaleX: mScaleX,
      scrollX: mScrollX,
      selectX: mSelectX,
      isLongPass: isLongPress,
      isOnTap: isOnTap,
      isTapShowInfoDialog: widget.isTapShowInfoDialog,
      mainState: widget.mainState,
      volHidden: widget.volHidden,
      secondaryStateLi: widget.secondaryStateLi,
      isLine: widget.isLine,
      hideGrid: widget.hideGrid,
      showNowPrice: widget.showNowPrice,
      fixedLength: widget.fixedLength,
      maDayList: widget.maDayList,
      verticalTextAlignment: widget.verticalTextAlignment,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        mHeight = constraints.maxHeight;
        mWidth = constraints.maxWidth;
        return RawGestureDetector(
          gestures: {
            // Registering a ScaleGestureRecognizer to handle scale gestures
            ScaleGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
              () => ScaleGestureRecognizer(),
              (ScaleGestureRecognizer instance) {
                instance
                  ..onStart = (details) {
                    pointerCount = details.pointerCount;
                    isScale = true;
                  }
                  ..onUpdate = (details) {
                    pointerCount = details.pointerCount;
                    // if (isDrag || isLongPress) return;
                    // if (isLongPress) return;
                    mScaleX = (_lastScale * details.scale).clamp(0.5, 2.2);
                    notifyChanged();
                  }
                  ..onEnd = (details) {
                    pointerCount = 1;
                    isScale = false;
                    _lastScale = mScaleX;
                  };
              },
            ),
            // Registering a HorizontalDragGestureRecognizer to handle horizontal drag gestures
            HorizontalDragGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<
                    HorizontalDragGestureRecognizer>(
              () => HorizontalDragGestureRecognizer(),
              (HorizontalDragGestureRecognizer instance) {
                instance
                  ..onDown = (details) {
                    if (pointerCount > 1) {
                      return;
                    }
                    isOnTap = false;
                    _stopAnimation();
                    _onDragChanged(true);
                  }
                  ..onUpdate = (details) {
                    if (pointerCount > 1) {
                      return;
                    }
                    if (isScale || isLongPress) {
                      return;
                    }
                    mScrollX =
                        ((details.primaryDelta ?? 0) / mScaleX + mScrollX)
                            .clamp(0.0, ChartPainter.maxScrollX)
                            .toDouble();
                    notifyChanged();
                  }
                  ..onEnd = (details) {
                    var velocity = details.velocity.pixelsPerSecond.dx;
                    _onFling(velocity);
                    _onDragChanged(false);
                  }
                  ..onCancel = () {
                    _onDragChanged(false);
                  };
              },
            ),
          },
          child: GestureDetector(
            onTapUp: (details) {
              // if (!widget.isTrendLine && widget.onSecondaryTap != null && _painter.isInSecondaryRect(details.localPosition)) {
              //   widget.onSecondaryTap!();
              // }

              if (!widget.isTrendLine &&
                  painter.isInMainRect(details.localPosition)) {
                isOnTap = true;

                if (mSelectX != details.localPosition.dx &&
                    widget.isTapShowInfoDialog) {
                  mSelectX = details.localPosition.dx;

                  longPressTriggered = false;
                  _timer?.cancel();

                  Future.delayed(Duration(milliseconds: 12500), () {
                    notifyChanged();
                  });
                }
              }
              if (widget.isTrendLine && !isLongPress && enableCordRecord) {
                enableCordRecord = false;
                Offset p1 = Offset(getTrendLineX(), mSelectY);
                if (!waitingForOtherPairofCords) {
                  lines.add(TrendLine(
                      p1, Offset(-1, -1), trendLineMax!, trendLineScale!));
                }

                if (waitingForOtherPairofCords) {
                  var a = lines.last;
                  lines.removeLast();
                  lines
                      .add(TrendLine(a.p1, p1, trendLineMax!, trendLineScale!));
                  waitingForOtherPairofCords = false;
                } else {
                  waitingForOtherPairofCords = true;
                }
                notifyChanged();
              }
            },
            // onHorizontalDragDown: (details) {
            //   if(pointerCount > 1 ){
            //     return;
            //   }
            //   isOnTap = false;
            //   _stopAnimation();
            //   _onDragChanged(true);
            // },
            // onHorizontalDragUpdate: (details) {
            //   if(pointerCount > 1 ){
            //     return;
            //   }
            //   if (isScale || isLongPress) return;
            //   mScrollX = ((details.primaryDelta ?? 0) / mScaleX + mScrollX)
            //       .clamp(0.0, ChartPainter.maxScrollX)
            //       .toDouble();
            //   notifyChanged();
            // },
            // onHorizontalDragEnd: (DragEndDetails details) {
            //   if(pointerCount > 1 ){
            //     return;
            //   }
            //   var velocity = details.velocity.pixelsPerSecond.dx;
            //   _onFling(velocity);
            // },
            // onHorizontalDragCancel: () => _onDragChanged(false),
            // onScaleStart: (_) {
            //   pointerCount = _.pointerCount;
            //   isScale = true;
            // },
            // onScaleUpdate: (details) {
            //   pointerCount = details.pointerCount;
            //   // if (isDrag || isLongPress) return;
            //   // if (isLongPress) return;
            //   mScaleX = (_lastScale * details.scale).clamp(0.5, 2.2);
            //   notifyChanged();
            // },
            // onScaleEnd: (_) {
            //   pointerCount = 1;
            //   isScale = false;
            //   _lastScale = mScaleX;
            // },
            onLongPressStart: (details) {
              _timer?.cancel();
              _longPressStartTime = DateTime.now();
              longPressTriggered = false;
              // print("notifyChanged: onLongPressStart");
              // _timer = Timer(
              //     Duration(milliseconds: widget.isLongFocusDurationTime*2), () {
              //   // notifyChanged();
              //   longPressTriggered = true;
              //
              //   // print("notifyChanged: onLongPressStart - 2");
              // });

              isOnTap = false;
              isLongPress = true;
              if ((mSelectX != details.localPosition.dx ||
                      mSelectY != details.globalPosition.dy) &&
                  !widget.isTrendLine) {
                mSelectX = details.localPosition.dx;
                notifyChanged();
              }
              //For TrendLine
              if (widget.isTrendLine && changeinXposition == null) {
                mSelectX = changeinXposition = details.localPosition.dx;
                mSelectY = changeinYposition = details.globalPosition.dy;
                notifyChanged();
              }
              //For TrendLine
              if (widget.isTrendLine && changeinXposition != null) {
                changeinXposition = details.localPosition.dx;
                changeinYposition = details.globalPosition.dy;
                notifyChanged();
              }
            },
            onLongPressMoveUpdate: (details) {
              var longPressTemp =
                  (_longPressStartTime?.millisecondsSinceEpoch ?? 0);
              if (DateTime.now().millisecondsSinceEpoch - longPressTemp >=
                  500) {
                longPressTriggered = true;
                notifyChanged();
              } else {
                // longPressTriggered = false;
                // notifyChanged();
              }

              if ((mSelectX != details.localPosition.dx ||
                      mSelectY != details.globalPosition.dy) &&
                  !widget.isTrendLine) {
                mSelectX = details.localPosition.dx;
                mSelectY = details.localPosition.dy;
                notifyChanged();
              }
              if (widget.isTrendLine) {
                mSelectX =
                    mSelectX + (details.localPosition.dx - changeinXposition!);
                changeinXposition = details.localPosition.dx;
                mSelectY =
                    mSelectY + (details.globalPosition.dy - changeinYposition!);
                changeinYposition = details.globalPosition.dy;
                notifyChanged();
              }
            },
            onLongPressEnd: (details) {
              // _timer?.cancel();
              isLongPress = false;
              enableCordRecord = true;

              // # 短按需设置为0
              if (widget.isLongFocusDurationTime == 0) {
                mInfoWindowStream.sink.add(null);
                notifyChanged();
              }

              if (!longPressTriggered) {
                notifyChanged();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  mInfoWindowStream.sink.add(null);
                });
              }
            },
            child: Stack(
              children: <Widget>[
                CustomPaint(
                  size: Size(double.infinity, baseDimension.mDisplayHeight),
                  painter: painter,
                ),
                //#十字光标长按0.5秒后才触发 -----------------------------------------------》》》》》 !! 关键 ！！ （isLongFocusDurationTime: 500/0 和 isLongFocus：true/false 切换）
                if (widget.showInfoDialog &&
                    (widget.isLongFocusDurationTime == 0 || longPressTriggered))
                  _buildInfoDialog()
              ],
            ),
          ),
        );
      },
    );
  }

  void _stopAnimation({bool needNotify = true}) {
    if (_controller != null && _controller!.isAnimating) {
      _controller!.stop();
      _onDragChanged(false);
      if (needNotify) {
        notifyChanged();
      }
    }
  }

  void _onDragChanged(bool isOnDrag) {
    isDrag = isOnDrag;
    if (widget.isOnDrag != null) {
      widget.isOnDrag!(isDrag);
    }
  }

  void _onFling(double x) {
    _controller = AnimationController(
        duration: Duration(milliseconds: widget.flingTime), vsync: this);
    aniX = null;
    aniX = Tween<double>(begin: mScrollX, end: x * widget.flingRatio + mScrollX)
        .animate(CurvedAnimation(
            parent: _controller!.view, curve: widget.flingCurve));
    aniX!.addListener(() {
      mScrollX = aniX!.value;
      if (mScrollX <= 0) {
        mScrollX = 0;
        if (widget.onLoadMore != null) {
          widget.onLoadMore!(true);
        }
        _stopAnimation();
      } else if (mScrollX >= ChartPainter.maxScrollX) {
        mScrollX = ChartPainter.maxScrollX;
        if (widget.onLoadMore != null) {
          widget.onLoadMore!(false);
        }
        _stopAnimation();
      }
      notifyChanged();
    });
    aniX!.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        _onDragChanged(false);
        notifyChanged();
      }
    });
    _controller!.forward();
  }

  void notifyChanged() => setState(() {});

  late List<String> infos;

  Widget _buildInfoDialog() {
    return StreamBuilder<InfoWindowEntity?>(
      stream: mInfoWindowStream.stream,
      builder: (context, snapshot) {
        if (widget.isLongFocusDurationTime == 0 &&
            ((!isLongPress && !isOnTap) ||
                widget.isLine == true ||
                !snapshot.hasData ||
                snapshot.data?.kLineEntity == null)) {
          return SizedBox();
        }
        if (widget.isLongFocusDurationTime != 0 &&
            (!longPressTriggered || widget.isLine == true
            // ||
            // !snapshot.hasData ||
            // snapshot.data?.kLineEntity == null
            )) {
          return SizedBox();
        }
        if (widget.isLongFocusDurationTime != 0 &&
            !longPressTriggered &&
            snapshot.data == null) {
          return SizedBox.shrink();
        }
        if (snapshot.data == null) {
          return SizedBox.shrink();
        }

        KLineEntity entity = snapshot.data!.kLineEntity;
        final dialogWidth = mWidth / 3;
        if (snapshot.data!.isLeft) {
          return Positioned(
            top: 25,
            left: 10.0,
            child: PopupInfoView(
              entity: entity,
              width: dialogWidth,
              chartColors: widget.chartColors,
              chartTranslations: widget.chartTranslations,
              materialInfoDialog: widget.materialInfoDialog,
              timeFormat: widget.timeFormat,
              fixedLength: widget.fixedLength,
            ),
          );
        }
        return Positioned(
          top: 25,
          right: 10.0,
          child: PopupInfoView(
            entity: entity,
            width: dialogWidth,
            chartColors: widget.chartColors,
            chartTranslations: widget.chartTranslations,
            materialInfoDialog: widget.materialInfoDialog,
            timeFormat: widget.timeFormat,
            fixedLength: widget.fixedLength,
          ),
        );
      },
    );
  }
}
