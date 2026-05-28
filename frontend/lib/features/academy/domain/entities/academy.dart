/// Academy entity —학원 기본 정보
class Academy {
  final String id;
  final String slug;
  final String name;
  final String? address;
  final String ownerUserId;
  final DateTime createdAt;

  const Academy({
    required this.id,
    required this.slug,
    required this.name,
    this.address,
    required this.ownerUserId,
    required this.createdAt,
  });

  Academy copyWith({
    String? id,
    String? slug,
    String? name,
    String? address,
    String? ownerUserId,
    DateTime? createdAt,
  }) {
    return Academy(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      name: name ?? this.name,
      address: address ?? this.address,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Academy &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          slug == other.slug &&
          name == other.name &&
          address == other.address &&
          ownerUserId == other.ownerUserId &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      slug.hashCode ^
      name.hashCode ^
      address.hashCode ^
      ownerUserId.hashCode ^
      createdAt.hashCode;
}
