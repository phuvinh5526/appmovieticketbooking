class District {
  String id; // ID của huyện
  String name; // Tên huyện
  String provinceId; // ID của tỉnh mà huyện thuộc về

  District({required this.id, required this.name, required this.provinceId});

  // Phương thức chuyển đổi từ Map sang District
  factory District.fromMap(Map<String, dynamic> map) {
    return District(
      id: map['id'],
      name: map['name'],
      provinceId: map['provinceId'],
    );
  }

  // Phương thức chuyển đổi từ District sang Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'provinceId': provinceId,
    };
  }

  // Phương thức chuyển đổi từ JSON sang District
  factory District.fromJson(Map<String, dynamic> json) {
    return District.fromMap(json);
  }

  // Phương thức chuyển đổi từ District sang JSON
  Map<String, dynamic> toJson() {
    return toMap();
  }
}
