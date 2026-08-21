class Booking {
  final String id;
  final String userId;
  final String stationId;
  final String chargerId;
  final String timeSlotId;
  final DateTime bookingTime;
  final String status;

  // Extra fields for displaying
  final String userName;
  final String vehicle;
  final double kwh;
  final double price;

  Booking({
    required this.id,
    required this.userId,
    required this.stationId,
    required this.chargerId,
    required this.timeSlotId,
    required this.bookingTime,
    required this.status,
    this.userName = '',
    this.vehicle = '',
    this.kwh = 0.0,
    this.price = 0.0,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      stationId: json['stationId'] ?? '',
      chargerId: json['chargerId'] ?? '',
      timeSlotId: json['timeSlotId'] ?? '',
      bookingTime: json['bookingTime'] != null
          ? DateTime.tryParse(json['bookingTime']) ?? DateTime.now()
          : DateTime.now(),
      status: json['status'] ?? 'PENDING',
      userName: json['userName'] ?? '',
      vehicle: json['vehicle'] ?? '',
      kwh: (json['kwh'] as num?)?.toDouble() ?? 0.0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'stationId': stationId,
      'chargerId': chargerId,
      'timeSlotId': timeSlotId,
      'status': status,
      'userName': userName,
      'vehicle': vehicle,
      'kwh': kwh,
      'price': price,
    };
  }
}
