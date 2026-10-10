import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';

import '../../../providers/api_providers.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/locale_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'add_vehicle_banner.dart';
import 'driver_companies.dart';
import '../../shared/pre_verification_card.dart';
import 'profile_avatar.dart';

class DriverProfileScreen extends ConsumerStatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  ConsumerState<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends ConsumerState<DriverProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Сессия обновляется из /auth/me только при холодном старте приложения
    // (SessionController._restore) — если админ подтвердил верификацию, пока
    // водитель уже был в приложении, бейдж и баннер молча показывали старый
    // статус. Перетягиваем свежий профиль при каждом открытии вкладки.
    _refreshDriver();
  }

  Future<void> _refreshDriver() async {
    try {
      final fresh = await ref.read(driverRepositoryProvider).me();
      if (mounted) ref.read(sessionProvider.notifier).updateDriver(fresh);
    } catch (e) {
      debugPrint('DriverProfileScreen: failed to refresh driver status: $e');
    }
  }

  Future<void> _acceptLicenseName() async {
    try {
      final updated = await ref.read(driverRepositoryProvider).acceptLicenseName();
      if (mounted) ref.read(sessionProvider.notifier).updateDriver(updated);
    } catch (e) {
      debugPrint('DriverProfileScreen: accept license name: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.commonError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final session = ref.watch(sessionProvider);
    final driver = session?.driver;
    final locale = ref.watch(localeProvider);
    // 053 п.1: машин нет — плашка «Добавьте машину» первым блоком и «!» у гаража.
    final noVehicles = ref.watch(garageVehiclesProvider).valueOrNull?.isEmpty ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.profileTitle),
        actions: [IconButton(icon: const Icon(LucideIcons.pencil), onPressed: () => context.push('/driver/setup'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 054 п.3: фото рядом с именем; нажатие — сменить / убрать.
          Row(
            children: [
              if (driver != null) ...[ProfileAvatar(driver: driver), const SizedBox(width: AppSpacing.md)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(driver?.fullName ?? '', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(LucideIcons.star, size: 16, color: Colors.amber),
                            Text(driver == null ? ' —' : ' ${formatRating(driver.ratingAvg, driver.ratingCount)}${driver.ratingCount == 0 ? '' : ' (${driver.ratingCount})'}'),
                          ],
                        ),
                        StatusBadge(
                          label: (driver?.isVerified ?? false) ? t.profileVerified : t.profileNotVerified,
                          color: (driver?.isVerified ?? false) ? StatusBadge.success : StatusBadge.neutral,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (driver?.avatarOffer ?? false) ...[
            const SizedBox(height: AppSpacing.lg),
            const AvatarOfferCard(),
          ],
          // 045 п.10: ФИО из одобренных прав — подставить одним нажатием.
          if (driver?.licenseFullName != null) ...[
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              key: const Key('licenseNameBanner'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.licenseNameBanner(driver!.licenseFullName!), style: AppTextStyles.body),
                  const SizedBox(height: AppSpacing.sm),
                  PrimaryButton(key: const Key('licenseNameAccept'), label: t.licenseNameAccept, onPressed: _acceptLicenseName),
                ],
              ),
            ),
          ],
          if (noVehicles) ...[
            const SizedBox(height: AppSpacing.lg),
            const AddVehicleBanner(key: Key('profileAddVehicleBanner'), buttonKey: Key('profileAddVehicle')),
          ],
          if (!(driver?.isVerified ?? false)) ...[
            const SizedBox(height: AppSpacing.lg),
            // 058 п.9: что можно до проверки, что нельзя и что откроется.
            PreVerificationCard.driver(t, key: const Key('driverPreVerifyCard')),
            const SizedBox(height: AppSpacing.sm),
            _CompletenessBanner(driver: driver),
          ],
          // 058 п.6: «Компании, где я в списке» — выйти из любой.
          const DriverCompaniesSection(),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(LucideIcons.phone),
            title: Text(t.profilePhone),
            subtitle: Text(session?.user.phone ?? '-'),
          ),
          ListTile(
            leading: const Icon(LucideIcons.languages),
            title: Text(t.profileLanguage),
            trailing: DropdownButton<Locale>(
              value: locale,
              items: const [
                DropdownMenuItem(value: Locale('kk'), child: Text('Қазақша')),
                DropdownMenuItem(value: Locale('ru'), child: Text('Русский')),
                DropdownMenuItem(value: Locale('zh'), child: Text('中文')),
                DropdownMenuItem(value: Locale('en'), child: Text('English')),
              ],
              onChanged: (value) {
                if (value != null) ref.read(sessionProvider.notifier).setLocale(value.languageCode);
              },
            ),
          ),
          ListTile(
            key: const Key('profileGarageItem'),
            leading: const Icon(LucideIcons.truck),
            title: Text(t.garageGoToGarage),
            trailing: noVehicles
                ? const CircleAvatar(
                    key: Key('profileGarageAlert'),
                    radius: 11,
                    backgroundColor: AppColors.accent,
                    child: Text('!', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700)),
                  )
                : null,
            onTap: () => context.push('/driver/garage'),
          ),
          // 056 п.6: доставленные рейсы и закрытые отклики с причиной.
          ListTile(
            key: const Key('profileTripHistory'),
            leading: const Icon(LucideIcons.history),
            title: Text(t.profileTripHistory),
            onTap: () => context.push('/driver/history'),
          ),
          ListTile(
            leading: const Icon(LucideIcons.smartphone),
            title: Text(t.profileMyDevices),
            onTap: () => context.push('/devices'),
          ),
          ListTile(
            leading: const Icon(LucideIcons.bell),
            title: Text(t.profileNotificationSettings),
            onTap: () => context.push('/notifications/settings'),
          ),
          // 043 п.2: Условия, Политика, Оферта, версия, «Удалить аккаунт».
          ListTile(
            key: const Key('profileAboutItem'),
            leading: const Icon(LucideIcons.info),
            title: Text(t.aboutTitle),
            onTap: () => context.push('/about'),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            key: const Key('driverProfileLogoutButton'),
            onPressed: () => ref.read(sessionProvider.notifier).logout(),
            child: Text(t.profileLogout),
          ),
        ],
      ),
    );
  }
}

/// Задача 032, п.13 (038) — верификация ЛИЧНОСТИ: только селфи и права;
/// техпаспорта живут у машин в гараже (задача 031, этап A) и на процент
/// готовности профиля не влияют.
const _requiredDriverDocTypes = [
  VerificationDocType.selfie,
  VerificationDocType.driverLicense,
];

class _CompletenessBanner extends ConsumerWidget {
  const _CompletenessBanner({required this.driver});

  final Driver? driver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final pending = driver?.verificationStatus == DriverVerificationStatus.pending;
    // Процент считается по факту одобренных обязательных документов, а не
    // по захардкоженной константе 60/80 — та не менялась независимо от
    // реального прогресса проверки (причина жалобы «висит 60% после
    // верификации в админке»).
    final docs = ref.watch(driverVerificationDocumentsProvider).valueOrNull ?? const [];
    final approvedCount =
        docs.where((d) => _requiredDriverDocTypes.contains(d.type) && d.status == VerificationDocStatus.approved).length;
    final percent = (approvedCount / _requiredDriverDocTypes.length * 100).round();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 8,
              backgroundColor: AppColors.divider,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(t.profileCompleteness(percent), style: AppTextStyles.body),
          if (!pending) ...[
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              key: const Key('driverProfileVerifyButton'),
              label: t.driverVerificationRequiredAction,
              onPressed: () => context.push('/driver/verification'),
            ),
          ],
        ],
      ),
    );
  }
}
