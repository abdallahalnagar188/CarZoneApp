import 'dart:developer' as dev;

import 'package:get/get.dart';

import '../../commons/models/area_model.dart';
import '../../commons/models/customer_model.dart';
import '../enums/enums.dart';
import '../local/cache_controller.dart';
import '../local/cache_helper.dart';
import '../network/dio_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'carzone_db_service.dart';
import 'supabase_service.dart';

class SessionService extends GetxService {
  final user = Rxn<CustomerModel>();
  final userToken = RxnString();
  final areaId = 'nasr'.obs;

  String? returnRoute;
  dynamic returnArguments;
  void Function()? pendingAction;

  CarzoneDbService get _db => Get.find<CarzoneDbService>();

  bool get isLoggedIn => user.value != null;

  String? get userId => user.value?.id;

  String? get accessToken => userToken.value;

  AreaModel get area => _db.area(areaId.value);

  double get lat => area.lat;

  double get lng => area.lng;

  SessionService init() {
    ensureValidSession();
    _restoreUser();
    _restoreToken();

    // Listen to customers list updates from Supabase so profile is restored
    // as soon as remote data arrives
    ever(_db.customers, (_) {
      if (user.value == null) {
        _restoreUser();
      }
    });

    // Listen to Supabase auth state changes
    SupabaseService.client.auth.onAuthStateChange.listen((data) async {
      final authUser = data.session?.user;
      final sessionToken = data.session?.accessToken;

      if (authUser != null) {
        if (sessionToken != null) {
          await saveToken(sessionToken);
        }
        final cust = _db.customerById(authUser.id);
        if (cust != null) {
          await signIn(cust, token: sessionToken);
        } else {
          await refreshProfile();
        }
        await _db.loadFavorites(authUser.id);
      } else if (data.event == AuthChangeEvent.signedOut) {
        await clearToken();
        user.value = null;
        _db.favorites.clear();
      }
    });

    final cachedArea = CacheController().getter(key: CacheKeys.areaId);
    if (cachedArea is String) areaId.value = cachedArea;
    return this;
  }

  Future<void> _restoreToken() async {
    try {
      final secure = await CacheHelper.safeRead(key: CacheKeys.userToken.name);
      if (secure != null && secure.isNotEmpty) {
        userToken.value = secure;
      } else {
        final cached = CacheController().getter(key: CacheKeys.userToken);
        if (cached is String && cached.isNotEmpty) {
          userToken.value = cached;
        }
      }

      // Check current Supabase active session token as definitive source
      final activeToken = SupabaseService.client.auth.currentSession?.accessToken;
      if (activeToken != null && activeToken.isNotEmpty) {
        userToken.value = activeToken;
      }

      if (userToken.value != null) {
        await DioHelper.updateHeadersManually();
      }
    } catch (e) {
      dev.log('[SessionService] _restoreToken error: $e');
    }
  }

  void _restoreUser() {
    final cache = CacheController();
    final id = cache.getter(key: CacheKeys.userId);
    if (id is String) user.value = _db.customerById(id);

    // If no cached user or not found in local db, check Supabase auth
    if (user.value == null) {
      final authUser = SupabaseService.client.auth.currentUser;
      if (authUser != null) {
        user.value = _db.customerById(authUser.id);
        if (user.value != null) {
          CacheController().setter(key: CacheKeys.userId, value: authUser.id);
          CacheController().setter(key: CacheKeys.loggedIn, value: true);
        } else {
          refreshProfile();
        }
      }
    }
  }

  Future<void> saveToken(String token) async {
    userToken.value = token;
    try {
      await CacheHelper.assignSecureData(key: CacheKeys.userToken.name, value: token);
      await CacheController().setter(key: CacheKeys.userToken, value: token);
      final uid = userId ?? SupabaseService.client.auth.currentUser?.id;
      if (uid != null) {
        await _db.updateCustomerToken(uid, token);
      }
      await DioHelper.updateHeadersManually();
    } catch (e) {
      dev.log('[SessionService] saveToken error: $e');
    }
  }

