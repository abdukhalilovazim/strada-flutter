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

  /// Serverdagi haqiqiy ID ekanligini tekshirish.
  /// Mahalliy vaqt tamg'asi (masalan: 1794171913534) yoki 'local_' prefiksli IDlar serverda mavjud emas.
  bool get isServerId {
    if (id.isEmpty || id.startsWith('local_')) return false;
    final parsed = int.tryParse(id);
    if (parsed == null) return false;
    // MySQL auto-increment IDlar odatda kichik sonlar. 13 xonali millisekund timestamp esa 1.7 trilliondan katta.
    return parsed < 1000000000;
  }

  /// Podyezd, qavat, xonadon qisqacha ma'lumoti
  String get detailsSummary {
    final parts = <String>[];
    if (entrance != null && entrance!.trim().isNotEmpty) {
      parts.add('${entrance!.trim()}-podyezd');
    }
    if (floor != null && floor!.trim().isNotEmpty) {
      parts.add('${floor!.trim()}-qavat');
    }
    if (apartment != null && apartment!.trim().isNotEmpty) {
      parts.add('${apartment!.trim()}-xonadon');
    }
    return parts.join(', ');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'address': address,
        'lat': lat,
        'lng': lng,
        'comment': comment,
        'apartment': apartment,
        'floor': floor,
        'entrance': entrance,
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
      ];
      if (oldParts.isNotEmpty) {
        resolvedComment = oldParts.join(', ');
      }
    }

    String? apt = json['apartment']?.toString();
    String? flr = json['floor']?.toString();
    String? ent = json['entrance']?.toString();

    // Agar alohida maydonlar bo'lmasa, comment ichidan tiklab olamiz
    if (resolvedComment != null && resolvedComment.isNotEmpty) {
      if (apt == null || apt.isEmpty) {
        final m = RegExp(r'(\d+)-xonadon|Xonadon:\s*([^\s,]+)', caseSensitive: false).firstMatch(resolvedComment);
        if (m != null) apt = m.group(1) ?? m.group(2);
      }
      if (ent == null || ent.isEmpty) {
        final m = RegExp(r'(\d+)-podyezd|Podyezd:\s*([^\s,]+)', caseSensitive: false).firstMatch(resolvedComment);
        if (m != null) ent = m.group(1) ?? m.group(2);
      }
      if (flr == null || flr.isEmpty) {
        final m = RegExp(r'(\d+)-qavat|Qavat:\s*([^\s,]+)', caseSensitive: false).firstMatch(resolvedComment);
        if (m != null) flr = m.group(1) ?? m.group(2);
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
      apartment: apt,
      floor: flr,
      entrance: ent,
      doorphone: null,
    );
  }
}

