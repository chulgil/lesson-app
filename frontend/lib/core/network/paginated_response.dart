/// Generic paginated response matching FastAPI pagination schema.
class PaginatedResponse<T> {
  final List<T> items;
  final int total;
  final int page;
  final int size;
  final int pages;

  const PaginatedResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.size,
    required this.pages,
  });

  /// Whether there are more pages.
  bool get hasNext => page < pages;

  /// Whether this is the first page.
  bool get isFirst => page == 1;

  /// Parse from JSON with a factory for item deserialization.
  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PaginatedResponse<T>(
      items:
          (json['items'] as List<dynamic>)
              .map((e) => fromJsonT(e as Map<String, dynamic>))
              .toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      size: json['size'] as int,
      pages: json['pages'] as int,
    );
  }
}
