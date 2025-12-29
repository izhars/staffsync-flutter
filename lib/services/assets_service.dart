import '../models/Asset.dart';
import 'network_service.dart';

class AssetsService {
  final NetworkService _networkService = NetworkService();

  Future<List<Asset>> getMyAssets() async {
    try {
      final response = await _networkService.get('/assets/my-assets');
      if (response['success'] == true) {
        final List<dynamic> assetsJson = response['assets'];
        return assetsJson.map((json) {
          try {
            return Asset.fromJson(json);
          } catch (e) {
            // Log the error but don't break the whole list
            print('Error parsing asset: $e');
            // Return a default asset or skip it
            return Asset.fromJson({
              '_id': 'error',
              'assetId': 'ERROR',
              'name': 'Error loading asset',
              'category': 'error',
              'purchaseDate': DateTime.now().toIso8601String(),
              'purchasePrice': 0,
              'status': 'retired',
              'condition': 'error',
              'createdAt': DateTime.now().toIso8601String(),
              'updatedAt': DateTime.now().toIso8601String(),
            });
          }
        }).toList();
      }
      throw Exception('Failed to load my assets');
    } catch (e) {
      print('Error in getMyAssets: $e');
      rethrow;
    }
  }
}