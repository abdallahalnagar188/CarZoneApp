import '../../core/constance/supabase_constants.dart';
import 'localized_text.dart';

class WorkingDay {
  /// Opening and closing wall-clock times in the branch, "HH:mm".
  final String open;
  final String close;
  final bool closed;

  const WorkingDay(this.open, this.close, {this.closed = false});

  /// A day without opening hours (no row in branch_working_hours, or hours
  /// that are not known yet): nothing is open or bookable.
  static const none = WorkingDay('00:00', '00:00', closed: true);

  /// Accepts a branch_working_hours row (opens_at / closes_at as "HH:mm:ss")
  /// or the app's own cached shape (open / close).
  factory WorkingDay.fromJson(Map<String, dynamic> json) {
    final open = _hhmm(json['opens_at'] ?? json['open']);
    final close = _hhmm(json['closes_at'] ?? json['close']);
    if (open == null || close == null) return none;
    return WorkingDay(open, close, closed: json['closed'] == true);
  }

  static String? _hhmm(dynamic value) {
    final parts = value?.toString().split(':');
    if (parts == null || parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  int get openMin => _minutes(open);

  /// Minutes after the day's midnight; a branch closing at or after midnight
  /// closes the next day (same rule as get_branch_slots).
  int get closeMin {
    final c = _minutes(close);
    return c <= openMin ? c + 1440 : c;
  }

  static int _minutes(String hhmm) {
    final parts = hhmm.split(':');
    return (int.tryParse(parts[0]) ?? 0) * 60 + (parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0);
  }

  Map<String, dynamic> toJson() => {
    'open': open,
    'close': close,
    'closed': closed,
  };
}

class BranchSettings {
  final bool autoConfirm;
  final int slotIntervalMin;
  final int leadTimeMin;
  final int maxAdvanceDays;
  final int freeCancelMin;
  final int noShowGraceMin;
  final int reminderMin;

  /// How far ahead a slot must start: a wash that confirms by hand gets at
  /// least 30 minutes to do it (same rule as booking_lead_min() in the database).
  int get bookingLeadMin => autoConfirm ? leadTimeMin : (leadTimeMin < 30 ? 30 : leadTimeMin);

  const BranchSettings({
    this.autoConfirm = false,
    this.slotIntervalMin = 30,
    this.leadTimeMin = 15,
    this.maxAdvanceDays = 7,
    this.freeCancelMin = 60,
    this.noShowGraceMin = 15,
    this.reminderMin = 45,
  });

  factory BranchSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const BranchSettings();
    return BranchSettings(
      autoConfirm: json['auto_confirm'] ?? json['autoConfirm'] ?? false,
      slotIntervalMin: (json['slot_interval_min'] ?? json['slotIntervalMin'] ?? 30) as int,
      leadTimeMin: (json['lead_time_min'] ?? json['leadTimeMin'] ?? 15) as int,
      maxAdvanceDays: (json['max_advance_days'] ?? json['maxAdvanceDays'] ?? 7) as int,
      freeCancelMin: (json['free_cancel_min'] ?? json['freeCancelMin'] ?? 60) as int,
      noShowGraceMin: (json['no_show_grace_min'] ?? json['noShowGraceMin'] ?? 15) as int,
      reminderMin: (json['reminder_min'] ?? json['reminderMin'] ?? 45) as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'auto_confirm': autoConfirm,
    'slot_interval_min': slotIntervalMin,
    'lead_time_min': leadTimeMin,
    'max_advance_days': maxAdvanceDays,
    'free_cancel_min': freeCancelMin,
    'no_show_grace_min': noShowGraceMin,
    'reminder_min': reminderMin,
  };
}

class BranchModel {
  /// Public bucket the partner portal uploads branch photos to.
  static const photoBucket = 'branch-photos';

  /// Related rows embedded in every branch query (GAP-016): opening hours,
  /// amenities with their names, and photos.
  static const relatedSelect =
      'branch_working_hours(weekday, opens_at, closes_at, closed), '
      'branch_amenities(amenity_id, amenities(name)), '
      'branch_photos(storage_path, position)';

  /// [relatedSelect] without the amenity names, for a database that refuses them.
  static const relatedSelectBasic =
      'branch_working_hours(weekday, opens_at, closes_at, closed), '
      'branch_amenities(amenity_id), '
      'branch_photos(storage_path, position)';

  final String id;
  final String businessId;
  final LocalizedText name;
  final String areaId;
  final LocalizedText address;
  final double lat;
  final double lng;
  final String phone;

  /// Amenity ids set by the wash (branch_amenities).
  final List<String> amenities;

  /// Names of [amenities] from the amenities table, when loaded.
  final Map<String, LocalizedText> amenityNames;
  final int capacity;
  final bool active;
  final bool featured;
  final bool businessActive;

  /// Seven days indexed by `weekday % 7` (0 = Sunday, like Postgres `dow`);
  /// empty while the hours are not loaded.
  final List<WorkingDay> workingHours;

  /// Whether [workingHours], [amenities] and [photos] come from the database.
  /// False for a branch row loaded without its related tables.
  final bool detailsLoaded;

  /// Public URLs of the wash's own photos, in their display order.
  final List<String> photos;
  final BranchSettings settings;

  /// Picks a decorative stock picture while the wash has no photo of its own.
  final int photoSeed;
  final double rating;
  final int reviewCount;

  const BranchModel({
    required this.id,
    required this.businessId,
    required this.name,
    required this.areaId,
    required this.address,
    required this.lat,
    required this.lng,
    required this.phone,
    required this.amenities,
    required this.capacity,
    required this.workingHours,
    required this.photoSeed,
    this.amenityNames = const {},
    this.photos = const [],
    this.detailsLoaded = true,
    this.active = true,
    this.featured = false,
    this.businessActive = true,
    this.settings = const BranchSettings(),
    this.rating = 0.0,
    this.reviewCount = 0,
  });

  bool get bookable => active && businessActive;

  /// Whether the opening hours are known (loaded from branch_working_hours).
  bool get hoursKnown => detailsLoaded && workingHours.length == 7;

  WorkingDay hoursFor(DateTime day) => hoursKnown ? workingHours[day.weekday % 7] : WorkingDay.none;

  /// Seven days from branch_working_hours rows; a weekday without a row is
  /// closed, as the booking RPCs treat it.
  static List<WorkingDay> hoursFromRows(List rows) {
    final days = List<WorkingDay>.filled(7, WorkingDay.none);
    for (final r in rows) {
      final m = Map<String, dynamic>.from(r as Map);
      final weekday = (m['weekday'] as num?)?.toInt();
      if (weekday == null || weekday < 0 || weekday > 6) continue;
      days[weekday] = WorkingDay.fromJson(m);
    }
    return days;
  }

  /// A branch_photos storage path as a public URL (full URLs are kept).
  static String photoUrl(String path) => path.startsWith('http')
      ? path
      : '${SupabaseConstants.supabaseUrl}/storage/v1/object/public/$photoBucket/${path.replaceFirst(RegExp('^/+'), '')}';

  static List<String> _photosFromRows(List rows) {
    final list = rows.map((r) => Map<String, dynamic>.from(r as Map)).where((m) => (m['storage_path']?.toString() ?? '').isNotEmpty).toList()
      ..sort((a, b) => ((a['position'] as num?) ?? 0).compareTo((b['position'] as num?) ?? 0));
    return list.map((m) => photoUrl(m['storage_path'].toString())).toList();
  }

  /// This branch with the related rows of [json] (a branch row embedding
  /// [relatedSelect]). Keeps this branch unchanged when [json] has none.
  BranchModel withRelated(Map<String, dynamic> json) {
    final related = _Related.fromJson(json);
    if (related == null) return this;
    return _copy(related);
  }

  /// [fresh] keeping the related rows this branch already had, when [fresh]
  /// was loaded without them (a discover_branches row).
  static BranchModel keepRelated(BranchModel fresh, BranchModel? old) {
    if (fresh.detailsLoaded || old == null || !old.detailsLoaded) return fresh;
    return fresh._copy(_Related(old.workingHours, old.amenities, old.amenityNames, old.photos));
  }

  BranchModel _copy(_Related r) => BranchModel(
        id: id,
        businessId: businessId,
        name: name,
        areaId: areaId,
        address: address,
        lat: lat,
        lng: lng,
        phone: phone,
        amenities: r.amenities,
        amenityNames: r.amenityNames,
        capacity: capacity,
        workingHours: r.hours,
        photos: r.photos,
        detailsLoaded: true,
        photoSeed: photoSeed,
        active: active,
        featured: featured,
        businessActive: businessActive,
        settings: settings,
        rating: rating,
        reviewCount: reviewCount,
      );

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    final related = _Related.fromJson(json);
    return BranchModel(
      id: json['id']?.toString() ?? '',
      businessId: json['business_id']?.toString() ?? json['businessId']?.toString() ?? '',
      name: LocalizedText.fromJson(json['name']),
      areaId: json['area_id']?.toString() ?? json['areaId']?.toString() ?? '',
      address: LocalizedText.fromJson(json['address']),
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      phone: json['phone']?.toString() ?? '',
      amenities: related?.amenities ?? const [],
      amenityNames: related?.amenityNames ?? const {},
      capacity: (json['capacity'] as num?)?.toInt() ?? 4,
      active: json['active'] as bool? ?? true,
      featured: json['featured'] as bool? ?? false,
      businessActive: json['business_active'] ?? json['businessActive'] ?? true,
      workingHours: related?.hours ?? const [],
      photos: related?.photos ?? const [],
      detailsLoaded: related != null,
      settings: BranchSettings.fromJson(json['settings'] != null ? Map<String, dynamic>.from(json['settings'] as Map) : json),
      photoSeed: (json['photo_seed'] ?? json['photoSeed'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['review_count'] ?? json['reviewCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'business_id': businessId,
    'name': name.toJson(),
    'area_id': areaId,
    'address': address.toJson(),
    'lat': lat,
    'lng': lng,
    'phone': phone,
    'capacity': capacity,
    'active': active,
    'featured': featured,
    'business_active': businessActive,
    if (detailsLoaded) 'working_hours': workingHours.map((h) => h.toJson()).toList(),
    if (detailsLoaded) 'amenities': amenities,
    if (detailsLoaded) 'photos': photos,
    'settings': settings.toJson(),
    'photo_seed': photoSeed,
    'rating': rating,
    'review_count': reviewCount,
  };
}

/// The rows of a branch's related tables, when the query embedded them.
class _Related {
  final List<WorkingDay> hours;
  final List<String> amenities;
  final Map<String, LocalizedText> amenityNames;
  final List<String> photos;

  const _Related(this.hours, this.amenities, this.amenityNames, this.photos);

  static _Related? fromJson(Map<String, dynamic> json) {
    // Database shape: embedded related tables.
    final hoursRows = json['branch_working_hours'];
    if (hoursRows is List) {
      final amenityRows = (json['branch_amenities'] as List?) ?? const [];
      final ids = <String>[];
      final names = <String, LocalizedText>{};
      for (final r in amenityRows) {
        final m = Map<String, dynamic>.from(r as Map);
        final id = m['amenity_id']?.toString();
        if (id == null || id.isEmpty) continue;
        final named = m['amenities'];
        // An amenity switched off by the platform comes back without its row.
        if (m.containsKey('amenities') && named is! Map) continue;
        ids.add(id);
        if (named is Map && named['name'] != null) names[id] = LocalizedText.fromJson(named['name']);
      }
      return _Related(
        BranchModel.hoursFromRows(hoursRows),
        ids,
        names,
        BranchModel._photosFromRows((json['branch_photos'] as List?) ?? const []),
      );
    }
    // The app's own cached shape (toJson).
    final cached = json['working_hours'] ?? json['workingHours'];
    if (cached is List && cached.length == 7) {
      return _Related(
        cached.map((e) => WorkingDay.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
        ((json['amenities'] as List?) ?? const []).map((e) => e.toString()).toList(),
        const {},
        ((json['photos'] as List?) ?? const []).map((e) => e.toString()).toList(),
      );
    }
    return null;
  }
}
