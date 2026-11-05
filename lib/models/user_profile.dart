class UserProfile {
  final String id;
  final String username;
  final String fullName;
  final String email;
  final String phone;
  final String role;
  final String department;
  final String avatarUrl;
  final String bio;

  const UserProfile({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.department,
    required this.avatarUrl,
    required this.bio,
  });

  factory UserProfile.defaultProfile() {
    return const UserProfile(
      id: 'usr_owner_01',
      username: 'admin',
      fullName: 'John W. Henry',
      email: 'john.henry@liverpoolfc.com',
      phone: '+1 (617) 226-6000',
      role: 'Principal Owner & Club Chairman',
      department: 'Board of Directors & Club Ownership (FSG)',
      avatarUrl: 'assets/images/john.jpg',
      bio: 'Principal Owner of Liverpool Football Club & Fenway Sports Group (FSG). Overseeing global club investments, Anfield stadium expansions, commercial deals with Adidas, and championship pursuits.',
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? 'usr_owner_01',
      username: json['username'] as String? ?? 'admin',
      fullName: json['fullName'] as String? ?? json['full_name'] as String? ?? 'John W. Henry',
      email: json['email'] as String? ?? 'john.henry@liverpoolfc.com',
      phone: json['phone'] as String? ?? '+1 (617) 226-6000',
      role: json['role'] as String? ?? 'Principal Owner & Club Chairman',
      department: json['department'] as String? ?? 'Board of Directors & Club Ownership (FSG)',
      avatarUrl: json['avatarUrl'] as String? ?? json['avatar_url'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'department': department,
      'avatarUrl': avatarUrl,
      'bio': bio,
    };
  }

  UserProfile copyWith({
    String? id,
    String? username,
    String? fullName,
    String? email,
    String? phone,
    String? role,
    String? department,
    String? avatarUrl,
    String? bio,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      department: department ?? this.department,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
    );
  }
}
