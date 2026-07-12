import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/json_list_parser.dart';
import '../domain/models/fleet_utilization_report.dart';
import '../domain/models/fuel_efficiency_row.dart';
import '../domain/models/operational_cost_row.dart';
import '../domain/models/report_type.dart';
import '../domain/models/vehicle_roi_row.dart';

class ReportsRepository {
  ReportsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<ApiResult<List<FuelEfficiencyRow>>> fetchFuelEfficiency() {
    return _apiClient.get<List<FuelEfficiencyRow>>(
      ApiEndpoints.reportsFuelEfficiency,
      parser: (data) => parseJsonList(data, FuelEfficiencyRow.fromJson),
    );
  }

  Future<ApiResult<FleetUtilizationReport>> fetchFleetUtilization() {
    return _apiClient.get<FleetUtilizationReport>(
      ApiEndpoints.reportsFleetUtilization,
      parser: (data) =>
          FleetUtilizationReport.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<List<OperationalCostRow>>> fetchOperationalCost() {
    return _apiClient.get<List<OperationalCostRow>>(
      ApiEndpoints.reportsOperationalCost,
      parser: (data) => parseJsonList(data, OperationalCostRow.fromJson),
    );
  }

  Future<ApiResult<List<VehicleRoiRow>>> fetchVehicleRoi() {
    return _apiClient.get<List<VehicleRoiRow>>(
      ApiEndpoints.reportsVehicleRoi,
      parser: (data) => parseJsonList(data, VehicleRoiRow.fromJson),
    );
  }

  Future<ApiResult<String>> exportCsv(ReportType report) {
    return _apiClient.getRaw(
      ApiEndpoints.reportsExportCsv,
      queryParameters: {'report': report.exportSlug},
    );
  }
}
