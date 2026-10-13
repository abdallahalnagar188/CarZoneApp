import 'localized_text.dart';

class WorkingDay {
  final String open;
  final String close;
  final bool closed;

  const WorkingDay(this.open, this.close, {this.closed = false});
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
  });

  bool get bookable => active && businessActive;

  WorkingDay hoursFor(DateTime day) => workingHours[day.weekday % 7];
}