  Future<void> clearToken() async {
    final uid = userId ?? SupabaseService.client.auth.currentUser?.id;
    if (uid != null) {
      await _db.updateCustomerToken(uid, null);
    }
    userToken.value = null;
    try {
      await CacheHelper.clearCache(key: CacheKeys.userToken.name);
      await CacheController().setter(key: CacheKeys.userToken, value: null);
      await DioHelper.updateHeadersManually();
    } catch (e) {
      dev.log('[SessionService] clearToken error: $e');
    }
  }

  Future<void> ensureValidSession() async {
    try {
      final session = SupabaseService.client.auth.currentSession;
      if (session != null && session.isExpired) {
        dev.log('[SessionService] Session is expired. Attempting token refresh...');
        try {
          final res = await SupabaseService.client.auth.refreshSession();
          if (res.session != null) {
            dev.log('[SessionService] Session token refreshed successfully.');
            await saveToken(res.session!.accessToken);
          }
        } catch (refreshErr) {
          dev.log('[SessionService] Token refresh failed ($refreshErr). Signing out expired session.');
          await signOut();
        }
      }
    } catch (e) {
      dev.log('[SessionService] ensureValidSession error: $e');
    }
  }

  Future<void> refreshProfile() async {
    final authUser = SupabaseService.client.auth.currentUser;
    if (authUser == null) return;
    try {
      final res = await SupabaseService.client
          .from('customers')
          .select()
          .eq('id', authUser.id)
          .maybeSingle();
      if (res != null) {
        final cust = CustomerModel.fromJson(Map<String, dynamic>.from(res));
        final idx = _db.customers.indexWhere((c) => c.id == cust.id);
        if (idx != -1) {
          _db.customers[idx] = cust;
        } else {
          _db.customers.add(cust);
        }
        user.value = cust;
        await CacheController().setter(key: CacheKeys.userId, value: cust.id);
        await CacheController().setter(key: CacheKeys.loggedIn, value: true);

        // Ensure token is synced if active
        if (userToken.value != null && cust.accessToken != userToken.value) {
          await _db.updateCustomerToken(cust.id, userToken.value);
        }
      }
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('JWT expired') || errStr.contains('PGRST303')) {
        dev.log('[SessionService] JWT expired during refreshProfile. Attempting recovery...');
        try {
          final res = await SupabaseService.client.auth.refreshSession();
          if (res.session != null) {
            await saveToken(res.session!.accessToken);
            return refreshProfile();
          }
        } catch (_) {
          await signOut();
          return;
        }
      }
      dev.log('[SessionService] refreshProfile error: $e');
    }
  }

  Future<void> signIn(CustomerModel customer, {String? token}) async {
    user.value = customer;
    await CacheController().setter(key: CacheKeys.userId, value: customer.id);
    await CacheController().setter(key: CacheKeys.loggedIn, value: true);
    await CacheController().setter(key: CacheKeys.name, value: customer.name);
    await CacheController().setter(key: CacheKeys.mobile, value: customer.phone);

    final effectiveToken = token ??
        userToken.value ??
        SupabaseService.client.auth.currentSession?.accessToken;

    if (effectiveToken != null) {
      await saveToken(effectiveToken);
    }

    final guestId = CacheController().getter(key: CacheKeys.guestUserId);
    if (guestId is String && guestId.isNotEmpty) {
      await _db.migrateGuestFavorites(guestId, customer.id);
      await CacheController().setter(key: CacheKeys.guestUserId, value: null);
    }
    await _db.loadFavorites(customer.id);
  }

  Future<void> signOut() async {
    await clearToken();
    user.value = null;
    _db.favorites.clear();
    await CacheController().logout();
    try {
      await SupabaseService.client.auth.signOut();
    } catch (e) {
      dev.log('[SessionService] Supabase sign-out error: $e');
    }
  }

  Future<void> setArea(String id) async {
    areaId.value = id;
    await CacheController().setter(key: CacheKeys.areaId, value: id);
  }

  void rememberReturn(String route, {dynamic arguments, void Function()? action}) {
    returnRoute = route;
    returnArguments = arguments;
    pendingAction = action;
  }

  void clearReturn() {
    returnRoute = null;
    returnArguments = null;
    pendingAction = null;
  }
}
