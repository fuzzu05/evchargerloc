class ChargingStation {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double pricePerKwh;
  final String gridPower;
  final bool hasCafe;
  final bool hasWifi;
  final bool hasRestroom;
  final bool is247;
  final String openTime;
  final String closeTime;

  ChargingStation({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.pricePerKwh,
    required this.gridPower,
    required this.hasCafe,
    required this.hasWifi,
    required this.hasRestroom,
    required this.is247,
    required this.openTime,
    required this.closeTime,
  });

  factory ChargingStation.fromJson(Map<String, dynamic> json) {
    double lat = 0.0;
    double lng = 0.0;

    if (json['location'] != null && json['location']['coordinates'] != null) {
      // GeoJsonPoint uses [longitude, latitude]
      var coords = json['location']['coordinates'] as List;
      if (coords.length >= 2) {
        lng = (coords[0] as num).toDouble();
        lat = (coords[1] as num).toDouble();
      }
    }

    return ChargingStation(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown Station',
      address: json['address'] ?? '',
      latitude: lat,
      longitude: lng,
      pricePerKwh: (json['pricePerKwh'] as num?)?.toDouble() ?? 0.0,
      gridPower: json['gridPower'] ?? '',
      hasCafe: json['hasCafe'] ?? false,
      hasWifi: json['hasWifi'] ?? false,
      hasRestroom: json['hasRestroom'] ?? false,
      is247: json['is247'] ?? false,
      openTime: json['openTime'] ?? '',
      closeTime: json['closeTime'] ?? '',
    );
  }
}
