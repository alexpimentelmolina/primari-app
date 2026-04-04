class Profile {
  final String id;
  final String accountType; // 'person' | 'business'
  final String displayName;
  final String phone;
  final String city;
  final String postalCode;
  final String? address;
  final String addressVisibility; // 'exact' | 'city_only' | 'hidden'
  final String? avatarUrl;
  final String? bio;
  final bool isActive;

  const Profile({
    required this.id,
    required this.accountType,
    required this.displayName,
    required this.phone,
    required this.city,
    required this.postalCode,
    this.address,
    this.addressVisibility = 'city_only',
    this.avatarUrl,
    this.bio,
    this.isActive = true,
  });

  factory Profile.fromMap(Map<String, dynamic> map) => Profile(
        id: map['id'] as String,
        accountType: map['account_type'] as String,
        displayName: map['display_name'] as String,
        phone: map['phone'] as String,
        city: map['city'] as String,
        postalCode: map['postal_code'] as String,
        address: map['address'] as String?,
        addressVisibility:
            map['address_visibility'] as String? ?? 'city_only',
        avatarUrl: map['avatar_url'] as String?,
        bio: map['bio'] as String?,
        isActive: map['is_active'] as bool? ?? true,
      );

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'account_type': accountType,
      'display_name': displayName,
      'phone': phone,
      'city': city,
      'postal_code': postalCode,
      'address_visibility': addressVisibility,
      'is_active': isActive,
    };
    if (address != null && address!.isNotEmpty) map['address'] = address;
    if (avatarUrl != null) map['avatar_url'] = avatarUrl;
    if (bio != null && bio!.isNotEmpty) map['bio'] = bio;
    return map;
  }
}
