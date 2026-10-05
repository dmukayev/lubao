import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../providers/api_providers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import 'status_helpers.dart';
import 'package:lucide_icons/lucide_icons.dart';

class DealDetailScreen extends ConsumerStatefulWidget {
  const DealDetailScreen({super.key, required this.dealId});

  final String dealId;

  @override
  ConsumerState<DealDetailScreen> createState() => _DealDetailScreenState();
}

class _DealDetailScreenState extends ConsumerState<DealDetailScreen> {
  bool _busy = false;
  bool _openingChat = false;

  /// Чат теперь по `chatId`, не по `dealId` (задача 017, п.1) — находим
  /// существующий чат пары водитель+компания по грузу этой сделки (он уже
  /// привязан к сделке на бэкенде) и переходим в него.
  Future<void> _openChat(Deal deal) async {
    setState(() => _openingChat = true);
    try {
      final session = ref.read(sessionProvider);
      final thread = await ref.read(chatRepositoryProvider).findOrCreate(
            driverId: session?.driver != null ? null : deal.driverId,
            cargoId: deal.cargoId,
          );
      if (mounted) context.push('/chat/${thread.id}');
    } catch (e) {
      debugPrint('DealDetailScreen: failed to open chat: $e');
      if (mounted) {
        final t = context.l10n;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(t.chatOpenFailed),
          action: SnackBarAction(label: t.commonRetry, onPressed: () => _openChat(deal)),
        ));
      }
    } finally {
      if (mounted) setState(() => _openingChat = false);
    }
  }

  Future<void> _advance(DealStatus next) async {
    setState(() => _busy = true);
    try {
      await ref.read(dealRepositoryProvider).advanceStatus(widget.dealId, next);
      ref.invalidate(dealByIdProvider(widget.dealId));
      ref.invalidate(dealsMineProvider);
    } on DioException catch (e) {
      if (isDriverNotVerifiedError(e)) {
        if (mounted) await showVerificationRequiredSheet(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.commonError)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    final t = context.l10n;
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.dealCancel),
        content: AppTextField(label: t.dealCancelReasonLabel, controller: controller, maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(t.commonCancel)),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: Text(t.commonDone)),
        ],
      ),
    );
    if (reason == null || reason.trim().isEmpty) return;

    setState(() => _busy = true);
    try {
      await ref.read(dealRepositoryProvider).cancel(widget.dealId, reason: reason.trim());
      ref.invalidate(dealByIdProvider(widget.dealId));
      ref.invalidate(dealsMineProvider);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _leaveReview() async {
    final t = context.l10n;
    int rating = 5;
    final commentController = TextEditingController();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(t.reviewTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final starIndex = i + 1;
                  return IconButton(
                    icon: Icon(starIndex <= rating ? LucideIcons.star : LucideIcons.star, color: Colors.amber),
                    onPressed: () => setDialogState(() => rating = starIndex),
                  );
                }),
              ),
              AppTextField(label: t.reviewCommentLabel, controller: commentController, maxLines: 3),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t.commonCancel)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(t.reviewSubmit)),
          ],
        ),
      ),
    );

    if (submitted != true) return;
    await ref.read(reviewRepositoryProvider).submit(widget.dealId, rating: rating, comment: commentController.text);
    ref.invalidate(reviewsForDealProvider(widget.dealId));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final dealAsync = ref.watch(dealByIdProvider(widget.dealId));
    final session = ref.watch(sessionProvider);
    final isDriver = session?.user.role == UserRole.driver;

    final deal = dealAsync.valueOrNull;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.dealDetailTitle),
        actions: [
          if (deal != null)
            IconButton(
              icon: _openingChat
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(LucideIcons.messageCircle),
              onPressed: _openingChat ? null : () => _openChat(deal),
            ),
        ],
      ),
      body: dealAsync.when(
        loading: () => const LoadingView(),
        error: (e, st) {
          debugPrint('DealDetailScreen: $e');
          return ErrorView(message: t.commonError);
        },
        data: (deal) {
          final (statusLabel, statusColor) = dealStatusPresentation(t, deal.status);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(isDriver ? deal.companyName : deal.driverName, style: Theme.of(context).textTheme.titleLarge)),
                    StatusBadge(label: statusLabel, color: statusColor),
                  ],
                ),
                if (deal.cargo != null) ...[
                  const SizedBox(height: 8),
                  Text(formatMoney(deal.cargo!.price, deal.cargo!.currency), style: Theme.of(context).textTheme.headlineSmall),
                ],
                const Divider(height: 32),
                Text(t.dealTimelineTitle, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                _timeline(context, deal),
                if (deal.status == DealStatus.cancelled && deal.cancelReason != null) ...[
                  const SizedBox(height: 16),
                  Text('${t.dealCancelReasonLabel}: ${deal.cancelReason}'),
                ],
                if (!isDriver) ...[
                  const Divider(height: 32),
                  Text(t.dealDriverLocationTitle, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  if (deal.driverLocation != null)
                    Text(
                      '${deal.driverLocation!.lat.toStringAsFixed(5)}, ${deal.driverLocation!.lng.toStringAsFixed(5)}\n'
                      '${t.dealLocationUpdatedAt}: ${formatDateTime(deal.driverLocation!.updatedAt)}',
                    )
                  else
                    Text(t.dealLocationNoData, style: TextStyle(color: Theme.of(context).disabledColor)),
                ],
                const SizedBox(height: 24),
                if (isDriver && deal.nextStatus != null) ...[
                  PrimaryButton(
                    label: switch (deal.nextStatus!) {
                      DealStatus.confirmedByDriver => t.dealConfirm,
                      DealStatus.loaded => t.dealMarkLoaded,
                      DealStatus.inTransit => t.dealMarkInTransit,
                      DealStatus.delivered => t.dealMarkDelivered,
                      _ => t.commonNext,
                    },
                    loading: _busy,
                    onPressed: () => _advance(deal.nextStatus!),
                  ),
                  const SizedBox(height: 8),
                ],
                if (deal.isCancellable)
                  OutlinedButton(onPressed: _busy ? null : _cancel, child: Text(t.dealCancel)),
                if (deal.status == DealStatus.delivered) ...[
                  const SizedBox(height: 24),
                  Text(t.reviewsReceivedTitle, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  _ReviewsSection(dealId: widget.dealId, onAddReview: _leaveReview),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _timeline(BuildContext context, Deal deal) {
    final t = context.l10n;
    final steps = <(String, DateTime?)>[
      (t.dealStatusSelected, deal.createdAt),
      (t.dealStatusConfirmed, deal.confirmedAt),
      (t.dealStatusLoaded, deal.loadedAt),
      (t.dealStatusInTransit, deal.inTransitAt),
      (t.dealStatusDelivered, deal.deliveredAt),
    ];
    return Column(
      children: steps.map((step) {
        final (label, at) = step;
        final done = at != null;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(done ? LucideIcons.checkCircle2 : LucideIcons.circle,
                  size: 18, color: done ? StatusBadge.success : Theme.of(context).disabledColor),
              const SizedBox(width: 8),
              Expanded(child: Text(label)),
              if (at != null) Text(formatDate(at), style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ReviewsSection extends ConsumerWidget {
  const _ReviewsSection({required this.dealId, required this.onAddReview});

  final String dealId;
  final VoidCallback onAddReview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final session = ref.watch(sessionProvider);
    final reviewsAsync = ref.watch(reviewsForDealProvider(dealId));

    return reviewsAsync.when(
      loading: () => const LoadingView(),
      error: (e, st) {
        debugPrint('DealDetailScreen (reviews): $e');
        return Text(t.commonError);
      },
      data: (reviews) {
        final myRole = session?.user.role == UserRole.driver ? UserRole.driver : UserRole.company;
        final alreadyReviewed = reviews.any((r) => r.authorRole == myRole);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final review in reviews)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    ...List.generate(
                      5,
                      (i) => Icon(i < review.rating ? LucideIcons.star : LucideIcons.star, size: 16, color: Colors.amber),
                    ),
                    const SizedBox(width: 8),
                    if (review.comment != null) Expanded(child: Text(review.comment!)),
                  ],
                ),
              ),
            if (!alreadyReviewed) ...[
              const SizedBox(height: 8),
              OutlinedButton(onPressed: onAddReview, child: Text(t.reviewTitle)),
            ],
          ],
        );
      },
    );
  }
}
