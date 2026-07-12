import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/utils/responsive.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_dialogs.dart';
import '../../../../shared/widgets/app_gap.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import '../../../../shared/widgets/app_text.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../application/trip_form_provider.dart';
import '../../../fleet/domain/fleet_formatters.dart';

class TripFormScreen extends ConsumerStatefulWidget {
  const TripFormScreen({super.key});

  @override
  ConsumerState<TripFormScreen> createState() => _TripFormScreenState();
}

class _TripFormScreenState extends ConsumerState<TripFormScreen> {
  static final _decimalInput =
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'));

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _sourceController;
  late final TextEditingController _destinationController;
  late final TextEditingController _cargoController;
  late final TextEditingController _distanceController;
  String? _vehicleId;
  String? _driverId;

  @override
  void initState() {
    super.initState();
    _sourceController = TextEditingController();
    _destinationController = TextEditingController();
    _cargoController = TextEditingController();
    _distanceController = TextEditingController();
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _destinationController.dispose();
    _cargoController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_vehicleId == null || _driverId == null) {
      showSnackBarMessage(context, 'Select a vehicle and driver.');
      return;
    }

    FocusScope.of(context).unfocus();
    final cargoWeight = double.tryParse(_cargoController.text.trim());
    final plannedDistance = double.tryParse(_distanceController.text.trim());

    if (cargoWeight == null || cargoWeight <= 0) {
      showSnackBarMessage(context, 'Enter a valid cargo weight.');
      return;
    }

    if (plannedDistance == null || plannedDistance <= 0) {
      showSnackBarMessage(context, 'Enter a valid planned distance.');
      return;
    }

    final result = await ref.read(tripFormProvider.notifier).submit(
          source: _sourceController.text,
          destination: _destinationController.text,
          vehicleId: _vehicleId!,
          driverId: _driverId!,
          cargoWeight: cargoWeight,
          plannedDistance: plannedDistance,
        );

    if (!mounted) {
      return;
    }

    if (result.error != null) {
      if (result.statusCode == 409) {
        await showConflictDialog(context, message: result.error!);
      } else {
        showSnackBarMessage(context, result.error!);
      }
      return;
    }

    showSnackBarMessage(context, 'Trip created as draft.');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tripFormProvider);

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

    if (state.error != null &&
        state.vehicles.isEmpty &&
        state.drivers.isEmpty) {
      return Center(
        child: Padding(
          padding: Responsive.getPaddingSymmetric(horizontal: 16, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                state.error!,
                size: 14,
                textAlign: TextAlign.center,
              ),
              const AppGap(16),
              AppButton(
                label: 'Retry',
                expand: false,
                onPressed: () => ref.invalidate(tripFormProvider),
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
              AppTextField(
                controller: _sourceController,
                label: 'Source',
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Source is required';
                  }
                  return null;
                },
              ),
              const AppGap(12),
              AppTextField(
                controller: _destinationController,
                label: 'Destination',
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Destination is required';
                  }
                  return null;
                },
              ),
              const AppGap(12),
              _AssignmentDropdown(
                label: 'Vehicle',
                value: _vehicleId,
                hint: state.vehicles.isEmpty
                    ? 'No available vehicles'
                    : 'Select vehicle',
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
                onChanged: state.isSubmitting
                    ? null
                    : (value) => setState(() => _vehicleId = value),
              ),
              const AppGap(12),
              _AssignmentDropdown(
                label: 'Driver',
                value: _driverId,
                hint: state.drivers.isEmpty
                    ? 'No available drivers'
                    : 'Select driver',
                items: state.drivers
                    .map(
                      (driver) => DropdownMenuItem(
                        value: driver.id,
                        child: Text('${driver.name} · ${driver.licenseNumber}'),
                      ),
                    )
                    .toList(),
                onChanged: state.isSubmitting
                    ? null
                    : (value) => setState(() => _driverId = value),
              ),
              const AppGap(12),
              AppTextField(
                controller: _cargoController,
                label: 'Cargo Weight (kg)',
                keyboardType: TextInputType.number,
                inputFormatters: [_decimalInput],
                textInputAction: TextInputAction.next,
                validator: (value) {
                  final parsed = double.tryParse(value ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a positive cargo weight';
                  }
                  return null;
                },
              ),
              if (_vehicleId != null) ...[
                const AppGap(6),
                Builder(
                  builder: (context) {
                    final vehicle = state.vehicles
                        .where((v) => v.id == _vehicleId)
                        .firstOrNull;
                    if (vehicle == null) {
                      return const SizedBox.shrink();
                    }
                    return AppText(
                      'Max capacity: ${FleetFormatters.formatCapacity(vehicle.maxLoadCapacity)}',
                      size: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    );
                  },
                ),
              ],
              const AppGap(12),
              AppTextField(
                controller: _distanceController,
                label: 'Planned Distance (km)',
                keyboardType: TextInputType.number,
                inputFormatters: [_decimalInput],
                textInputAction: TextInputAction.done,
                validator: (value) {
                  final parsed = double.tryParse(value ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a positive distance';
                  }
                  return null;
                },
              ),
              const AppGap(24),
              AppButton(
                label: 'Create Draft Trip',
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

class _AssignmentDropdown extends StatelessWidget {
  const _AssignmentDropdown({
    required this.label,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final String hint;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        contentPadding: Responsive.getPaddingSymmetric(
          horizontal: 12,
          vertical: 4,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(hint),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
