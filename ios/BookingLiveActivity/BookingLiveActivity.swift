import ActivityKit
import SwiftUI
import WidgetKit

@main
struct BookingLiveActivityBundle: WidgetBundle {
  var body: some Widget {
    BookingLiveActivity()
  }
}

// MARK: - Palette (Wash Up, matches lib/core/constance/app_colors.dart)

private enum Palette {
  static let brand = Color(red: 0x00 / 255, green: 0x70 / 255, blue: 0xE8 / 255)
  static let sky = Color(red: 0x03 / 255, green: 0x96 / 255, blue: 0xFB / 255)
  static let glow = Color(red: 0x6F / 255, green: 0xD3 / 255, blue: 0xFF / 255)
  static let deep = Color(red: 0x01 / 255, green: 0x39 / 255, blue: 0x8C / 255)
  static let night = Color(red: 0x01 / 255, green: 0x19 / 255, blue: 0x3A / 255)
  static let success = Color(red: 0x34 / 255, green: 0xD3 / 255, blue: 0x99 / 255)
  static let danger = Color(red: 0xF8 / 255, green: 0x71 / 255, blue: 0x71 / 255)

  static func accent(_ state: BookingActivityAttributes.ContentState) -> Color {
    switch state.status {
    case "completed": return success
    case "cancelled", "no_show": return danger
    default: return glow
    }
  }
}

private extension BookingActivityAttributes {
  /// Arabic UI with Latin digits, as in the app ("4:00 م").
  var locale: Locale { Locale(identifier: isArabic ? "ar_EG@numbers=latn" : "en_US") }
  var direction: LayoutDirection { isArabic ? .rightToLeft : .leftToRight }
  var deepLink: URL? { URL(string: "carzone://booking?id=\(orderId)") }
}

private extension BookingActivityAttributes.ContentState {
  var isCancelled: Bool { status == "cancelled" || status == "no_show" }
  var symbol: String {
    switch status {
    case "completed": return "checkmark.seal.fill"
    case "cancelled", "no_show": return "xmark.circle.fill"
    case "in_service": return "drop.fill"
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

// MARK: - Widget

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
      return DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          HStack(spacing: 6) {
            StatusBadge(state: state, size: 34)
            Text(state.shortStatus)
              .font(.system(size: 13, weight: .semibold))
              .foregroundStyle(Palette.accent(state))
              .lineLimit(1)
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
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.7))
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
        Image(systemName: state.symbol)
          .foregroundStyle(Palette.accent(state))
      } compactTrailing: {
        CountdownLabel(state: state, font: .system(size: 13, weight: .semibold, design: .rounded), fallbackToStatus: true)
          .frame(maxWidth: 64)
          .environment(\.locale, attributes.locale)
      } minimal: {
        StageRing(state: state)
      }
      .widgetURL(attributes.deepLink)
      .keylineTint(Palette.sky)
    }
  }
}

// MARK: - Lock screen

private struct LockScreenView: View {
  let attributes: BookingActivityAttributes
  let state: BookingActivityAttributes.ContentState

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(alignment: .center, spacing: 12) {
        StatusBadge(state: state, size: 44)
        VStack(alignment: .leading, spacing: 2) {
          Text(attributes.branchName)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.white.opacity(0.65))
            .lineLimit(1)
          Text(state.title)
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
        Spacer(minLength: 8)
        CountdownLabel(state: state, font: .system(size: 22, weight: .bold, design: .rounded))
      }

      StageTrack(labels: attributes.stageLabels, state: state, compact: false)

      HStack(spacing: 8) {
        Image(systemName: "clock")
          .font(.system(size: 11, weight: .semibold))
        Text(state.subtitle)
          .font(.system(size: 13, weight: .medium))
          .lineLimit(1)
        Spacer(minLength: 8)
        CodeChip(attributes: attributes, state: state)
      }
      .foregroundStyle(.white.opacity(0.8))
    }
    .padding(16)
    .background(
      LinearGradient(colors: [Palette.night, Palette.deep], startPoint: .topLeading, endPoint: .bottomTrailing)
    )
  }
}

// MARK: - Pieces

/// Round badge with the stage symbol, glowing in the status colour.
private struct StatusBadge: View {
  let state: BookingActivityAttributes.ContentState
  let size: CGFloat

