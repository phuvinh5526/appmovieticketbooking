class Province {
  String id; // ID của tỉnh
  String name; // Tên tỉnh

  Province({
    required this.id,
    required this.name,
  });

  // Phương thức chuyển đổi từ Map sang Province
  factory Province.fromMap(Map<String, dynamic> map) {
    return Province(
      id: map['id'],
      name: map['name'],
    );
  }

  // Phương thức chuyển đổi từ Province sang Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  // Phương thức chuyển đổi từ JSON sang Province
  factory Province.fromJson(Map<String, dynamic> json) {
    return Province.fromMap(json);
  }

  // Phương thức chuyển đổi từ Province sang JSON
  Map<String, dynamic> toJson() {
    return toMap();
  }
}
