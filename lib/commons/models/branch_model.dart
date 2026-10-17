import 'localized_text.dart';

class WorkingDay {
  final String open;
  final String close;
  final bool closed;

  const WorkingDay(this.open, this.close, {this.closed = false});

  factory WorkingDay.fromJson(Map<String, dynamic> json) {
    return WorkingDay(
      json['open']?.toString() ?? '09:00',
      json['close']?.toString() ?? '22:00',
      closed: json['closed'] == true,
    );
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
  final String id;
  final String businessId;
  final LocalizedText name;
  final String areaId;
  final LocalizedText address;
  final double lat;
  final double lng;
  final String phone;
  final List<String> amenities;
  final int capacity;
  final bool active;
  final bool featured;
  final bool businessActive;
  final List<WorkingDay> workingHours;
  final BranchSettings settings;
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
    this.active = true,
    this.featured = false,
    this.businessActive = true,
    this.settings = const BranchSettings(),
    this.rating = 0.0,
    this.reviewCount = 0,
  });

  bool get bookable => active && businessActive;

  WorkingDay hoursFor(DateTime day) => workingHours[day.weekday % 7];

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    final whList = (json['working_hours'] ?? json['workingHours']) as List?;
    final hours = whList != null
        ? whList.map((e) => WorkingDay.fromJson(Map<String, dynamic>.from(e as Map))).toList()
        : <WorkingDay>[];

    final rawAmenities = (json['amenities'] as List?)?.map((e) => e.toString()).toList() ?? [];

    return BranchModel(
      id: json['id']?.toString() ?? '',
      businessId: json['business_id']?.toString() ?? json['businessId']?.toString() ?? '',
      name: LocalizedText.fromJson(json['name']),
      areaId: json['area_id']?.toString() ?? json['areaId']?.toString() ?? '',
      address: LocalizedText.fromJson(json['address']),
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      phone: json['phone']?.toString() ?? '',
      amenities: rawAmenities,
      capacity: (json['capacity'] as num?)?.toInt() ?? 4,
      active: json['active'] as bool? ?? true,
      featured: json['featured'] as bool? ?? false,
      businessActive: json['business_active'] ?? json['businessActive'] ?? true,
      workingHours: hours.isNotEmpty ? hours : List.generate(7, (_) => const WorkingDay('09:00', '22:00')),
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
    'amenities': amenities,
    'capacity': capacity,
    'active': active,
    'featured': featured,
    'business_active': businessActive,
    'working_hours': workingHours.map((h) => h.toJson()).toList(),
    'settings': settings.toJson(),
    'photo_seed': photoSeed,
    'rating': rating,
    'review_count': reviewCount,
  };
}
