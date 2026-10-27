import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/i18n/localization.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/notification/notification_providers.dart';

class MeroKothaApp extends ConsumerWidget {
  const MeroKothaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final localeCode = ref.watch(localeProvider);

    // Keeps the FCM coordinator alive for the session: it registers/refreshes
    // the device token once a user is signed in and routes notification taps
    // into the right conversation.
    ref.watch(notificationCoordinatorProvider);

    // Apply the language stored on the user document after sign-in.
    ref.listen(currentUserProvider, (_, next) {
      ref.read(localeProvider.notifier).applyRemote(next.asData?.value?.locale);
    });

    return MaterialApp.router(
      title: 'MeroKotha',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: Locale(localeCode),
      routerConfig: router,
    );
  }
}
