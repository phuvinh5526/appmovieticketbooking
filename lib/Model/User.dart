import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  String id;
  String fullName;
  String phoneNumber;
  String email;
  String hashedPassword;
  DateTime birthDate;
  String gender;
  String province;
  String district;
  String status;
  DateTime createdAt;
  DateTime? updatedAt;

  User({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    required this.hashedPassword,
    required this.birthDate,
    required this.gender,
    required this.province,
    required this.district,
    this.status = "Active",
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "fullName": fullName,
      "phoneNumber": phoneNumber,
      "email": email,
      "hashedPassword": hashedPassword,
      "birthDate": Timestamp.fromDate(birthDate),
      "gender": gender,
      "province": province,
      "district": district,
      "status": status,
      "createdAt": Timestamp.fromDate(createdAt),
      "updatedAt": updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    // Hàm helper để xử lý mọi định dạng thời gian từ Firebase (Timestamp, String, DateTime)
    DateTime parseTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      if (value is DateTime) return value;
      return DateTime.now();
    }

    return User(
      id: json["id"]?.toString() ?? '',
      fullName: json["fullName"]?.toString() ?? 'Người dùng',
      phoneNumber: json["phoneNumber"]?.toString() ?? '',
      email: json["email"]?.toString() ?? '',
      hashedPassword: json["hashedPassword"]?.toString() ?? '',
      birthDate: parseTime(json["birthDate"]),
      gender: json["gender"]?.toString() ?? 'Khác',
      province: json["province"]?.toString() ?? 'Chưa chọn',
      district: json["district"]?.toString() ?? 'Chưa chọn',
      status: json["status"]?.toString() ?? "Active",
      createdAt: parseTime(json["createdAt"]),
      updatedAt: json["updatedAt"] != null ? parseTime(json["updatedAt"]) : null,
    );
  }

  User copyWith({
    String? id,
    String? fullName,
    String? phoneNumber,
    String? email,
    String? hashedPassword,
    DateTime? birthDate,
    String? gender,
    String? province,
    String? district,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      hashedPassword: hashedPassword ?? this.hashedPassword,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      province: province ?? this.province,
      district: district ?? this.district,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
