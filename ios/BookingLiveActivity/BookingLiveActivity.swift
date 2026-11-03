import ActivityKit
import SwiftUI
import WidgetKit

@main
struct BookingLiveActivityBundle: WidgetBundle {
  var body: some Widget {
    BookingLiveActivity()
  }
}

// MARK: - Palette (Wash Up Brand Identity)

private enum Palette {
  static let brand = Color(red: 0x00 / 255, green: 0x70 / 255, blue: 0xE8 / 255) // #0070E8 Bright Blue
  static let sky = Color(red: 0x03 / 255, green: 0x96 / 255, blue: 0xFB / 255)   // #0396FB Sky
  static let cyan = Color(red: 0x01 / 255, green: 0xBD / 255, blue: 0xFE / 255)  // #01BDFE Cyan Ribbon
  static let glow = Color(red: 0x6F / 255, green: 0xD3 / 255, blue: 0xFF / 255)  // #6FD3FF Glow
  static let deep = Color(red: 0x01 / 255, green: 0x39 / 255, blue: 0x8C / 255)  // #01398C Royal
  static let night = Color(red: 0x01 / 255, green: 0x19 / 255, blue: 0x3A / 255) // #01193A Navy Text / Bg
  static let surface = Color(red: 0x07 / 255, green: 0x20 / 255, blue: 0x47 / 255)

  static func statusColor(_ status: String) -> Color {
    switch status {
    case "pending": return Color(red: 0xFB / 255, green: 0xBF / 255, blue: 0x24 / 255)    // Amber #FBBF24
    case "confirmed": return sky                                                          // Sky #0396FB
    case "waiting": return Color(red: 0xA7 / 255, green: 0x8B / 255, blue: 0xFA / 255)    // Violet #A78BFA
    case "in_service": return Color(red: 0x22 / 255, green: 0xD3 / 255, blue: 0xEE / 255) // Aqua #22D3EE
    case "completed": return Color(red: 0x34 / 255, green: 0xD3 / 255, blue: 0x99 / 255)  // Emerald #34D399
    case "cancelled", "no_show": return Color(red: 0xF8 / 255, green: 0x71 / 255, blue: 0x71 / 255) // Coral #F87171
    default: return brand
    }
  }

  static func statusGradient(_ status: String) -> [Color] {
    switch status {
    case "pending":
      return [Color(red: 0xD9 / 255, green: 0x77 / 255, blue: 0x06 / 255), statusColor(status)]
    case "waiting":
      return [Color(red: 0x7C / 255, green: 0x3A / 255, blue: 0xED / 255), statusColor(status)]
    case "in_service":
      return [Color(red: 0x02 / 255, green: 0x84 / 255, blue: 0xC7 / 255), cyan]
    case "completed":
      return [Color(red: 0x05 / 255, green: 0x96 / 255, blue: 0x69 / 255), statusColor(status)]
    case "cancelled", "no_show":
      return [Color(red: 0xDC / 255, green: 0x26 / 255, blue: 0x26 / 255), statusColor(status)]
    default:
      return [brand, sky]
    }
  }
}

/// The app's typeface (IBM Plex Sans Arabic, bundled with this extension).
/// Live Activities cannot animate on their own, so nothing here uses timelines.
private enum Typo {
  static func plex(_ size: CGFloat, _ weight: Font.Weight = .medium) -> Font {
    switch weight {
    case .bold, .heavy, .black: return .custom("IBMPlexSansArabic-Bold", size: size)
    case .semibold: return .custom("IBMPlexSansArabic-SemiBold", size: size)
    default: return .custom("IBMPlexSansArabic-Medium", size: size)
    }
  }

  /// Timers keep system digits so they stay monospaced while ticking.
  static func timer(_ size: CGFloat) -> Font { .system(size: size, weight: .bold, design: .rounded) }
}

private extension BookingActivityAttributes {
  /// Arabic UI with Latin digits, matching the app ("4:00 م").
  var locale: Locale { Locale(identifier: isArabic ? "ar_EG@numbers=latn" : "en_US") }
  var direction: LayoutDirection { isArabic ? .rightToLeft : .leftToRight }
  var deepLink: URL? { URL(string: "washup://booking?id=\(orderId)") }
}

