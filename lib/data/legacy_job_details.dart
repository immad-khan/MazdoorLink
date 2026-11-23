/// Snapshot of an existing repair booking used by the legacy tracking flow.
/// New inspection requests use VisitRequest instead.
class LegacyJobDetails {
  const LegacyJobDetails({
    required this.descriptionEn,
    required this.descriptionUr,
    required this.price,
    required this.categoryKey,
    this.paymentMethod = 'Cash',
    this.customerLatitude,
    this.customerLongitude,
  });

  final String descriptionEn;
  final String descriptionUr;
  final double price;
  final String categoryKey;
  final String paymentMethod;
  final double? customerLatitude;
  final double? customerLongitude;
}
