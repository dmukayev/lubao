import 'common.dart';

class Review {
  const Review({
    required this.id,
    required this.dealId,
    required this.authorUserId,
    required this.authorRole,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  final String id;
  final String dealId;
  final String authorUserId;
  final UserRole authorRole;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'] as String,
        dealId: json['dealId'] as String,
        authorUserId: json['authorUserId'] as String,
        authorRole: userRoleFromJson(json['authorRole'] as String),
        rating: json['rating'] as int,
        comment: json['comment'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