private extension BookingActivityAttributes.ContentState {
  var isCancelled: Bool { status == "cancelled" || status == "no_show" }
  var symbol: String {
    switch status {
    case "pending": return "clock.fill"
    case "confirmed": return "calendar.badge.checkmark"
    case "waiting": return "car.side.fill"
    case "in_service": return "drop.fill"
    case "completed": return "checkmark.seal.fill"
    case "cancelled", "no_show": return "xmark.circle.fill"
    default: return "car.fill"
    }
  }

  /// Live countdown: to the slot before arrival, to the ready time while washing.
  /// Nil once that moment has passed (a ClosedRange must not run backwards).
  var countdown: ClosedRange<Date>? {
    let now = Date()
    switch status {
    case "pending", "confirmed":
      return scheduledAt > now ? now...scheduledAt : nil
    case "in_service":
      guard let ready = readyAt, ready > now else { return nil }
      return min(serviceStartedAt ?? now, now)...ready
    default:
      return nil
    }
  }

  /// The check-in code is only useful between the wash confirming and the car arriving.
  var showsCode: Bool { status == "confirmed" }
}

// MARK: - Widget Definition

struct BookingLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: BookingActivityAttributes.self) { context in
      LockScreenView(attributes: context.attributes, state: context.state)
        .environment(\.layoutDirection, context.attributes.direction)
        .environment(\.locale, context.attributes.locale)
        .activityBackgroundTint(Palette.night)
        .activitySystemActionForegroundColor(.white)
        .widgetURL(context.attributes.deepLink)
    } dynamicIsland: { context in
      let attributes = context.attributes
      let state = context.state
      let statusColor = Palette.statusColor(state.status)

      return DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          HStack(spacing: 8) {
            StatusBadge(state: state, size: 32)
            VStack(alignment: .leading, spacing: 2) {
              BrandMark(height: 10)
              Text(state.shortStatus)
                .font(Typo.plex(13, .semibold))
                .foregroundStyle(statusColor)
                .lineLimit(1)
            }
          }
          .padding(.leading, 4)
          .environment(\.layoutDirection, attributes.direction)
        }
        DynamicIslandExpandedRegion(.trailing) {
          TrailingValue(attributes: attributes, state: state, compact: true)
            .padding(.trailing, 4)
            .environment(\.locale, attributes.locale)
        }
        DynamicIslandExpandedRegion(.center) {
          Text(state.title)
            .font(Typo.plex(14, .bold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
        DynamicIslandExpandedRegion(.bottom) {
          VStack(spacing: 8) {
            StageTrack(labels: attributes.stageLabels, state: state, compact: true)
            HStack {
              Text(attributes.branchName)
                .font(Typo.plex(12))
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(1)
              Spacer(minLength: 8)
              FooterChip(attributes: attributes, state: state)
            }
          }
          .padding(.top, 4)
          .environment(\.layoutDirection, attributes.direction)
          .environment(\.locale, attributes.locale)
        }
      } compactLeading: {
        Image(systemName: state.symbol)
          .font(.system(size: 12, weight: .bold))
          .foregroundStyle(statusColor)
      } compactTrailing: {
        Group {
          if let range = state.countdown {
            Text(timerInterval: range, countsDown: true)
              .font(Typo.timer(13))
              .monospacedDigit()
              .multilineTextAlignment(.trailing)
              .frame(maxWidth: 52)
          } else {
            Text(state.shortStatus)
              .font(Typo.plex(12, .semibold))
              .lineLimit(1)
              .frame(maxWidth: 64)
          }
        }
        .foregroundStyle(statusColor)
        .environment(\.locale, attributes.locale)
      } minimal: {
        StageRing(state: state)
      }
      .widgetURL(attributes.deepLink)
      .keylineTint(statusColor)
    }
  }
}

// MARK: - Lock screen View

