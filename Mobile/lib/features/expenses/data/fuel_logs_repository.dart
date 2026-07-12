import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_result.dart';
import '../domain/models/fuel_log.dart';
import '../domain/models/paginated_fuel_logs.dart';

class FuelLogsRepository {
  FuelLogsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  static const defaultPageSize = 20;

  Future<ApiResult<PaginatedFuelLogs>> fetchLogs({
    int page = 1,
    int limit = defaultPageSize,
    String? vehicleId,
    String? tripId,
  }) {
    final queryParameters = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (vehicleId != null && vehicleId.isNotEmpty) {
      queryParameters['vehicleId'] = vehicleId;
    }
    if (tripId != null && tripId.isNotEmpty) {
      queryParameters['tripId'] = tripId;
    }

    return _apiClient.get<PaginatedFuelLogs>(
      ApiEndpoints.fuelLogs,
      queryParameters: queryParameters,
      parser: PaginatedFuelLogs.fromDynamic,
    );
  }

  Future<ApiResult<FuelLog>> fetchLog(String id) {
    return _apiClient.get<FuelLog>(
      ApiEndpoints.fuelLog(id),
      parser: (data) => FuelLog.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<FuelLog>> createLog(Map<String, dynamic> body) {
    return _apiClient.post<FuelLog>(
      ApiEndpoints.fuelLogs,
      data: body,
      parser: (data) => FuelLog.fromJson(data as Map<String, dynamic>),
    );
  }
}
