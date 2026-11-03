import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../commons/models/area_model.dart';
import '../../commons/models/branch_model.dart';
import '../../commons/models/country_model.dart';
import '../../commons/models/customer_model.dart';
import '../../commons/models/localized_text.dart';
import '../../commons/models/notification_model.dart';
import '../../commons/models/offer_model.dart';
import '../../commons/models/order_model.dart';
import '../../commons/models/review_model.dart';
import '../../commons/models/vehicle_model.dart';
import '../../commons/models/wash_service_model.dart';
import '../network/api_call.dart';
import 'connectivity_service.dart';
import 'notification_service.dart';
import 'supabase_service.dart';

class WashUpDbService extends GetxService {
  RealtimeChannel? _notificationsChannel;
  String? _notificationsChannelFor;
  RealtimeChannel? _ordersChannel;
  String? _ordersChannelFor;
  Timer? _resubscribeTimer;
  Worker? _reconnectWorker;

  Future<bool>? _homeFetch;

  /// Where the customer is browsing from (set by SessionService), so the home
  /// fetch loads the washes nearest to them in their country.
  ({double lat, double lng, String country}) Function()? origin;

  // Remote reactive collections
  final countries = <CountryModel>[].obs;
  final areas = <AreaModel>[].obs;

  /// Service categories (exterior, interior…) in their display order.
  final categories = <({String id, LocalizedText name})>[].obs;
  final branches = <BranchModel>[].obs;
  final services = <WashServiceModel>[].obs;
  final offers = <OfferModel>[].obs;
  final reviews = <ReviewModel>[].obs;
  final customers = <CustomerModel>[].obs;
  final vehicles = <VehicleModel>[].obs;
  final orders = <OrderModel>[].obs;
  final notifications = <NotificationModel>[].obs;
  final favorites = <String>{}.obs;
  final complaints = <Map<String, dynamic>>[].obs;

  // Remote synchronization state
  final isSyncing = false.obs;
  final isSynced = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;

  WashUpDbService init() {
    _reconnectWorker = ConnectivityService.maybe?.onReconnect(_onReconnected);
    // Only fetch Home essentials on app startup — never download the entire database at once!
    fetchHomeData();
    return this;
  }

  /// Realtime does not replay changes missed while offline: rejoin the
  /// channels and reload what the home screen and live booking show.
  Future<void> _onReconnected() async {
    dev.log('[WashUpDbService] connection back, resyncing');
    await _resubscribeRealtime();
    await fetchHomeData();
  }

  /// Customer id that rows are stored under for [userId] (auth id or customer id).
  String _customerIdFor(String userId) =>
      (customerById(userId) ?? customers.firstWhereOrNull((c) => c.userId == userId))?.id ?? userId;

  static List<T> _rows<T>(dynamic res, T Function(Map<String, dynamic>) fromJson) =>
      (res as List).map((e) => fromJson(Map<String, dynamic>.from(e as Map))).toList();

  void upsertBranches(List<BranchModel> newBranches) {
    for (final b in newBranches) {
      final index = branches.indexWhere((existing) => existing.id == b.id);
      if (index >= 0) {
        branches[index] = b;
      } else {
        branches.add(b);
      }
    }
  }

  void upsertServices(List<WashServiceModel> newServices) {
    for (final s in newServices) {
      final index = services.indexWhere((existing) => existing.id == s.id);
      if (index >= 0) {
        services[index] = s;
      } else {
        services.add(s);
      }
    }
  }

  void upsertReviews(List<ReviewModel> newReviews) {
    for (final r in newReviews) {
      final index = reviews.indexWhere((existing) => existing.id == r.id);
      if (index >= 0) {
        reviews[index] = r;
      } else {
        reviews.add(r);
      }
    }
  }

  void upsertOrders(List<OrderModel> newOrders) {
    for (final o in newOrders) {
      final index = orders.indexWhere((existing) => existing.id == o.id);
      if (index >= 0) {
        orders[index] = o;
      } else {
        orders.add(o);
      }
    }
  }