private struct LockScreenView: View {
  let attributes: BookingActivityAttributes
  let state: BookingActivityAttributes.ContentState

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Header: status badge, brand + branch over the title, then the live value.
      HStack(alignment: .center, spacing: 12) {
        StatusBadge(state: state, size: 40)

        VStack(alignment: .leading, spacing: 3) {
          HStack(spacing: 6) {
            BrandMark(height: 12)
            Text(attributes.branchName)
              .font(Typo.plex(12))
              .foregroundStyle(.white.opacity(0.7))
              .lineLimit(1)
          }
          Text(state.title)
            .font(Typo.plex(16, .bold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }

        Spacer(minLength: 8)
        TrailingValue(attributes: attributes, state: state, compact: false)
      }

      StageTrack(labels: attributes.stageLabels, state: state, compact: false)

      HStack(spacing: 8) {
        Text(state.subtitle)
          .font(Typo.plex(13))
          .foregroundStyle(.white.opacity(0.85))
          .lineLimit(1)
        Spacer(minLength: 8)
        FooterChip(attributes: attributes, state: state)
      }
    }
    .padding(16)
    .background(
      ZStack {
        LinearGradient(
          colors: [Palette.night, Palette.surface, Palette.deep.opacity(0.9)],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
        // The system clips the activity to its own corners, so no shape or border here.
        RadialGradient(
          colors: [Palette.statusColor(state.status).opacity(0.18), .clear],
          center: .topLeading,
          startRadius: 0,
          endRadius: 180
        )
      }
    )
  }
}

// MARK: - Pieces

/// The Wash Up mark, sized by height.
private struct BrandMark: View {
  let height: CGFloat

  var body: some View {
    if let image = UIImage(named: "LiveMark") {
      Image(uiImage: image)
        .resizable()
        .scaledToFit()
        .frame(height: height)
    } else {
      Text("WASH UP")
        .font(.system(size: height * 0.75, weight: .black))
        .foregroundStyle(Palette.glow)
    }
  }
}

private struct StatusBadge: View {
  let state: BookingActivityAttributes.ContentState
  let size: CGFloat

  var body: some View {
    let statusColor = Palette.statusColor(state.status)
    ZStack {
      Circle()
        .fill(LinearGradient(colors: Palette.statusGradient(state.status), startPoint: .topLeading, endPoint: .bottomTrailing))
        .overlay(Circle().stroke(Color.white.opacity(0.25), lineWidth: 1))
        .shadow(color: statusColor.opacity(0.5), radius: 6, x: 0, y: 2)
      Image(systemName: state.symbol)
        .font(.system(size: size * 0.44, weight: .bold))
        .foregroundStyle(.white)
    }
    .frame(width: size, height: size)
  }
}

/// The value at the trailing edge: a captioned countdown, or the total once the car is ready.
private struct TrailingValue: View {
  let attributes: BookingActivityAttributes
  let state: BookingActivityAttributes.ContentState
  let compact: Bool

  private var statusColor: Color { Palette.statusColor(state.status) }
  private var caption: String? {
    state.status == "in_service" ? attributes.readyInLabel : attributes.startsInLabel
  }

  var body: some View {
    if let range = state.countdown {
      VStack(alignment: .trailing, spacing: 1) {
        if let caption, !compact {
          Text(caption)
            .font(Typo.plex(10))
            .foregroundStyle(.white.opacity(0.6))
            .lineLimit(1)
        }
        Text(timerInterval: range, countsDown: true)
          .font(Typo.timer(compact ? 18 : 20))
          .monospacedDigit()
          .multilineTextAlignment(.trailing)
          .foregroundStyle(statusColor)
      }
      .frame(maxWidth: compact ? 76 : 92, alignment: .trailing)
    } else if state.status == "completed", let total = attributes.total {
      VStack(alignment: .trailing, spacing: 1) {
        if let label = attributes.totalLabel, !compact {
          Text(label)
            .font(Typo.plex(10))
            .foregroundStyle(.white.opacity(0.6))
        }
        Text(total)
          .font(Typo.plex(compact ? 15 : 17, .bold))
          .foregroundStyle(statusColor)
          .lineLimit(1)
      }
    }
  }
}

/// Dynamic Island minimal view: progress ring around the status symbol.
private struct StageRing: View {
  let state: BookingActivityAttributes.ContentState

