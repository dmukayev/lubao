import '../api/api_client.dart';
import '../models/review.dart';

class ReviewRepository {
  ReviewRepository(this._client);

  final ApiClient _client;

  Future<List<Review>> forDeal(String dealId) async {
    final res = await _client.dio.get('/deals/$dealId/reviews');
    return (res.data as List<dynamic>).map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Review> submit(String dealId, {required int rating, String? comment}) async {
    final res = await _client.dio
        .post('/deals/$dealId/reviews', data: {'rating': rating, if (comment != null) 'comment': comment});
    return Review.fromJson(res.data as Map<String, dynamic>);
  }
}
