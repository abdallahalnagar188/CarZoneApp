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
  // Wash Up Official Brand Palette
  static let brand = Color(red: 0x00 / 255, green: 0x70 / 255, blue: 0xE8 / 255) // #0070E8 Bright Blue
  static let sky = Color(red: 0x03 / 255, green: 0x96 / 255, blue: 0xFB / 255)   // #0396FB Sky
  static let cyan = Color(red: 0x01 / 255, green: 0xBD / 255, blue: 0xFE / 255)  // #01BDFE Cyan Ribbon
  static let glow = Color(red: 0x6F / 255, green: 0xD3 / 255, blue: 0xFF / 255)  // #6FD3FF Glow
  static let deep = Color(red: 0x01 / 255, green: 0x39 / 255, blue: 0x8C / 255)  // #01398C Royal
  static let night = Color(red: 0x01 / 255, green: 0x19 / 255, blue: 0x3A / 255) // #01193A Navy Text / Bg
  static let surface = Color(red: 0x07 / 255, green: 0x20 / 255, blue: 0x47 / 255)

  // Custom Color per Status (WCAG AA & OLED Tuned)
  static func statusColor(_ status: String) -> Color {
    switch status {
    case "pending":
      return Color(red: 0xFB / 255, green: 0xBF / 255, blue: 0x24 / 255) // Amber Gold #FBBF24
    case "confirmed":
      return Color(red: 0x03 / 255, green: 0x96 / 255, blue: 0xFB / 255) // Sky Blue #0396FB
    case "waiting":
      return Color(red: 0xA7 / 255, green: 0x8B / 255, blue: 0xFA / 255) // Purple Violet #A78BFA
    case "in_service":
      return Color(red: 0x22 / 255, green: 0xD3 / 255, blue: 0xEE / 255) // Aqua / Teal Wash #22D3EE
    case "completed":
      return Color(red: 0x34 / 255, green: 0xD3 / 255, blue: 0x99 / 255) // Emerald Green #34D399
    case "cancelled", "no_show":
      return Color(red: 0xF8 / 255, green: 0x71 / 255, blue: 0x71 / 255) // Coral Red #F87171
    default:
      return brand
    }
  }

  // Glow Halo Color per Status
  static func statusGlow(_ status: String) -> Color {
    switch status {
    case "pending":
      return Color(red: 0xFD / 255, green: 0xE6 / 255, blue: 0x8A / 255)
    case "confirmed":
      return Color(red: 0x6F / 255, green: 0xD3 / 255, blue: 0xFF / 255)
    case "waiting":
      return Color(red: 0xDD / 255, green: 0xD6 / 255, blue: 0xFE / 255)
    case "in_service":
      return Color(red: 0xA5 / 255, green: 0xF3 / 255, blue: 0xFC / 255)
    case "completed":
      return Color(red: 0xA7 / 255, green: 0xF3 / 255, blue: 0xD0 / 255)
    case "cancelled", "no_show":
      return Color(red: 0xFE / 255, green: 0xCA / 255, blue: 0xCA / 255)
    default:
      return glow
    }
  }

  // LinearGradient for Badge & Progress per Status
  static func statusGradient(_ status: String) -> [Color] {
    switch status {
    case "pending":
      return [Color(red: 0xD9 / 255, green: 0x77 / 255, blue: 0x06 / 255), Color(red: 0xFB / 255, green: 0xBF / 255, blue: 0x24 / 255)]
    case "confirmed":
      return [brand, sky]
    case "waiting":
      return [Color(red: 0x7C / 255, green: 0x3A / 255, blue: 0xED / 255), Color(red: 0xA7 / 255, green: 0x8B / 255, blue: 0xFA / 255)]
    case "in_service":
      return [Color(red: 0x02 / 255, green: 0x84 / 255, blue: 0xC7 / 255), cyan, Color(red: 0x67 / 255, green: 0xE8 / 255, blue: 0xF9 / 255)]
    case "completed":
      return [Color(red: 0x05 / 255, green: 0x96 / 255, blue: 0x69 / 255), Color(red: 0x34 / 255, green: 0xD3 / 255, blue: 0x99 / 255)]
    case "cancelled", "no_show":
      return [Color(red: 0xDC / 255, green: 0x26 / 255, blue: 0x26 / 255), Color(red: 0xF8 / 255, green: 0x71 / 255, blue: 0x71 / 255)]
    default:
      return [brand, sky]
    }
  }

  static func accent(_ state: BookingActivityAttributes.ContentState) -> Color {
    statusColor(state.status)
  }
}

