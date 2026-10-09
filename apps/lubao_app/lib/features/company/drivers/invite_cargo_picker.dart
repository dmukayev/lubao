import 'package:flutter/material.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../shared/status_helpers.dart';

/// Выбор груза для приглашения водителя: понятно, что надо сделать — подсказка
/// сверху, у каждого груза кружок выбора, выбранная карточка подсвечена,
/// «Пригласить» внизу активна, когда груз отмечен. Один груз — уже отмечен.
Future<Cargo?> showInviteCargoPicker(
  BuildContext context, {
  required String driverName,
  required List<Cargo> cargos,
  required ReferenceData? refData,
}) {
  return showModalBottomSheet<Cargo>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.cardLarge))),
    builder: (_) => _InviteCargoPicker(driverName: driverName, cargos: cargos, refData: refData),
  );
}

class _InviteCargoPicker extends StatefulWidget {
  const _InviteCargoPicker({required this.driverName, required this.cargos, required this.refData});

  final String driverName;
  final List<Cargo> cargos;
  final ReferenceData? refData;

  @override
  State<_InviteCargoPicker> createState() => _InviteCargoPickerState();
}

class _InviteCargoPickerState extends State<_InviteCargoPicker> {
  late String? _selected = widget.cargos.length == 1 ? widget.cargos.first.id : null;

  String _route(Cargo c, String locale) {
    final rd = widget.refData;
    if (rd == null) return '';
    final origin = rd.pointOrNull(c.pointId)?.name.forLanguageCode(locale);
    final destination = rd.cityById(c.destinationCityId)?.name.forLanguageCode(locale) ?? rd.countryById(c.destinationCountryId).name.forLanguageCode(locale);
    return origin == null ? destination : '$origin → $destination';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final rd = widget.refData;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.lg, AppSpacing.screen, AppSpacing.xs),
              child: Text(t.driversInviteTitle(widget.driverName), style: AppTextStyles.title),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              child: Row(
                children: [
                  const Icon(LucideIcons.mousePointerClick, size: 18, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(child: Text(t.driversInvitePickHint, key: const Key('inviteCargoHint'), style: AppTextStyles.body.copyWith(color: AppColors.textSecondary))),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                children: [
                  for (final c in widget.cargos)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _CargoOption(
                        key: Key('inviteCargo-${c.id}'),
                        selected: _selected == c.id,
                        route: _route(c, locale),
                        details: [
                          if (rd != null) rd.categoryById(c.categoryId)?.name.forLanguageCode(locale),
                          if (c.weightKg != null) formatCargoWeight(c.weightKg!, tonUnit: t.unitTon, kgUnit: t.unitKg, languageCode: locale),
                          if (rd != null) rd.bodyTypeById(c.bodyTypeId).name.forLanguageCode(locale),
                          formatDate(c.readyDate),
                        ].whereType<String>().join(' · '),
                        price: formatMoney(c.price, c.currency),
                        onTap: () => setState(() => _selected = c.id),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.md),
              child: PrimaryButton(
                key: const Key('inviteCargoSubmit'),
                label: t.driversAtPointInviteShort,
                icon: LucideIcons.send,
                onPressed: _selected == null ? null : () => Navigator.of(context).pop(widget.cargos.firstWhere((c) => c.id == _selected)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CargoOption extends StatelessWidget {
  const _CargoOption({super.key, required this.selected, required this.route, required this.details, required this.price, required this.onTap});

  final bool selected;
  final String route;
  final String details;
  final String price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: AppCard(
        onTap: onTap,
        borderColor: selected ? AppColors.primary : null,
        child: Row(
          children: [
            // Кружок выбора: пустой → отмечен.
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.primary : Colors.transparent,
                border: Border.all(color: selected ? AppColors.primary : AppColors.textSecondary, width: 2),
              ),
              child: selected ? const Icon(LucideIcons.check, size: 16, color: Colors.white) : null,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(route, style: AppTextStyles.bodyStrong, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(details, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(price, style: AppTextStyles.bodyStrong),
          ],
        ),
      ),
    );
  }
}
