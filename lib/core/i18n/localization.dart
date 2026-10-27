import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:merokotha/features/auth/data/user_repository.dart';
import 'package:merokotha/features/auth/providers/auth_provider.dart';

/// English/Nepali string tables. Missing keys fall back to English, and a
/// missing English entry falls back to the key itself — the app never
/// renders a blank because of localization.
class L {
  L._();

  static const supported = ['en', 'ne'];

  static String t(String locale, String key) =>
      _values[locale]?[key] ?? _values['en']![key] ?? key;

  static const _values = <String, Map<String, String>>{
    'en': {
      // Bottom nav
      'nav_home': 'Home',
      'nav_saved': 'Saved',
      'nav_listings': 'Listings',
      'nav_messages': 'Messages',
      'nav_inbox': 'Inbox',
      'nav_profile': 'Profile',
      // Common
      'common_search': 'Search',
      'common_filter': 'Filter',
      'common_filters': 'Filters',
      'common_apply': 'Apply',
      'common_reset': 'Reset',
      'common_save': 'Save',
      'common_cancel': 'Cancel',
      'common_delete': 'Delete',
      'common_edit': 'Edit',
      'common_close': 'Close',
      'common_retry': 'Retry',
      'common_clear': 'Clear',
      'common_done': 'Done',
      'common_all': 'All',
      'common_optional': 'optional',
      // Auth / login
      'login_title': 'Welcome to Mero Kotha',
      'login_subtitle':
          'Sign in to list rooms, save favourites, and chat with owners.',
      'login_google': 'Continue with Google',
      'login_email': 'Continue with Email',
      'login_signin': 'Sign In',
      'login_register': 'Create Account',
      'login_password': 'Password',
      'login_forgot': 'Forgot password?',
      'login_reset_sent': 'Password reset email sent. Check your inbox.',
      'login_reset_title': 'Reset password',
      'login_reset_hint': 'Enter your account email to receive a reset link.',
      'login_send_link': 'Send reset link',
      'login_no_account': "Don't have an account? Register",
      'login_have_account': 'Already have an account? Sign in',
      'login_link_google': 'Link Google account',
      'login_link_email': 'Add email sign-in',
      'login_terms': 'By continuing you agree to our Terms & Privacy Policy.',
      // Onboarding
      'onboarding_title': 'Find your\nperfect room',
      'onboarding_subtitle':
          'Tell us a bit about yourself to personalise your experience.',
      'onboarding_details': 'Your details',
      'onboarding_name': 'Full name',
      'onboarding_email': 'Email',
      'onboarding_phone': 'Phone number',
      'onboarding_phone_optional': 'Phone number (optional)',
      'onboarding_location': 'Location',
      'onboarding_continue': 'Continue',
      // Profile
      'profile_member': 'Member',
      'profile_saved_rooms': 'Saved rooms',
      'profile_my_listings': 'My listings',
      'profile_personal_info': 'Personal information',
      'profile_quick_links': 'Quick links',
      'profile_account': 'Account',
      'profile_my_inquiries': 'My inquiries',
      'profile_my_reports': 'My reports',
      'profile_saved_searches': 'Saved searches',
      'profile_find_agent': 'Find an agent',
      'profile_language': 'Language',
      'profile_app_version': 'App version',
      'profile_logout': 'Logout',
      'profile_updated': 'Profile updated',
      'profile_bio': 'Bio',
      'profile_bio_hint': 'Tell renters about yourself...',
      'profile_contact_email': 'Contact email',
      'profile_public_phone': 'Public call number',
      'profile_whatsapp': 'WhatsApp number',
      'profile_hide_name': 'Hide my public name',
      'profile_save_changes': 'Save changes',
      // Home / search
      'home_greeting': 'Hello',
      'home_search_hint': 'Search by location, property type...',
      'home_post_room': 'Have a room to rent?',
      'home_post_room_sub': 'Post it for free and reach seekers.',
      'home_post': 'Post FREE',
      'home_free': 'FREE',
      'home_explore': 'All rooms',
      'home_view_all': 'View All',
      'search_results': 'places found',
      'search_result': 'place found',
      'search_no_results': 'No results found',
      'search_no_results_sub': 'Try different keywords or remove some filters',
      'search_clear_filters': 'Clear filters',
      'search_property_type': 'Property Type',
      'search_price_range': 'Price Range',
      'search_features': 'Features',
      'search_furnishing': 'Furnishing',
      'search_furnished': 'Furnished',
      'search_semi': 'Semi-furnished',
      'search_unfurnished': 'Unfurnished',
      'search_verified_only': 'Verified listings only',
      'search_sort': 'Sort by',
      'search_sort_newest': 'Newest',
      'search_sort_price_asc': 'Price: low to high',
      'search_sort_price_desc': 'Price: high to low',
      'search_sort_viewed': 'Most viewed',
      'search_sort_nearest': 'Nearest',
      'search_nearby': 'Nearby',
      'search_use_location': 'Use my location',
      'search_radius': 'Radius',
      'search_save': 'Save search',
      // Listing
      'listing_verified': 'Verified',
      'listing_pending': 'Pending review',
      'listing_rejected': 'Needs changes',
      'listing_suspended': 'Suspended',
      'listing_deposit': 'Deposit',
      'listing_call': 'Call',
      'listing_whatsapp': 'WhatsApp',
      'listing_report': 'Report listing',
      'listing_listed_by': 'Listed by',
      'listing_owner_hidden': 'Property Owner',
      // Inquiries / chat
      'inbox_pending': 'Pending',
      'inbox_accepted': 'Accepted',
      'inbox_declined': 'Declined',
      // Agents
      'agents_title': 'Verified Agents',
      'agents_subtitle': 'Browse admin-verified agents and their rentals.',
      'agents_search_hint': 'Search agents by name or area...',
      'agents_rentals': 'Active rentals',
      'agents_no_results': 'No agents found',
      // Reports
      'reports_title': 'My reports',
      'reports_empty': 'No reports yet',
      'reports_empty_sub': 'Listings you report will show up here.',
      'report_dialog_title': 'Report this listing',
      'report_category': 'Reason',
      'report_details': 'Details',
      'report_details_hint': 'What is wrong with this listing?',
      'report_submit': 'Submit report',
      'report_submitted': 'Report submitted. Our team will review it.',
      // Admin
      'admin_dashboard': 'Admin Dashboard',
      'admin_pending_listings': 'Pending listings',
      'admin_pending_agents': 'Agent applications',
      'admin_pending_reports': 'Pending reports',
      'admin_reports': 'Reports',
      'admin_history': 'Decision history',
      'admin_analytics': 'Analytics',
      'admin_verify': 'Verify',
      'admin_reject': 'Reject',
      'admin_suspend': 'Suspend',
      'admin_restore': 'Restore',
      'admin_review_reason': 'Review reason (shown to the lister)',
      // Analytics
      'analytics_title': 'Analytics',
      'analytics_visits': 'Visits',
      'analytics_visitors': 'Visitors',
      'analytics_inquiries': 'Inquiries',
      'analytics_accepted': 'Accepted',
      'analytics_trend': 'Last 14 days',
      'analytics_performance': 'Listing performance',
    },
    'ne': {
      'nav_home': 'होम',
      'nav_saved': 'सेभ',
      'nav_listings': 'लिस्टिङ',
      'nav_messages': 'सन्देश',
      'nav_inbox': 'इनबक्स',
      'nav_profile': 'प्रोफाइल',
      'common_search': 'खोज्नुहोस्',
      'common_filter': 'फिल्टर',
      'common_filters': 'फिल्टरहरू',
      'common_apply': 'लागू गर्नुहोस्',
      'common_reset': 'रिसेट',
      'common_save': 'सेभ गर्नुहोस्',
      'common_cancel': 'रद्द गर्नुहोस्',
      'common_delete': 'मेट्नुहोस्',
      'common_edit': 'सम्पादन',
      'common_close': 'बन्द गर्नुहोस्',
      'common_retry': 'पुन: प्रयास',
      'common_clear': 'हटाउनुहोस्',
      'common_done': 'भयो',
      'common_all': 'सबै',
      'common_optional': 'वैकल्पिक',
      'login_title': 'मेरो कोठामा स्वागत छ',
      'login_subtitle':
          'कोठा सूचीबद्ध गर्न, मनपरेका सेभ गर्न र घरबेटीसँग कुरा गर्न साइन इन गर्नुहोस्।',
      'login_google': 'Google बाट जारी राख्नुहोस्',
      'login_email': 'इमेलबाट जारी राख्नुहोस्',
      'login_signin': 'साइन इन',
      'login_register': 'खाता खोल्नुहोस्',
      'login_password': 'पासवर्ड',
      'login_forgot': 'पासवर्ड बिर्सनुभयो?',
      'login_reset_sent': 'पासवर्ड रिसेट इमेल पठाइयो। इनबक्स हेर्नुहोस्।',
      'login_reset_title': 'पासवर्ड रिसेट गर्नुहोस्',
      'login_reset_hint': 'रिसेट लिङ्क पाउन खाताको इमेल लेख्नुहोस्।',
      'login_send_link': 'रिसेट लिङ्क पठाउनुहोस्',
      'login_no_account': 'खाता छैन? दर्ता गर्नुहोस्',
      'login_have_account': 'खाता छ? साइन इन गर्नुहोस्',
      'login_link_google': 'Google खाता जोड्नुहोस्',
      'login_link_email': 'इमेल साइन-इन थप्नुहोस्',
      'login_terms': 'जारी राखेर तपाईं हाम्रा सर्त र गोपनीयता नीतिमा सहमत हुनुहुन्छ।',
      'onboarding_title': 'आफ्नो\nउपयुक्त कोठा खोज्नुहोस्',
      'onboarding_subtitle': 'अनुभव निजीकृत गर्न आफ्नो बारेमा थोरै बताउनुहोस्।',
      'onboarding_details': 'तपाईंका विवरण',
      'onboarding_name': 'पूरा नाम',
      'onboarding_email': 'इमेल',
      'onboarding_phone': 'फोन नम्बर',
      'onboarding_phone_optional': 'फोन नम्बर (वैकल्पिक)',
      'onboarding_location': 'ठेगाना',
      'onboarding_continue': 'जारी राख्नुहोस्',
      'profile_member': 'सदस्य',
      'profile_saved_rooms': 'सेभ गरिएका कोठा',
      'profile_my_listings': 'मेरा लिस्टिङ',
      'profile_personal_info': 'व्यक्तिगत जानकारी',
      'profile_quick_links': 'द्रुत लिङ्कहरू',
      'profile_account': 'खाता',
      'profile_my_inquiries': 'मेरा सोधपुछहरू',
      'profile_my_reports': 'मेरा रिपोर्टहरू',
      'profile_saved_searches': 'सेभ गरिएका खोजहरू',
      'profile_find_agent': 'एजेन्ट खोज्नुहोस्',
      'profile_language': 'भाषा',
      'profile_app_version': 'एप संस्करण',
      'profile_logout': 'लगआउट',
      'profile_updated': 'प्रोफाइल अद्यावधिक भयो',
      'profile_bio': 'बायो',
      'profile_bio_hint': 'आफ्नो बारेमा भाडामा लिनेलाई बताउनुहोस्...',
      'profile_contact_email': 'सम्पर्क इमेल',
      'profile_public_phone': 'सार्वजनिक कल नम्बर',
      'profile_whatsapp': 'व्हाट्सएप नम्बर',
      'profile_hide_name': 'मेरो सार्वजनिक नाम लुकाउनुहोस्',
      'profile_save_changes': 'परिवर्तन सेभ गर्नुहोस्',
      'home_greeting': 'नमस्ते',
      'home_search_hint': 'स्थान, सम्पत्ति प्रकारले खोज्नुहोस्...',
      'home_post_room': 'भाडामा दिने कोठा छ?',
      'home_post_room_sub': 'नि:शुल्क पोस्ट गर्नुहोस् र खोज्नेसम्म पुग्नुहोस्।',
      'home_post': 'नि:शुल्क पोस्ट',
      'home_free': 'नि:शुल्क',
      'home_explore': 'सबै कोठाहरू',
      'home_view_all': 'सबै हेर्नुहोस्',
      'search_results': 'ठाउँ भेटिए',
      'search_result': 'ठाउँ भेटियो',
      'search_no_results': 'कुनै नतिजा भेटिएन',
      'search_no_results_sub': 'फरक शब्द प्रयोग गर्नुहोस् वा फिल्टर हटाउनुहोस्',
      'search_clear_filters': 'फिल्टर हटाउनुहोस्',
      'search_property_type': 'सम्पत्ति प्रकार',
      'search_price_range': 'मूल्य सीमा',
      'search_features': 'सुविधाहरू',
      'search_furnishing': 'फर्निसिङ',
      'search_furnished': 'फर्निस्ड',
      'search_semi': 'सेमी-फर्निस्ड',
      'search_unfurnished': 'अनफर्निस्ड',
      'search_verified_only': 'प्रमाणित लिस्टिङ मात्र',
      'search_sort': 'क्रमबद्ध गर्नुहोस्',
      'search_sort_newest': 'नयाँ पहिले',
      'search_sort_price_asc': 'मूल्य: कमदेखि धेरै',
      'search_sort_price_desc': 'मूल्य: धेरैदेखि कम',
      'search_sort_viewed': 'धेरै हेरिएका',
      'search_sort_nearest': 'नजिकका',
      'search_nearby': 'नजिकै',
      'search_use_location': 'मेरो स्थान प्रयोग गर्नुहोस्',
      'search_radius': 'त्रिज्या',
      'search_save': 'खोज सेभ गर्नुहोस्',
      'listing_verified': 'प्रमाणित',
      'listing_pending': 'समीक्षा बाँकी',
      'listing_rejected': 'सुधार आवश्यक',
      'listing_suspended': 'निलम्बित',
      'listing_deposit': 'धरौटी',
      'listing_call': 'कल गर्नुहोस्',
      'listing_whatsapp': 'व्हाट्सएप',
      'listing_report': 'लिस्टिङ रिपोर्ट गर्नुहोस्',
      'listing_listed_by': 'सूचीबद्ध गर्ने',
      'listing_owner_hidden': 'घरबेटी',
      'inbox_pending': 'बाँकी',
      'inbox_accepted': 'स्वीकृत',
      'inbox_declined': 'अस्वीकृत',
      'agents_title': 'प्रमाणित एजेन्टहरू',
      'agents_subtitle': 'प्रमाणित एजेन्ट र तिनका भाडा हेर्नुहोस्।',
      'agents_search_hint': 'नाम वा क्षेत्रले एजेन्ट खोज्नुहोस्...',
      'agents_rentals': 'सक्रिय भाडाहरू',
      'agents_no_results': 'कुनै एजेन्ट भेटिएनन्',
      'reports_title': 'मेरा रिपोर्टहरू',
      'reports_empty': 'अहिलेसम्म कुनै रिपोर्ट छैन',
      'reports_empty_sub': 'तपाईंले रिपोर्ट गरेका लिस्टिङ यहाँ देखिनेछन्।',
      'report_dialog_title': 'यो लिस्टिङ रिपोर्ट गर्नुहोस्',
      'report_category': 'कारण',
      'report_details': 'विवरण',
      'report_details_hint': 'यो लिस्टिङमा के समस्या छ?',
      'report_submit': 'रिपोर्ट पठाउनुहोस्',
      'report_submitted': 'रिपोर्ट पठाइयो। हाम्रो टोलीले समीक्षा गर्नेछ।',
      'admin_dashboard': 'एडमिन ड्यासबोर्ड',
      'admin_pending_listings': 'बाँकी लिस्टिङ',
      'admin_pending_agents': 'एजेन्ट आवेदन',
      'admin_pending_reports': 'बाँकी रिपोर्ट',
      'admin_reports': 'रिपोर्टहरू',
      'admin_history': 'निर्णय इतिहास',
      'admin_analytics': 'एनालिटिक्स',
      'admin_verify': 'प्रमाणित गर्नुहोस्',
      'admin_reject': 'अस्वीकार गर्नुहोस्',
      'admin_suspend': 'निलम्बन गर्नुहोस्',
      'admin_restore': 'पुनर्स्थापना गर्नुहोस्',
      'admin_review_reason': 'समीक्षा कारण (सूचीकर्तालाई देखिने)',
      'analytics_title': 'एनालिटिक्स',
      'analytics_visits': 'अवलोकन',
      'analytics_visitors': 'अवलोकनकर्ता',
      'analytics_inquiries': 'सोधपुछहरू',
      'analytics_accepted': 'स्वीकृत',
      'analytics_trend': 'पछिल्ला १४ दिन',
      'analytics_performance': 'लिस्टिङ प्रदर्शन',
    },
  };
}

/// App language state ('en' | 'ne'). Persists to `users/{uid}.locale` so the
/// choice follows the account; defaults to the device locale.
class LocaleNotifier extends Notifier<String> {
  LocaleNotifier();

  @override
  String build() => ui.PlatformDispatcher.instance.locale.languageCode == 'ne'
      ? 'ne'
      : 'en';

  /// Apply the locale stored on the user document (called on sign-in).
  void applyRemote(String? code) {
    if (code == null || (code != 'en' && code != 'ne')) return;
    if (state != code) state = code;
  }

  /// Switch language now and persist to the user document (best-effort).
  Future<void> setLocale(String code) async {
    if (code != 'en' && code != 'ne') return;
    state = code;
    try {
      final user = ref.read(authStateProvider).asData?.value;
      if (user != null) {
        await ref.read(userRepositoryProvider).updateUser(user.uid, {
          'locale': code,
        });
      }
    } catch (_) {
      // Local switch already applied; persistence is best-effort.
    }
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, String>(
  LocaleNotifier.new,
);

/// Translate [key] with the current app language.
String tr(WidgetRef ref, String key) => L.t(ref.watch(localeProvider), key);
