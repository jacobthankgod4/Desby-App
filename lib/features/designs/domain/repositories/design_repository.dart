import '../../../../core/error/failures.dart';
import '../entities/design.dart';

abstract class DesignRepository {
  Future<Result<void>> uploadDesign(Design design);
  Future<Result<void>> updateDesign(Design design);
  Future<Result<void>> deleteDesign(String id);
  Future<Result<Design>> getDesignById(String id);
  Future<Result<List<Design>>> getDesigns({String? category});
  Stream<List<Design>> streamDesigns({
    String? category,
    String? tailorId,
    String? gender,
  });
  Future<Result<List<Design>>> getFeaturedDesigns();
  Future<Result<void>> toggleLike(String designId, String userId);
  Future<Result<int>> getLikeCount(String designId);
  Future<Result<List<String>>> getLikedDesignIds(String userId);
}
