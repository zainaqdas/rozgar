class LocationPoint {
  final double lat;
  final double lng;
  final String address;
  final String? city;

  const LocationPoint({
    required this.lat,
    required this.lng,
    this.address = '',
    this.city,
  });

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        'address': address,
        'city': city,
      };

  factory LocationPoint.fromJson(Map<String, dynamic> json) => LocationPoint(
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        address: json['address'] as String? ?? '',
        city: json['city'] as String?,
      );

  @override
  String toString() => 'LocationPoint(lat: $lat, lng: $lng, address: $address)';
}
