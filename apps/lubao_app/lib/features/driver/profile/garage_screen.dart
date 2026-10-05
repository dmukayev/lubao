import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../providers/api_providers.dart';
import '../../../providers/data_providers.dart';
import 'add_vehicle_sheet.dart';

/// «Мой гараж» (задача 031, этап B, макет 26) — тягачи и прицепы по
/// отдельности, каждый со своим статусом проверки.
class GarageScreen extends ConsumerWidget {
  const GarageScreen({super.key});

  Future<void> _addVehicle(BuildContext context, WidgetRef ref) async {
    final added = await showAddVehicleSheet(context, ref);
    if (added) ref.invalidate(garageVehiclesProvider);
  }

  Future<void> _archive(BuildContext context, WidgetRef ref, GarageVehicle vehicle) async {
    final t = context.l10n;
    try {
      await ref.read(driverRepositoryProvider).archiveVehicle(vehicle.id);
      ref.invalidate(garageVehiclesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.garageArchived)));
      }
    } catch (e) {
      debugPrint('GarageScreen: failed to archive vehicle: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.commonError)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final vehiclesAsync = ref.watch(garageVehiclesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.garageTitle)),
      body: vehiclesAsync.when(
        loading: () => const LoadingView(),
        error: (e, st) {
          debugPrint('GarageScreen: $e');
          return ErrorView(message: t.commonError, onRetry: () => ref.invalidate(garageVehiclesProvider));
        },
        data: (vehicles) {
          final tractors = vehicles.where((v) => v.kind == VehicleKind.tractor || v.kind == VehicleKind.rigid).toList();
          final trailers = vehicles.where((v) => v.kind == VehicleKind.trailer).toList();

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            children: [
              _SectionLabel(t.garageTractorsSection),
              const SizedBox(height: AppSpacing.sm),
              if (tractors.isEmpty)
                _EmptyRow(t.garageEmptyTractors)
              else
                for (final v in tractors) ...[
                  _VehicleCard(vehicle: v, onArchive: () => _archive(context, ref, v)),
                  const SizedBox(height: AppSpacing.sm),
                ],
              const SizedBox(height: AppSpacing.lg),
              _SectionLabel(t.garageTrailersSection),
              const SizedBox(height: AppSpacing.sm),
              if (trailers.isEmpty)
                _EmptyRow(t.garageEmptyTrailers)
              else
                for (final v in trailers) ...[
                  _VehicleCard(vehicle: v, onArchive: () => _archive(context, ref, v)),
                  const SizedBox(height: AppSpacing.sm),
                ],
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: () => _addVehicle(context, ref),
                icon: const Icon(LucideIcons.plus),
                label: Text(t.garageAddVehicle),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Text(t.garageOcrHint, style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600));
  }
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(text, style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.vehicle, required this.onArchive});

  final GarageVehicle vehicle;
  final VoidCallback onArchive;

  String _title(BuildContext context) {
    final t = context.l10n;
    if (vehicle.kind == VehicleKind.trailer) {
      final parts = <String>[
        if (vehicle.brand != null) vehicle.brand!,
        if (vehicle.capacityTons != null) '${vehicle.capacityTons!.toStringAsFixed(0)} ${t.unitTon}',
        if (vehicle.lengthM != null) '${vehicle.lengthM!.toStringAsFixed(1)} м',
      ];
      return parts.isEmpty ? t.garageKindTrailer : parts.join(' · ');
    }
    final parts = <String>[
      if (vehicle.brand != null) vehicle.brand!,
      if (vehicle.plateNumber != null && vehicle.plateNumber!.isNotEmpty) vehicle.plateNumber!,
    ];
    return parts.isEmpty ? t.garageKindTractor : parts.join(' · ');
  }

  String? _subtitle(BuildContext context) {
    final t = context.l10n;
    if (vehicle.kind == VehicleKind.trailer) {
      return vehicle.plateNumber;
    }
    if (vehicle.vin != null && vehicle.vin!.length > 4) {
      return '${t.garageVin} …${vehicle.vin!.substring(vehicle.vin!.length - 4)}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final subtitle = _subtitle(context);

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(AppRadius.field)),
            child: Icon(
              vehicle.kind == VehicleKind.trailer ? LucideIcons.package : LucideIcons.truck,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_title(context), style: AppTextStyles.bodyStrong),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          StatusBadge(
            label: vehicle.isVerified ? t.garageVerified : t.garagePending,
            color: vehicle.isVerified ? StatusBadge.success : StatusBadge.warning,
          ),
          PopupMenuButton<String>(
            icon: const Icon(LucideIcons.moreVertical, size: 18),
            onSelected: (value) {
              if (value == 'archive') onArchive();
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'archive', child: Text(t.garageArchive)),
            ],
          ),
        ],
      ),
    );
  }
}
