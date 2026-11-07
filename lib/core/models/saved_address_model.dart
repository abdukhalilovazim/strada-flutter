class SavedAddressModel {
  final String id;
  final String label;
  final String address;
  final double lat;
  final double lng;
  final String? comment;
  final String? apartment;
  final String? floor;
  final String? entrance;
  final String? doorphone;

  const SavedAddressModel({
    required this.id,
    required this.label,
    required this.address,
    required this.lat,
    required this.lng,
    this.comment,
    this.apartment,
    this.floor,
    this.entrance,
    this.doorphone,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'address': address,
        'lat': lat,
        'lng': lng,
        'comment': comment,
      };

  factory SavedAddressModel.fromJson(Map<String, dynamic> json) {
    // If old saved address has separate fields, seamlessly migrate to comment
    String? resolvedComment = json['comment']?.toString();
    if (resolvedComment == null || resolvedComment.isEmpty) {
      final oldParts = [
        if (json['apartment'] != null && json['apartment'].toString().isNotEmpty)
          '${json['apartment']}-xonadon',
        if (json['entrance'] != null && json['entrance'].toString().isNotEmpty)
          '${json['entrance']}-podyezd',
        if (json['floor'] != null && json['floor'].toString().isNotEmpty)
          '${json['floor']}-qavat',
        if (json['doorphone'] != null && json['doorphone'].toString().isNotEmpty)
          'Domofon: ${json['doorphone']}',
      ];
      if (oldParts.isNotEmpty) {
        resolvedComment = oldParts.join(', ');
      }
    }

    return SavedAddressModel(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? 'Manzil',
      address: json['address']?.toString() ?? json['address_text']?.toString() ?? '',
      lat: (json['lat'] as num?)?.toDouble() ??
          double.tryParse(json['latitude']?.toString() ?? '') ??
          0.0,
      lng: (json['lng'] as num?)?.toDouble() ??
          double.tryParse(json['longitude']?.toString() ?? '') ??
          0.0,
      comment: resolvedComment,
      apartment: json['apartment']?.toString(),
      floor: json['floor']?.toString(),
      entrance: json['entrance']?.toString(),
      doorphone: json['doorphone']?.toString(),
    );
  }
}

