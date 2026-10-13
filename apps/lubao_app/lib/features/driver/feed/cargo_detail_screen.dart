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
import '../trips/driver_trips_screen.dart';
import '../../shared/error_feedback.dart';
import '../../shared/offer_sheet.dart';
import '../../shared/share_action.dart';
import 'favorite_button.dart';
import '../../shared/company_verified_badge.dart';
import '../../shared/cargo_info.dart';

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
        ).showSnackBar(SnackBar(content: Text(responseConflictText(context.l10n, e) ?? errorMessage(context.l10n, e))));
      }
    } finally {
      if (mounted) setState(() => _responding = false);
    }
  }

  void _refreshMine() {
    ref.invalidate(myCargoResponseProvider(widget.cargoId));
    ref.invalidate(cargoFeedProvider);
    ref.invalidate(myResponsesProvider);
  }

  Future<void> _offerAction(Future<void> Function() action) async {
    setState(() => _responding = true);
    try {
      await action();
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      _refreshMine();
      if (mounted) setState(() => _responding = false);
    }
  }

  /// 058 п.5: «Предложить свою цену» (и в ответ на приглашение) / «Изменить цену».
  Future<void> _proposePrice(Cargo cargo, MyCargoResponse? mine) async {
    final t = context.l10n;
    final offer = await showOfferSheet(context, currency: cargo.currency, title: t.offerSheetTitle, initialPrice: mine?.offer.proposedPrice ?? cargo.price, initialComment: mine?.offer.proposedComment);
    if (offer == null || !mounted) return;
    final repo = ref.read(cargoRepositoryProvider);
    await _offerAction(() async {
      if (mine != null && mine.status == ResponseStatus.pending) {
        await repo.updateOffer(mine.id, proposedPrice: offer.price, proposedComment: offer.comment);
      } else {
        await repo.respond(widget.cargoId, proposedPrice: offer.price, proposedComment: offer.comment);
        unawaited(ref.read(pushServiceProvider).requestPermissionAndRegister());
      }
    });
  }

  /// «Согласен» на встречную — сделка сразу (подтверждена, если проверен).
  Future<void> _agreeCounter(String responseId) async {
    String? dealId;
    await _offerAction(() async => dealId = await ref.read(cargoRepositoryProvider).acceptCounter(responseId));
    ref.invalidate(dealsMineProvider);
    if (dealId != null && mounted) context.push('/deal/$dealId');
  }

  /// 058 п.5: состояние торга над кнопками.
  Widget? _offerBlock(Cargo cargo, LubaoLocalizations t) {
    final mine = ref.watch(myCargoResponseProvider(widget.cargoId)).valueOrNull;
    final status = mine?.status;
    final offer = mine?.offer ?? ResponseOffer.none;
    final canPropose = cargo.status == CargoStatus.published && (status == null || status == ResponseStatus.invited || status == ResponseStatus.cancelled);
    if (offer.counterPending && status == ResponseStatus.pending) {
      return AppCard(
        key: const Key('offerCounterCard'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.offerCounterFromLogist(formatMoney(offer.counterPrice!, cargo.currency)), style: AppTextStyles.bodyStrong),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('offerCounterDecline'),
                    onPressed: _responding ? null : () => _offerAction(() => ref.read(cargoRepositoryProvider).declineCounter(mine!.id)),
                    child: Text(t.offerDecline),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    key: const Key('offerCounterAgree'),
                    onPressed: _responding ? null : () => _agreeCounter(mine!.id),
                    child: Text(t.offerAgree),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
    if (status == ResponseStatus.pending && offer.hasDriverPrice) {
      return Row(
        children: [
          Expanded(
            child: Text(
              offer.counterStatus == CounterStatus.declined ? t.offerCounterDeclinedDriver : t.offerSent(formatMoney(offer.proposedPrice!, cargo.currency)),
              key: const Key('offerSentText'),
              style: AppTextStyles.body,
            ),
          ),
          if (offer.counterPrice == null)
            TextButton(key: const Key('offerChange'), onPressed: _responding ? null : () => _proposePrice(cargo, mine), child: Text(t.offerChange)),
        ],
      );
    }
    if (canPropose) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          key: const Key('offerProposeButton'),
          icon: const Icon(LucideIcons.badgeDollarSign, size: 18),
          onPressed: _responding ? null : () => _proposePrice(cargo, mine),
          label: Text(t.offerPropose),
        ),
      );
    }
    return null;
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
        ).showSnackBar(SnackBar(content: Text(responseConflictText(context.l10n, e) ?? errorMessage(context.l10n, e))));
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
            // С кнопкой Flutter не убирает SnackBar сам (persist) — висел до нажатия.
            persist: false,
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
      appBar: AppBar(
        title: Text(t.cargoDetailTitle),
        actions: [
          // 058 п.8: ☆ — в «Избранное».
          FavoriteCargoButton(cargoId: widget.cargoId),
          // 052 п.4: водитель делится любым грузом из ленты («брат, глянь»).
          if (cargoAsync.valueOrNull != null && ref.watch(referenceDataProvider).valueOrNull != null)
            IconButton(
              key: const Key('cargoDetailShare'),
              tooltip: t.shareButton,
              icon: const Icon(LucideIcons.share),
              onPressed: () => shareContent(context, ref,
                  kind: ShareKind.cargo,
                  targetId: cargoAsync.value!.id,
                  dialogTitle: t.shareDialogCargo,
                  buildText: (url) => cargoShareText(t, ref.read(referenceDataProvider).value!, cargoAsync.value!, url, Localizations.localeOf(context).languageCode)),
            ),
        ],
      ),
      body: cargoAsync.when(
        loading: () => const LoadingView(),
        error: (e, st) {
          debugPrint('CargoDetailScreen (cargo): $e');
          return ErrorView(message: errorMessage(t, e));
        },
        data: (cargo) => referenceData.when(
          loading: () => const LoadingView(),
          error: (e, st) {
            debugPrint('CargoDetailScreen (referenceData): $e');
            return ErrorView(message: errorMessage(t, e));
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
                    ?_offerBlock(cargoAsync.value!, t),
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
                    // Логист не указал телефон — «Позвонить» и WhatsApp неактивны: сказать почему.
                    if (!contactLocked && !(cargoAsync.value!.hasContactPhone))
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Text(t.contactNoPhone, key: const Key('cargoNoPhoneHint'), style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CargoMainCard(cargo: cargo, refData: refData),
          if (cargo.allowPartial) ...[
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
              child: PartialLoadBlock(cargo: cargo, hint: ref.watch(partialHintProvider(cargo.id)).valueOrNull),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          CargoParamsBlock(cargo: cargo, refData: refData),
          if (cargo.photoUrls.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            CargoPhotosStrip(photoUrls: cargo.photoUrls),
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
                        companyDisplayName(cargo.companyName, cargo.companyNameLatin, Localizations.localeOf(context).languageCode).isEmpty ? '' : companyDisplayName(cargo.companyName, cargo.companyNameLatin, Localizations.localeOf(context).languageCode).substring(0, 1).toUpperCase(),
                        style: AppTextStyles.bodyStrong.copyWith(color: AppColors.accentText),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 066: «Проверена» с галочкой / серое «Не проверена».
                          Wrap(
                            spacing: AppSpacing.xs,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(companyDisplayName(cargo.companyName, cargo.companyNameLatin, Localizations.localeOf(context).languageCode), key: const Key('cargoDetailCompanyName'), style: AppTextStyles.bodyStrong),
                              CompanyVerifiedBadge(isVerified: cargo.companyIsVerified, keySuffix: 'detail'),
                            ],
                          ),
                          // 069: латиницей — а оригинал мелко серым.
                          if (companyDisplayName(cargo.companyName, cargo.companyNameLatin, Localizations.localeOf(context).languageCode) != cargo.companyName)
                            Text(cargo.companyName, key: const Key('cargoDetailCompanyOriginal'), style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                          // 058 п.8а: грузовладелец / экспедитор / перевозчик.
                          Text(
                            [companyKindLabel(t, cargo.companyKind), ?formatLastSeen(t, cargo.contactLastSeenAt)].join(' · '),
                            key: const Key('cargoDetailCompanyKind'),
                            style: AppTextStyles.caption,
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
          // 066 п.5: жалоба на груз без сделки — две от разных водителей
          // ставят непроверенную компанию на паузу.
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('cargoDetailComplain'),
              style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
              onPressed: () => _complainAboutCargo(context, ref, cargo.id),
              icon: const Icon(LucideIcons.flag, size: 16),
              label: Text(t.cargoComplainTitle),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

/// 066 п.5: «Пожаловаться на груз» — в очередь жалоб админки.
Future<void> _complainAboutCargo(BuildContext context, WidgetRef ref, String cargoId) async {
  final t = context.l10n;
  final controller = TextEditingController();
  var showError = false;
  final text = await showDialog<String>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        key: const Key('cargoComplainDialog'),
        title: Text(t.cargoComplainTitle),
        // Узкий экран + крупный шрифт + клавиатура (iPhone SE): прокрутка, а не переполнение.
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.cargoComplainBody, style: AppTextStyles.body),
              const SizedBox(height: AppSpacing.sm),
              // 072: пустую жалобу не отправляем — ошибка под полем.
              AppTextField(
                key: const Key('cargoComplainText'),
                label: t.complaintReasonLabel,
                controller: controller,
                maxLines: 3,
                errorText: showError && controller.text.trim().isEmpty ? t.garageFieldRequired : null,
                onChanged: (_) => setDialogState(() {}),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(t.commonCancel)),
          FilledButton(
            key: const Key('cargoComplainSubmit'),
            onPressed: () => controller.text.trim().isEmpty ? setDialogState(() => showError = true) : Navigator.pop(dialogContext, controller.text),
            child: Text(t.complaintSend),
          ),
        ],
      ),
    ),
  );
  if (text == null || text.trim().isEmpty || !context.mounted) return;
  try {
    await ref.read(cargoRepositoryProvider).complain(cargoId, reason: text.trim());
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.complaintSent)));
  } catch (e) {
    if (context.mounted) showApiError(context, e);
  }
}
