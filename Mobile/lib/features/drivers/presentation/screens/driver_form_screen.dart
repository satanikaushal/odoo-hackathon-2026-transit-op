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
import '../../application/driver_form_provider.dart';
import '../../domain/models/driver_status.dart';

class DriverFormScreen extends ConsumerStatefulWidget {
  const DriverFormScreen({
    super.key,
    this.driverId,
  });

  final String? driverId;

  @override
  ConsumerState<DriverFormScreen> createState() => _DriverFormScreenState();
}

class _DriverFormScreenState extends ConsumerState<DriverFormScreen> {
  static final _integerInput =
      FilteringTextInputFormatter.allow(RegExp(r'[0-9]'));
  static final _phoneInput =
      FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]'));

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _licenseNumberController;
  late final TextEditingController _licenseCategoryController;
  late final TextEditingController _contactController;
  late final TextEditingController _safetyScoreController;
  late final TextEditingController _expiryController;
  DateTime? _licenseExpiryDate;
  DriverStatus _status = DriverStatus.AVAILABLE;
  bool _populated = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _licenseNumberController = TextEditingController();
    _licenseCategoryController = TextEditingController();
    _contactController = TextEditingController();
    _safetyScoreController = TextEditingController(text: '100');
    _expiryController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _licenseNumberController.dispose();
    _licenseCategoryController.dispose();
    _contactController.dispose();
    _safetyScoreController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  void _populateForm(DriverFormState state) {
    if (_populated || state.driver == null) {
      return;
    }
    final driver = state.driver!;
    _nameController.text = driver.name;
    _licenseNumberController.text = driver.licenseNumber;
    _licenseCategoryController.text = driver.licenseCategory;
    _contactController.text = driver.contactNumber;
    _safetyScoreController.text = driver.safetyScore.round().toString();
    _licenseExpiryDate = driver.licenseExpiryDate;
    _expiryController.text =
        DateFormat('dd MMM yyyy').format(driver.licenseExpiryDate);
    _status = driver.status;
    _populated = true;
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _licenseExpiryDate ?? now,
      firstDate: DateTime(now.year - 20),
      lastDate: DateTime(now.year + 20),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _licenseExpiryDate = picked;
      _expiryController.text = DateFormat('dd MMM yyyy').format(picked);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_licenseExpiryDate == null) {
      showSnackBarMessage(context, 'Select a license expiry date.');
      return;
    }

    FocusScope.of(context).unfocus();
    final safetyScore = double.tryParse(_safetyScoreController.text.trim());

    if (safetyScore == null || safetyScore < 0 || safetyScore > 100) {
      showSnackBarMessage(context, 'Safety score must be between 0 and 100.');
      return;
    }

    final result =
        await ref.read(driverFormProvider(widget.driverId).notifier).submit(
              name: _nameController.text,
              licenseNumber: _licenseNumberController.text,
              licenseCategory: _licenseCategoryController.text,
              licenseExpiryDate: _licenseExpiryDate!,
              contactNumber: _contactController.text,
              safetyScore: safetyScore,
              status: _status,
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
      widget.driverId == null ? 'Driver created.' : 'Driver updated.',
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(driverFormProvider(widget.driverId));

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

    if (state.error != null &&
        state.driver == null &&
        widget.driverId != null) {
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
                controller: _nameController,
                label: 'Full Name',
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
                controller: _licenseNumberController,
                label: 'License Number',
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'License number is required';
                  }
                  return null;
                },
              ),
              const AppGap(12),
              AppTextField(
                controller: _licenseCategoryController,
                label: 'License Category',
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'License category is required';
                  }
                  return null;
                },
              ),
              const AppGap(12),
              AppTextField(
                controller: _expiryController,
                label: 'License Expiry Date',
                readOnly: true,
                onTap: state.isSubmitting ? null : _pickExpiryDate,
                suffixIcon: const Icon(Icons.calendar_today_outlined),
                validator: (value) {
                  if (_licenseExpiryDate == null) {
                    return 'Expiry date is required';
                  }
                  return null;
                },
              ),
              const AppGap(12),
              AppTextField(
                controller: _contactController,
                label: 'Contact Number',
                keyboardType: TextInputType.phone,
                inputFormatters: [_phoneInput],
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Contact number is required';
                  }
                  return null;
                },
              ),
              const AppGap(12),
              AppTextField(
                controller: _safetyScoreController,
                label: 'Safety Score (0–100)',
                keyboardType: TextInputType.number,
                inputFormatters: [_integerInput],
                textInputAction: TextInputAction.next,
                validator: (value) {
                  final parsed = double.tryParse(value ?? '');
                  if (parsed == null || parsed < 0 || parsed > 100) {
                    return 'Enter a score between 0 and 100';
                  }
                  return null;
                },
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
                  child: DropdownButton<DriverStatus>(
                    isExpanded: true,
                    value: _status,
                    items: DriverStatus.values
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
                label:
                    widget.driverId == null ? 'Create Driver' : 'Save Changes',
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
