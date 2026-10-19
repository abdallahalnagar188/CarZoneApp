import 'dart:developer' as dev;

import 'package:get/get.dart';

import '../../commons/models/area_model.dart';
import '../../commons/models/branch_model.dart';
import '../../commons/models/customer_model.dart';
import '../../commons/models/localized_text.dart';
import '../../commons/models/notification_model.dart';
import '../../commons/models/offer_model.dart';
import '../../commons/models/order_model.dart';
import '../../commons/models/review_model.dart';
import '../../commons/models/vehicle_model.dart';
import '../../commons/models/wash_service_model.dart';
import 'supabase_service.dart';

class CarzoneDbService extends GetxService {
  // Remote reactive collections
  final areas = <AreaModel>[].obs;
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

  int _nextTicket = 501;

  static const AreaModel defaultArea = AreaModel(
    id: 'nasr',
    name: LocalizedText('مدينة نصر', 'Nasr City'),
    lat: 30.0566,
    lng: 31.3301,
  );

  CarzoneDbService init() {
    // Only fetch Home essentials on app startup — never download the entire database at once!
    fetchHomeData();
    return this;
  }

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

  AreaModel area(String id) =>
      areas.firstWhereOrNull((a) => a.id == id) ??
      (areas.isNotEmpty ? areas.first : defaultArea);

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
  String nextTicket() => 'TK-${_nextTicket++}';

  void _initCounters() {
    // Dynamically calculate next complaint ticket
    var maxTicket = 500;
    for (final c in complaints) {
      final ticketStr = c['ticket_number']?.toString() ?? '';
      final parts = ticketStr.split('-');
      if (parts.length == 2) {
        final parsed = int.tryParse(parts[1]);
        if (parsed != null && parsed > maxTicket) {
          maxTicket = parsed;
        }
      }
    }
    _nextTicket = maxTicket + 1;
  }

