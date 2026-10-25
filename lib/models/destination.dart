class Destination {
  final String id;
  final String name;
  final String address;
  final String contact;
  final String notes;

  Destination({
    required this.id,
    required this.name,
    required this.address,
    this.contact = '',
    this.notes = '',
  });

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['adresse']?.toString() ?? '',
      contact: json['kontakt']?.toString() ?? '',
      notes: json['notizen']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'adresse': address,
      'kontakt': contact,
      'notizen': notes,
    };
  }

  Destination copyWith({
    String? id,
    String? name,
    String? address,
    String? contact,
    String? notes,
  }) {
    return Destination(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      contact: contact ?? this.contact,
      notes: notes ?? this.notes,
    );
  }
}
