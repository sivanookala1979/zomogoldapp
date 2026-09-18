import '../models/product_model.dart';

/// Non-web fallback. USB printing relies on WebUSB, which only exists in the
/// browser, so on Android/iOS/desktop this simply reports that it is
/// unsupported. See `tsc_printer_web.dart` for the real implementation.
class TscPrinter {
  /// Sends a 50mm x 30mm test label to the TSC TE244.
  static Future<void> printTestLabel() async {
    throw UnsupportedError(
      'USB label printing is only available in the web build of the app.',
    );
  }

  /// Sends a product label to the TSC TE244.
  ///
  /// Actual implementation is available in the web build through WebUSB.
  /// Android/iOS/desktop use this fallback.
  static Future<void> printProductLabel(
    ProductModel product,
  ) async {
    throw UnsupportedError(
      'USB product label printing is only available in the web build of the app.',
    );
  }
}