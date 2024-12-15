// import 'dart:math';

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
