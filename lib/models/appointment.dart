import 'package:flutter/material.dart';

/// קטגוריית תור - כוללת שם, צבע ואייקון
class AppointmentCategory {
  final String name;
  final Color color;
  final IconData icon;

  const AppointmentCategory(this.name, this.color, this.icon);

  static const List<AppointmentCategory> all = [
    AppointmentCategory('כלה', Color(0xFFD4AF37), Icons.diamond_outlined),
    AppointmentCategory('ערב', Color(0xFF4A1525), Icons.nightlife_outlined),
    AppointmentCategory('יומיומי', Color(0xFFD8A7B1), Icons.wb_sunny_outlined),
    AppointmentCategory('צילומים', Color(0xFF5B7B88), Icons.camera_alt_outlined),
    AppointmentCategory('קורס', Color(0xFF6B7A59), Icons.school_outlined),
    AppointmentCategory('אחר', Color(0xFF8D7B68), Icons.more_horiz),
  ];

  static AppointmentCategory byName(String name) {
    return all.firstWhere(
      (c) => c.name == name,
      orElse: () => all.last,
    );
  }
}

/// סטטוס תור
enum AppointmentStatus { confirmed, pending, completed, cancelled }

extension AppointmentStatusX on AppointmentStatus {
  String get label {
    switch (this) {
      case AppointmentStatus.confirmed:
        return 'מאושר';
      case AppointmentStatus.pending:
        return 'ממתין לאישור';
      case AppointmentStatus.completed:
        return 'הושלם';
      case AppointmentStatus.cancelled:
        return 'בוטל';
    }
  }

  Color get color {
    switch (this) {
      case AppointmentStatus.confirmed:
        return const Color(0xFF4A7C59);
      case AppointmentStatus.pending:
        return const Color(0xFFC68E17);
      case AppointmentStatus.completed:
        return const Color(0xFF5B7B88);
      case AppointmentStatus.cancelled:
        return const Color(0xFFA33636);
    }
  }
}

class Appointment {
  final String id;
  final String clientName;
  final String phone;
  final DateTime dateTime;
  final int durationMinutes;
  final String category;
  final double price;
  final String notes;
  final AppointmentStatus status;

  const Appointment({
    required this.id,
    required this.clientName,
    required this.phone,
    required this.dateTime,
    required this.durationMinutes,
    required this.category,
    required this.price,
    this.notes = '',
    this.status = AppointmentStatus.confirmed,
  });

  DateTime get endTime => dateTime.add(Duration(minutes: durationMinutes));

  AppointmentCategory get categoryData => AppointmentCategory.byName(category);

  Appointment copyWith({
    String? id,
    String? clientName,
    String? phone,
    DateTime? dateTime,
    int? durationMinutes,
    String? category,
    double? price,
    String? notes,
    AppointmentStatus? status,
  }) {
    return Appointment(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      phone: phone ?? this.phone,
      dateTime: dateTime ?? this.dateTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      category: category ?? this.category,
      price: price ?? this.price,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientName': clientName,
        'phone': phone,
        'dateTime': dateTime.toIso8601String(),
        'durationMinutes': durationMinutes,
        'category': category,
        'price': price,
        'notes': notes,
        'status': status.name,
      };

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
        id: json['id'] as String,
        clientName: json['clientName'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        dateTime: DateTime.parse(json['dateTime'] as String),
        durationMinutes: json['durationMinutes'] as int? ?? 60,
        category: json['category'] as String? ?? 'אחר',
        price: (json['price'] as num?)?.toDouble() ?? 0,
        notes: json['notes'] as String? ?? '',
        status: AppointmentStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => AppointmentStatus.confirmed,
        ),
      );
}
