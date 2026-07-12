import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/utils/responsive.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_dialogs.dart';
import '../../../../shared/widgets/app_gap.dart';
import '../../../../shared/widgets/app_shimmer.dart';
import '../../../../shared/widgets/app_text.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../application/trip_detail_provider.dart';
import '../../domain/trip_formatters.dart';
import '../../../fleet/domain/fleet_formatters.dart';

class TripCompleteScreen extends ConsumerStatefulWidget {
  const TripCompleteScreen({
    super.key,
    required this.tripId,
  });

  final String tripId;

  @override
  ConsumerState<TripCompleteScreen> createState() =>
      _TripCompleteScreenState();
}

class _TripCompleteScreenState extends ConsumerState<TripCompleteScreen> {
  static final _decimalInput =
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'));

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _odometerController;
  late final TextEditingController _fuelController;
  late final TextEditingController _revenueController;

  @override
  void initState() {
    super.initState();
    _odometerController = TextEditingController();
    _fuelController = TextEditingController();
    _revenueController = TextEditingController();
  }

  @override
  void dispose() {
    _odometerController.dispose();
    _fuelController.dispose();
    _revenueController.dispose();
    super.dispose();
  }

  void _populateOdometerHint(double? currentOdometer) {
    if (_odometerController.text.isNotEmpty || currentOdometer == null) {
      return;
    }
    _odometerController.text = currentOdometer.round().toString();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    final finalOdometer = double.tryParse(_odometerController.text.trim());
    if (finalOdometer == null) {
      showSnackBarMessage(context, 'Enter a valid final odometer reading.');
      return;
    }

    final fuelText = _fuelController.text.trim();
    final fuelConsumed =
        fuelText.isEmpty ? null : double.tryParse(fuelText);

    if (fuelText.isNotEmpty && fuelConsumed == null) {
      showSnackBarMessage(context, 'Enter a valid fuel consumed value.');
      return;
    }

    final revenue = _revenueController.text.trim();

    final result = await ref
        .read(tripDetailProvider(widget.tripId).notifier)
        .complete(
          widget.tripId,
          finalOdometer: finalOdometer,
          fuelConsumed: fuelConsumed,
          revenue: revenue.isEmpty ? null : revenue,
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

    showSnackBarMessage(context, 'Trip completed.');
    context.go(AppRoutes.tripDetail(widget.tripId));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tripDetailProvider(widget.tripId));
    final trip = state.trip;
    final currentOdometer = trip?.vehicle?.odometer;

    if (state.isLoading && trip == null) {
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

    if (state.error != null && trip == null) {
      return Center(
        child: AppText(
          state.error!,
          size: 14,
          textAlign: TextAlign.center,
        ),
      );
    }

    _populateOdometerHint(currentOdometer);

    return ListView(
      padding: Responsive.getPaddingSymmetric(horizontal: 16, vertical: 16),
      children: [
        if (trip != null) ...[
          AppText(
            TripFormatters.formatRoute(trip),
            size: 16,
            fontWeight: FontWeight.w700,
          ),
          const AppGap(8),
          if (currentOdometer != null)
            AppText(
              'Current odometer: ${FleetFormatters.formatOdometer(currentOdometer)}',
              size: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          const AppGap(20),
        ],
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _odometerController,
                label: 'Final Odometer (km)',
                keyboardType: TextInputType.number,
                inputFormatters: [_decimalInput],
                textInputAction: TextInputAction.next,
                validator: (value) {
                  final parsed = double.tryParse(value ?? '');
                  if (parsed == null || parsed < 0) {
                    return 'Enter a valid odometer reading';
                  }
                  if (currentOdometer != null && parsed < currentOdometer) {
                    return 'Must be ≥ current reading '
                        '(${currentOdometer.round()} km)';
                  }
                  return null;
                },
              ),
              const AppGap(12),
              AppTextField(
                controller: _fuelController,
                label: 'Fuel Consumed (L, optional)',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [_decimalInput],
                textInputAction: TextInputAction.next,
              ),
              const AppGap(12),
              AppTextField(
                controller: _revenueController,
                label: 'Revenue (optional)',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [_decimalInput],
                textInputAction: TextInputAction.done,
              ),
              const AppGap(24),
              AppButton(
                label: 'Complete Trip',
                isLoading: state.isMutating,
                onPressed: state.isMutating ? null : _submit,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
