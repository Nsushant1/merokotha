class AppRoutes {
  AppRoutes._();

  // Landing (public — no login required)
  static const landing = '/';

  // Auth
  static const splash = '/splash';
  static const login = '/login';
  static const onboarding = '/onboarding';

  // Shared home + profile — one account browses and posts, no roles.
  static const home = '/home';
  static const profile = '/profile';
  static const myInquiries = '/my-inquiries';
  static const applyAgent = '/apply-agent';

  // Owner capabilities (paths kept stable; open to every signed-in user)
  static const uploadListing = '/owner/upload';
  static const myListings = '/owner/listings';
  static const ownerInquiries = '/owner/inquiries';
  static const ownerMap = '/owner/map';

  // Customer capabilities
  static const search = '/customer/search';
  static const customerMap = '/customer/map';
  static const roomDetail = '/customer/room/:id';
  static const favourites = '/customer/favourites';
  static const inquire = '/customer/inquire/:id';

  // Agent (separate interface, requires approved application)
  static const agentHome = '/agent/home';
  static const agentUpload = '/agent/upload';
  static const agentListings = '/agent/listings';
  static const agentInquiries = '/agent/inquiries';
  static const agentProfile = '/agent/profile';

  // Shared
  static const chatList = '/chat';
  static const chatThread = '/chat/:chatId';

  // Super admin
  static const adminHome = '/admin/home';
  static const adminUsers = '/admin/users';
  static const adminUserDetail = '/admin/users/:uid';
  static const adminListings = '/admin/listings';
  static const adminInquiries = '/admin/inquiries';
  static const adminAds = '/admin/ads';
  static const adminAdForm = '/admin/ads/form';
}