  var body: some View {
    let progress = state.isCancelled ? 1 : Double(max(state.stage, 0)) / 4
    let statusColor = Palette.statusColor(state.status)
    ZStack {
      Circle().stroke(Color.white.opacity(0.18), lineWidth: 2.5)
      Circle()
        .trim(from: 0, to: max(progress, 0.08))
        .stroke(statusColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
        .rotationEffect(.degrees(-90))
      Image(systemName: state.symbol)
        .font(.system(size: 9, weight: .bold))
        .foregroundStyle(statusColor)
    }
  }
}

/// Booked → Confirmed → Arrived → Washing → Ready.
private struct StageTrack: View {
  let labels: [String]
  let state: BookingActivityAttributes.ContentState
  let compact: Bool

  private var reached: Int { state.isCancelled ? -1 : state.stage }
  private var statusColor: Color { Palette.statusColor(state.status) }

  /// The last stage counts as done once reached: the car is ready.
  private func isDone(_ i: Int) -> Bool { i < reached || (i == reached && i == 4) }

  var body: some View {
    VStack(spacing: 6) {
      HStack(spacing: 0) {
        ForEach(0..<5, id: \.self) { i in
          dot(i)
          if i < 4 {
            Capsule()
              .fill(i < reached ? statusColor : Color.white.opacity(0.18))
              .frame(height: 3)
          }
        }
      }
      if !compact {
        HStack(spacing: 0) {
          ForEach(0..<5, id: \.self) { i in
            Text(i < labels.count ? labels[i] : "")
              .font(Typo.plex(11, i == reached ? .semibold : .medium))
              .foregroundStyle(i == reached ? statusColor : (i < reached ? .white.opacity(0.85) : .white.opacity(0.5)))
              .lineLimit(1)
              .minimumScaleFactor(0.7)
              .frame(maxWidth: .infinity, alignment: i == 0 ? .leading : i == 4 ? .trailing : .center)
          }
        }
      }
    }
  }

  @ViewBuilder
  private func dot(_ i: Int) -> some View {
    ZStack {
      if isDone(i) {
        Circle().fill(statusColor).frame(width: 12, height: 12)
        Image(systemName: "checkmark")
          .font(.system(size: 6, weight: .black))
          .foregroundStyle(Palette.night)
      } else if i == reached {
        Circle().fill(statusColor.opacity(0.25)).frame(width: 18, height: 18)
        Circle().stroke(statusColor, lineWidth: 2).frame(width: 14, height: 14)
        Circle().fill(statusColor).frame(width: 7, height: 7)
      } else {
        Circle().fill(Color.white.opacity(0.25)).frame(width: 8, height: 8)
      }
    }
    .frame(width: 18, height: 18)
  }
}

/// The check-in code while it is needed, otherwise the booking number.
private struct FooterChip: View {
  let attributes: BookingActivityAttributes
  let state: BookingActivityAttributes.ContentState

  private var statusColor: Color { Palette.statusColor(state.status) }

  var body: some View {
    if state.showsCode && !attributes.code.isEmpty {
      HStack(spacing: 4) {
        Text(attributes.codeLabel)
          .font(Typo.plex(10))
          .foregroundStyle(.white.opacity(0.7))
        Text(attributes.code)
          .font(.system(size: 13, weight: .bold, design: .monospaced))
          .foregroundStyle(statusColor)
          .environment(\.layoutDirection, .leftToRight)
      }
      .padding(.horizontal, 9)
      .padding(.vertical, 4)
      .background(Capsule().fill(statusColor.opacity(0.15)))
      .overlay(Capsule().stroke(statusColor.opacity(0.35), lineWidth: 0.8))
    } else {
      Text(attributes.number)
        .font(.system(size: 11, weight: .semibold, design: .monospaced))
        .foregroundStyle(.white.opacity(0.55))
        .environment(\.layoutDirection, .leftToRight)
    }
  }
}
