class Product {
  final String id;
  final String sellerId;
  final String title;
  final String description;
  final double price;
  final String unit;
  final String category;
  final String deliveryType; // 'shipping' | 'in_person' | 'both'
  final String city;
  final String postalCode;
  final String status; // 'active' | 'paused' | 'deleted'
  final String? coverImageUrl;
  final int viewsCount;
  final DateTime createdAt;
  // Coordenadas reales — nullable para compatibilidad con productos sin geocodificar
  final double? lat;
  final double? lng;

  const Product({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.description,
    required this.price,
    required this.unit,
    required this.category,
    required this.deliveryType,
    required this.city,
    required this.postalCode,
    required this.status,
    this.coverImageUrl,
    this.viewsCount = 0,
    required this.createdAt,
    this.lat,
    this.lng,
  });

  factory Product.fromMap(Map<String, dynamic> m) => Product(
        id: m['id'] as String,
        sellerId: m['seller_id'] as String,
        title: m['title'] as String,
        description: m['description'] as String? ?? '',
        price: (m['price'] as num).toDouble(),
        unit: m['unit'] as String,
        category: m['category'] as String,
        deliveryType: m['delivery_type'] as String,
        city: m['city'] as String? ?? '',
        postalCode: m['postal_code'] as String? ?? '',
        status: m['status'] as String? ?? 'active',
        coverImageUrl: m['cover_image_url'] as String?,
        viewsCount: m['views_count'] as int? ?? 0,
        createdAt: DateTime.parse(m['created_at'] as String),
        lat: (m['lat'] as num?)?.toDouble(),
        lng: (m['lng'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toInsertMap() => {
        'seller_id': sellerId,
        'title': title,
        'description': description,
        'price': price,
        'unit': unit,
        'category': category,
        'delivery_type': deliveryType,
        'city': city,
        'postal_code': postalCode,
        'status': status,
        if (coverImageUrl != null) 'cover_image_url': coverImageUrl,
      };

  Map<String, dynamic> toUpdateMap() => {
        'title': title,
        'description': description,
        'price': price,
        'unit': unit,
        'category': category,
        'delivery_type': deliveryType,
        'city': city,
        'postal_code': postalCode,
        if (coverImageUrl != null) 'cover_image_url': coverImageUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };

  // ── UI helpers ──────────────────────────────────────────────────────────────

  static const categories = [
    'frutas y verduras',
    'huevos',
    'miel',
    'carne',
    'pescado y marisco',
    'quesos y lácteos',
    'aceite',
    'panadería y repostería artesanal',
    'conservas y elaborados artesanales',
    'otros',
  ];

  static const units = [
    'kg',
    'g',
    'litro',
    'docena',
    'unidad',
    'caja',
    'bandeja',
  ];

  static const deliveryOptions = {
    'shipping': 'Envío a domicilio',
    'in_person': 'Recogida en persona',
    'both': 'Envío y recogida',
  };

  String get priceLabel {
    final formatted = price == price.truncateToDouble()
        ? price.toInt().toString()
        : price.toStringAsFixed(2);
    return '$formatted €';
  }

  String get deliveryLabel =>
      deliveryOptions[deliveryType] ?? deliveryType;

  String get categoryLabel => category.isNotEmpty
      ? category[0].toUpperCase() + category.substring(1)
      : '';
}

class ProductImage {
  final String id;
  final String productId;
  final String imageUrl;
  final int sortOrder;
  final bool isCover;

  const ProductImage({
    required this.id,
    required this.productId,
    required this.imageUrl,
    required this.sortOrder,
    required this.isCover,
  });

  factory ProductImage.fromMap(Map<String, dynamic> m) => ProductImage(
        id: m['id'] as String,
        productId: m['product_id'] as String,
        imageUrl: m['image_url'] as String,
        sortOrder: m['sort_order'] as int? ?? 0,
        isCover: m['is_cover'] as bool? ?? false,
      );
}

class ProductDetail {
  final Product product;
  final List<ProductImage> images;
  final Map<String, dynamic>? seller;

  const ProductDetail({
    required this.product,
    required this.images,
    this.seller,
  });

  String? get coverUrl {
    if (product.coverImageUrl != null) return product.coverImageUrl;
    if (images.isNotEmpty) return images.first.imageUrl;
    return null;
  }
}
