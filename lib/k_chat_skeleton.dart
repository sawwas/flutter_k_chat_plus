import 'package:flutter/material.dart';

import 'dart:math';

import 'package:shimmer/shimmer.dart';

//# K 线骨架屏
class KChartSkeleton extends StatefulWidget {
  final double width, height;
  final bool themeColor;

  const KChartSkeleton(
      {super.key,
      this.themeColor = false,
      this.width = double.infinity,
      this.height = 210.0});

  @override
  State<StatefulWidget> createState() {
    return _KChartSkeletonState();
  }
}

class _KChartSkeletonState extends State<KChartSkeleton> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[800]!,
        highlightColor:
            widget.themeColor ? Color(0xFF000000) : Color(0xFFF2F2F2),
        period: Duration(seconds: 2),
        child: Container(
          width: widget.width,
          height: widget.height,
          color: Colors.transparent,
          child: CustomPaint(
            painter: SkeletonChartPainter(),
          ),
        ),
      ),
    );
  }
}

class CandleData {
  final double open;
  final double close;
  final double high;
  final double low;
  final bool isBullish;

  CandleData({
    required this.open,
    required this.close,
    required this.high,
    required this.low,
    required this.isBullish,
  });
}

class SkeletonChartPainter extends CustomPainter {
  final List<CandleData> _candles = [];

  SkeletonChartPainter() {
    _generateCandles();
  }

  void _generateCandles() {
    final Random random = Random();
    double previousClose = 120; // Starting value for the first candle

    for (int i = 0; i < 20; i++) {
      final isBullish = random.nextBool();
      final double change =
          5 + random.nextDouble() * 10.75; // Ensuring height between 5 and 80
      final double open = previousClose;
      final double close = isBullish ? open + change : open - change;
      final double high = max(open, close) + random.nextDouble() * 20;
      final double low = min(open, close) - random.nextDouble() * 10;

      _candles.add(CandleData(
        open: open,
        close: close,
        high: high,
        low: low,
        isBullish: isBullish,
      ));
      previousClose = close;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey[600]!.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final double gridGap = size.width / 10; // Adjusted for 10 grid columns
    final double candleSpacing = 2.0;
    final double candleWidth = (gridGap - candleSpacing) *
        2 /
        5; // Adjusted to fit within grid with spacing

    // Draw vertical grid lines
    for (double i = 0; i <= size.width; i += gridGap) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }

    // Draw horizontal grid lines
    for (double i = 0; i <= size.height; i += gridGap) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // Draw candlesticks
    final double scaleFactor = 1; // 缩放比例

    for (int i = 0; i < _candles.length; i++) {
      final candle = _candles[i];
      final double x = i * (candleWidth + candleSpacing) + gridGap / 2;

      final candlePaint = Paint()
        ..color = candle.isBullish
            ? Colors.grey[200]!.withValues(alpha: 0.10)
            : Colors.grey[700]!.withValues(alpha: 0.05)
        ..style = PaintingStyle.fill;

      final openY = size.height - candle.open * scaleFactor;
      final closeY = size.height - candle.close * scaleFactor;
      final highY = size.height - candle.high * scaleFactor;
      final lowY = size.height - candle.low * scaleFactor;

      // 画蜡烛
      canvas.drawRect(
        Rect.fromLTWH(x - candleWidth / 2, min(openY, closeY), candleWidth,
            (openY - closeY).abs()),
        candlePaint,
      );

      // 画灯芯
      canvas.drawLine(Offset(x, highY), Offset(x, lowY), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
