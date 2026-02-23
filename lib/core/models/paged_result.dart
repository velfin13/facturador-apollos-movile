class PagedResult<T> {
  final List<T> items;
  final int total;
  final int page;
  final int size;

  const PagedResult({
    required this.items,
    required this.total,
    required this.page,
    required this.size,
  });

  bool get hasMore => (page + 1) * size < total;

  /// Crea un PagedResult desde el mapa `data` de la respuesta de la API.
  /// [fromItem] convierte cada elemento del JSON al tipo T.
  static PagedResult<T> fromApiData<T>(
    Map<String, dynamic> data,
    T Function(Map<String, dynamic>) fromItem,
  ) {
    final rawItems = data['items'] as List<dynamic>? ?? [];
    return PagedResult<T>(
      items: rawItems.map((e) => fromItem(e as Map<String, dynamic>)).toList(),
      total: data['total'] as int? ?? 0,
      page: data['page'] as int? ?? 0,
      size: data['size'] as int? ?? 20,
    );
  }
}
