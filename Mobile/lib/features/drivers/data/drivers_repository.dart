import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_result.dart';
import '../domain/models/driver.dart';
import '../domain/models/paginated_drivers.dart';

class DriversRepository {
  DriversRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  static const defaultPageSize = 20;

  Future<ApiResult<PaginatedDrivers>> fetchDrivers({
    int page = 1,
    int limit = defaultPageSize,
    String? status,
    String? query,
  }) {
    final queryParameters = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status;
    }
    if (query != null && query.isNotEmpty) {
      queryParameters['q'] = query;
    }

    return _apiClient.get<PaginatedDrivers>(
      ApiEndpoints.drivers,
      queryParameters: queryParameters,
      parser: PaginatedDrivers.fromDynamic,
    );
  }

  Future<ApiResult<Driver>> fetchDriver(String id) {
    return _apiClient.get<Driver>(
      ApiEndpoints.driver(id),
      parser: (data) => Driver.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<Driver>> createDriver(Map<String, dynamic> body) {
    return _apiClient.post<Driver>(
      ApiEndpoints.drivers,
      data: body,
      parser: (data) => Driver.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<Driver>> updateDriver(
    String id,
    Map<String, dynamic> body,
  ) {
    return _apiClient.patch<Driver>(
      ApiEndpoints.driver(id),
      data: body,
      parser: (data) => Driver.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<void>> deleteDriver(String id) {
    return _apiClient.delete<void>(ApiEndpoints.driver(id));
  }
}
