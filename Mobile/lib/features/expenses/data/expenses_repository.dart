import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_result.dart';
import '../domain/models/expense.dart';
import '../domain/models/paginated_expenses.dart';

class ExpensesRepository {
  ExpensesRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  static const defaultPageSize = 20;

  Future<ApiResult<PaginatedExpenses>> fetchExpenses({
    int page = 1,
    int limit = defaultPageSize,
    String? vehicleId,
    String? tripId,
    String? category,
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
    if (category != null && category.isNotEmpty) {
      queryParameters['category'] = category;
    }

    return _apiClient.get<PaginatedExpenses>(
      ApiEndpoints.expenses,
      queryParameters: queryParameters,
      parser: PaginatedExpenses.fromDynamic,
    );
  }

  Future<ApiResult<Expense>> fetchExpense(String id) {
    return _apiClient.get<Expense>(
      ApiEndpoints.expense(id),
      parser: (data) => Expense.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResult<Expense>> createExpense(Map<String, dynamic> body) {
    return _apiClient.post<Expense>(
      ApiEndpoints.expenses,
      data: body,
      parser: (data) => Expense.fromJson(data as Map<String, dynamic>),
    );
  }
}
