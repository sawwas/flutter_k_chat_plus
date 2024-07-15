class ChartTranslations {
  final String date;
  final String open;
  final String high;
  final String low;
  final String close;
  final String changeAmount;
  final String change;
  final String amount;
  final String vol;

  const ChartTranslations({
    this.date = 'Date',
    this.open = 'Open',
    this.high = 'High',
    this.low = 'Low',
    this.close = 'Close',
    this.changeAmount = 'Change',
    this.change = 'Change%',
    this.amount = 'Amount',
    this.vol = 'Volume',
  });
}

class DepthChartTranslations {
  final String price;
  final String amount;

  const DepthChartTranslations({
    this.price = 'Price',
    this.amount = 'Amount',
  });
}
