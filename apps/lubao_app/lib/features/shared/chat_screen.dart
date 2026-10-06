import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/api_providers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import 'status_helpers.dart';

const _languageNames = {'ru': 'русском', 'kk': 'қазақском', 'zh': 'китайском'};

/// Чат — пара водитель+компания(+груз), не только сделка (задача 017,
/// п.1): экран открывается по `chatId`, а не по `dealId` — сделка (если
/// есть) подгружается отдельно через `thread.dealId`.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.chatId});

  final String chatId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  bool _sending = false;
  bool _sharingLocation = false;
  bool _confirming = false;
  // Задача 038, п.13 — карточка груза сворачивается при прокрутке истории
  // вверх (reverse-список: pixels растут от нижнего края).
  bool _cardCollapsed = false;

  StreamSubscription<Map<String, dynamic>>? _messageNewSub;
  StreamSubscription<Map<String, dynamic>>? _messageReadSub;
  StreamSubscription<Map<String, dynamic>>? _messageTranslatedSub;
  StreamSubscription<Map<String, dynamic>>? _chatUpdatedSub;
  StreamSubscription<Map<String, dynamic>>? _dealUpdatedSub;
  StreamSubscription<void>? _reconnectedSub;
  Timer? _pollTimer;
  // `ref` недоступен в dispose() у ConsumerStatefulElement (риверпод
  // помечает его disposed до вызова State.dispose) — сохраняем сервис из
  // initState, чтобы отписаться от комнаты без обращения к ref.
  late final RealtimeService _realtime;

  /// Сокет — основной канал (задача 011, п.6); если за 10с после открытия
  /// он не поднялся (прокси блокирует WS — см. задачу 020 про Китай),
  /// переходим на опрос каждые 10с, пока не подключится (п.7). После
  /// любого (пере)подключения — [RealtimeService] сам перезаходит в эту
  /// комнату (задача 029, п.3), здесь только догоняющий рефетч на случай
  /// сообщений, пропущенных во время обрыва.
  @override
  void initState() {
    super.initState();
    _realtime = ref.read(realtimeServiceProvider);
    final realtime = _realtime;
    realtime.joinChat(widget.chatId);
    _messageNewSub = realtime.onMessageNew.listen((data) {
      if (data['chatId'] == widget.chatId) {
        ref.invalidate(chatMessagesProvider(widget.chatId));
        ref.invalidate(chatThreadProvider(widget.chatId));
        unawaited(ref.read(chatRepositoryProvider).markRead(widget.chatId));
      }
    });
    _messageReadSub = realtime.onMessageRead.listen((data) {
      if (data['chatId'] == widget.chatId) {
        ref.invalidate(chatMessagesProvider(widget.chatId));
      }
    });
    // Перевод подъехал отдельно (задача 029, п.6) — сообщение уже на
    // экране с оригиналом, здесь просто подменяем его переводом.
    _messageTranslatedSub = realtime.onMessageTranslated.listen((data) {
      if (data['chatId'] == widget.chatId) {
        ref.invalidate(chatMessagesProvider(widget.chatId));
      }
    });
    _reconnectedSub = realtime.onReconnected.listen((_) {
      ref.invalidate(chatMessagesProvider(widget.chatId));
    });
    // Задача 038, п.12 — вторая сторона видит отзыв отклика/привязку
    // груза/смену статуса сделки сразу: карточка и кнопки обновляются по
    // комнатным событиям, а не при следующем заходе в чат.
    _chatUpdatedSub = realtime.onChatUpdated.listen((data) {
      if (data['chatId'] == widget.chatId) {
        ref.invalidate(chatThreadProvider(widget.chatId));
      }
    });
    _dealUpdatedSub = realtime.onDealUpdated.listen((data) {
      final dealId = data['dealId'];
      if (dealId is String) {
        ref.invalidate(dealByIdProvider(dealId));
        ref.invalidate(chatThreadProvider(widget.chatId));
      }
    });
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!realtime.isConnected) ref.invalidate(chatMessagesProvider(widget.chatId));
    });
    unawaited(ref.read(chatRepositoryProvider).markRead(widget.chatId));
  }

  @override
  void dispose() {
    _realtime.leaveChat(widget.chatId);
    _messageNewSub?.cancel();
    _messageReadSub?.cancel();
    _messageTranslatedSub?.cancel();
    _chatUpdatedSub?.cancel();
    _dealUpdatedSub?.cancel();
    _reconnectedSub?.cancel();
    _pollTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send([String? text]) async {
    final message = (text ?? _controller.text).trim();
    if (message.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ref.read(chatRepositoryProvider).send(widget.chatId, message);
      // Задача 038, п.11 — быстрый ответ/📍 (готовый text) не должен
      // стирать черновик, который пользователь набирает в поле ввода.
      if (text == null) _controller.clear();
      ref.invalidate(chatMessagesProvider(widget.chatId));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// «Перевод недоступен · повторить» (задача 010, п.7).
  Future<void> _retryTranslation(ChatMessage message) async {
    try {
      await ref.read(chatRepositoryProvider).retryTranslation(widget.chatId, message.id);
      ref.invalidate(chatMessagesProvider(widget.chatId));
    } catch (_) {
      // остаётся FAILED — пользователь может попробовать снова
    }
  }

  /// Водитель — «Отправить моё место» (задача 032, п.15): геопозиция
  /// запрашивается ТОЛЬКО по нажатию этой кнопки (не фонового слежения,
  /// см. `LocationReporter`/задача 008/014) и уходит ссылкой на карту —
  /// Amap для китайской компании-получателя (своя карта, без входа),
  /// 2ГИС для остальных.
  Future<void> _sendMyLocation(ChatThread? thread) async {
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
      final isChina = thread?.counterpartCountryCode == 'CN';
      final link = isChina
          // Amap понимает WGS84-координаты напрямую (coordinate=wgs84) и
          // открывается как в приложении, так и веб-версией без ключа/
          // входа — не нужно встраивать карту в апп для китайской стороны.
          ? 'https://uri.amap.com/marker?position=${position.longitude},${position.latitude}'
              '&coordinate=wgs84&src=lubao&callnative=1'
          : 'https://2gis.kz/geo/${position.longitude},${position.latitude}';
      await _send('📍 ${t.chatLocationMessagePrefix}: $link');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.chatLocationError)));
      }
    } finally {
      if (mounted) setState(() => _sharingLocation = false);
    }
  }

  /// Логист — «Место погрузки» (задача 032, п.15, решение 2026-10-06):
  /// НЕ его GPS — диалог со вставкой готовой ссылки (Baidu/Amap/2ГИС),
  /// отправленной тут же в чат. Ничего не сохраняется в груз — адрес
  /// всегда свежий, разрешение на геолокацию у логиста не запрашивается.
  Future<void> _sendLoadingPlaceLink() async {
    final t = context.l10n;
    final controller = TextEditingController();
    final link = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final trimmed = controller.text.trim();
          final valid = trimmed.startsWith('https://') && trimmed.length <= 500;
          return AlertDialog(
            title: Text(t.chatLoadingPlaceDialogTitle),
            content: AppTextField(
              label: '',
              hintText: t.chatLoadingPlaceDialogHint,
              controller: controller,
              onChanged: (_) => setDialogState(() {}),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(t.commonCancel)),
              FilledButton(
                onPressed: valid ? () => Navigator.pop(dialogContext, trimmed) : null,
                child: Text(t.commonDone),
              ),
            ],
          );
        },
      ),
    );
    if (link == null || !mounted) return;
    if (!link.startsWith('https://') || link.length > 500) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.chatLoadingPlaceLinkInvalid)));
      return;
    }
    await _send('📍 ${t.chatLoadingPlaceMessagePrefix}: $link');
  }

  /// Звонок не должен ждать запись события (задача 017, п.5г) — сначала
  /// открываем звонилку, `contact_event` пишем без ожидания.
  Future<void> _call(ChatThread thread) async {
    final phone = thread.counterpartPhone;
    if (phone == null) return;
    unawaited(launchUrl(Uri(scheme: 'tel', path: phone)));
    unawaited(ref.read(cargoRepositoryProvider).logContactEvent(
          driverId: thread.driverId,
          companyId: thread.companyId,
          cargoId: thread.cargoId,
          dealId: thread.dealId,
          type: 'CALL',
        ));
  }

  Future<void> _confirm(DealStatus status) async {
    final dealId = ref.read(chatThreadProvider(widget.chatId)).valueOrNull?.dealId;
    if (dealId == null) return;
    setState(() => _confirming = true);
    try {
      await ref.read(dealRepositoryProvider).advanceStatus(dealId, status);
      ref.invalidate(dealByIdProvider(dealId));
    } on DioException catch (e) {
      final full = asVehicleFullError(e);
      if (isDriverNotVerifiedError(e)) {
        if (mounted) await showVerificationRequiredSheet(context);
      } else if (full != null) {
        // Задача 038, п.10 — та же шторка «Машина заполнена», что в
        // карточке сделки, с переходом к занимающей машину сделке.
        if (mounted) await showVehicleFullSheet(context, full);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.commonError)));
      }
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final threadAsync = ref.watch(chatThreadProvider(widget.chatId));
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));
    final isDriver = ref.watch(sessionProvider)?.driver != null;
    final referenceData = ref.watch(referenceDataProvider).valueOrNull;

    final thread = threadAsync.valueOrNull;
    final dealAsync = thread?.dealId != null ? ref.watch(dealByIdProvider(thread!.dealId!)) : null;
    final deal = dealAsync?.valueOrNull;

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
                  if (thread?.counterpartWechatId != null)
                    Text('WeChat: ${thread!.counterpartWechatId}', style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (thread?.counterpartPhone != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: IconSquareButton(icon: LucideIcons.phone, onPressed: () => _call(thread!)),
            ),
        ],
      ),
      body: Column(
        children: [
          if (thread != null && referenceData != null)
            _CargoActionBar(
              chatId: widget.chatId,
              thread: thread,
              deal: deal,
              refData: referenceData,
              isDriver: isDriver,
              collapsed: _cardCollapsed,
            ),
          Expanded(
            child: messagesAsync.when(
              loading: () => const LoadingView(),
              error: (e, st) {
                debugPrint('ChatScreen: $e');
                return ErrorView(message: t.commonError);
              },
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
                  // Системные сообщения (задача 038, п.11) — по центру,
                  // нейтрально, текст из ARB на языке читателя.
                  if (message.isSystem) {
                    rows.add(Center(child: _SystemMessageChip(message: message)));
                    continue;
                  }
                  rows.add(Column(
                    crossAxisAlignment: message.isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      ChatBubble(
                        text: message.displayText(locale),
                        isMine: message.isMine,
                        isTranslated: message.translations != null && message.originalLang != locale,
                        originalText: message.originalText,
                        isTranslationFailed: !message.isMine &&
                            message.originalLang != locale &&
                            message.translationStatus == ChatMessageTranslationStatus.failed,
                        onRetryTranslation: () => _retryTranslation(message),
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

                return NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    final collapsed = notification.metrics.pixels > 120;
                    if (collapsed != _cardCollapsed) setState(() => _cardCollapsed = collapsed);
                    return false;
                  },
                  child: ListView.separated(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen, vertical: AppSpacing.md),
                    itemCount: rows.length,
                    separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) => rows[rows.length - 1 - index],
                  ),
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
                  Tooltip(
                    message: isDriver ? t.chatAttachLocation : t.chatLoadingPlaceTooltip,
                    child: IconSquareButton(
                      icon: LucideIcons.mapPin,
                      onPressed: _sharingLocation ? null : (isDriver ? () => _sendMyLocation(thread) : _sendLoadingPlaceLink),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppTextField(
                      key: const Key('chatMessageInput'),
                      label: '',
                      hintText: t.chatInputHint,
                      controller: _controller,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconSquareButton(
                    key: const Key('chatSendButton'),
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

/// Системная строка чата (задача 038, п.11) — «водитель готов взять»,
/// «выбран водитель», «перевозка подтверждена», «отклик отозван»,
/// «предложен груз»: нейтральная плашка по центру, текст строится из ARB
/// на языке ЧИТАТЕЛЯ (модель перевода не участвует). Неизвестный код
/// (новый сервер + старый клиент) — русский фолбэк originalText.
class _SystemMessageChip extends StatelessWidget {
  const _SystemMessageChip({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final text = systemMessageText(t, message.systemCode, message.systemParams, message.originalText);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: AppTextStyles.caption, textAlign: TextAlign.center),
    );
  }
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

/// Закреплённая карточка груза/сделки над перепиской (задача 035) —
/// заменяет старую `_DealSummaryBar`, которая показывалась только когда
/// СДЕЛКА уже существовала. Теперь видна с момента, когда у чата просто
/// есть груз (до отклика), и несёт действия по роли и состоянию: «Готов
/// взять»/«Отклик отправлен»+«Отозвать» у водителя, «Выбрать водителя» у
/// логиста — те же вызовы, что в карточке груза/списке откликов, не
/// дублирующая логика. Для чата без груза вовсе — у логиста «Предложить
/// груз» вместо карточки.
class _CargoActionBar extends ConsumerStatefulWidget {
  const _CargoActionBar({
    required this.chatId,
    required this.thread,
    required this.deal,
    required this.refData,
    required this.isDriver,
    required this.collapsed,
  });

  final String chatId;
  final ChatThread thread;
  final Deal? deal;
  final ReferenceData refData;
  final bool isDriver;

  /// Свёрнута при прокрутке истории (038, п.13) — остаётся одна строка
  /// маршрут+цена+статус, детали и кнопки скрываются.
  final bool collapsed;

  @override
  ConsumerState<_CargoActionBar> createState() => _CargoActionBarState();
}

class _CargoActionBarState extends ConsumerState<_CargoActionBar> {
  bool _busy = false;

  void _reload() => ref.invalidate(chatThreadProvider(widget.chatId));

  /// Ошибки действий карточки — не молчать (задача 038, п.2): 409 с кодом
  /// переводится в понятный текст, остальное — commonError. После ошибки
  /// карточка перезагружается: статус на сервере мог уйти вперёд (другая
  /// вкладка/логист), и кнопки должны отразить реальность.
  void _showError(Object error) {
    if (!mounted) return;
    final t = context.l10n;
    final text = responseConflictText(t, error) ?? t.commonError;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    _reload();
  }

  Future<void> _respond(String cargoId) async {
    setState(() => _busy = true);
    try {
      await ref.read(cargoRepositoryProvider).respond(cargoId);
      // Системную строку «готов взять» постит сервер (задача 038, п.11).
      ref.invalidate(chatMessagesProvider(widget.chatId));
      _reload();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _withdraw(String responseId) async {
    setState(() => _busy = true);
    try {
      await ref.read(cargoRepositoryProvider).withdrawResponse(responseId);
      _reload();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _selectDriver(String cargoId, String driverId, String? responseId) async {
    setState(() => _busy = true);
    try {
      if (responseId != null) {
        await ref.read(cargoRepositoryProvider).updateResponseStatus(responseId, 'SELECTED');
      } else {
        await ref.read(cargoRepositoryProvider).inviteDriver(cargoId, driverId);
      }
      // Системную строку «выбран водитель» постит сервер (038, п.11).
      ref.invalidate(chatMessagesProvider(widget.chatId));
      _reload();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Следующий статус сделки из карточки чата (038, п.13) — тот же
  /// advanceStatus, что в карточке сделки, без дублирующей логики.
  Future<void> _advanceDeal(String dealId, DealStatus next) async {
    setState(() => _busy = true);
    try {
      await ref.read(dealRepositoryProvider).advanceStatus(dealId, next);
      ref.invalidate(dealByIdProvider(dealId));
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _offerCargo() async {
    final cargo = await showModalBottomSheet<Cargo>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CargoPickerSheet(refData: widget.refData),
    );
    if (cargo == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final result = await ref.read(chatRepositoryProvider).attachCargo(widget.chatId, cargo.id);
      // Сервер мог вернуть ДРУГОЙ чат (пара водитель+компания+этот груз уже
      // существует — attach-or-navigate, задача 035/038 п.3): переходим в
      // него, а не перезагружаем текущий без груза.
      if (!mounted) return;
      if (result.id != widget.chatId) {
        context.pushReplacement('/chat/${result.id}');
        return;
      }
      _reload();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final thread = widget.thread;

    if (thread.cargoId == null) {
      // Задача 035, п.3 — чат без груза (логист написал водителю из «Кто
      // будет на точке»): у водителя тут нечего предлагать, только у
      // логиста есть что предложить.
      if (widget.isDriver) return const SizedBox.shrink();
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: const BoxDecoration(color: AppColors.surface, border: Border(bottom: BorderSide(color: AppColors.divider))),
        child: Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _busy ? null : _offerCargo,
            icon: const Icon(LucideIcons.package, size: 16),
            label: Text(t.chatOfferCargoButton),
          ),
        ),
      );
    }

    final cargo = ref.watch(cargoByIdProvider(thread.cargoId!)).valueOrNull;
    if (cargo == null) return const SizedBox.shrink();

    final locale = Localizations.localeOf(context).languageCode;
    final country = widget.refData.countryById(cargo.destinationCountryId);
    final city = widget.refData.cityById(cargo.destinationCityId);
    final destinationLabel =
        [city?.name.forLanguageCode(locale), country.name.forLanguageCode(locale)].whereType<String>().join(', ');
    final point = widget.refData.pointById(cargo.pointId);
    final deal = widget.deal;
    final (statusLabel, statusColor) = deal != null ? dealStatusPresentation(t, deal.status) : cargoStatusPresentation(t, cargo.status);

    Widget? actionRow;
    if (deal != null) {
      // Задача 038, п.13 — кнопки следующих статусов прямо в карточке
      // чата: водитель двигает «Загружен»/«В пути»/«Доставлено» не выходя
      // из переписки (подтверждение — отдельная _ConfirmCard в ленте).
      final next = deal.nextStatus;
      if (widget.isDriver && next != null && next != DealStatus.confirmedByDriver) {
        actionRow = PrimaryButton(
          label: switch (next) {
            DealStatus.loaded => t.dealMarkLoaded,
            DealStatus.inTransit => t.dealMarkInTransit,
            DealStatus.delivered => t.dealMarkDelivered,
            _ => t.commonNext,
          },
          loading: _busy,
          onPressed: () => _advanceDeal(deal.id, next),
        );
      }
    } else {
      final responseStatus = thread.cargoResponseStatus;
      if (widget.isDriver) {
        if (responseStatus == 'PENDING') {
          actionRow = Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: null, child: Text(t.chatResponseSentLabel))),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : () => _withdraw(thread.cargoResponseId!),
                  child: Text(t.chatWithdrawButton),
                ),
              ),
            ],
          );
        } else if (responseStatus == 'REJECTED') {
          // Логист отклонил — повторный отклик сервер не примет (038, п.1).
          actionRow = OutlinedButton(onPressed: null, child: Text(t.chatResponseClosed));
        } else if (responseStatus == 'SELECTED') {
          // Выбран, а сделка в карточке ещё не подгрузилась (038, п.27) —
          // не «Готов взять» (отклик уже есть), а лоадер до обновления.
          actionRow = const Center(child: Padding(padding: EdgeInsets.all(AppSpacing.sm), child: CircularProgressIndicator(strokeWidth: 2)));
        } else {
          // null (ещё не откликался) или CANCELLED (отозвал и передумал —
          // сервер переоткрывает тот же отклик, 038 п.2).
          actionRow = PrimaryButton(label: t.chatCargoReadyButton, loading: _busy, onPressed: () => _respond(thread.cargoId!));
        }
      } else {
        if (responseStatus == null || responseStatus == 'PENDING') {
          // Нет отклика — это приглашение («Пригласить к грузу»), есть —
          // выбор из откликов (038, п.27).
          actionRow = PrimaryButton(
            label: responseStatus == null ? t.driversAtPointInvite : t.responseSelect,
            loading: _busy,
            onPressed: () => _selectDriver(thread.cargoId!, thread.driverId, thread.cargoResponseId),
          );
        } else if (responseStatus == 'REJECTED' || responseStatus == 'CANCELLED') {
          // Выбор только из PENDING (038, п.1) — решённый отклик из чата
          // не воскресить; SELECTED без сделки — сделка ещё грузится.
          actionRow = OutlinedButton(onPressed: null, child: Text(t.chatResponseClosed));
        }
      }
    }

    // Задача 038, п.13 — детали: кузов/вес/объём + пересчёт цены в тенге.
    final bodyType = widget.refData.bodyTypeById(cargo.bodyTypeId);
    final detailParts = <String>[
      bodyType.name.forLanguageCode(locale),
      if (cargo.weightKg != null) '${(cargo.weightKg! / 1000).toStringAsFixed(0)} ${t.unitTon}',
      if (cargo.volumeM3 != null) '${cargo.volumeM3!.toStringAsFixed(0)} ${t.unitM3}',
    ];
    final kztLabel = formatKztConversion(widget.refData.convertToKzt(cargo.price, cargo.currency));
    if (kztLabel != null) detailParts.add(kztLabel);

    return Material(
      color: AppColors.surface,
      child: InkWell(
        // Тап по карточке — к самой карточке груза (038, п.13): водителю —
        // его экран груза, логисту — свои отклики по грузу.
        onTap: () => widget.isDriver
            ? context.push('/driver/cargo/${cargo.id}')
            : context.push('/company/cargos/${cargo.id}/responses'),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen, vertical: AppSpacing.sm),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
              // Свёрнута при прокрутке (038, п.13) — только строка выше.
              if (!widget.collapsed) ...[
                if (detailParts.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    detailParts.join(' · '),
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (actionRow != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  actionRow,
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Список своих опубликованных грузов для «Предложить груз» (задача 035,
/// п.3) — тот же `myCargosProvider`, что у «Мои грузы» логиста.
class _CargoPickerSheet extends ConsumerWidget {
  const _CargoPickerSheet({required this.refData});

  final ReferenceData refData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    final cargosAsync = ref.watch(myCargosProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.chatOfferCargoSheetTitle, style: AppTextStyles.bodyStrong),
            const SizedBox(height: AppSpacing.md),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: cargosAsync.when(
                loading: () => const LoadingView(),
                error: (e, st) => ErrorView(message: t.commonError),
                data: (cargos) => cargos.isEmpty
                    ? EmptyState(message: t.myCargosEmpty)
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: cargos.length,
                        itemBuilder: (context, index) {
                          final cargo = cargos[index];
                          final country = refData.countryById(cargo.destinationCountryId);
                          final city = refData.cityById(cargo.destinationCityId);
                          final destinationLabel =
                              [city?.name.forLanguageCode(locale), country.name.forLanguageCode(locale)].whereType<String>().join(', ');
                          return ListTile(
                            title: Text(destinationLabel),
                            subtitle: Text(formatMoney(cargo.price, cargo.currency)),
                            onTap: () => Navigator.pop(context, cargo),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
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
