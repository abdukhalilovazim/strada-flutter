class CheckoutBranch {
  final String id;
  final String title;
  final double latitude;
  final double longitude;

  const CheckoutBranch({
    required this.id,
    required this.title,
    required this.latitude,
    required this.longitude,
  });

  factory CheckoutBranch.fromJson(Map<String, dynamic> json) {
    return CheckoutBranch(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

