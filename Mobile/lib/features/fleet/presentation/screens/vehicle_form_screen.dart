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
import '../../application/vehicle_form_provider.dart';
import '../../domain/models/vehicle_status.dart';

class VehicleFormScreen extends ConsumerStatefulWidget {
  const VehicleFormScreen({
    super.key,
    this.vehicleId,
  });

  final String? vehicleId;

  @override
  ConsumerState<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends ConsumerState<VehicleFormScreen> {
  static final _integerInput =
      FilteringTextInputFormatter.allow(RegExp(r'[0-9]'));
  static final _decimalInput =
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'));

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _registrationController;
  late final TextEditingController _nameController;
  late final TextEditingController _typeController;
  late final TextEditingController _capacityController;
  late final TextEditingController _odometerController;
  late final TextEditingController _costController;
  late final TextEditingController _regionController;
  VehicleStatus _status = VehicleStatus.AVAILABLE;
  bool _populated = false;

  @override
  void initState() {
    super.initState();
    _registrationController = TextEditingController();
    _nameController = TextEditingController();
    _typeController = TextEditingController();
    _capacityController = TextEditingController();
    _odometerController = TextEditingController(text: '0');
    _costController = TextEditingController();
    _regionController = TextEditingController();
  }

  @override
  void dispose() {
    _registrationController.dispose();
    _nameController.dispose();
    _typeController.dispose();
    _capacityController.dispose();
    _odometerController.dispose();
    _costController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  void _populateForm(VehicleFormState state) {
    if (_populated || state.vehicle == null) {
      return;
    }
    final vehicle = state.vehicle!;
    _registrationController.text = vehicle.registrationNumber;
    _nameController.text = vehicle.name;
    _typeController.text = vehicle.type;
    _capacityController.text = vehicle.maxLoadCapacity.toString();
    _odometerController.text = vehicle.odometer.toString();
    _costController.text = vehicle.acquisitionCost;
    _regionController.text = vehicle.region ?? '';
    _status = vehicle.status;
    _populated = true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    final capacity = double.tryParse(_capacityController.text.trim());
    final odometer = double.tryParse(_odometerController.text.trim()) ?? 0;

    if (capacity == null || capacity <= 0) {
      showSnackBarMessage(context, 'Enter a valid load capacity.');
      return;
    }

    final result = await ref.read(vehicleFormProvider(widget.vehicleId).notifier).submit(
          registrationNumber: _registrationController.text,
          name: _nameController.text,
          type: _typeController.text,
          maxLoadCapacity: capacity,
          odometer: odometer,
          acquisitionCost: _costController.text,
          status: _status,
          region: _regionController.text,
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

    showSnackBarMessage(
      context,
      widget.vehicleId == null ? 'Vehicle created.' : 'Vehicle updated.',
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vehicleFormProvider(widget.vehicleId));

    if (state.isLoading) {
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

    if (state.error != null && state.vehicle == null && widget.vehicleId != null) {
      return Center(
        child: AppText(
          state.error!,
          size: 14,
          textAlign: TextAlign.center,
        ),
      );
    }

    _populateForm(state);

    return ListView(
      padding: Responsive.getPaddingSymmetric(horizontal: 16, vertical: 16),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _registrationController,
                label: 'Registration Number',
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Registration number is required';
                  }
                  return null;
                },
              ),
              const AppGap(12),
              AppTextField(
                controller: _nameController,
                label: 'Name / Model',
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const AppGap(12),
              AppTextField(
                controller: _typeController,
                label: 'Type',
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Type is required';
                  }
                  return null;
                },
              ),
              const AppGap(12),
              AppTextField(
                controller: _capacityController,
                label: 'Max Load Capacity (kg)',
                keyboardType: TextInputType.number,
                inputFormatters: [_decimalInput],
                textInputAction: TextInputAction.next,
                validator: (value) {
                  final parsed = double.tryParse(value ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a positive capacity';
                  }
                  return null;
                },
              ),
              const AppGap(12),
              AppTextField(
                controller: _odometerController,
                label: 'Odometer (km)',
                keyboardType: TextInputType.number,
                inputFormatters: [_integerInput],
                textInputAction: TextInputAction.next,
              ),
              const AppGap(12),
              AppTextField(
                controller: _costController,
                label: 'Acquisition Cost',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [_decimalInput],
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Acquisition cost is required';
                  }
                  if (double.tryParse(value.trim()) == null) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              const AppGap(12),
              AppTextField(
                controller: _regionController,
                label: 'Region (optional)',
                textInputAction: TextInputAction.next,
              ),
              const AppGap(12),
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Status',
                  contentPadding: Responsive.getPaddingSymmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<VehicleStatus>(
                    isExpanded: true,
                    value: _status,
                    items: VehicleStatus.values
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(status.label),
                          ),
                        )
                        .toList(),
                    onChanged: state.isSubmitting
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() => _status = value);
                            }
                          },
                  ),
                ),
              ),
              const AppGap(24),
              AppButton(
                label: widget.vehicleId == null ? 'Create Vehicle' : 'Save Changes',
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
