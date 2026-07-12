import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_result.dart';
import '../domain/models/dashboard_filter_options.dart';
import '../domain/models/dashboard_kpis.dart';

class DashboardRepository {
  DashboardRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<ApiResult<DashboardFilterOptions>> fetchFilterOptions() {
    return _apiClient.get<DashboardFilterOptions>(
      ApiEndpoints.dashboardFilters,
      parser: (data) =>
          DashboardFilterOptions.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<DashboardKpis>> fetchKpis({
    String? type,
    String? status,
    String? region,
  }) {
    final queryParameters = <String, dynamic>{};
    if (type != null && type.isNotEmpty) {
      queryParameters['type'] = type;
    }
    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status;
    }
    if (region != null && region.isNotEmpty) {
      queryParameters['region'] = region;
    }

    return _apiClient.get<DashboardKpis>(
      ApiEndpoints.dashboardKpis,
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
      parser: (data) => DashboardKpis.fromJson(data as Map<String, dynamic>),
    );
  }
}
