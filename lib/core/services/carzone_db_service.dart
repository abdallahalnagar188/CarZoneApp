import 'dart:developer' as dev;
import 'dart:math' as math;

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
import '../enums/enums.dart';
import '../local/cache_controller.dart';
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

  int _nextNumber = 10001;
  int _nextTicket = 501;
  static const _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final _rnd = math.Random();

  static const AreaModel defaultArea = AreaModel(
    id: 'nasr',
    name: LocalizedText('مدينة نصر', 'Nasr City'),
    lat: 30.0566,
    lng: 31.3301,
  );

  CarzoneDbService init() {
    // Initiate background remote fetch immediately upon service registration
    fetchFromSupabase();
    return this;
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

  // Next order number, code, and ticket generators
  String nextNumber() => 'CZ-${_nextNumber++}';

  String nextCode() {
    return List.generate(5, (_) => _codeChars[_rnd.nextInt(_codeChars.length)]).join();
  }

  String nextTicket() => 'TK-${_nextTicket++}';

  void _initCounters() {
    // Dynamically calculate next order number from existing orders in Supabase
    var maxNum = 10000;
    for (final o in orders) {
      final parts = o.number.split('-');
      if (parts.length == 2) {
        final parsed = int.tryParse(parts[1]);
        if (parsed != null && parsed > maxNum) {
          maxNum = parsed;
        }
      }
    }
    _nextNumber = maxNum + 1;

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

  /// Fetches all master data and user data from Supabase.
  Future<bool> fetchFromSupabase() async {
    try {
      isSyncing.value = true;
      hasError.value = false;
      errorMessage.value = '';
      final client = SupabaseService.client;

      final results = await Future.wait([
        client.from('areas').select(),
        client.from('branches').select(),
        client.from('services').select(),
        client.from('offers').select(),
        client.from('customers').select(),
        client.from('vehicles').select(),
        client.from('orders').select().order('created_at', ascending: false),
        client.from('reviews').select().order('created_at', ascending: false),
        client.from('notifications').select().order('created_at', ascending: false),
        client.from('complaints').select().order('created_at', ascending: false),
      ]);

      final remoteAreas = (results[0] as List)
          .map((e) => AreaModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final remoteBranches = (results[1] as List)
          .map((e) => BranchModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final remoteServices = (results[2] as List)
          .map((e) => WashServiceModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final remoteOffers = (results[3] as List)
          .map((e) => OfferModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final remoteCustomers = (results[4] as List)
          .map((e) => CustomerModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final remoteVehicles = (results[5] as List)
          .map((e) => VehicleModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final remoteOrders = (results[6] as List)
          .map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final remoteReviews = (results[7] as List)
          .map((e) => ReviewModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final remoteNotifications = (results[8] as List)
          .map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      final remoteComplaints = (results[9] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      areas.assignAll(remoteAreas);
      branches.assignAll(remoteBranches);
      services.assignAll(remoteServices);
      offers.assignAll(remoteOffers);
      customers.assignAll(remoteCustomers);
      vehicles.assignAll(remoteVehicles);
      orders.assignAll(remoteOrders);
      reviews.assignAll(remoteReviews);
      notifications.assignAll(remoteNotifications);
      complaints.assignAll(remoteComplaints);

      // If user is currently authenticated in Supabase or has cached/guest ID, load their favorites
      final cachedUserId = CacheController().getter(key: CacheKeys.userId);
      final guestUserId = CacheController().getter(key: CacheKeys.guestUserId);
      final effectiveUid = client.auth.currentUser?.id ??
          (cachedUserId is String ? cachedUserId : null) ??
          (guestUserId is String ? guestUserId : null);
      if (effectiveUid != null) {
        await loadFavorites(effectiveUid);
      }

      _initCounters();
      isSynced.value = true;
      dev.log('[CarzoneDbService] Successfully loaded 100% data from Supabase.');
      return true;
    } catch (e, st) {
      hasError.value = true;
      errorMessage.value = e.toString();
      dev.log('[CarzoneDbService] Supabase fetch error: $e\n$st');
      return false;
    } finally {
      isSyncing.value = false;
    }
  }

  /// Load favorites for specific user from Supabase.
  Future<void> loadFavorites(String userId) async {
    try {
      final res = await SupabaseService.client
          .from('favorites')
          .select('branch_id')
          .eq('user_id', userId);
      final set = (res as List).map((e) => e['branch_id'].toString()).toSet();
      favorites.assignAll(set);
    } catch (e) {
      dev.log('[CarzoneDbService] Error loading favorites from Supabase: $e');
    }
  }

  /// Toggle favorite on branch for user in Supabase.
  Future<void> toggleFavorite(String branchId, String userId) async {
    if (favorites.contains(branchId)) {
      favorites.remove(branchId);
      try {
        await SupabaseService.client
            .from('favorites')
            .delete()
            .eq('user_id', userId)
            .eq('branch_id', branchId);
      } catch (e) {
        dev.log('[CarzoneDbService] Error deleting favorite from Supabase: $e');
      }
    } else {
      favorites.add(branchId);
      try {
        await SupabaseService.client.from('favorites').upsert({
          'user_id': userId,
          'branch_id': branchId,
        });
      } catch (e) {
        dev.log('[CarzoneDbService] Error inserting favorite to Supabase: $e');
      }
    }
  }

  /// Migrates any favorites recorded under guest ID to target user ID
  Future<void> migrateGuestFavorites(String guestId, String targetUserId) async {
    if (guestId == targetUserId) return;
    try {
      final res = await SupabaseService.client
          .from('favorites')
          .select('branch_id')
          .eq('user_id', guestId);
      final guestBranchIds = (res as List).map((e) => e['branch_id'].toString()).toList();
      for (final bid in guestBranchIds) {
        await SupabaseService.client.from('favorites').upsert({
          'user_id': targetUserId,
          'branch_id': bid,
        });
      }
      await SupabaseService.client
          .from('favorites')
          .delete()
          .eq('user_id', guestId);
    } catch (e) {
      dev.log('[CarzoneDbService] Error migrating guest favorites: $e');
    }
  }

  // Remote Write Operations
  Future<void> saveOrder(OrderModel order) async {
    try {
      await SupabaseService.client.from('orders').upsert(order.toJson());
    } catch (e) {
      dev.log('[CarzoneDbService] Error saving order to Supabase: $e');
    }
  }

  Future<void> saveVehicle(VehicleModel vehicle) async {
    try {
      await SupabaseService.client.from('vehicles').upsert(vehicle.toJson());
    } catch (e) {
      dev.log('[CarzoneDbService] Error saving vehicle to Supabase: $e');
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
      final now = DateTime.now().toIso8601String();
      await SupabaseService.client.from('customers').update({
        'access_token': token,
        'token_updated_at': now,
      }).eq('id', customerId);

      final cust = customerById(customerId);
      if (cust != null) {
        cust.accessToken = token;
        cust.tokenUpdatedAt = DateTime.tryParse(now);
        customers.refresh();
      }
    } catch (e) {
      dev.log('[CarzoneDbService] Error updating customer token in Supabase: $e');
    }
  }

  Future<void> saveNotification(NotificationModel notif) async {
    try {
      await SupabaseService.client.from('notifications').upsert(notif.toJson());
    } catch (e) {
      dev.log('[CarzoneDbService] Error saving notification to Supabase: $e');
    }
  }

  Future<void> markNotificationRead(String notifId) async {
    try {
      await SupabaseService.client
          .from('notifications')
          .update({'read': true})
          .eq('id', notifId);
    } catch (e) {
      dev.log('[CarzoneDbService] Error updating notification in Supabase: $e');
    }
  }

  Future<void> markAllNotificationsRead(String userId) async {
    try {
      await SupabaseService.client
          .from('notifications')
          .update({'read': true})
          .eq('user_id', userId);
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
