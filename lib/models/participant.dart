class Participant {
  final String id;
  final String firstName;
  final String lastName;
  final String address;
  final String email;
  final String phone;
  final String role; // 'Fahrer', 'Mitfahrer', 'Flexibel'
  final bool isActive;

  Participant({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.address,
    required this.email,
    required this.phone,
    this.role = 'Flexibel',
    this.isActive = true,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      id: json['id']?.toString() ?? '',
      firstName: json['vorname']?.toString() ?? '',
      lastName: json['nachname']?.toString() ?? '',
      address: json['adresse']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['telefon']?.toString() ?? '',
      role: json['rolle']?.toString() ?? 'Flexibel',
      isActive: json['aktiv'] == true ||
          json['aktiv']?.toString().toLowerCase() == 'true',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vorname': firstName,
      'nachname': lastName,
      'adresse': address,
      'email': email,
      'telefon': phone,
      'rolle': role,
      'aktiv': isActive,
    };
  }

  Participant copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? address,
    String? email,
    String? phone,
    String? role,
    bool? isActive,
  }) {
    return Participant(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      address: address ?? this.address,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
    );
  }
}
