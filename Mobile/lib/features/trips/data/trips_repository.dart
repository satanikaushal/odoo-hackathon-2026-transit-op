import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_result.dart';
import '../domain/models/paginated_trips.dart';
import '../domain/models/trip.dart';

class TripsRepository {
  TripsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  static const defaultPageSize = 20;

  Future<ApiResult<PaginatedTrips>> fetchTrips({
    int page = 1,
    int limit = defaultPageSize,
    String? status,
    String? search,
    String? vehicleId,
    String? driverId,
  }) {
    final queryParameters = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status;
    }
    if (search != null && search.isNotEmpty) {
      queryParameters['search'] = search;
    }
    if (vehicleId != null && vehicleId.isNotEmpty) {
      queryParameters['vehicleId'] = vehicleId;
    }
    if (driverId != null && driverId.isNotEmpty) {
      queryParameters['driverId'] = driverId;
    }

    return _apiClient.get<PaginatedTrips>(
      ApiEndpoints.trips,
      queryParameters: queryParameters,
      parser: (data) => PaginatedTrips.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<Trip>> fetchTrip(String id) {
    return _apiClient.get<Trip>(
      ApiEndpoints.trip(id),
      parser: (data) => Trip.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<Trip>> createTrip(Map<String, dynamic> body) {
    return _apiClient.post<Trip>(
      ApiEndpoints.trips,
      data: body,
      parser: (data) => Trip.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<Trip>> dispatchTrip(String id) {
    return _apiClient.post<Trip>(
      ApiEndpoints.tripDispatch(id),
      parser: (data) => Trip.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<Trip>> completeTrip(
    String id,
    Map<String, dynamic> body,
  ) {
    return _apiClient.post<Trip>(
      ApiEndpoints.tripComplete(id),
      data: body,
      parser: (data) => Trip.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<Trip>> cancelTrip(String id) {
    return _apiClient.post<Trip>(
      ApiEndpoints.tripCancel(id),
      parser: (data) => Trip.fromJson(data as Map<String, dynamic>),
    );
  }
}
