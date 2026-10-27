//
//  PausePanel.swift
//  One-Sec
//
//  Created by Christina Go on 10/26/26.
//


//
//  PausePanel.swift
//  One-Sec
//
import SwiftUI

struct PausePanel: View {
    let color: Color
    let breathingIn: Bool
    let breathDuration: Double
    let declined: Bool
    let buttonsVisible: Bool
    let contentVisible: Bool
    let attemptsToday: Int
    let appName: String
    let onNotNow: () -> Void
    let onContinue: () -> Void
    let onActivity: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Spacer()
            middle
            Spacer()
            footer
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 24)
        .padding(.top, 80)
        .padding(.bottom, 56)
        .opacity(contentVisible ? 1 : 0)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            Rectangle()
                .fill(color.gradient)
                .ignoresSafeArea()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(declined ? "Good choice." : "Before you scroll.")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .contentTransition(.opacity)

            Text("^[\(attemptsToday) attempt](inflect: true) today")
                .font(.system(.title3, design: .rounded, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    @ViewBuilder
    private var middle: some View {
        if declined {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .padding(.bottom, 8)
                Text("You chose your time.")
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                Text("Swipe up when you're ready.")
                    .foregroundStyle(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .transition(.scale(scale: 0.9).combined(with: .opacity))
        } else {
            VStack(spacing: 40) {
                flower
                Text(breathingIn ? "Breathe in" : "Breathe out")
                    .font(.system(.title, design: .rounded, weight: .semibold))
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.6), value: breathingIn)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var flower: some View {
        ZStack {
            ForEach(0..<6) { i in
                Circle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 130, height: 130)
                    .offset(y: breathingIn ? -56 : 0)
                    .rotationEffect(.degrees(Double(i) * 60))
                    .blendMode(.plusLighter)
            }
        }
        .frame(width: 280, height: 280)
        .scaleEffect(breathingIn ? 1 : 0.55)
        .rotationEffect(.degrees(breathingIn ? 60 : 0))
        .animation(.easeInOut(duration: breathDuration), value: breathingIn)
    }

    private var footer: some View {
        ZStack(alignment: .bottom) {
            if buttonsVisible {
                VStack(spacing: 12) {
                    Button(declined ? "Done" : "Not now", action: onNotNow)
                        .buttonStyle(PanelButton(fill: .white, text: color))

                    Button("Continue to \(appName)", action: onContinue)
                        .buttonStyle(PanelButton(fill: .white.opacity(0.18), text: .white))

                    Button("View activity", action: onActivity)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.top, 4)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                Text("Pause. Breathe. Choose.")
                    .font(.footnote.weight(.medium))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 170, alignment: .bottom)
    }
}

private struct PanelButton: ButtonStyle {
    let fill: Color
    let text: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded, weight: .semibold))
            .foregroundStyle(text)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(fill, in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