  // Safe entity accessors with null/empty fallbacks
  BranchModel? branch(String id) => branches.firstWhereOrNull((b) => b.id == id);

  AreaModel? area(String? id) => id == null ? null : areas.firstWhereOrNull((a) => a.id == id);

  CountryModel country(String? code) =>
      countries.firstWhereOrNull((c) => c.code == code) ?? (code == 'EG' || code == null ? CountryModel.egypt : _unknownCountry(code));

  /// A country the table does not list yet: Egypt's money and time are wrong
  /// for it, but it still gets its own code so nothing is shown under Egypt.
  CountryModel _unknownCountry(String code) => CountryModel(
        code: code,
        name: LocalizedText(code, code),
        currency: CountryModel.egypt.currency,
        currencySymbol: CountryModel.egypt.currencySymbol,
        currencyDecimals: 2,
        timezone: CountryModel.egypt.timezone,
        lat: CountryModel.egypt.lat,
        lng: CountryModel.egypt.lng,
      );

  /// The branch's country, through its area.
  CountryModel countryOfBranch(String? branchId) {
    final b = branchId == null ? null : branch(branchId);
    return country(area(b?.areaId)?.countryCode);
  }

  /// A category's name from the database, or the built-in one while it loads.
  String categoryName(String id) => categories.firstWhereOrNull((c) => c.id == id)?.name.value ?? 'cat.$id'.tr;

  List<AreaModel> areasIn(String countryCode) => areas.where((a) => a.countryCode == countryCode).toList();

  /// Countries that have at least one area, for the area picker.
  List<CountryModel> get servedCountries {
    final codes = areas.map((a) => a.countryCode).toSet();
    return countries.where((c) => codes.contains(c.code)).toList();
  }

  WashServiceModel? service(String id) => services.firstWhereOrNull((s) => s.id == id);

  OrderModel? order(String id) => orders.firstWhereOrNull((o) => o.id == id);

  VehicleModel? vehicle(String id) => vehicles.firstWhereOrNull((v) => v.id == id);

  CustomerModel? customerByPhone(String phone) =>
      customers.firstWhereOrNull((c) => c.phone == phone);

  CustomerModel? customerById(String? id) =>
      id == null ? null : customers.firstWhereOrNull((c) => c.id == id);

  List<WashServiceModel> servicesFor(String branchId) =>
      services.where((s) => s.branchId == branchId && s.active).toList();

