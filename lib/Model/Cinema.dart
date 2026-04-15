class Cinema {
  final String id;
  final String name;
  final String provinceId;
  final String address;

  Cinema({
    required this.id,
    required this.name,
    required this.provinceId,
    required this.address,
  });

  factory Cinema.fromJson(Map<String, dynamic> json) {
    return Cinema(
      id: json['id'],
      name: json['name'],
      provinceId: json['provinceId'],
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'provinceId': provinceId,
      'address': address,
    };
  }
}
