import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_result.dart';
import '../../dashboard/domain/models/dashboard_filter_options.dart';
import '../domain/models/paginated_vehicles.dart';
import '../domain/models/vehicle.dart';
import '../domain/models/vehicle_operational_cost.dart';
import '../domain/models/vehicle_status.dart';

class FleetRepository {
  FleetRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  static const defaultPageSize = 20;

  Future<ApiResult<DashboardFilterOptions>> fetchFilterOptions() {
    return _apiClient.get<DashboardFilterOptions>(
      ApiEndpoints.dashboardFilters,
      parser: (data) =>
          DashboardFilterOptions.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<PaginatedVehicles>> fetchVehicles({
    int page = 1,
    int limit = defaultPageSize,
    String? status,
    String? type,
    String? search,
  }) {
    final queryParameters = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status;
    }
    if (type != null && type.isNotEmpty) {
      queryParameters['type'] = type;
    }
    if (search != null && search.isNotEmpty) {
      queryParameters['search'] = search;
    }

    return _apiClient.get<PaginatedVehicles>(
      ApiEndpoints.vehicles,
      queryParameters: queryParameters,
      parser: (data) =>
          PaginatedVehicles.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<Vehicle>> fetchVehicle(String id) {
    return _apiClient.get<Vehicle>(
      ApiEndpoints.vehicle(id),
      parser: (data) => Vehicle.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<VehicleOperationalCost>> fetchVehicleCosts(String id) {
    return _apiClient.get<VehicleOperationalCost>(
      ApiEndpoints.vehicleCosts(id),
      parser: (data) =>
          VehicleOperationalCost.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<Vehicle>> createVehicle(Map<String, dynamic> body) {
    return _apiClient.post<Vehicle>(
      ApiEndpoints.vehicles,
      data: body,
      parser: (data) => Vehicle.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<Vehicle>> updateVehicle(
    String id,
    Map<String, dynamic> body,
  ) {
    return _apiClient.patch<Vehicle>(
      ApiEndpoints.vehicle(id),
      data: body,
      parser: (data) => Vehicle.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<Vehicle>> updateVehicleStatus(
    String id,
    VehicleStatus status,
  ) {
    return _apiClient.patch<Vehicle>(
      ApiEndpoints.vehicleStatus(id),
      data: {'status': status.name},
      parser: (data) => Vehicle.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<void>> deleteVehicle(String id) {
    return _apiClient.delete<void>(ApiEndpoints.vehicle(id));
  }
}
