class PriceCalculator {
  static double calculateProductMRP({
    required String metalName,
    required String carats,
    required double metalGrams,
    required double metalRate,
    required double stoneWeight,
    required double stoneCost,
    required double makingChargeValue,
    required String makingChargeType,
  }) {
    double baseMetalPrice = 0;

    if (metalName.toLowerCase() == 'gold') {
      double caratValue = double.tryParse(carats) ?? 0;
      baseMetalPrice = (caratValue / 24) * metalRate * metalGrams;
    } else {
      baseMetalPrice = metalRate * metalGrams;
    }

    double totalStonePrice = stoneWeight * stoneCost;
    double priceBeforeMaking = baseMetalPrice + totalStonePrice;

    double finalMrp = 0;
    if (makingChargeType == 'Flat') {
      finalMrp = priceBeforeMaking + makingChargeValue;
    } else {
      finalMrp =
          priceBeforeMaking + (priceBeforeMaking * (makingChargeValue / 100));
    }

    return finalMrp;
  }

  static double calculateSellingPrice({
    required double mrp,
    required double discountPercent,
  }) {
    if (discountPercent <= 0) return mrp;
    return mrp - discountPercent;
  }
}