  var body: some View {
    ZStack {
      Circle()
        .fill(
          LinearGradient(
            colors: state.isCancelled ? [Palette.danger.opacity(0.9), Palette.danger.opacity(0.6)]
              : state.status == "completed" ? [Palette.success, Palette.success.opacity(0.7)]
              : [Palette.sky, Palette.brand],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
      Image(systemName: state.symbol)
        .font(.system(size: size * 0.42, weight: .semibold))
        .foregroundStyle(.white)
    }
    .frame(width: size, height: size)
    .shadow(color: Palette.accent(state).opacity(0.45), radius: 6)
  }
}

/// Time left until the slot / until the car is ready; otherwise the short status.
private struct CountdownLabel: View {
  let state: BookingActivityAttributes.ContentState
  let font: Font
  var fallbackToStatus = false

  var body: some View {
    if let range = state.countdown {
      Text(timerInterval: range, countsDown: true)
        .font(font)
        .monospacedDigit()
        .multilineTextAlignment(.trailing)
        .foregroundStyle(Palette.accent(state))
    } else if fallbackToStatus {
      Text(state.shortStatus)
        .font(font)
        .lineLimit(1)
        .foregroundStyle(Palette.accent(state))
    } else if state.status == "completed" || state.isCancelled {
      Image(systemName: state.symbol)
        .font(.system(size: 22, weight: .bold))
        .foregroundStyle(Palette.accent(state))
    }
  }
}

/// Booked → Confirmed → Arrived → Washing → Ready, with the current stage glowing.
private struct StageTrack: View {
  let labels: [String]
  let state: BookingActivityAttributes.ContentState
  let compact: Bool

  private var reached: Int { state.isCancelled ? -1 : state.stage }

  var body: some View {
    VStack(spacing: 6) {
      HStack(spacing: 0) {
        ForEach(0..<5, id: \.self) { i in
          dot(i)
          if i < 4 {
            Capsule()
              .fill(i < reached ? AnyShapeStyle(LinearGradient(colors: [Palette.sky, Palette.glow], startPoint: .leading, endPoint: .trailing))
                    : AnyShapeStyle(Color.white.opacity(0.18)))
              .frame(height: 3)
          }
        }
      }
      if !compact {
        HStack(spacing: 0) {
          ForEach(0..<5, id: \.self) { i in
            Text(i < labels.count ? labels[i] : "")
              .font(.system(size: 10, weight: i == reached ? .bold : .medium))
              .foregroundStyle(i <= reached ? .white : .white.opacity(0.45))
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
    let isCurrent = i == reached
    let done = i < reached || (isCurrent && i == 4)
    ZStack {
      if isCurrent && !done {
        Circle().fill(Palette.glow.opacity(0.25)).frame(width: 18, height: 18)
      }
      Circle()
        .fill(done || isCurrent ? Palette.glow : Color.white.opacity(0.25))
        .frame(width: isCurrent ? 10 : 8, height: isCurrent ? 10 : 8)
      if done && i == 4 {
        Image(systemName: "checkmark")
          .font(.system(size: 6, weight: .black))
          .foregroundStyle(Palette.night)
      }
    }
    .frame(width: 18, height: 18)
  }
}

/// The check-in code the wash scans or asks for.
private struct CodeChip: View {
  let attributes: BookingActivityAttributes
  let state: BookingActivityAttributes.ContentState

  var body: some View {
    if !attributes.code.isEmpty && !state.isCancelled && state.status != "completed" {
      HStack(spacing: 4) {
        Text(attributes.codeLabel)
          .font(.system(size: 10, weight: .medium))
          .foregroundStyle(.white.opacity(0.65))
        Text(attributes.code)
          .font(.system(size: 13, weight: .bold, design: .monospaced))
          .foregroundStyle(.white)
          .environment(\.layoutDirection, .leftToRight)
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(Capsule().fill(Color.white.opacity(0.12)))
    } else {
      Text(attributes.number)
        .font(.system(size: 11, weight: .semibold, design: .monospaced))
        .foregroundStyle(.white.opacity(0.6))
    }
  }
}

/// Dynamic Island minimal view: progress ring around the stage symbol.
private struct StageRing: View {
  let state: BookingActivityAttributes.ContentState

  var body: some View {
    let progress = state.isCancelled ? 1 : Double(max(state.stage, 0)) / 4
    ZStack {
      Circle().stroke(Color.white.opacity(0.2), lineWidth: 2.5)
      Circle()
        .trim(from: 0, to: max(progress, 0.08))
        .stroke(Palette.accent(state), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
        .rotationEffect(.degrees(-90))
      Image(systemName: state.symbol)
        .font(.system(size: 9, weight: .bold))
        .foregroundStyle(Palette.accent(state))
    }
  }
}
