import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_result.dart';
import '../domain/models/maintenance_log.dart';
import '../domain/models/paginated_maintenance_logs.dart';

class MaintenanceRepository {
  MaintenanceRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  static const defaultPageSize = 20;

  Future<ApiResult<PaginatedMaintenanceLogs>> fetchLogs({
    int page = 1,
    int limit = defaultPageSize,
    String? status,
    String? vehicleId,
  }) {
    final queryParameters = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status;
    }
    if (vehicleId != null && vehicleId.isNotEmpty) {
      queryParameters['vehicleId'] = vehicleId;
    }

    return _apiClient.get<PaginatedMaintenanceLogs>(
      ApiEndpoints.maintenance,
      queryParameters: queryParameters,
      parser: PaginatedMaintenanceLogs.fromDynamic,
    );
  }

  Future<ApiResult<MaintenanceLog>> fetchLog(String id) {
    return _apiClient.get<MaintenanceLog>(
      ApiEndpoints.maintenanceLog(id),
      parser: (data) => MaintenanceLog.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<MaintenanceLog>> openLog(Map<String, dynamic> body) {
    return _apiClient.post<MaintenanceLog>(
      ApiEndpoints.maintenance,
      data: body,
      parser: (data) => MaintenanceLog.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<MaintenanceLog>> closeLog(String id) {
    return _apiClient.post<MaintenanceLog>(
      ApiEndpoints.maintenanceClose(id),
      parser: (data) => MaintenanceLog.fromJson(data as Map<String, dynamic>),
    );
  }
}
