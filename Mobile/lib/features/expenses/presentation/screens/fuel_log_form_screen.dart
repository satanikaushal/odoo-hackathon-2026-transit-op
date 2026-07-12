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
import '../../../fleet/domain/models/vehicle.dart';
import '../../../trips/domain/models/trip.dart';
import '../../application/fuel_log_form_provider.dart';

class FuelLogFormScreen extends ConsumerStatefulWidget {
  const FuelLogFormScreen({super.key});

  @override
  ConsumerState<FuelLogFormScreen> createState() => _FuelLogFormScreenState();
}

class _FuelLogFormScreenState extends ConsumerState<FuelLogFormScreen> {
  static final _decimalInput =
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'));

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _litersController;
  late final TextEditingController _costController;
  late final TextEditingController _dateController;
  String? _vehicleId;
  String? _tripId;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _litersController = TextEditingController();
    _costController = TextEditingController();
    _dateController = TextEditingController();
  }

  @override
  void dispose() {
    _litersController.dispose();
    _costController.dispose();
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

    final liters = double.tryParse(_litersController.text.trim());
    if (liters == null || liters <= 0) {
      showSnackBarMessage(context, 'Enter a valid liters value.');
      return;
    }

    FocusScope.of(context).unfocus();

    final result = await ref.read(fuelLogFormProvider.notifier).submit(
          vehicleId: _vehicleId!,
          liters: liters,
          cost: _costController.text,
          tripId: _tripId,
          date: _selectedDate,
        );

    if (!mounted) {
      return;
    }

    if (result.error != null) {
      if (result.statusCode == 400) {
        showSnackBarMessage(context, result.error!);
      } else {
        showSnackBarMessage(context, result.error!);
      }
      return;
    }

    showSnackBarMessage(context, 'Fuel log recorded.');
    context.pop();
  }

  void _onVehicleChanged(String? value) {
    setState(() {
      _vehicleId = value;
      _tripId = null;
    });
    if (value != null) {
      ref.read(fuelLogFormProvider.notifier).loadTripsForVehicle(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fuelLogFormProvider);

    if (state.isLoadingOptions) {
      return ListView(
        padding: Responsive.getPaddingSymmetric(horizontal: 16, vertical: 16),
        children: [
          AppShimmer(
            child: Column(
              children: List.generate(
                5,
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
                onPressed: () => ref.invalidate(fuelLogFormProvider),
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
              _VehicleDropdown(
                vehicles: state.vehicles,
                value: _vehicleId,
                isSubmitting: state.isSubmitting,
                onChanged: _onVehicleChanged,
              ),
              const AppGap(12),
              _TripDropdown(
                trips: state.trips,
                value: _tripId,
                isLoading: state.isLoadingTrips,
                vehicleSelected: _vehicleId != null,
                isSubmitting: state.isSubmitting,
                onChanged: (value) => setState(() => _tripId = value),
              ),
              const AppGap(12),
              AppTextField(
                controller: _litersController,
                label: 'Liters',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [_decimalInput],
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Liters is required';
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
                controller: _costController,
                label: 'Cost',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [_decimalInput],
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Cost is required';
                  }
                  final parsed = double.tryParse(value.trim());
                  if (parsed == null || parsed < 0) {
                    return 'Enter a valid cost';
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
                label: 'Record Fuel Log',
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

class _VehicleDropdown extends StatelessWidget {
  const _VehicleDropdown({
    required this.vehicles,
    required this.value,
    required this.isSubmitting,
    required this.onChanged,
  });

  final List<Vehicle> vehicles;
  final String? value;
  final bool isSubmitting;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
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
          value: value,
          hint: Text(
            vehicles.isEmpty ? 'No vehicles available' : 'Select vehicle',
          ),
          items: vehicles
              .map(
                (vehicle) => DropdownMenuItem(
                  value: vehicle.id,
                  child: Text(
                    '${vehicle.registrationNumber} · ${vehicle.name}',
                  ),
                ),
              )
              .toList(),
          onChanged: isSubmitting ? null : onChanged,
        ),
      ),
    );
  }
}

class _TripDropdown extends StatelessWidget {
  const _TripDropdown({
    required this.trips,
    required this.value,
    required this.isLoading,
    required this.vehicleSelected,
    required this.isSubmitting,
    required this.onChanged,
  });

  final List<Trip> trips;
  final String? value;
  final bool isLoading;
  final bool vehicleSelected;
  final bool isSubmitting;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
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
          value: value,
          hint: Text(
            !vehicleSelected
                ? 'Select a vehicle first'
                : isLoading
                    ? 'Loading trips...'
                    : 'No trip',
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('No trip'),
            ),
            ...trips.map(
              (trip) => DropdownMenuItem<String?>(
                value: trip.id,
                child: Text(trip.routeLabel),
              ),
            ),
          ],
          onChanged:
              isSubmitting || !vehicleSelected || isLoading ? null : onChanged,
        ),
      ),
    );
  }
}
