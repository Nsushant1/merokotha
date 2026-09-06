class AppRoutes {
  AppRoutes._();

  // Landing (public — no login required)
  static const landing = '/';

  // Auth
  static const splash = '/splash';
  static const login = '/login';
  static const roleSelect = '/role-select';
  static const onboarding = '/onboarding';

  // Owner
  static const ownerHome = '/owner/home';
  static const uploadListing = '/owner/upload';
  static const myListings = '/owner/listings';
  static const ownerInquiries = '/owner/inquiries';
  static const ownerMap = '/owner/map';
  static const ownerProfile = '/owner/profile';

  // Customer
  static const customerHome = '/customer/home';
  static const search = '/customer/search';
  static const customerMap = '/customer/map';
  static const roomDetail = '/customer/room/:id';
  static const favourites = '/customer/favourites';
  static const inquire = '/customer/inquire/:id';
  static const customerProfile = '/customer/profile';

  // Shared
  static const chatList = '/chat';
  static const chatThread = '/chat/:chatId';

  // Super admin
  static const adminHome = '/admin/home';
  static const adminUsers = '/admin/users';
  static const adminUserDetail = '/admin/users/:uid';
  static const adminListings = '/admin/listings';
  static const adminInquiries = '/admin/inquiries';
}
