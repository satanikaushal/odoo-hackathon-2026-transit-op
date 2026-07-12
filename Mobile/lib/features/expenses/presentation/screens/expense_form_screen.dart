import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../shared/utils/responsive.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_dialogs.dart';
import '../../../../shared/widgets/app_gap.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import '../../../../shared/widgets/app_text.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../application/expense_form_provider.dart';
import '../../domain/models/expense_category.dart';

class ExpenseFormScreen extends ConsumerStatefulWidget {
  const ExpenseFormScreen({super.key});

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  static final _decimalInput =
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'));

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _dateController;
  String? _vehicleId;
  String? _tripId;
  ExpenseCategory _category = ExpenseCategory.toll;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _descriptionController = TextEditingController();
    _dateController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _selectedDate = picked;
      _dateController.text = DateFormat('dd MMM yyyy').format(picked);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_vehicleId == null) {
      showSnackBarMessage(context, 'Select a vehicle.');
      return;
    }

    FocusScope.of(context).unfocus();

    final result = await ref.read(expenseFormProvider.notifier).submit(
          vehicleId: _vehicleId!,
          category: _category,
          amount: _amountController.text,
          tripId: _tripId,
          description: _descriptionController.text,
          date: _selectedDate,
        );

    if (!mounted) {
      return;
    }

    if (result.error != null) {
      showSnackBarMessage(context, result.error!);
      return;
    }

    showSnackBarMessage(context, 'Expense recorded.');
    context.pop();
  }

  void _onVehicleChanged(String? value) {
    setState(() {
      _vehicleId = value;
      _tripId = null;
    });
    if (value != null) {
      ref.read(expenseFormProvider.notifier).loadTripsForVehicle(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expenseFormProvider);
    final theme = Theme.of(context);

    if (state.isLoadingOptions) {
      return ListView(
        padding: Responsive.getPaddingSymmetric(horizontal: 16, vertical: 16),
        children: [
          AppShimmer(
            child: Column(
              children: List.generate(
                6,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppShimmerBox(
                    height: Responsive.getH(52),
                    borderRadius: 8,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (state.error != null && state.vehicles.isEmpty) {
      return Center(
        child: Padding(
          padding: Responsive.getPaddingSymmetric(horizontal: 16, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(state.error!, size: 14, textAlign: TextAlign.center),
              const AppGap(16),
              AppButton(
                label: 'Retry',
                expand: false,
                onPressed: () => ref.invalidate(expenseFormProvider),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: Responsive.getPaddingSymmetric(horizontal: 16, vertical: 16),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Vehicle',
                  contentPadding: Responsive.getPaddingSymmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _vehicleId,
                    hint: Text(
                      state.vehicles.isEmpty
                          ? 'No vehicles available'
                          : 'Select vehicle',
                    ),
                    items: state.vehicles
                        .map(
                          (vehicle) => DropdownMenuItem(
                            value: vehicle.id,
                            child: Text(
                              '${vehicle.registrationNumber} · ${vehicle.name}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: state.isSubmitting ? null : _onVehicleChanged,
                  ),
                ),
              ),
              const AppGap(12),
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Category',
                  contentPadding: Responsive.getPaddingSymmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ExpenseCategory>(
                    isExpanded: true,
                    value: _category,
                    items: ExpenseCategory.values
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(category.label),
                          ),
                        )
                        .toList(),
                    onChanged: state.isSubmitting
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() => _category = value);
                            }
                          },
                    style: TextStyle(
                      fontSize: Responsive.getF(14),
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              const AppGap(12),
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Trip (optional)',
                  contentPadding: Responsive.getPaddingSymmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    isExpanded: true,
                    value: _tripId,
                    hint: Text(
                      _vehicleId == null
                          ? 'Select a vehicle first'
                          : state.isLoadingTrips
                              ? 'Loading trips...'
                              : 'No trip',
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('No trip'),
                      ),
                      ...state.trips.map(
                        (trip) => DropdownMenuItem<String?>(
                          value: trip.id,
                          child: Text(trip.routeLabel),
                        ),
                      ),
                    ],
                    onChanged: state.isSubmitting ||
                            _vehicleId == null ||
                            state.isLoadingTrips
                        ? null
                        : (value) => setState(() => _tripId = value),
                  ),
                ),
              ),
              const AppGap(12),
              AppTextField(
                controller: _amountController,
                label: 'Amount',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [_decimalInput],
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Amount is required';
                  }
                  final parsed = double.tryParse(value.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a value greater than 0';
                  }
                  return null;
                },
              ),
              const AppGap(12),
              AppTextField(
                controller: _descriptionController,
                label: 'Description (optional)',
                maxLines: 2,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value != null && value.trim().length > 500) {
                    return 'Description must be 500 characters or fewer';
                  }
                  return null;
                },
              ),
              const AppGap(12),
              AppTextField(
                controller: _dateController,
                label: 'Date (optional)',
                readOnly: true,
                onTap: state.isSubmitting ? null : _pickDate,
              ),
              const AppGap(24),
              AppButton(
                label: 'Record Expense',
                isLoading: state.isSubmitting,
                onPressed: state.isSubmitting ? null : _submit,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
