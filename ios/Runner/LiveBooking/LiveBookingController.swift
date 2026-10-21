import ActivityKit
import Flutter
import Foundation

/// Bridges `carzone/live_booking` (Flutter's LiveBookingService) to ActivityKit.
final class LiveBookingController {
  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "carzone/live_booking", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard #available(iOS 16.2, *) else { return result(nil) }
      let args = call.arguments as? [String: Any] ?? [:]
      switch call.method {
      case "show":
        Task { await show(args) }
        result(nil)
      case "end":
        let orderId = args["orderId"] as? String ?? ""
        Task { await end(orderId: orderId) }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  @available(iOS 16.2, *)
  private static func show(_ args: [String: Any]) async {
    guard let orderId = args["orderId"] as? String else { return }
    let state = contentState(args)
    let content = ActivityContent(state: state, staleDate: nil)

    // One booking at a time: anything else still on screen is finished.
    for activity in Activity<BookingActivityAttributes>.activities where activity.attributes.orderId != orderId {
      await activity.end(nil, dismissalPolicy: .immediate)
    }

    if let current = Activity<BookingActivityAttributes>.activities.first(where: { $0.attributes.orderId == orderId }) {
      if state.isFinal {
        let linger = (args["dismissAfterSeconds"] as? NSNumber)?.doubleValue ?? 900
        await current.end(content, dismissalPolicy: .after(Date().addingTimeInterval(linger)))
      } else {
        await current.update(content)
      }
      return
    }

    // A booking that already ended is not worth starting a new activity for.
    guard !state.isFinal, ActivityAuthorizationInfo().areActivitiesEnabled else { return }
    let attributes = BookingActivityAttributes(
      orderId: orderId,
      number: args["number"] as? String ?? "",
      code: args["code"] as? String ?? "",
      codeLabel: args["codeLabel"] as? String ?? "",
      branchName: args["branchName"] as? String ?? "",
      serviceName: args["serviceName"] as? String ?? "",
      stageLabels: args["stageLabels"] as? [String] ?? [],
      isArabic: args["isArabic"] as? Bool ?? true
    )
    do {
      _ = try Activity.request(attributes: attributes, content: content, pushType: nil)
    } catch {
      NSLog("[LiveBooking] could not start the Live Activity: \(error)")
    }
  }

  @available(iOS 16.2, *)
  private static func end(orderId: String) async {
    for activity in Activity<BookingActivityAttributes>.activities where activity.attributes.orderId == orderId {
      await activity.end(nil, dismissalPolicy: .immediate)
    }
  }

  @available(iOS 16.1, *)
  private static func contentState(_ args: [String: Any]) -> BookingActivityAttributes.ContentState {
    func date(_ key: String) -> Date? {
      (args[key] as? NSNumber).map { Date(timeIntervalSince1970: $0.doubleValue / 1000) }
    }
    return BookingActivityAttributes.ContentState(
      status: args["status"] as? String ?? "pending",
      stage: (args["stage"] as? NSNumber)?.intValue ?? 0,
      title: args["title"] as? String ?? "",
      shortStatus: args["shortStatus"] as? String ?? "",
      subtitle: args["subtitle"] as? String ?? "",
      scheduledAt: date("scheduledAt") ?? Date(),
      serviceStartedAt: date("serviceStartedAt"),
      readyAt: date("readyAt"),
      isFinal: args["isFinal"] as? Bool ?? false
    )
  }
}
