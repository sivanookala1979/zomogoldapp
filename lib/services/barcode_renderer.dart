import 'package:barcode/barcode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BarcodeRenderer extends StatelessWidget {
  final String productId;

  const BarcodeRenderer({
    super.key,
    required this.productId,
  });

  @override
  Widget build(BuildContext context) {
    final barcode = Barcode.code128();

    return SizedBox(
      width: 300,
      height: 100,
      child: SvgPicture.string(
        barcode.toSvg(
          productId,
          width: 300,
          height: 100,
        ),
      ),
    );
  }
}