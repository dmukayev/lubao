import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../providers/api_providers.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/data_providers.dart';
import '../../shared/status_helpers.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../services/push_service.dart';
import '../deals/my_responses_screen.dart';

class CargoDetailScreen extends ConsumerStatefulWidget {
  const CargoDetailScreen({super.key, required this.cargoId});

  final String cargoId;

  @override
  ConsumerState<CargoDetailScreen> createState() => _CargoDetailScreenState();
}

class _CargoDetailScreenState extends ConsumerState<CargoDetailScreen> {
  bool _responding = false;
  bool _openingChat = false;

  /// «Готов взять» — и первый отклик, и согласие на приглашение (INVITED → PENDING).
  Future<void> _respond() async {
    setState(() => _responding = true);
    try {
      await ref.read(cargoRepositoryProvider).respond(widget.cargoId);
      unawaited(ref.read(pushServiceProvider).requestPermissionAndRegister());
      ref.invalidate(myCargoResponseProvider(widget.cargoId));
      // 045 п.2: плашка «Вы откликнулись» в ленте — по свежим данным.
      ref.invalidate(cargoFeedProvider);
      ref.invalidate(myResponsesProvider);
    } on DioException catch (e) {
      ref.invalidate(myCargoResponseProvider(widget.cargoId));
      if (e.response?.statusCode != 409 && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(responseConflictText(context.l10n, e) ?? context.l10n.commonError)));
      }
    } finally {
      if (mounted) setState(() => _responding = false);
    }
  }

  /// «Отказаться» от приглашения.
  Future<void> _decline(String responseId) async {
    setState(() => _responding = true);
    try {
      await ref.read(cargoRepositoryProvider).withdrawResponse(responseId);
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(responseConflictText(context.l10n, e) ?? context.l10n.commonError)));
      }
    } finally {
      ref.invalidate(myCargoResponseProvider(widget.cargoId));
      ref.invalidate(cargoFeedProvider);
      ref.invalidate(myResponsesProvider);
      if (mounted) setState(() => _responding = false);
    }
  }

  /// Номер логиста — по нажатию (043 п.11): сервер проверяет правила и
  /// лимит, сам пишет contact_event и только тогда отдаёт номер.
  Future<String?> _revealPhone(Cargo cargo, String type) async {
    try {
      return await ref.read(cargoRepositoryProvider).revealCargoContact(cargo.id, type: type);
    } catch (e) {
      debugPrint('CargoDetailScreen: reveal contact: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(contactErrorText(context.l10n, e))));
      return null;
    }
  }

  /// Непроверенному водителю телефон открывается после отклика «Готов взять»;
  /// проверенному — сразу (decisions.md 2026-10-07).
  bool _contactUnlocked() {
    if (ref.watch(sessionProvider)?.driver?.isVerified ?? false) return true;
    final status = ref.watch(myCargoResponseProvider(widget.cargoId)).valueOrNull?.status;
    return status == ResponseStatus.pending || status == ResponseStatus.selected;
  }

  Future<void> _call(Cargo cargo) async {
    final phone = await _revealPhone(cargo, 'CALL');
    if (phone == null) return;
    await launchUrl(Uri(scheme: 'tel', path: phone));
  }

  Future<void> _whatsapp(Cargo cargo) async {
    final phone = await _revealPhone(cargo, 'WHATSAPP');
    if (phone == null) return;
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$digits');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _chat(Cargo cargo) async {
    setState(() => _openingChat = true);
    try {
      final thread = await ref.read(chatRepositoryProvider).findOrCreate(cargoId: cargo.id);
      if (mounted) context.push('/chat/${thread.id}');
    } catch (e) {
      debugPrint('CargoDetailScreen: failed to open chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.chatOpenFailed),
            action: SnackBarAction(label: context.l10n.commonRetry, onPressed: () => _chat(cargo)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _openingChat = false);
    }
  }

  /// Нижняя кнопка по реальному состоянию отклика (041): «Откликнуться» /
  /// «Готов взять»+«Отказаться» (приглашение) / «Вы откликнулись» / «Вас
  /// выбрали» / «Груз уже занят». Непроверенному — мягкая строка над кнопкой.
  Widget _respondArea(Cargo cargo, LubaoLocalizations t) {
    final mine = ref.watch(myCargoResponseProvider(widget.cargoId)).valueOrNull;
    final status = mine?.status;
    if (status == ResponseStatus.invited) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              key: const Key('cargoDetailDeclineButton'),
              onPressed: _responding ? null : () => _decline(mine!.id),
              child: Text(t.cargoDecline),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: PrimaryButton(
              key: const Key('cargoDetailRespondButton'),
              label: t.chatCargoReadyButton,
              loading: _responding,
              onPressed: _respond,
            ),
          ),
        ],
      );
    }
    final (label, enabled) = switch (status) {
      ResponseStatus.pending => (t.cargoAlreadyResponded, false),
      ResponseStatus.selected => (t.cargoYouAreSelected, false),
      ResponseStatus.rejected => (t.chatResponseClosed, false),
      _ => cargo.status == CargoStatus.published ? (t.cargoRespond, true) : (t.cargoNotAvailable, false),
    };
    return PrimaryButton(
      key: const Key('cargoDetailRespondButton'),
      label: label,
      loading: _responding,
      onPressed: enabled ? _respond : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final cargoAsync = ref.watch(cargoByIdProvider(widget.cargoId));
    final referenceData = ref.watch(referenceDataProvider);
    final contactLocked = !_contactUnlocked();
    final canContact = !contactLocked && (cargoAsync.valueOrNull?.hasContactPhone ?? false);

    return Scaffold(
      appBar: AppBar(title: Text(t.cargoDetailTitle)),
      body: cargoAsync.when(
        loading: () => const LoadingView(),
        error: (e, st) {
          debugPrint('CargoDetailScreen (cargo): $e');
          return ErrorView(message: t.commonError);
        },
        data: (cargo) => referenceData.when(
          loading: () => const LoadingView(),
          error: (e, st) {
            debugPrint('CargoDetailScreen (referenceData): $e');
            return ErrorView(message: t.commonError);
          },
          data: (refData) => _CargoDetailBody(cargo: cargo, refData: refData),
        ),
      ),
      bottomNavigationBar: cargoAsync.valueOrNull == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.sm),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Новичок откликается и без проверки; подтвердить перевозку —
                    // только после неё (041, п.1) — мягкая подсказка, не запрет.
                    if (!(ref.watch(sessionProvider)?.driver?.isVerified ?? false))
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Text(
                          // 043 п.11: до отклика — как открыть телефон, после — про проверку.
                          contactLocked ? t.contactRespondFirst : t.cargoVerifyHint,
                          key: Key(contactLocked ? 'cargoContactLockedHint' : 'cargoVerifyHint'),
                          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    Row(
                      children: [
                        IconSquareButton(
                          key: const Key('cargoDetailCallButton'),
                          icon: LucideIcons.phone,
                          size: AppSizes.buttonHeight,
                          onPressed: canContact ? () => _call(cargoAsync.value!) : null,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        IconSquareButton(
                          key: const Key('cargoDetailChatButton'),
                          icon: LucideIcons.messageSquare,
                          size: AppSizes.buttonHeight,
                          loading: _openingChat,
                          onPressed: () => _chat(cargoAsync.value!),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        if (!cargoAsync.value!.isWhatsappBlocked) ...[
                          IconSquareButton(
                            key: const Key('cargoDetailWhatsappButton'),
                            child: const WhatsAppIcon(),
                            background: WhatsAppIcon.whatsappSoft,
                            semanticLabel: t.commonWhatsApp,
                            size: AppSizes.buttonHeight,
                            onPressed: canContact ? () => _whatsapp(cargoAsync.value!) : null,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Expanded(child: _respondArea(cargoAsync.value!, t)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// «Можно догрузом» + для водителя с активной сделкой подсказка «Помещается к
/// текущему: 8 т + 10 т из 20 т» (040, п.6).
class PartialLoadBlock extends StatelessWidget {
  const PartialLoadBlock({required this.cargo, required this.hint});

  final Cargo cargo;
  final PartialHint? hint;

  static String _tons(double kg) {
    final tons = kg / 1000;
    return tons == tons.roundToDouble() ? tons.toStringAsFixed(0) : tons.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final h = hint;
    String? hintText;
    var good = false;
    if (h != null) {
      if (h.reason == 'NEXT_TRIP') {
        hintText = t.cargoPartialHintNextTrip;
      } else if (h.cargoWeightKg != null && h.capacityKg != null) {
        good = h.fits;
        hintText = (h.fits ? t.cargoPartialHintFits : t.cargoPartialHintFull)(
          _tons(h.committedWeightKg),
          _tons(h.cargoWeightKg!),
          _tons(h.capacityKg!),
        );
      }
    }
    return Container(
      key: const Key('cargoPartialBlock'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: hintText == null || good ? AppColors.primarySoft : AppColors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.feedBadgePartial, style: AppTextStyles.bodyStrong.copyWith(color: AppColors.primary)),
          if (hintText != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(hintText, key: const Key('cargoPartialHint'), style: AppTextStyles.body),
          ],
        ],
      ),
    );
  }
}

class _CargoDetailBody extends ConsumerWidget {
  const _CargoDetailBody({required this.cargo, required this.refData});

  final Cargo cargo;
  final ReferenceData refData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final country = refData.countryById(cargo.destinationCountryId);
    final city = refData.cityById(cargo.destinationCityId);
    final bodyType = refData.bodyTypeById(cargo.bodyTypeId);
    final pointName = refData.pointOrNull(cargo.pointId)?.name.forLanguageCode(locale) ?? '';
    final destinationLabel = [
      city?.name.forLanguageCode(locale),
      country.name.forLanguageCode(locale),
    ].whereType<String>().join(', ');

    final kzt = refData.convertToKzt(cargo.price, cargo.currency);
    final usd = refData.convertToUsd(cargo.price, cargo.currency);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RoutePoint(
                  color: AppColors.primary,
                  title: pointName,
                  // 047: категория и км по дороге — как в строке ленты.
                  subtitle: [
                    if (refData.categoryById(cargo.categoryId) case final c?) c.name.forLanguageCode(locale),
                    if (cargo.distanceKm != null && cargo.distanceKm! > 0) '${formatThousands(cargo.distanceKm!)} ${t.unitKm}',
                    formatDate(cargo.readyDate),
                  ].join(' · '),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Container(width: 2, height: 20, color: AppColors.divider),
                ),
                _RoutePoint(color: AppColors.accent, title: destinationLabel, subtitle: null),
                const Divider(height: AppSpacing.xl * 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.cargoDetailPriceLabel, style: AppTextStyles.caption),
                          const SizedBox(height: AppSpacing.xs),
                          Text(formatMoney(cargo.price, cargo.currency), style: AppTextStyles.priceDetail),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (formatKztConversion(kzt) != null)
                          Text(formatKztConversion(kzt)!, style: AppTextStyles.caption),
                        if (usd != null) Text(formatMoney(usd, Currency.usd), style: AppTextStyles.caption),
                        if ((cargo.pricePerKm == null ? null : refData.convertToKzt(cargo.pricePerKm!, cargo.currency)) case final perKm?)
                          Text(
                            t.perKmKzt(formatThousands(perKm.round())),
                            key: const Key('cargoDetailPerKm'),
                            style: AppTextStyles.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  ],
                ),
                // 047 п.6: «Рынок за месяц: 650–720 ₸/км» — если есть статистика по маршруту.
                if (cargo.market != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    t.cargoMarketMonth(formatThousands(cargo.market!.p25.round()), formatThousands(cargo.market!.p75.round())),
                    key: const Key('cargoDetailMarket'),
                    style: AppTextStyles.caption,
                  ),
                ],
              ],
            ),
          ),
          if (cargo.allowPartial) ...[
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              child: PartialLoadBlock(cargo: cargo, hint: ref.watch(partialHintProvider(cargo.id)).valueOrNull),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: Row(
              children: [
                Expanded(
                  child: _DetailChip(label: t.cargoBodyType, value: bodyType.name.forLanguageCode(locale), leading: BodyTypeIcon(bodyTypeCode: bodyType.code, width: 40)),
                ),
                const SizedBox(width: AppSpacing.sm),
                if (cargo.weightKg != null)
                  Expanded(
                    child: _DetailChip(label: t.cargoWeight, value: formatCargoWeight(cargo.weightKg!, tonUnit: t.unitTon, kgUnit: t.unitKg, languageCode: Localizations.localeOf(context).languageCode)),
                  ),
                if (cargo.weightKg != null) const SizedBox(width: AppSpacing.sm),
                if (cargo.volumeM3 != null)
                  Expanded(
                    child: _DetailChip(label: t.cargoVolume, value: '${cargo.volumeM3} ${t.unitM3}'),
                  ),
              ],
            ),
          ),
          if (cargo.photoUrls.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              child: Text(t.cargoPhotos, style: AppTextStyles.title),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                itemCount: cargo.photoUrls.length,
                separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.field),
                  child: GestureDetector(
                    onTap: () => _openPhoto(context, cargo.photoUrls, index),
                    child: Image.network(cargo.photoUrls[index], width: 96, height: 96, fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.accentSoft,
                      child: Text(
                        cargo.companyName.isEmpty ? '' : cargo.companyName.substring(0, 1).toUpperCase(),
                        style: AppTextStyles.bodyStrong.copyWith(color: AppColors.accentText),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(child: Text(cargo.companyName, style: AppTextStyles.bodyStrong)),
                              if (cargo.companyIsVerified) ...[
                                const SizedBox(width: AppSpacing.xs),
                                const Icon(LucideIcons.badgeCheck, size: 16, color: AppColors.primary),
                              ],
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          // Один текст с переносом, а не ряд кусков: на узком
                          // экране с крупным шрифтом ряд вылезал вправо (iPhone SE
                          // в e2e: «Пока нет отзывов · 0 сделок» — +84 px).
                          Text.rich(
                            TextSpan(
                              style: AppTextStyles.caption,
                              children: [
                                if (cargo.companyRatingCount > 0) ...[
                                  const WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: Padding(
                                      padding: EdgeInsets.only(right: AppSpacing.xs),
                                      child: Icon(LucideIcons.star, size: 14, color: AppColors.accent),
                                    ),
                                  ),
                                  TextSpan(text: cargo.companyRatingAvg.toStringAsFixed(1)),
                                ] else
                                  TextSpan(text: t.cargoDetailNoReviews),
                                TextSpan(text: ' · ${t.cargoDetailCompanyDeals(cargo.companyCompletedDeals)}'),
                                // 046 п.3: отмены компании видны водителю.
                                if (cancelStatsText(t, cargo.companyCancelStats) case final stats?) TextSpan(text: ' · $stats'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (cargo.description != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(AppRadius.field),
                    ),
                    child: Text(cargo.description!, style: AppTextStyles.body),
                  ),
                ],
                // Задача 012 — звонить/писать нужно конкретному логисту,
                // опубликовавшему груз, а не «компании» (decisions.md
                // «Компания: проверка, роли, контакты»): имя и WeChat
                // показываем отдельно от карточки компании выше (там —
                // репутация компании, тут — живой человек).
                if (cargo.contactName != null && cargo.contactName!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      const Icon(LucideIcons.user, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(child: Text(cargo.contactName!, style: AppTextStyles.bodyStrong)),
                    ],
                  ),
                  if (cargo.contactWechatId != null && cargo.contactWechatId!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        const Icon(LucideIcons.messageCircle, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: AppSpacing.xs),
                        Text('WeChat: ${cargo.contactWechatId}', style: AppTextStyles.caption),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  void _openPhoto(BuildContext context, List<String> photoUrls, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
          body: PageView.builder(
            controller: PageController(initialPage: initialIndex),
            itemCount: photoUrls.length,
            itemBuilder: (context, index) => InteractiveViewer(child: Center(child: Image.network(photoUrls[index]))),
          ),
        ),
      ),
    );
  }
}

class _RoutePoint extends StatelessWidget {
  const _RoutePoint({required this.color, required this.title, required this.subtitle});

  final Color color;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.route),
              if (subtitle != null) ...[const SizedBox(height: 2), Text(subtitle!, style: AppTextStyles.caption)],
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.label, required this.value, this.leading});

  final String label;
  final String value;

  /// Миниатюра кузова у «Тип кузова» (045 п.4).
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.field)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.xs),
          if (leading != null) ...[leading!, const SizedBox(height: AppSpacing.xs)],
          Text(value, style: AppTextStyles.bodyStrong),
        ],
      ),
    );
  }
}

