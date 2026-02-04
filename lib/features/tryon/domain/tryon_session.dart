class TryonSession {
  final String id;
  final String userId;
  final Map<String, dynamic> outfitSnapshot;
  final String? generatedImageUrl;
  final DateTime createdAt;

  TryonSession({
    required this.id,
    required this.userId,
    required this.outfitSnapshot,
    this.generatedImageUrl,
    required this.createdAt,
  });

  factory TryonSession.fromJson(Map<String, dynamic> json) {
    return TryonSession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      outfitSnapshot: json['outfit_snapshot'] as Map<String, dynamic>,
      generatedImageUrl: json['generated_image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'outfit_snapshot': outfitSnapshot,
      'generated_image_url': generatedImageUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class PositionedItem {
  final String itemId;
  final double x;
  final double y;
  final double scale;

  PositionedItem({
    required this.itemId,
    required this.x,
    required this.y,
    this.scale = 1.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'x': x,
      'y': y,
      'scale': scale,
    };
  }

  factory PositionedItem.fromJson(Map<String, dynamic> json) {
    return PositionedItem(
      itemId: json['item_id'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
    );
  }
}
