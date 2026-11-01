class SavedAddressModel {
  final String id;
  final String label;
  final String address;
  final double lat;
  final double lng;
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
        'apartment': apartment,
        'floor': floor,
        'entrance': entrance,
        'doorphone': doorphone,
      };

  factory SavedAddressModel.fromJson(Map<String, dynamic> json) =>
      SavedAddressModel(
        id: json['id']?.toString() ?? '',
        label: json['label']?.toString() ?? 'Manzil',
        address: json['address']?.toString() ?? '',
        lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
        lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
        apartment: json['apartment']?.toString(),
        floor: json['floor']?.toString(),
        entrance: json['entrance']?.toString(),
        doorphone: json['doorphone']?.toString(),
      );
}

