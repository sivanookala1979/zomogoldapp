import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String productId;
  final String categoryId;
  final String productName;
  final String productNameLower;
  final String userId;
  final List<String> images;
  final String metalName;
  final String carats;
  final double metalGrams;
  final double stoneWeight;
  final double stoneCost;
  final String stoneWeightUnit;
  final double purity;
  final double makingCharges;
  final double discount;
  final String tagId;
  final String productInformation;
  final String specifications;
  final bool hallmark;
  final DateTime createdTimestamp;
  final DateTime modifiedTimestamp;
  final String gender;
  final int viewCount;

  // Jewellery label fields
  final int pieceCount;
  final String ornamentType;
  final String designCode;
  final double otherCharges;
  final double americanDiamondWeight;
  final int americanDiamondCount;
  final double kundanWeight;
  final int kundanCount;
  final int stoneCount;
  final String manufacturingNumber;

  ProductModel({
    required this.productId,
    required this.categoryId,
    required this.productName,
    required this.productNameLower,
    required this.userId,
    required this.images,
    required this.metalName,
    required this.carats,
    required this.metalGrams,
    required this.stoneWeight,
    required this.stoneCost,
    required this.stoneWeightUnit,
    required this.purity,
    required this.makingCharges,
    required this.discount,
    required this.tagId,
    required this.productInformation,
    required this.specifications,
    required this.hallmark,
    required this.createdTimestamp,
    required this.modifiedTimestamp,
    required this.gender,
    required this.viewCount,
    required this.pieceCount,
    required this.ornamentType,
    required this.designCode,
    required this.otherCharges,
    required this.americanDiamondWeight,
    required this.americanDiamondCount,
    required this.kundanWeight,
    required this.kundanCount,
    required this.stoneCount,
    required this.manufacturingNumber,
  });

  factory ProductModel.fromSnapshot(DocumentSnapshot snap) {
    var data = snap.data() as Map<String, dynamic>;

    return ProductModel(
      productId: data["productId"],
      categoryId: data["categoryId"],
      productName: data["productName"] ?? "",
      productNameLower: data["productNameLower"] ?? "",
      userId: data["userId"],
      images: List<String>.from(data["images"] ?? []),
      metalName: data["metalName"],
      carats: data["carats"] ?? "Select",
      metalGrams: (data["metalGrams"] ?? 0).toDouble(),
      stoneWeight: (data["stoneWeight"] ?? 0).toDouble(),
      stoneCost: (data["stoneCost"] ?? 0).toDouble(),
      stoneWeightUnit: data["stoneWeightUnit"],
      purity: (data["purity"] ?? 0).toDouble(),
      makingCharges: (data["makingCharges"] ?? 0).toDouble(),
      discount: (data["discount"] ?? 0).toDouble(),
      tagId: data["tagId"],
      productInformation: data["productInformation"],
      specifications: data["specifications"] ?? "",
      hallmark: data["hallmark"] ?? false,
      createdTimestamp:
          (data["createdTimestamp"] as Timestamp).toDate(),
      modifiedTimestamp:
          (data["modifiedTimestamp"] as Timestamp).toDate(),
      gender: data["gender"] ?? "Unisex",
      viewCount: data["viewCount"] ?? 0,

      // Jewellery label fields
      pieceCount: (data["pieceCount"] ?? 1).toInt(),
      ornamentType: data["ornamentType"] ?? "",
      designCode: data["designCode"] ?? "",
      otherCharges: (data["otherCharges"] ?? 0).toDouble(),
      americanDiamondWeight:
          (data["americanDiamondWeight"] ?? 0).toDouble(),
      americanDiamondCount:
          (data["americanDiamondCount"] ?? 0).toInt(),
      kundanWeight:
          (data["kundanWeight"] ?? 0).toDouble(),
      kundanCount:
          (data["kundanCount"] ?? 0).toInt(),
      stoneCount:
          (data["stoneCount"] ?? 0).toInt(),
      manufacturingNumber:
          data["manufacturingNumber"] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "productId": productId,
      "categoryId": categoryId,
      "productName": productName,
      "productNameLower": productNameLower,
      "userId": userId,
      "images": images,
      "metalName": metalName,
      "carats": carats,
      "metalGrams": metalGrams,
      "stoneWeight": stoneWeight,
      "stoneCost": stoneCost,
      "stoneWeightUnit": stoneWeightUnit,
      "purity": purity,
      "makingCharges": makingCharges,
      "discount": discount,
      "tagId": tagId,
      "productInformation": productInformation,
      "specifications": specifications,
      "hallmark": hallmark,
      "createdTimestamp": Timestamp.fromDate(createdTimestamp),
      "modifiedTimestamp": Timestamp.fromDate(modifiedTimestamp),
      "gender": gender,
      "viewCount": viewCount,

      // Jewellery label fields
      "pieceCount": pieceCount,
      "ornamentType": ornamentType,
      "designCode": designCode,
      "otherCharges": otherCharges,
      "americanDiamondWeight": americanDiamondWeight,
      "americanDiamondCount": americanDiamondCount,
      "kundanWeight": kundanWeight,
      "kundanCount": kundanCount,
      "stoneCount": stoneCount,
      "manufacturingNumber": manufacturingNumber,
    };
  }
}