  /// 1. Home Page startup fetch: lightweight call loading ONLY areas, active offers (limit 6),
  /// and top branches (limit 10) for the user's selected area.
  Future<bool> fetchHomeData({String? areaId}) async {
    try {
      isSyncing.value = true;
      hasError.value = false;
      errorMessage.value = '';
      final client = SupabaseService.client;

      var branchQuery = client.from('branches').select();
      if (areaId != null && areaId.isNotEmpty) {
        branchQuery = branchQuery.eq('area_id', areaId);
      }

      final catalogResults = await Future.wait([
        client.from('areas').select(),
        branchQuery.limit(10),
        client.from('offers').select('*, offer_branches(branch_id)').limit(8),
        client.from('services').select().limit(25),
      ]);

      final remoteAreas = (catalogResults[0] as List)
          .map((e) => AreaModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final remoteBranches = (catalogResults[1] as List)
          .map((e) => BranchModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final remoteOffers = (catalogResults[2] as List)
          .map((e) => OfferModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final remoteServices = (catalogResults[3] as List)
          .map((e) => WashServiceModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      areas.assignAll(remoteAreas);
      offers.assignAll(remoteOffers);
      upsertBranches(remoteBranches);
      upsertServices(remoteServices);

      // Authenticated user active order lookup only
      final currentUser = client.auth.currentUser;
      if (currentUser != null) {
        try {
          final custRes = await client.from('customers').select().eq('user_id', currentUser.id).limit(1);
          if (custRes.isNotEmpty) {
            final cust = CustomerModel.fromJson(Map<String, dynamic>.from(custRes.first as Map));
            final idx = customers.indexWhere((c) => c.id == cust.id);
            if (idx >= 0) {
              customers[idx] = cust;
            } else {
              customers.add(cust);
            }
            fetchVehicles(cust.id);
          }
          final orderRes = await client.from('orders').select().eq('customer_id', currentUser.id).order('scheduled_at', ascending: false).limit(5);
          final remoteOrders = (orderRes as List)
              .map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
          upsertOrders(remoteOrders);
        } catch (_) {}
      }

      _initCounters();
      isSynced.value = true;
      return true;
    } catch (e) {
      dev.log('[CarzoneDbService] fetchHomeData error: $e');
      hasError.value = true;
      errorMessage.value = e.toString();
      return false;
    } finally {
      isSyncing.value = false;
    }
  }

  /// 2. Map Page fetch: called on-demand when user opens the map. Loads branches with coordinates (limit 60).
  Future<List<BranchModel>> fetchMapBranches({String? areaId}) async {
    try {
      final client = SupabaseService.client;
      var query = client.from('branches').select();
      if (areaId != null && areaId.isNotEmpty) {
        query = query.eq('area_id', areaId);
      }
      final res = await query.limit(60);
      final list = (res as List)
          .map((e) => BranchModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      upsertBranches(list);
      return list;
    } catch (e) {
      dev.log('[CarzoneDbService] fetchMapBranches error: $e');
      return [];
    }
  }

  /// 3. Search / Results Page fetch: loads branches page by page using database pagination (.range).
  Future<List<BranchModel>> fetchPaginatedBranches({
    required int page,
    int pageSize = 10,
    String? areaId,
    String? category,
  }) async {
    try {
      final client = SupabaseService.client;
      final from = page * pageSize;
      final to = from + pageSize - 1;

      var query = client.from('branches').select();
      if (areaId != null && areaId.isNotEmpty) {
        query = query.eq('area_id', areaId);
      }
      final res = await query.range(from, to);
      final list = (res as List)
          .map((e) => BranchModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      upsertBranches(list);

      // Fetch primary services for these branches so prices calculate correctly
      if (list.isNotEmpty) {
        final bIds = list.map((b) => b.id).toList();
        final sRes = await client.from('services').select().inFilter('branch_id', bIds).eq('type', 'primary');
        final servicesList = (sRes as List)
            .map((e) => WashServiceModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        upsertServices(servicesList);
      }

      return list;
    } catch (e) {
      dev.log('[CarzoneDbService] fetchPaginatedBranches error: $e');
      return [];
    }
  }

  /// 4. Wash Details Page fetch: loads single branch info, its specific services, and recent reviews.
  Future<BranchModel?> fetchBranchDetails(String branchId) async {
    try {
      final client = SupabaseService.client;
      final results = await Future.wait<dynamic>([
        client.from('branches').select().eq('id', branchId).maybeSingle(),
        client.from('services').select().eq('branch_id', branchId),
        client.from('reviews').select().eq('branch_id', branchId).order('created_at', ascending: false).limit(25),
      ]);

      if (results[0] != null) {
        final b = BranchModel.fromJson(Map<String, dynamic>.from(results[0] as Map));
        upsertBranches([b]);
      }
      if (results[1] is List) {
        final sList = (results[1] as List)
            .map((e) => WashServiceModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        upsertServices(sList);
      }
      if (results[2] is List) {
        final rList = (results[2] as List)
            .map((e) => ReviewModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        upsertReviews(rList);
      }

      return branch(branchId);
    } catch (e) {
      dev.log('[CarzoneDbService] fetchBranchDetails error: $e');
      return branch(branchId);
    }
  }

  /// 5. Bookings Page fetch: loads user's bookings with pagination (.range).
  Future<List<OrderModel>> fetchUserBookings({
    required String userId,
    int page = 0,
    int pageSize = 15,
  }) async {
    try {
      final cust = customerById(userId) ?? customers.firstWhereOrNull((c) => c.userId == userId);
      final effectiveCustId = cust?.id ?? userId;

      final client = SupabaseService.client;
      final from = page * pageSize;
      final to = from + pageSize - 1;

      final res = await client
          .from('orders')
          .select('*, order_items(*)')
          .eq('customer_id', effectiveCustId)
          .order('scheduled_at', ascending: false)
          .range(from, to);

      final list = (res as List)
          .map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      upsertOrders(list);
      return list;
    } catch (e) {
      dev.log('[CarzoneDbService] fetchUserBookings error: $e');
      return [];
    }
  }

  /// Alias for backward compatibility that delegates to fetchHomeData
  Future<bool> fetchFromSupabase() => fetchHomeData();

  /// Load favorites for specific user from Supabase.
  Future<void> loadFavorites(String userId) async {
    try {
      final cust = customerById(userId) ?? customers.firstWhereOrNull((c) => c.userId == userId);
      final effectiveCustId = cust?.id ?? userId;

      final res = await SupabaseService.client
          .from('customer_favorites')
          .select('branch_id')
          .eq('customer_id', effectiveCustId);
      final set = (res as List).map((e) => e['branch_id'].toString()).toSet();
      favorites.assignAll(set);
    } catch (e) {
      dev.log('[CarzoneDbService] Error loading favorites from Supabase: $e');
    }
  }

  /// Load vehicles for specific user from Supabase.
  Future<List<VehicleModel>> fetchVehicles(String userId) async {
    try {
      final cust = customerById(userId) ?? customers.firstWhereOrNull((c) => c.userId == userId);
      final effectiveCustId = cust?.id ?? userId;

      final res = await SupabaseService.client
          .from('vehicles')
          .select()
          .eq('customer_id', effectiveCustId)
          .order('created_at', ascending: true);

      final list = (res as List)
          .map((e) => VehicleModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      vehicles.removeWhere((v) => v.customerId == effectiveCustId);
      vehicles.addAll(list);
      return list;
    } catch (e) {
      dev.log('[CarzoneDbService] Error fetching vehicles from Supabase: $e');
      return [];
    }
  }

  /// Toggle favorite on branch for user in Supabase.
  Future<void> toggleFavorite(String branchId, String userId) async {
    final cust = customerById(userId) ?? customers.firstWhereOrNull((c) => c.userId == userId);
    final effectiveCustId = cust?.id ?? userId;

    if (favorites.contains(branchId)) {
      favorites.remove(branchId);
      try {
        await SupabaseService.client
            .from('customer_favorites')
            .delete()
            .eq('customer_id', effectiveCustId)
            .eq('branch_id', branchId);
      } catch (e) {
        dev.log('[CarzoneDbService] Error deleting favorite from Supabase: $e');
      }
    } else {
      favorites.add(branchId);
      try {
        await SupabaseService.client.from('customer_favorites').upsert(
          {
            'customer_id': effectiveCustId,
            'branch_id': branchId,
          },
          onConflict: 'customer_id,branch_id',
          ignoreDuplicates: true,
        );
      } catch (e) {
        dev.log('[CarzoneDbService] Error inserting favorite to Supabase: $e');
      }
    }
  }

  /// Migrates any favorites recorded under guest ID to target user ID
  Future<void> migrateGuestFavorites(String guestId, String targetUserId) async {
    if (guestId == targetUserId) return;
    try {
      final targetCust = customerById(targetUserId) ?? customers.firstWhereOrNull((c) => c.userId == targetUserId);
      final effectiveTargetId = targetCust?.id ?? targetUserId;

      for (final bid in favorites) {
        await SupabaseService.client.from('customer_favorites').upsert(
          {
            'customer_id': effectiveTargetId,
            'branch_id': bid,
          },
          onConflict: 'customer_id,branch_id',
          ignoreDuplicates: true,
        );
      }
    } catch (e) {
      dev.log('[CarzoneDbService] Error migrating guest favorites: $e');
    }
  }

  // Remote Write Operations (orders go through OrderService RPCs)
  Future<void> saveVehicle(VehicleModel vehicle) async {
    try {
      if (vehicle.isDefault) {
        // Ensure at most one default vehicle exists by unsetting others first
        await SupabaseService.client
            .from('vehicles')
            .update({'is_default': false})
            .eq('customer_id', vehicle.customerId)
            .neq('id', vehicle.id);
      }
      await SupabaseService.client.from('vehicles').upsert(vehicle.toJson());
    } catch (e) {
      dev.log('[CarzoneDbService] Error saving vehicle to Supabase: $e');
      rethrow;
    }
  }

  Future<void> deleteVehicle(String id) async {
    try {
      await SupabaseService.client.from('vehicles').delete().eq('id', id);
    } catch (e) {
      dev.log('[CarzoneDbService] Error deleting vehicle from Supabase: $e');
    }
  }

  Future<void> saveReview(ReviewModel review) async {
    try {
      await SupabaseService.client.from('reviews').upsert(review.toJson());
    } catch (e) {
      dev.log('[CarzoneDbService] Error saving review to Supabase: $e');
    }
  }

  Future<void> saveCustomer(CustomerModel customer) async {
    try {
      await SupabaseService.client.from('customers').upsert(customer.toJson());
    } catch (e) {
      dev.log('[CarzoneDbService] Error saving customer to Supabase: $e');
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
      if (authUser != null && token != null && token.isNotEmpty) {
        final platformStr = GetPlatform.isIOS ? 'ios' : 'android';
        await SupabaseService.client.from('push_devices').upsert({
          'user_id': authUser.id,
          'app': 'customer',
          'platform': platformStr,
          'token': token,
          'last_seen_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      dev.log('[CarzoneDbService] Error updating customer push device in Supabase: $e');
    }
  }

  Future<void> saveNotification(NotificationModel notif) async {
    try {
      await SupabaseService.client.from('customer_notifications').upsert(
        notif.toJson(),
        onConflict: 'id',
        ignoreDuplicates: true,
      );
    } catch (e) {
      dev.log('[CarzoneDbService] Error saving notification to Supabase: $e');
    }
  }

  Future<void> markNotificationRead(String notifId) async {
    try {
      await SupabaseService.client
          .from('customer_notifications')
          .update({'read': true})
          .eq('id', notifId);
    } catch (e) {
      dev.log('[CarzoneDbService] Error updating notification in Supabase: $e');
    }
  }

  Future<void> markAllNotificationsRead(String userId) async {
    try {
      final cust = customerById(userId) ?? customers.firstWhereOrNull((c) => c.userId == userId);
      final effectiveCustId = cust?.id ?? userId;

      await SupabaseService.client
          .from('customer_notifications')
          .update({'read': true})
          .eq('customer_id', effectiveCustId);
    } catch (e) {
      dev.log('[CarzoneDbService] Error updating all notifications in Supabase: $e');
    }
  }

  Future<void> saveComplaint(Map<String, dynamic> complaint) async {
    try {
      await SupabaseService.client.from('complaints').upsert(complaint);
    } catch (e) {
      dev.log('[CarzoneDbService] Error saving complaint to Supabase: $e');
    }
  }

  CustomerModel registerCustomer(String authId, String phone, String name) {
    final row = CustomerModel(id: authId, name: name, phone: phone);
    customers.add(row);
    saveCustomer(row);
    return row;
  }

  void notify({
    required String userId,
    required String type,
    required LocalizedText title,
    required LocalizedText body,
    String? orderId,
  }) {
    final notif = NotificationModel(
      id: 'nt_${DateTime.now().microsecondsSinceEpoch}',
      userId: userId,
      type: type,
      title: title,
      body: body,
      orderId: orderId,
      createdAt: DateTime.now(),
    );
    notifications.insert(0, notif);
    saveNotification(notif);
  }
}
