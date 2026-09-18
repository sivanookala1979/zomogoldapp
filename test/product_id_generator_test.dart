import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Product ID should contain 8 digits from 1 to 9', () {
    final productId = '76344621';

    expect(productId.length, 8);
    expect(RegExp(r'^[1-9]{8}$').hasMatch(productId), true);
  });
}