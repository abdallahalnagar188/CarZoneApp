enum RequestMethod { get, post, put, delete, patch }

enum CacheKeys {
  onboarded,
  loggedIn,
  language,
  theme,
  userToken,
  userId,
  name,
  mobile,
  areaId,
  recentSearches,
  notifReminders,
  notifOffers,
  guestUserId,
}

enum AppLanguages { ar, en }

enum TosterTypes { warning, sucsses, failed }

enum OrderStatus {
  pending,
  confirmed,
  waiting,
  inService,
  completed,
  cancelled,
  noShow;

  String get key => switch (this) {
        OrderStatus.inService => 'in_service',
        OrderStatus.noShow => 'no_show',
        _ => name,
      };

  bool get isUpcoming => const [
        OrderStatus.pending,
        OrderStatus.confirmed,
        OrderStatus.waiting,
        OrderStatus.inService,
      ].contains(this);

  bool get canCancel =>
      this == OrderStatus.pending || this == OrderStatus.confirmed;
}

enum PaymentStatus { pending, paid, refunded }

enum ServiceType { primary, addon }

enum SortMode { nearest, rated, price, earliest }

enum DiscountType { percent, fixed }
