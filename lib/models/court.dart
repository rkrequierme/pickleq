class Court {
  final int? id;
  final int number;
  final String name;
  final String status; // 'available', 'occupied', 'maintenance'

  Court({
    this.id,
    required this.number,
    required this.name,
    required this.status,
  });

  Court copyWith({
    int? id,
    int? number,
    String? name,
    String? status,
  }) {
    return Court(
      id: id ?? this.id,
      number: number ?? this.number,
      name: name ?? this.name,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'number': number,
      'name': name,
      'status': status,
    };
  }

  factory Court.fromMap(Map<String, dynamic> map) {
    return Court(
      id: map['id'] as int?,
      number: map['number'] as int,
      name: map['name'] as String,
      status: map['status'] as String,
    );
  }

  @override
  String toString() {
    return 'Court(id: $id, number: $number, name: $name, status: $status)';
  }
}