  List<ReviewModel> reviewsFor(String branchId) =>
      reviews.where((r) => r.branchId == branchId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  ({double rating, int count}) ratingFor(String branchId) {
    final list = reviews.where((r) => r.branchId == branchId).toList();
    if (list.isEmpty) return (rating: 0, count: 0);
    final avg = list.fold<int>(0, (s, r) => s + r.stars) / list.length;
    return (rating: avg, count: list.length);
  }

  // Complaint ticket generator (order numbers and codes come from the server)
  static int _ticketCounter = 0;
  String nextTicket() {
    final seq = ++_ticketCounter;
    final now = DateTime.now().microsecondsSinceEpoch;
    return 'TK-${now % 10000000}$seq';
  }

    // Tickets are generated with unique timestamp sequence via nextTicket()

  /// 1. Home Page startup fetch: lightweight call loading ONLY areas, active offers (limit 6),
  /// and top branches (limit 10) for the user's selected area.
  /// Concurrent calls for the same area share one request (splash + service init).
  Future<bool> fetchHomeData() {
    final inFlight = _homeFetch;
    if (inFlight != null) return inFlight;
    final fetch = _fetchHomeData();
    _homeFetch = fetch;
    fetch.whenComplete(() {
      if (identical(_homeFetch, fetch)) _homeFetch = null;
    });
    return fetch;
  }

  Future<bool> _fetchHomeData() async {
    try {
      isSyncing.value = true;
      hasError.value = false;
      errorMessage.value = '';
      final client = SupabaseService.client;

      final catalogResults = await Future.wait<dynamic>([
        ApiCall.read(() => client.from('areas').select().eq('active', true).order('sort_order'), tag: 'areas'),
        ApiCall.read(() => client.from('countries').select().eq('active', true).order('sort_order'), tag: 'countries'),
        ApiCall.read(() => client.from('service_categories').select('id, name').order('id'), tag: 'categories'),
        ApiCall.read(() => client.from('offers').select('*, offer_branches(branch_id)').limit(8), tag: 'offers'),
      ]);

      areas.assignAll(_rows(catalogResults[0], AreaModel.fromJson));
      countries.assignAll(_rows(catalogResults[1], CountryModel.fromJson));
      categories.assignAll([
        for (final r in catalogResults[2] as List)
          (id: (r as Map)['id'].toString(), name: LocalizedText.fromJson(r['name'])),
      ]..sort((a, b) => _categoryOrder(a.id).compareTo(_categoryOrder(b.id))));
      offers.assignAll(_rows(catalogResults[3], OfferModel.fromJson));

      // The nearest washes in the customer's country; any 20 before a position is known.
      final from = origin?.call();
      if (from != null) {
        await discover(lat: from.lat, lng: from.lng, country: from.country, limit: 20, throwOnError: true);
      } else {
        final res = await ApiCall.read(() => client.from('branches').select().eq('active', true).limit(20), tag: 'home branches');
        final list = _rows(res, BranchModel.fromJson);
        upsertBranches(list);
        await _fetchPrimaryServices(list.map((b) => b.id).toList());
      }

      // Authenticated user active order lookup only
      final currentUser = client.auth.currentUser;
      if (currentUser != null) {
        try {
          String? customerId;
          final custRes = await ApiCall.read(
            () => client.from('customers').select().eq('user_id', currentUser.id).limit(1),
            tag: 'home customer',
          );
          if (custRes.isNotEmpty) {
            final cust = CustomerModel.fromJson(Map<String, dynamic>.from(custRes.first as Map));
            final idx = customers.indexWhere((c) => c.id == cust.id);
            if (idx >= 0) {
              customers[idx] = cust;
            } else {
              customers.add(cust);
            }
            customerId = cust.id;
            fetchVehicles(cust.id);
          }
          final lookupId = customerId ?? currentUser.id;
          final orderRes = await ApiCall.read(
            () => client
                .from('orders')
                .select('*, order_items(*), order_events(*)')
                .eq('customer_id', lookupId)
                .order('scheduled_at', ascending: false)
                .limit(5),
            tag: 'home orders',
          );
          upsertOrders(_rows(orderRes, OrderModel.fromJson));

          await fetchNotifications(lookupId);
          subscribeToCustomerNotifications(lookupId);
          subscribeToCustomerOrders(lookupId);
        } catch (e) {
          // The catalog loaded; the user's part retries on the next refresh or reconnect.
          dev.log('[WashUpDbService] fetchHomeData user data error: $e');
        }
      }

      isSynced.value = true;
      return true;
    } catch (e) {
      dev.log('[WashUpDbService] fetchHomeData error: $e');
      hasError.value = true;
      errorMessage.value = ApiException.messageFor(e);
      return false;
    } finally {
      isSyncing.value = false;
    }
  }

  /// Washes around a point, nearest first (the discover_branches RPC). Each
  /// row carries its distance and lowest primary price; the branches and
  /// their primary services are cached for the screens that list them.
  Future<List<({BranchModel branch, double km, num? fromPrice})>> discover({
    required double lat,
    required double lng,
    String? country,
    String? category,
    String? query,
    double? maxKm,
    int limit = 20,
    int offset = 0,
    bool throwOnError = false,
  }) async {
    try {
      final res = await ApiCall.read(
        () => SupabaseService.client.rpc('discover_branches', params: {
          'p_lat': lat,
          'p_lng': lng,
          'p_country': country,
          'p_category': category,
          'p_query': (query?.trim().isEmpty ?? true) ? null : query!.trim(),
          'p_max_km': maxKm,
          'p_limit': limit,
          'p_offset': offset,
        }),
        tag: 'discover branches',
      );
      final rows = [
        for (final r in res as List)
          (
            branch: BranchModel.fromJson(Map<String, dynamic>.from((r as Map)['branch'] as Map)),
            km: (r['km'] as num).toDouble(),
            fromPrice: r['from_price'] as num?,
          ),
      ];
      upsertBranches(rows.map((r) => r.branch).toList());
      await _fetchPrimaryServices(rows.map((r) => r.branch.id).toList());
      return rows;
    } catch (e) {
      dev.log('[WashUpDbService] discover error: $e');
      if (throwOnError) rethrow;
      return const [];
    }
  }

  static const _knownCategoryOrder = ['exterior', 'interior', 'full', 'deep'];

  /// The four first categories keep the order the home screen always had.
  static int _categoryOrder(String id) {
    final i = _knownCategoryOrder.indexOf(id);
    return i < 0 ? 100 : i;
  }

  /// Primary services of [branchIds] not loaded yet, so their prices show.
  Future<void> _fetchPrimaryServices(List<String> branchIds) async {
    final missing = branchIds.where((id) => !services.any((s) => s.branchId == id)).toList();
    if (missing.isEmpty) return;
    final res = await ApiCall.read(
      () => SupabaseService.client.from('services').select().inFilter('branch_id', missing).eq('type', 'primary'),
      tag: 'primary services',
    );
    upsertServices(_rows(res, WashServiceModel.fromJson));
  }

  /// Wash Details Page fetch: loads single branch info, its specific services, and recent reviews.
  /// On failure returns the cached branch (if any), or rethrows with [throwOnError].
  Future<BranchModel?> fetchBranchDetails(String branchId, {bool throwOnError = false}) async {
    try {
      final client = SupabaseService.client;
      final results = await Future.wait<dynamic>([
        ApiCall.read(() => client.from('branches').select().eq('id', branchId).maybeSingle(), tag: 'branch'),
        ApiCall.read(() => client.from('services').select().eq('branch_id', branchId), tag: 'branch services'),
        ApiCall.read(
          () => client.from('reviews').select().eq('branch_id', branchId).order('created_at', ascending: false).limit(25),
          tag: 'branch reviews',
        ),
      ]);

      if (results[0] != null) {
        final b = BranchModel.fromJson(Map<String, dynamic>.from(results[0] as Map));
        upsertBranches([b]);
      }
      if (results[1] is List) {
        upsertServices(_rows(results[1], WashServiceModel.fromJson));
      }
      if (results[2] is List) {
        upsertReviews(_rows(results[2], ReviewModel.fromJson));
      }

      return branch(branchId);
    } catch (e) {
      dev.log('[WashUpDbService] fetchBranchDetails error: $e');
      if (throwOnError) rethrow;
      return branch(branchId);
    }
  }

  /// 5. Bookings Page fetch: loads user's bookings with pagination (.range).
  Future<List<OrderModel>> fetchUserBookings({
    required String userId,
    int page = 0,
    int pageSize = 15,
    bool throwOnError = false,
  }) async {
    try {
      final effectiveCustId = _customerIdFor(userId);
      final from = page * pageSize;
      final to = from + pageSize - 1;

      final res = await ApiCall.read(
        () => SupabaseService.client
            .from('orders')
            .select('*, order_items(*), order_events(*)')
            .eq('customer_id', effectiveCustId)
            .order('scheduled_at', ascending: false)
            .range(from, to),
        tag: 'bookings page $page',
      );

      final list = _rows(res, OrderModel.fromJson);
      upsertOrders(list);
      return list;
    } catch (e) {
      dev.log('[WashUpDbService] fetchUserBookings error: $e');
      if (throwOnError) rethrow;
      return [];
    }
  }

  /// Alias for backward compatibility that delegates to fetchHomeData
  Future<bool> fetchFromSupabase() => fetchHomeData();

  /// Load favorites for specific user from Supabase.
  Future<void> loadFavorites(String userId) async {
    try {
      final effectiveCustId = _customerIdFor(userId);
      final res = await ApiCall.read(
        () => SupabaseService.client.from('customer_favorites').select('branch_id').eq('customer_id', effectiveCustId),
        tag: 'favorites',
      );
      final set = (res as List).map((e) => e['branch_id'].toString()).toSet();
      favorites.assignAll(set);
    } catch (e) {
      dev.log('[WashUpDbService] Error loading favorites from Supabase: $e');
    }
  }

  /// Load vehicles for specific user from Supabase.
  Future<List<VehicleModel>> fetchVehicles(String userId) async {
    try {
      final effectiveCustId = _customerIdFor(userId);
      final res = await ApiCall.read(
        () => SupabaseService.client
            .from('vehicles')
            .select()
            .eq('customer_id', effectiveCustId)
            .order('created_at', ascending: true),
        tag: 'vehicles',
      );

      final list = _rows(res, VehicleModel.fromJson);
      vehicles.removeWhere((v) => v.customerId == effectiveCustId);
      vehicles.addAll(list);
      return list;
    } catch (e) {
      dev.log('[WashUpDbService] Error fetching vehicles from Supabase: $e');
      return [];
    }
  }

  /// Toggle favorite on branch for user in Supabase. The change shows at once
  /// and is undone when the server call fails; returns whether it was saved.
  Future<bool> toggleFavorite(String branchId, String userId) async {
    final effectiveCustId = _customerIdFor(userId);
    final client = SupabaseService.client;
    final removing = favorites.contains(branchId);

    if (removing) {
      favorites.remove(branchId);
    } else {
      favorites.add(branchId);
    }
    try {
      if (removing) {
        await ApiCall.write(
          () => client.from('customer_favorites').delete().eq('customer_id', effectiveCustId).eq('branch_id', branchId),
          tag: 'remove favorite',
        );
      } else {
        await ApiCall.write(
          () => client.from('customer_favorites').upsert(
            {
              'customer_id': effectiveCustId,
              'branch_id': branchId,
            },
            onConflict: 'customer_id,branch_id',
            ignoreDuplicates: true,
          ),
          tag: 'add favorite',
        );
      }
      return true;
    } catch (e) {
      dev.log('[WashUpDbService] Error toggling favorite in Supabase: $e');
      if (removing) {
        favorites.add(branchId);
      } else {
        favorites.remove(branchId);
      }
      return false;
    }
  }

  /// Migrates any favorites recorded under guest ID to target user ID
  Future<void> migrateGuestFavorites(String guestId, String targetUserId) async {
    if (guestId == targetUserId || favorites.isEmpty) return;
    try {
      final effectiveTargetId = _customerIdFor(targetUserId);
      final rows = favorites.map((bid) => {'customer_id': effectiveTargetId, 'branch_id': bid}).toList();
      await ApiCall.write(
        () => SupabaseService.client.from('customer_favorites').upsert(
              rows,
              onConflict: 'customer_id,branch_id',
              ignoreDuplicates: true,
            ),
        tag: 'migrate favorites',
      );
    } catch (e) {
      dev.log('[WashUpDbService] Error migrating guest favorites: $e');
    }
  }

  // Remote Write Operations (orders go through OrderService RPCs)
  /// Throws [ApiException] on a connection failure, or the server's error.
  Future<void> saveVehicle(VehicleModel vehicle) async {
    try {
      final client = SupabaseService.client;
      if (vehicle.isDefault) {
        // Ensure at most one default vehicle exists by unsetting others first
        await ApiCall.write(
          () => client
              .from('vehicles')
              .update({'is_default': false})
              .eq('customer_id', vehicle.customerId)
              .neq('id', vehicle.id),
          tag: 'unset default vehicle',
        );
      }
      await ApiCall.write(() => client.from('vehicles').upsert(vehicle.toJson()), tag: 'save vehicle');
    } catch (e) {
      dev.log('[WashUpDbService] Error saving vehicle to Supabase: $e');
      rethrow;
    }
  }

  /// Returns whether the server deleted it.
  Future<bool> deleteVehicle(String id) async {
    try {
      await ApiCall.write(
        () => SupabaseService.client.from('vehicles').delete().eq('id', id),
        tag: 'delete vehicle',
      );
      return true;
    } catch (e) {
      dev.log('[WashUpDbService] Error deleting vehicle from Supabase: $e');
      return false;
    }
  }

  /// Throws when the review was not saved, so the screen does not claim it was.
  Future<void> saveReview(ReviewModel review) async {
    await ApiCall.write(() => SupabaseService.client.from('reviews').upsert(review.toJson()), tag: 'save review');
  }

  /// Every review the customer wrote, so the rate prompts (home, notifications,
  /// booking details) skip visits that are already rated.
  Future<void> fetchMyReviews(String customerId) async {
    try {
      final rows = await ApiCall.read(
        () => SupabaseService.client.from('reviews').select().eq('customer_id', customerId),
        tag: 'my reviews',
      );
      upsertReviews(_rows(rows, ReviewModel.fromJson));
    } catch (e) {
      dev.log('[WashUpDbService] Error loading the customer reviews: $e');
    }
  }

  /// The customer's review of [orderId], if any: only branch reviews are cached
  /// otherwise, so a booking reopened later would offer to rate it again.
  Future<void> fetchOrderReview(String orderId) async {
    try {
      final rows = await ApiCall.read(
        () => SupabaseService.client.from('reviews').select().eq('order_id', orderId).limit(1),
        tag: 'order review',
      );
      upsertReviews(_rows(rows, ReviewModel.fromJson));
    } catch (e) {
      dev.log('[WashUpDbService] Error loading the order review: $e');
    }
  }

  Future<void> saveCustomer(CustomerModel customer) async {
    try {
      await ApiCall.write(() => SupabaseService.client.from('customers').upsert(customer.toJson()), tag: 'save customer');
    } catch (e) {
      dev.log('[WashUpDbService] Error saving customer to Supabase: $e');
    }
  }

  Future<void> updateCustomerToken(String customerId, String? token) async {
    try {
      final cust = customerById(customerId);
      if (cust != null) {
        cust.accessToken = token;
        cust.tokenUpdatedAt = DateTime.now();
        customers.refresh();
      }

      final authUser = SupabaseService.client.auth.currentUser;
      if (authUser != null) {
        // Only store real device push tokens (never Supabase JWTs which start with 'eyJ')
        if (token != null && token.isNotEmpty && !token.startsWith('eyJ')) {
          final platformStr = GetPlatform.isIOS ? 'ios' : 'android';
          await ApiCall.write(
            () => SupabaseService.client.from('push_devices').upsert(
              {
                'user_id': authUser.id,
                'app': 'customer',
                'platform': platformStr,
                'token': token,
                'last_seen_at': DateTime.now().toUtc().toIso8601String(),
              },
              onConflict: 'token',
            ),
            tag: 'save push device',
          );
        } else if (token == null) {
          await ApiCall.write(
            () => SupabaseService.client.from('push_devices').delete().eq('user_id', authUser.id),
            tag: 'remove push device',
          );
        }
      }
    } catch (e) {
      dev.log('[WashUpDbService] Error updating customer push device in Supabase: $e');
    }
  }

  /// Tells the server this device shows [orderId] in its live booking widget,
  /// so status changes are pushed to the widget while the app is closed.
  Future<bool> followLiveBooking({
    required String orderId,
    required String fcmToken,
    String? activityToken,
    required String locale,
  }) async {
    try {
      await ApiCall.write(
        () => SupabaseService.client.from('live_booking_devices').upsert(
          {
            'order_id': orderId,
            'platform': GetPlatform.isIOS ? 'ios' : 'android',
            'fcm_token': fcmToken,
            'activity_token': activityToken,
            'locale': locale,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          },
          onConflict: 'order_id,fcm_token',
        ),
        tag: 'follow live booking',
      );
      return true;
    } catch (e) {
      dev.log('[WashUpDbService] followLiveBooking error: $e');
      return false;
    }
  }

  Future<void> unfollowLiveBooking(String orderId, String fcmToken) async {
    try {
      await ApiCall.write(
        () => SupabaseService.client
            .from('live_booking_devices')
            .delete()
            .eq('order_id', orderId)
            .eq('fcm_token', fcmToken),
        tag: 'unfollow live booking',
      );
    } catch (e) {
      dev.log('[WashUpDbService] unfollowLiveBooking error: $e');
    }
  }

  Future<void> markNotificationRead(String notifId) async {
    try {
      await ApiCall.write(
        () => SupabaseService.client.from('customer_notifications').update({'read': true}).eq('id', notifId),
        tag: 'mark notification read',
      );
    } catch (e) {
      dev.log('[WashUpDbService] Error updating notification in Supabase: $e');
    }
  }

  Future<void> markAllNotificationsRead(String userId) async {
    try {
      final effectiveCustId = _customerIdFor(userId);
      await ApiCall.write(
        () => SupabaseService.client
            .from('customer_notifications')
            .update({'read': true})
            .eq('customer_id', effectiveCustId),
        tag: 'mark all notifications read',
      );
    } catch (e) {
      dev.log('[WashUpDbService] Error updating all notifications in Supabase: $e');
    }
  }

  Future<void> saveComplaint(Map<String, dynamic> complaint) async {
    try {
      await ApiCall.write(() => SupabaseService.client.from('complaints').upsert(complaint), tag: 'save complaint');
    } catch (e) {
      dev.log('[WashUpDbService] Error saving complaint to Supabase: $e');
    }
  }

  CustomerModel registerCustomer(String authId, String phone, String name) {
    final row = CustomerModel(id: authId, name: name, phone: phone);
    customers.add(row);
    saveCustomer(row);
    return row;
  }

  Future<List<NotificationModel>> fetchNotifications(String customerId, {bool throwOnError = false}) async {
    try {
      final res = await ApiCall.read(
        () => SupabaseService.client
            .from('customer_notifications')
            .select()
            .eq('customer_id', customerId)
            .order('created_at', ascending: false)
            .limit(50),
        tag: 'notifications',
      );
      final list = _rows(res, NotificationModel.fromJson);
      notifications.assignAll(list);
      return list;
    } catch (e) {
      dev.log('[WashUpDbService] fetchNotifications error: $e');
      if (throwOnError) rethrow;
      return [];
    }
  }

  /// Order changes made by the wash (vendor dashboard) arrive live, so the
  /// bookings screens and the live booking widget follow without a refresh.
  void subscribeToCustomerOrders(String customerId) {
    if (_ordersChannelFor == customerId && _ordersChannel != null) return;
    _removeChannel(_ordersChannel);
    _ordersChannel = null;
    _ordersChannelFor = customerId;
    try {
      _ordersChannel = SupabaseService.client
          .channel('public:orders:$customerId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'orders',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'customer_id',
              value: customerId,
            ),
            callback: (payload) {
              final id = (payload.newRecord['id'] ?? payload.oldRecord['id'])?.toString();
              if (id == null) return;
              if (payload.eventType == PostgresChangeEvent.delete) {
                orders.removeWhere((o) => o.id == id);
              } else {
                refreshOrder(id);
              }
            },
          )
          .subscribe((status, error) => _onChannelStatus('orders', status, error));
    } catch (e) {
      dev.log('[WashUpDbService] subscribeToCustomerOrders error: $e');
    }
  }

