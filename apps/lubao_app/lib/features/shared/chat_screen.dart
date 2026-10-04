import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../providers/api_providers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import 'status_helpers.dart';

const _languageNames = {'ru': 'русском', 'kk': 'қазақском', 'zh': 'китайском'};

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.dealId});

  final String dealId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  bool _sending = false;
  bool _sharingLocation = false;
  bool _confirming = false;

  Future<void> _send([String? text]) async {
    final message = (text ?? _controller.text).trim();
    if (message.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ref.read(chatRepositoryProvider).send(widget.dealId, message);
      _controller.clear();
      ref.invalidate(chatMessagesProvider(widget.dealId));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _attachLocation() async {
    final t = context.l10n;
    setState(() => _sharingLocation = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw Exception('location permission denied');
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      // Amap понимает WGS84-координаты напрямую (coordinate=wgs84) и открывается
      // как в приложении, так и веб-версией без ключа/входа — подходит и для
      // казахстанской, и для китайской стороны без встраивания карты в апп.
      final link = 'https://uri.amap.com/marker?position=${position.longitude},${position.latitude}'
          '&coordinate=wgs84&src=lubao&callnative=1';
      await _send('📍 ${t.chatLocationMessagePrefix}: $link');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.chatLocationError)));
      }
    } finally {
      if (mounted) setState(() => _sharingLocation = false);
    }
  }

  Future<void> _call(Deal deal) async {
    final driverId = ref.read(sessionProvider)?.driver?.id;
    if (driverId == null) return;
    await ref.read(cargoRepositoryProvider).logContactEvent(
          driverId: driverId,
          companyId: deal.companyId,
          cargoId: deal.cargoId,
          type: 'CALL',
        );
  }

  Future<void> _confirm(DealStatus status) async {
    setState(() => _confirming = true);
    try {
      await ref.read(dealRepositoryProvider).advanceStatus(widget.dealId, status);
      ref.invalidate(dealByIdProvider(widget.dealId));
    } on DioException catch (e) {
      if (isDriverNotVerifiedError(e)) {
        if (mounted) await showVerificationRequiredSheet(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.commonError)));
      }
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final threadAsync = ref.watch(chatThreadProvider(widget.dealId));
    final messagesAsync = ref.watch(chatMessagesProvider(widget.dealId));
    final dealAsync = ref.watch(dealByIdProvider(widget.dealId));
    final isDriver = ref.watch(sessionProvider)?.driver != null;
    final referenceData = ref.watch(referenceDataProvider).valueOrNull;

    final thread = threadAsync.valueOrNull;
    final deal = dealAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.accentSoft,
              child: Text(
                (thread?.counterpartName ?? '').isEmpty ? '' : thread!.counterpartName.substring(0, 1).toUpperCase(),
                style: AppTextStyles.bodyStrong.copyWith(color: AppColors.accentText),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    thread?.counterpartName ?? t.chatTitle,
                    style: AppTextStyles.bodyStrong,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (thread?.counterpartLocale != null && _languageNames[thread!.counterpartLocale] != null)
                    Text(
                      t.chatWritesIn(_languageNames[thread.counterpartLocale]!),
                      style: AppTextStyles.caption,
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (deal != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: IconSquareButton(icon: LucideIcons.phone, onPressed: () => _call(deal)),
            ),
        ],
      ),
      body: Column(
        children: [
          if (deal?.cargo != null && referenceData != null) _DealSummaryBar(deal: deal!, refData: referenceData),
          Expanded(
            child: messagesAsync.when(
              loading: () => const LoadingView(),
              error: (e, st) => ErrorView(message: t.commonError),
              data: (list) {
                if (list.isEmpty) return EmptyState(message: t.chatEmpty, icon: LucideIcons.messageCircle);
                final showConfirmCard = isDriver && deal?.status == DealStatus.selected;

                // Собираем плоский список сверху вниз (старые -> новые), с
                // разделителями дат перед первым сообщением каждого дня, а
                // затем один раз переворачиваем — так реверс-индексация не
                // нужна и день границы считаются без off-by-one ошибок.
                final rows = <Widget>[];
                for (var i = 0; i < list.length; i++) {
                  final message = list[i];
                  final isFirstOfDay = i == 0 || !_isSameDay(list[i - 1].createdAt, message.createdAt);
                  if (isFirstOfDay) {
                    rows.add(Center(child: _DateDivider(date: message.createdAt)));
                  }
                  rows.add(Column(
                    crossAxisAlignment: message.isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      ChatBubble(
                        text: message.displayText(locale),
                        isMine: message.isMine,
                        isTranslated: message.translations != null && message.originalLang != locale,
                        originalText: message.originalText,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_formatTime(message.createdAt), style: AppTextStyles.caption),
                          if (message.isMine) ...[
                            const SizedBox(width: AppSpacing.xs),
                            Icon(
                              message.isRead ? LucideIcons.checkCheck : LucideIcons.check,
                              size: 14,
                              color: message.isRead ? AppColors.primary : AppColors.textSecondary,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ));
                }
                if (showConfirmCard) {
                  rows.add(_ConfirmCard(confirming: _confirming, onConfirm: () => _confirm(DealStatus.confirmedByDriver)));
                }

                return ListView.separated(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen, vertical: AppSpacing.md),
                  itemCount: rows.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) => rows[rows.length - 1 - index],
                );
              },
            ),
          ),
          if (isDriver)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
                children: [
                  QuickReplyChip(label: t.chatQuickReplyAtPlace, onTap: () => _send(t.chatQuickReplyAtPlace)),
                  const SizedBox(width: AppSpacing.sm),
                  QuickReplyChip(label: t.chatQuickReplyLoaded, onTap: () => _send(t.chatQuickReplyLoaded)),
                  const SizedBox(width: AppSpacing.sm),
                  QuickReplyChip(label: t.chatQuickReplyLate1h, onTap: () => _send(t.chatQuickReplyLate1h)),
                ],
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  IconSquareButton(
                    icon: LucideIcons.mapPin,
                    onPressed: _sharingLocation ? null : _attachLocation,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: AppTextField(label: '', hintText: t.chatInputHint, controller: _controller)),
                  const SizedBox(width: AppSpacing.sm),
                  IconSquareButton(
                    icon: LucideIcons.send,
                    onPressed: _sending ? null : () => _send(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

bool _isSameDay(DateTime a, DateTime b) {
  final la = a.toLocal();
  final lb = b.toLocal();
  return la.year == lb.year && la.month == lb.month && la.day == lb.day;
}

String _formatTime(DateTime date) {
  final local = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.hour)}:${two(local.minute)}';
}

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final now = DateTime.now();
    final local = date.toLocal();
    String label;
    if (_isSameDay(local, now)) {
      label = t.chatToday;
    } else if (_isSameDay(local, now.subtract(const Duration(days: 1)))) {
      label = t.chatYesterday;
    } else {
      label = formatDate(local);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: AppTextStyles.caption),
    );
  }
}

