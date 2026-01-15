import 'package:flutter/material.dart';
import 'package:zomogoldapp/screens/product_view_page.dart';

import '../models/price_calculator.dart';
import '../models/product_model.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final double ratePerGram;

  const ProductCard({
    super.key,
    required this.product,
    required this.ratePerGram,
  });

  @override
  Widget build(BuildContext context) {
    final basePrice = PriceCalculator.calculateBasePrice(
      weight: product.weight,
      ratePerUnit: ratePerGram,
    );

    final makingCharge = PriceCalculator.calculateMakingCharges(
      basePrice: basePrice,
      makingChargePercent: product.makingCharges,
    );

    final mrp = PriceCalculator.calculateMRP(
      basePrice: basePrice,
      makingChargeAmount: makingCharge,
    );

    final sellingPrice = PriceCalculator.calculateSellingPrice(
      mrp: mrp,
      discountPercent: product.discount,
    );

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ProductDetailsViewPage(productId: product.productId),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 0.9,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(14),
                      ),
                      child: product.images.isNotEmpty
                          ? Image.network(
                              product.images.first,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            )
                          : _imagePlaceholder(),
                    ),
                    const Positioned(
                      top: 8,
                      right: 8,
                      child: Icon(Icons.favorite_border, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '₹ ${sellingPrice.toStringAsFixed(0)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹ ${mrp.toStringAsFixed(0)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      decoration: TextDecoration.lineThrough,
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.tagId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(Icons.image_not_supported, size: 40),
    );
  }
}
