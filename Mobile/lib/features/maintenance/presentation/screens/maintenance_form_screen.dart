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
import '../../application/maintenance_form_provider.dart';

class MaintenanceFormScreen extends ConsumerStatefulWidget {
  const MaintenanceFormScreen({super.key});

  @override
  ConsumerState<MaintenanceFormScreen> createState() =>
      _MaintenanceFormScreenState();
}

class _MaintenanceFormScreenState extends ConsumerState<MaintenanceFormScreen> {
  static final _decimalInput =
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'));

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  late final TextEditingController _costController;
  String? _vehicleId;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    _costController = TextEditingController();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _costController.dispose();
    super.dispose();
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

    final result = await ref.read(maintenanceFormProvider.notifier).submit(
          vehicleId: _vehicleId!,
          description: _descriptionController.text,
          cost: _costController.text,
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

    showSnackBarMessage(context, 'Maintenance record opened.');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(maintenanceFormProvider);

    if (state.isLoadingOptions) {
      return ListView(
        padding: Responsive.getPaddingSymmetric(horizontal: 16, vertical: 16),
        children: [
          AppShimmer(
            child: Column(
              children: List.generate(
                4,
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
              AppText(
                state.error!,
                size: 14,
                textAlign: TextAlign.center,
              ),
              const AppGap(16),
              AppButton(
                label: 'Retry',
                expand: false,
                onPressed: () => ref.invalidate(maintenanceFormProvider),
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
                          ? 'No eligible vehicles'
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
                    onChanged: state.isSubmitting
                        ? null
                        : (value) => setState(() => _vehicleId = value),
                  ),
                ),
              ),
              const AppGap(12),
              AppTextField(
                controller: _descriptionController,
                label: 'Description',
                maxLines: 3,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Description is required';
                  }
                  if (value.trim().length > 500) {
                    return 'Description must be 500 characters or fewer';
                  }
                  return null;
                },
              ),
              const AppGap(12),
              AppTextField(
                controller: _costController,
                label: 'Estimated Cost (optional)',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [_decimalInput],
                textInputAction: TextInputAction.done,
              ),
              const AppGap(24),
              AppButton(
                label: 'Open Maintenance',
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
