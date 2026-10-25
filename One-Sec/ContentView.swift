
import SwiftUI
import UIKit
import CoreHaptics

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var wasInBackground = false
    @AppStorage("pauseAttempts") private var savedAttempts = ""
    @AppStorage("skipNextInstagramTrigger")
    private var skipNextInstagramTrigger = false

    @State private var panelVisible = false
    @State private var contentVisible = false
    @State private var buttonsVisible = false
    @State private var breathingIn = false
    @State private var breathingTimer: Timer?
    @State private var declined = false
    @State private var haptics = HapticManager()
    
    private let pauseColors: [Color] = [
        Color(red: 184/255, green: 121/255, blue: 121/255), // Dusty Rose
        Color(red: 141/255, green: 123/255, blue: 112/255), // Warm Taupe
        Color(red: 133/255, green: 133/255, blue: 104/255), // Olive
        Color(red: 130/255, green: 148/255, blue: 135/255), // Sage
        Color(red: 120/255, green: 140/255, blue: 155/255), // Slate Blue
        Color(red: 121/255, green: 103/255, blue: 125/255)  // Muted Plum
    ]
    @State private var pauseColor: Color = Color(red: 184/255, green: 121/255, blue: 121/255)
    
    private let breathDuration: Double = 4

    private func startFlow() {
        guard !panelVisible else { return }
        pauseColor = pauseColors.randomElement() ?? pauseColors[0]
        haptics.playBoiling()
        recordAttempt()

        guard !panelVisible else { return }
        
        haptics.playBoiling()
        
        recordAttempt()
        
        // Wait 2 seconds before showing the panel.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeInOut(duration: breathDuration)) {
                panelVisible = true
            }
            
            haptics.stop()
            haptics.playRamp()
            
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            
            // Reveal content after the 3-second slide finishes.
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeOut(duration: 0.5)) {
                    contentVisible = true
                }
                
                startBreathing()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    withAnimation(.easeOut(duration: 0.35)) {
                        buttonsVisible = true
                    }
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            }
        }
    
    }
    
    private var recentCount: Int {
        let now = Date().timeIntervalSince1970
        return savedAttempts.split(separator: ",")
            .compactMap { Double($0) }
            .filter { now - $0 < 86400 }
            .count
    }
    
    private func rampHaptics(step: Int = 0) {
        let intervals: [Double] = [
            0.65, 0.55, 0.45, 0.38, 0.32, 0.27, 0.23
        ]

        let styles: [UIImpactFeedbackGenerator.FeedbackStyle] = [
            .soft, .light, .medium, .medium, .heavy, .rigid, .rigid
        ]

        guard step < intervals.count else { return }

        UIImpactFeedbackGenerator(style: styles[step])
            .impactOccurred(intensity: 1.0)

        DispatchQueue.main.asyncAfter(
            deadline: .now() + intervals[step]
        ) {
            rampHaptics(step: step + 1)
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dimmed background
                Color(red: 0.12, green: 0.12, blue: 0.14)
                    .ignoresSafeArea()

                // Background glow
                Circle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 180, height: 180)
                    .scaleEffect(breathingIn ? 1.0 : 0.72)
                    .animation(.easeInOut(duration: breathDuration), value: breathingIn)
                    .frame(width: 220, height: 220)
                
                VStack {
                    Spacer()

                    if panelVisible {
                        VStack(spacing: 0) {
                            // Header
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("ONE SEC")
                                        .font(.caption.weight(.bold))
                                        .tracking(3)
                                        .foregroundStyle(.white.opacity(0.7))

                                    Text(declined
                                         ? "Good choice."
                                         : "Before you scroll.")
                                        .font(.system(size: 29, weight: .bold))
                                        .foregroundStyle(.white)
                                }

                                Spacer()

                                Image(systemName: "pause.circle.fill")
                                    .font(.system(size: 34))
                                    .foregroundStyle(.white.opacity(0.85))
                            }
                            .padding(.top, 80)
                            .padding(.horizontal, 26)

                            Spacer(minLength: 20)

                            if !declined {
                                // Breathing guide
                                VStack(spacing: 24) {
                                    
                                    ZStack {
                                        Circle()
                                            .fill(.white.opacity(0.08))
                                            .frame(width: 280, height: 280)
                                            .scaleEffect(breathingIn ? 1.0 : 0.79)

                                        Circle()
                                            .stroke(.white.opacity(0.18), lineWidth: 1)
                                            .frame(width: 176, height: 176)
                                            .scaleEffect(breathingIn ? 1.0 : 0.77)

                                        Circle()
                                            .fill(
                                                RadialGradient(
                                                    colors: [
                                                        Color.white.opacity(0.95),
                                                        Color(red: 1, green: 0.45, blue: 0.42)
                                                    ],
                                                    center: .topLeading,
                                                    startRadius: 2,
                                                    endRadius: 180
                                                )
                                            )
                                            .frame(width: 146, height: 146)
                                            .scaleEffect(breathingIn ? 1.0 : 0.64)
                                            .shadow(color: .red.opacity(0.35), radius: 25)
                                    }
                                    .frame(width: 280, height: 280)
                                    .animation(.easeInOut(duration: breathDuration), value: breathingIn)


                                    VStack(spacing: 8) {
                                        Text(breathingIn ? "Breathe in" : "Breathe out")
                                            .font(.system(size: 24, weight: .medium))
                                            .foregroundStyle(.white)
                                            .frame(width: 220, height: 32, alignment: .center)
                                            .multilineTextAlignment(.center)
                                            .contentTransition(.identity)

                                        Text("Take a moment for yourself")
                                            .font(.subheadline)
                                            .foregroundStyle(.white.opacity(0.65))
                                    }

                                    Text("\(recentCount) attempts in the past 24 hours")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(.white.opacity(0.65))
                                        .padding(.top, 4)
                                }
                            } else {
                                VStack(spacing: 14) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 58))
                                        .foregroundStyle(.white)

                                    Text("You chose your time.")
                                        .font(.title3.weight(.medium))
                                        .foregroundStyle(.white)

                                    Text("Swipe up when you're ready.")
                                        .foregroundStyle(.white.opacity(0.65))
                                }
                            }

                            Spacer(minLength: 20)

                            // Buttons appear after 3 seconds
                            
                            ZStack {
                                if buttonsVisible {
                                    VStack(spacing: 12) {
                                        Button {
                                            if !declined {
                                                withAnimation(.spring(response: 0.45)) {
                                                    declined = true
                                                }
                                                UIImpactFeedbackGenerator(style: .light)
                                                    .impactOccurred()
                                            }
                                        } label: {
                                            Text(declined ? "Done" : "Not now")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundStyle(.black)
                                                .frame(maxWidth: .infinity)
                                                .padding(19)
                                                .background(
                                                    .white,
                                                    in: RoundedRectangle(cornerRadius: 18)
                                                )
                                        }

                                        Button {
                                            continueToInstagram()
                                        } label: {
                                            Text("Continue to Instagram")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundStyle(.white.opacity(0.85))
                                                .frame(maxWidth: .infinity)
                                                .padding(16)
                                                .background(
                                                    .white.opacity(0.10),
                                                    in: RoundedRectangle(cornerRadius: 18)
                                                )
                                        }
                                    }
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                                } else {
                                    Text("Pause. Breathe. Choose.")
                                        .font(.footnote.weight(.medium))
                                        .tracking(1)
                                        .foregroundStyle(.white.opacity(0.55))
                                }
                            }
                            .frame(height: 130)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 70)
                        }
                        .opacity(contentVisible ? 1 : 0)
                        .frame(
                            maxWidth: .infinity,
                            maxHeight: .infinity
                        )
                        .background {
                            pauseColor
                            .ignoresSafeArea()
                        }
                        .transition(.move(edge: .bottom))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(edges: .bottom)
            }
            .ignoresSafeArea()
        }
        .preferredColorScheme(.dark)
        .onAppear {
            startFlow()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active {
                wasInBackground = true

                // Reset before iOS backgrounds the app.
                haptics.stop()
                breathingTimer?.invalidate()
                breathingTimer = nil

                var transaction = Transaction()
                transaction.disablesAnimations = true

                withTransaction(transaction) {
                    panelVisible = false
                    contentVisible = false
                    buttonsVisible = false
                    breathingIn = false
                    declined = false
                }
            }

            if newPhase == .active && wasInBackground {
                wasInBackground = false
                startFlow()
            }
        }
    }

    private func recordAttempt() {
        let now = Date().timeIntervalSince1970
        let recent = savedAttempts.split(separator: ",")
            .compactMap { Double($0) }
            .filter { now - $0 < 86400 }

        savedAttempts = (recent + [now])
            .map { String($0) }
            .joined(separator: ",")
    }

    
    private func startBreathing() {
        breathingTimer?.invalidate()

        breathingIn = true

        breathingTimer = Timer.scheduledTimer(
            withTimeInterval: breathDuration,
            repeats: true
        ) { _ in
            withAnimation(.easeInOut(duration: breathDuration)) {
                breathingIn.toggle()
            }
        }
    }


    private func continueToInstagram() {
        UserDefaults.standard.set(
            Date().timeIntervalSince1970,
            forKey: "instagramBypassTimestamp"
        )

        guard let url = URL(string: "instagram://") else { return }
        UIApplication.shared.open(url)
    }
}