private extension BookingActivityAttributes {
  /// Arabic UI with Latin digits, matching the app ("4:00 م").
  var locale: Locale { Locale(identifier: isArabic ? "ar_EG@numbers=latn" : "en_US") }
  var direction: LayoutDirection { isArabic ? .rightToLeft : .leftToRight }
  var deepLink: URL? { URL(string: "carzone://booking?id=\(orderId)") }
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

  /// Live countdown target: the slot before arrival, the ready time while washing.
  var countdown: ClosedRange<Date>? {
    let now = Date()
    switch status {
    case "pending", "confirmed" where scheduledAt > now:
      return now...scheduledAt
    case "in_service":
      guard let ready = readyAt, ready > now else { return nil }
      return (serviceStartedAt ?? now)...ready
    default:
      return nil
    }
  }
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
            StatusBadge(state: state, size: 36)
            VStack(alignment: .leading, spacing: 2) {
              Text("WASH UP")
                .font(.system(size: 9, weight: .black))
                .tracking(0.5)
                .foregroundStyle(Palette.glow)
              Text(state.shortStatus)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(statusColor)
                .lineLimit(1)
            }
          }
          .padding(.leading, 4)
        }
        DynamicIslandExpandedRegion(.trailing) {
          CountdownLabel(state: state, font: .system(size: 20, weight: .bold, design: .rounded))
            .padding(.trailing, 4)
            .environment(\.locale, attributes.locale)
        }
        DynamicIslandExpandedRegion(.center) {
          Text(state.title)
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(.white)
            .lineLimit(1)
        }
        DynamicIslandExpandedRegion(.bottom) {
          VStack(spacing: 10) {
            StageTrack(labels: attributes.stageLabels, state: state, compact: true)
            HStack {
              Text(attributes.branchName)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.75))
                .lineLimit(1)
              Spacer()
              CodeChip(attributes: attributes, state: state)
            }
          }
          .padding(.top, 4)
          .environment(\.layoutDirection, attributes.direction)
          .environment(\.locale, attributes.locale)
        }
      } compactLeading: {
        CompactLeadingBadge(state: state)
      } compactTrailing: {
        CountdownLabel(state: state, font: .system(size: 13, weight: .bold, design: .rounded), fallbackToStatus: true)
          .frame(maxWidth: 68)
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

  private var statusColor: Color { Palette.statusColor(state.status) }
  private var statusGlow: Color { Palette.statusGlow(state.status) }

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      // Header: Brand Badge, Status Title, Countdown / Final Symbol
      HStack(alignment: .center, spacing: 12) {
        StatusBadge(state: state, size: 44)

        VStack(alignment: .leading, spacing: 3) {
          HStack(spacing: 6) {
            Text("WASH UP")
              .font(.system(size: 9, weight: .black))
              .tracking(0.6)
              .padding(.horizontal, 6)
              .padding(.vertical, 2)
              .background(Capsule().fill(Palette.brand.opacity(0.35)))
              .overlay(Capsule().stroke(Palette.glow.opacity(0.35), lineWidth: 0.5))
              .foregroundStyle(Palette.glow)

            Text(attributes.branchName)
              .font(.system(size: 12, weight: .semibold))
              .foregroundStyle(.white.opacity(0.7))
              .lineLimit(1)
          }

          Text(state.title)
            .font(.system(size: 17, weight: .bold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
        }

        Spacer(minLength: 8)
        CountdownLabel(state: state, font: .system(size: 22, weight: .bold, design: .rounded))
      }

      // Animated Glowing Stage Track
      StageTrack(labels: attributes.stageLabels, state: state, compact: false)

      // Footer: Subtitle and Check-in Code Chip
      HStack(spacing: 8) {
        Image(systemName: "clock")
          .font(.system(size: 11, weight: .semibold))
          .foregroundStyle(statusColor)
        Text(state.subtitle)
          .font(.system(size: 13, weight: .medium))
          .lineLimit(1)
          .foregroundStyle(.white.opacity(0.85))

        Spacer(minLength: 8)
        CodeChip(attributes: attributes, state: state)
      }
    }
    .padding(16)
    .background(
      ZStack {
        // Base dark navy glass gradient
        LinearGradient(
          colors: [Palette.night, Palette.surface, Palette.deep.opacity(0.9)],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )

        // Status-colored ambient glow in the corner
        RadialGradient(
          colors: [statusGlow.opacity(0.22), Color.clear],
          center: .topLeading,
          startRadius: 0,
          endRadius: 180
        )
      }
    )
    .overlay(
      RoundedRectangle(cornerRadius: 22)
        .stroke(
          LinearGradient(
            colors: [statusColor.opacity(0.5), Palette.glow.opacity(0.2), Color.white.opacity(0.08)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          ),
          lineWidth: 1
        )
    )
    .clipShape(RoundedRectangle(cornerRadius: 22))
  }
}

// MARK: - Animated Glowing Pieces

/// Animated status badge that breathes with live glowing aura
private struct StatusBadge: View {
  let state: BookingActivityAttributes.ContentState
  let size: CGFloat

  var body: some View {
    TimelineView(.periodic(from: .now, by: 1.2)) { timeline in
      let second = Calendar.current.component(.second, from: timeline.date)
      let pulse = (second % 2 == 0)
      let statusColor = Palette.statusColor(state.status)
      let statusGlow = Palette.statusGlow(state.status)

      ZStack {
        // Outer breathing halo
        Circle()
          .fill(statusGlow.opacity(pulse ? 0.35 : 0.12))
          .frame(width: size + (pulse ? 7 : 2), height: size + (pulse ? 7 : 2))
          .animation(.easeInOut(duration: 1.1), value: pulse)

        // Gradient Badge Core
        Circle()
          .fill(LinearGradient(colors: Palette.statusGradient(state.status), startPoint: .topLeading, endPoint: .bottomTrailing))
          .frame(width: size, height: size)
          .overlay(
            Circle()
              .stroke(Color.white.opacity(0.3), lineWidth: 1)
          )
          .shadow(color: statusColor.opacity(0.7), radius: 6, x: 0, y: 2)

        Image(systemName: state.symbol)
          .font(.system(size: size * 0.44, weight: .bold))
          .foregroundStyle(.white)
      }
      .frame(width: size + 8, height: size + 8)
    }
  }
}

/// Dynamic Island compact leading view with glowing pulse
private struct CompactLeadingBadge: View {
  let state: BookingActivityAttributes.ContentState

  var body: some View {
    TimelineView(.periodic(from: .now, by: 1.2)) { timeline in
      let second = Calendar.current.component(.second, from: timeline.date)
      let pulse = (second % 2 == 0)
      let statusColor = Palette.statusColor(state.status)

      Image(systemName: state.symbol)
        .font(.system(size: 12, weight: .bold))
        .foregroundStyle(statusColor)
        .scaleEffect(pulse ? 1.1 : 1.0)
        .shadow(color: statusColor.opacity(pulse ? 0.9 : 0.4), radius: pulse ? 5 : 2)
        .animation(.easeInOut(duration: 1.1), value: pulse)
    }
  }
}

/// Dynamic Island minimal view: glowing animated progress ring
private struct StageRing: View {
  let state: BookingActivityAttributes.ContentState

  var body: some View {
    let progress = state.isCancelled ? 1 : Double(max(state.stage, 0)) / 4
    let statusColor = Palette.statusColor(state.status)

    TimelineView(.periodic(from: .now, by: 1.2)) { timeline in
      let second = Calendar.current.component(.second, from: timeline.date)
      let pulse = (second % 2 == 0)

      ZStack {
        Circle()
          .stroke(Color.white.opacity(0.18), lineWidth: 2.5)

        Circle()
          .trim(from: 0, to: max(progress, 0.08))
          .stroke(statusColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
          .rotationEffect(.degrees(-90))
          .shadow(color: statusColor.opacity(pulse ? 0.9 : 0.4), radius: 4)

        Image(systemName: state.symbol)
          .font(.system(size: 9, weight: .bold))
          .foregroundStyle(statusColor)
      }
      .animation(.easeInOut(duration: 1.1), value: pulse)
    }
  }
}

/// Time left until the slot / until car is ready, or short status
private struct CountdownLabel: View {
  let state: BookingActivityAttributes.ContentState
  let font: Font
  var fallbackToStatus = false

  private var statusColor: Color { Palette.statusColor(state.status) }

  var body: some View {
    if let range = state.countdown {
      Text(timerInterval: range, countsDown: true)
        .font(font)
        .monospacedDigit()
        .multilineTextAlignment(.trailing)
        .foregroundStyle(statusColor)
        .shadow(color: statusColor.opacity(0.4), radius: 4)
    } else if fallbackToStatus {
      Text(state.shortStatus)
        .font(font)
        .lineLimit(1)
        .foregroundStyle(statusColor)
        .shadow(color: statusColor.opacity(0.4), radius: 3)
    } else if state.status == "completed" || state.isCancelled {
      Image(systemName: state.symbol)
        .font(.system(size: 22, weight: .bold))
        .foregroundStyle(statusColor)
        .shadow(color: statusColor.opacity(0.6), radius: 5)
    }
  }
}

/// Booked → Confirmed → Arrived → Washing → Ready with animated glowing active dot
private struct StageTrack: View {
  let labels: [String]
  let state: BookingActivityAttributes.ContentState
  let compact: Bool

  private var reached: Int { state.isCancelled ? -1 : state.stage }
  private var statusColor: Color { Palette.statusColor(state.status) }
  private var statusGlow: Color { Palette.statusGlow(state.status) }

  var body: some View {
    VStack(spacing: 6) {
      HStack(spacing: 0) {
        ForEach(0..<5, id: \.self) { i in
          dot(i)
          if i < 4 {
            Capsule()
              .fill(
                i < reached
                  ? AnyShapeStyle(LinearGradient(colors: [statusColor, statusGlow], startPoint: .leading, endPoint: .trailing))
                  : AnyShapeStyle(Color.white.opacity(0.18))
              )
              .frame(height: 3)
              .shadow(color: i < reached ? statusColor.opacity(0.4) : Color.clear, radius: 2)
          }
        }
      }
      if !compact {
        HStack(spacing: 0) {
          ForEach(0..<5, id: \.self) { i in
            Text(i < labels.count ? labels[i] : "")
              .font(.system(size: 10, weight: i == reached ? .bold : .medium))
              .foregroundStyle(i == reached ? statusColor : (i < reached ? .white : .white.opacity(0.4)))
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
    let isCurrent = (i == reached)
    let isDone = (i < reached) || (isCurrent && i == 4)

    if isCurrent && !isDone {
      // Animated Glowing Active Dot
      TimelineView(.periodic(from: .now, by: 1.0)) { timeline in
        let second = Calendar.current.component(.second, from: timeline.date)
        let pulse = (second % 2 == 0)

        ZStack {
          // Pulsing halo aura
          Circle()
            .fill(statusGlow.opacity(pulse ? 0.4 : 0.15))
            .frame(width: pulse ? 20 : 16, height: pulse ? 20 : 16)
            .animation(.easeInOut(duration: 0.9), value: pulse)

          // Glowing ring
          Circle()
            .stroke(statusColor, lineWidth: 1.5)
            .frame(width: 13, height: 13)

          // Solid core
          Circle()
            .fill(statusColor)
            .frame(width: 8, height: 8)
            .shadow(color: statusGlow.opacity(0.9), radius: 5)
        }
        .frame(width: 20, height: 20)
      }
    } else {
      ZStack {
        Circle()
          .fill(isDone ? statusColor : Color.white.opacity(0.22))
          .frame(width: 8, height: 8)
          .shadow(color: isDone ? statusColor.opacity(0.5) : Color.clear, radius: 3)

        if isDone && i == 4 {
          Image(systemName: "checkmark")
            .font(.system(size: 6, weight: .black))
            .foregroundStyle(Palette.night)
        }
      }
      .frame(width: 20, height: 20)
    }
  }
}

/// The check-in code chip with modern glass styling
private struct CodeChip: View {
  let attributes: BookingActivityAttributes
  let state: BookingActivityAttributes.ContentState

  private var statusColor: Color { Palette.statusColor(state.status) }

  var body: some View {
    if !attributes.code.isEmpty && !state.isCancelled && state.status != "completed" {
      HStack(spacing: 4) {
        Text(attributes.codeLabel)
          .font(.system(size: 10, weight: .medium))
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
        .foregroundStyle(.white.opacity(0.6))
    }
  }
}
