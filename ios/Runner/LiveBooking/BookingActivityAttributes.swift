import ActivityKit
import Foundation

/// Shared by the app (which starts and updates the Live Activity) and the
/// BookingLiveActivity widget extension (which draws it). All text is already
/// localised by Flutter's LiveBookingService.
@available(iOS 16.1, *)
struct BookingActivityAttributes: ActivityAttributes {
  struct ContentState: Codable, Hashable {
    /// pending · confirmed · waiting · in_service · completed · cancelled · no_show
    var status: String
    /// 0 booked … 4 ready; -1 when cancelled or missed.
    var stage: Int
    var title: String
    var shortStatus: String
    var subtitle: String
    var scheduledAt: Date
    var serviceStartedAt: Date?
    var readyAt: Date?
    var isFinal: Bool
  }

  var orderId: String
  var number: String
  var code: String
  var codeLabel: String
  var branchName: String
  var serviceName: String
  var stageLabels: [String]
  var isArabic: Bool
  /// Optional so activities started by an older build still decode.
  /// The order total, formatted ("80 ج.م"), shown once the car is ready.
  var total: String?
  var totalLabel: String?
  /// Captions over the countdown: time left to the slot, and to the car being ready.
  var startsInLabel: String?
  var readyInLabel: String?
}