final class HapticManager {
    private var engine: CHHapticEngine?
    private var player: CHHapticPatternPlayer?

    init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            return
        }

        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("Haptic engine error: \(error)")
        }
    }

    func playBoiling() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            return
        }

        do {
            try engine?.start()

            // Closely spaced, irregular little pulses.
            let times: [Double] = [
                0.00, 0.09, 0.21, 0.29, 0.43,
                0.51, 0.62, 0.78, 0.84, 0.97,
                1.08, 1.16, 1.31, 1.39, 1.52,
                1.64, 1.72, 1.85, 1.94
            ]

            let events = times.map { time -> CHHapticEvent in
                let intensity = Float.random(in: 0.85...1.0)
                let sharpness = Float.random(in: 0.7...1.0)

                return CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(
                            parameterID: .hapticIntensity,
                            value: intensity
                        ),
                        CHHapticEventParameter(
                            parameterID: .hapticSharpness,
                            value: sharpness
                        )
                    ],
                    relativeTime: time
                )
            }

            let pattern = try CHHapticPattern(events: events, parameters: [])
            player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)

        } catch {
            print("Boiling haptics error: \(error)")
        }
    }

    func playRamp() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            return
        }

        do {
            try engine?.start()

            let duration = 3.0

            let event = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(
                        parameterID: .hapticIntensity,
                        value: 0.8
                    ),
                    CHHapticEventParameter(
                        parameterID: .hapticSharpness,
                        value: 0.8
                    )
                ],
                relativeTime: 0,
                duration: duration
            )

            let intensityCurve = CHHapticParameterCurve(
                parameterID: .hapticIntensityControl,
                controlPoints: [
                    .init(relativeTime: 0.0, value: 0.8),
                    .init(relativeTime: 0.7, value: 0.85),
                    .init(relativeTime: 1.4, value: 0.9),
                    .init(relativeTime: 2.1, value: 0.95),
                    .init(relativeTime: 3.0, value: 1.0)
                ],
                relativeTime: 0
            )

            let sharpnessCurve = CHHapticParameterCurve(
                parameterID: .hapticSharpnessControl,
                controlPoints: [
                    .init(relativeTime: 0.0, value: 0.1),
                    .init(relativeTime: 1.0, value: 0.25),
                    .init(relativeTime: 2.0, value: 0.55),
                    .init(relativeTime: 3.0, value: 0.9)
                ],
                relativeTime: 0
            )

            let pattern = try CHHapticPattern(
                events: [event],
                parameterCurves: [intensityCurve, sharpnessCurve]
            )

            player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)

        } catch {
            print("Ramp haptics error: \(error)")
        }
    }

    func stop() {
        try? player?.stop(atTime: 0)
        player = nil
    }
}