class _DealSummaryBar extends StatelessWidget {
  const _DealSummaryBar({required this.deal, required this.refData});

  final Deal deal;
  final ReferenceData refData;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final cargo = deal.cargo!;
    final country = refData.countryById(cargo.destinationCountryId);
    final city = refData.cityById(cargo.destinationCityId);
    final destinationLabel =
        [city?.name.forLanguageCode(locale), country.name.forLanguageCode(locale)].whereType<String>().join(', ');
    final point = refData.pointById(cargo.pointId);
    final (statusLabel, statusColor) = dealStatusPresentation(t, deal.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen, vertical: AppSpacing.sm),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.package, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '${point.name.forLanguageCode(locale)} → $destinationLabel · ${formatMoney(cargo.price, cargo.currency)}',
              style: AppTextStyles.caption.copyWith(color: AppColors.text),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          StatusBadge(label: statusLabel, color: statusColor),
        ],
      ),
    );
  }
}

class _ConfirmCard extends StatelessWidget {
  const _ConfirmCard({required this.confirming, required this.onConfirm});

  final bool confirming;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.chatConfirmTitle, style: AppTextStyles.bodyStrong),
          const SizedBox(height: AppSpacing.xs),
          Text(t.chatConfirmSubtitle, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.md),
          AccentButton(label: t.chatConfirmButton, loading: confirming, onPressed: onConfirm),
        ],
      ),
    );
  }
}
