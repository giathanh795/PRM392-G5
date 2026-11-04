class Sponsorship {
  final String id;
  final String name;
  final String logo;
  final String description;
  final String contractFileName;
  final String contractFileData;
  final bool removeContract;
  final double value;
  final String startDate;
  final String endDate;
  final String status;
  final String phone;
  final String email;
  final String contactPerson;

  const Sponsorship({
    required this.id,
    required this.name,
    this.logo = '',
    this.description = '',
    this.contractFileName = '',
    this.contractFileData = '',
    this.removeContract = false,
    this.value = 0,
    required this.startDate,
    required this.endDate,
    this.status = 'Active',
    this.phone = '',
    this.email = '',
    this.contactPerson = '',
  });

  Sponsorship copyWith({
    String? id,
    String? name,
    String? logo,
    String? description,
    String? contractFileName,
    String? contractFileData,
    bool? removeContract,
    double? value,
    String? startDate,
    String? endDate,
    String? status,
    String? phone,
    String? email,
    String? contactPerson,
  }) {
    return Sponsorship(
      id: id ?? this.id,
      name: name ?? this.name,
      logo: logo ?? this.logo,
      description: description ?? this.description,
      contractFileName: contractFileName ?? this.contractFileName,
      contractFileData: contractFileData ?? this.contractFileData,
      removeContract: removeContract ?? this.removeContract,
      value: value ?? this.value,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      contactPerson: contactPerson ?? this.contactPerson,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'logo': logo,
    'description': description,
    'contractFileName': contractFileName,
    'removeContract': removeContract,
    'value': value,
    'startDate': startDate,
    'endDate': endDate,
    'status': status,
    'phone': phone,
    'email': email,
    'contactPerson': contactPerson,
  };

  factory Sponsorship.fromJson(Map<String, dynamic> json) => Sponsorship(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    logo: json['logo']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    contractFileName: json['contractFileName']?.toString() ?? '',
    contractFileData: json['contractFileData']?.toString() ?? '',
    removeContract: json['removeContract'] == true,
    value: (json['value'] as num?)?.toDouble() ?? 0,
    startDate: json['startDate']?.toString() ?? '',
    endDate: json['endDate']?.toString() ?? '',
    status: json['status']?.toString() ?? 'Active',
    phone: json['phone']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    contactPerson: json['contactPerson']?.toString() ?? '',
  );
}