  /// Reloads one order with its items and status history.
  Future<void> refreshOrder(String orderId, {bool throwOnError = false}) async {
    try {
      final res = await ApiCall.read(
        () => SupabaseService.client
            .from('orders')
            .select('*, order_items(*), order_events(*)')
            .eq('id', orderId)
            .order('at', referencedTable: 'order_events')
            .maybeSingle(),
        tag: 'order',
      );
      if (res == null) return;
      upsertOrders([OrderModel.fromJson(Map<String, dynamic>.from(res))]);
      orders.refresh();
    } catch (e) {
      dev.log('[WashUpDbService] refreshOrder error: $e');
      if (throwOnError) rethrow;
    }
  }

  void subscribeToCustomerNotifications(String customerId) {
    if (_notificationsChannelFor == customerId && _notificationsChannel != null) return;
    _removeChannel(_notificationsChannel);
    _notificationsChannel = null;
    _notificationsChannelFor = customerId;
    try {
      _notificationsChannel = SupabaseService.client
          .channel('public:customer_notifications:$customerId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'customer_notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'customer_id',
              value: customerId,
            ),
            callback: (payload) {
              try {
                final newRecord = payload.newRecord;
                final notif = NotificationModel.fromJson(newRecord);
                if (!notifications.any((n) => n.id == notif.id)) {
                  notifications.insert(0, notif);
                  if (Get.isRegistered<NotificationService>()) {
                    final isArabic = Get.locale?.languageCode == 'ar';
                    NotificationService.to.showLocalNotification(
                      title: isArabic ? notif.title.ar : notif.title.en,
                      body: isArabic ? notif.body.ar : notif.body.en,
                      payload: jsonEncode({'order_id': notif.orderId, 'type': notif.type}),
                    );
                  }
                }
              } catch (e) {
                dev.log('[WashUpDbService] Realtime notification parse error: $e');
              }
            },
          )
          .subscribe((status, error) => _onChannelStatus('notifications', status, error));
    } catch (e) {
      dev.log('[WashUpDbService] subscribeToCustomerNotifications error: $e');
    }
  }

  /// The realtime client rejoins on its own after short drops. A channel that
  /// still errors while we are online is rebuilt after a pause; offline, the
  /// reconnect handler rebuilds it.
  void _onChannelStatus(String name, RealtimeSubscribeStatus status, Object? error) {
    dev.log('[WashUpDbService] $name channel: ${status.name}${error == null ? '' : ' ($error)'}');
    if (status != RealtimeSubscribeStatus.channelError && status != RealtimeSubscribeStatus.timedOut) return;
    if (!ConnectivityService.online) return;
    _resubscribeTimer?.cancel();
    _resubscribeTimer = Timer(const Duration(seconds: 10), () {
      if (ConnectivityService.online) _resubscribeRealtime();
    });
  }

  Future<void> _resubscribeRealtime() async {
    _resubscribeTimer?.cancel();
    final ordersFor = _ordersChannelFor;
    final notificationsFor = _notificationsChannelFor;
    final stale = [_ordersChannel, _notificationsChannel];
    _ordersChannel = null;
    _notificationsChannel = null;
    // Leave the old topics first: a leave sent after the new join would close it.
    await Future.wait(stale.map(_removeChannel));
    if (ordersFor != null && _ordersChannel == null) subscribeToCustomerOrders(ordersFor);
    if (notificationsFor != null && _notificationsChannel == null) {
      subscribeToCustomerNotifications(notificationsFor);
    }
  }

  Future<void> _removeChannel(RealtimeChannel? channel) async {
    if (channel == null) return;
    try {
      await SupabaseService.client.removeChannel(channel).timeout(const Duration(seconds: 5));
    } catch (e) {
      dev.log('[WashUpDbService] removeChannel error: $e');
    }
  }

  /// Local-only notification (list + banner). Real notifications are created
  /// on the server (customer_notifications) and arrive through realtime / push.
  void notify({
    required String userId,
    required String type,
    required LocalizedText title,
    required LocalizedText body,
    String? orderId,
  }) {
    final notif = NotificationModel(
      id: 'cn_${DateTime.now().microsecondsSinceEpoch}',
      userId: userId,
      type: type,
      title: title,
      body: body,
      orderId: orderId,
      createdAt: DateTime.now(),
    );
    notifications.insert(0, notif);

    try {
      if (Get.isRegistered<NotificationService>()) {
        final isArabic = Get.locale?.languageCode == 'ar';
        NotificationService.to.showLocalNotification(
          title: isArabic ? title.ar : title.en,
          body: isArabic ? body.ar : body.en,
          payload: jsonEncode({'order_id': orderId, 'type': type}),
        );
      }
    } catch (e) {
      dev.log('[WashUpDbService] Local notification alert error: $e');
    }
  }

  @override
  void onClose() {
    _reconnectWorker?.dispose();
    _resubscribeTimer?.cancel();
    _removeChannel(_notificationsChannel);
    _removeChannel(_ordersChannel);
    super.onClose();
  }
}
