
import SwiftUI
import UIKit
import CoreHaptics

struct AmbientBackground: View {
    @State private var animate = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.10, green: 0.12, blue: 0.22),
                        Color(red: 0.16, green: 0.17, blue: 0.29),
                        Color(red: 0.08, green: 0.10, blue: 0.18)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Circle()
                    .fill(Color(red: 0.48, green: 0.40, blue: 0.78)
                        .opacity(0.55))
                    .frame(width: 220, height: 220)
                    .blur(radius: 65)
                    .offset(
                        x: animate ? -80 : 45,
                        y: animate ? -150 : -60
                    )

                Circle()
                    .fill(Color(red: 0.30, green: 0.60, blue: 0.72)
                        .opacity(0.40))
                    .frame(width: 190, height: 190)
                    .blur(radius: 70)
                    .offset(
                        x: animate ? 100 : -70,
                        y: animate ? 100 : 190
                    )

                Circle()
                    .fill(Color(red: 0.65, green: 0.43, blue: 0.62)
                        .opacity(0.35))
                    .frame(width: 160, height: 160)
                    .blur(radius: 65)
                    .offset(
                        x: animate ? -90 : 70,
                        y: animate ? 240 : 100
                    )
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
            .clipped()
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 12)
                        .repeatForever(autoreverses: true)
                ) {
                    animate = true
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}


struct TrackingEvent: Codable, Identifiable {
    let id: UUID
    let appID: String
    let type: String
    let timestamp: Date

    init(appID: String, type: String) {
        self.id = UUID()
        self.appID = appID
        self.type = type
        self.timestamp = Date()
    }
}

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var wasInBackground = false
    @AppStorage("pauseAttempts") private var savedAttempts = ""
    @AppStorage("trackingEvents")
    private var trackingEventsData = "[]"
    @AppStorage("skipNextInstagramTrigger")
    private var skipNextInstagramTrigger = false

    @State private var panelVisible = false
    @State private var contentVisible = false
    @State private var buttonsVisible = false
    @State private var breathingIn = false
    @State private var breathingTimer: Timer?
    @State private var declined = false
    @State private var haptics = HapticManager()
    @State private var currentAppID = "instagram"
    @State private var flowStarted = false
    @State private var flowID = 0
    @State private var currentPrompt = PausePrompts.random()
    
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

    
    private func startFlow(appID: String? = nil) {
        flowID += 1
        let thisFlowID = flowID
        currentPrompt = PausePrompts.random()

        if let appID {
            currentAppID = appID
        }

        flowStarted = true

        // Start with a clean visual state.
        panelVisible = false
        contentVisible = false
        buttonsVisible = false
        breathingIn = false
        declined = false

        pauseColor = pauseColors.randomElement() ?? pauseColors[0]
        haptics.playBoiling()
        recordAttempt(appID: currentAppID)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            guard flowID == thisFlowID else { return }

            withAnimation(.easeInOut(duration: breathDuration)) {
                panelVisible = true
            }

            haptics.stop()
            haptics.playRamp()
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                guard flowID == thisFlowID else { return }

                withAnimation(.easeOut(duration: 0.5)) {
                    contentVisible = true
                }

                startBreathing()

                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    guard flowID == thisFlowID else { return }

                    withAnimation(.easeOut(duration: 0.35)) {
                        buttonsVisible = true
                    }

                    UIImpactFeedbackGenerator(style: .medium)
                        .impactOccurred()
                }
            }
        }
    }

    
    private func logEvent(
        _ type: String,
        appID: String = "instagram"
    ) {
        let data = Data(trackingEventsData.utf8)

        var events =
            (try? JSONDecoder().decode(
                [TrackingEvent].self,
                from: data
            )) ?? []

        events.append(
            TrackingEvent(appID: appID, type: type)
        )

        if let encoded = try? JSONEncoder().encode(events),
           let json = String(data: encoded, encoding: .utf8) {
            trackingEventsData = json
        }
    }
    
    private var recentCount: Int {
        let now = Date()

        let data = Data(trackingEventsData.utf8)
        let events = (try? JSONDecoder().decode(
            [TrackingEvent].self,
            from: data
        )) ?? []

        return events.filter { event in
            event.appID == currentAppID &&
            event.type == "attempt" &&
            now.timeIntervalSince(event.timestamp) < 86400 &&
            event.timestamp <= now
        }.count
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
                
                AmbientBackground()
                Text(currentPrompt)
                    .font(.system(size: 23, weight: .regular, design: .rounded))
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .foregroundStyle(.white.opacity(0.92))
                    .padding(.horizontal, 32)
                    .shadow(color: .white.opacity(0.15), radius: 12)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity)

                
                VStack {
                    Spacer()

                    if panelVisible {
                        VStack(spacing: 0) {
                            // Header
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Pause")
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
                                                logEvent("declined", appID: currentAppID)
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
                                            continueToApp()
                                        } label: {
                                            Text("Continue to \(currentAppID.capitalized)")
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
            // when user opens Pause directly
        }
        .onOpenURL { url in
            guard
                url.scheme == "pause",
                url.host == "open"
            else {
                return
            }

            let components = URLComponents(
                url: url,
                resolvingAgainstBaseURL: false
            )

            let appID = components?.queryItems?
                .first(where: { $0.name == "app" })?.value

            flowStarted = false
            startFlow(appID: appID)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active {
                wasInBackground = true
                flowStarted = false

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
            }
        }
    }

    private func recordAttempt(appID: String) {
        let now = Date().timeIntervalSince1970

        let recent = savedAttempts.split(separator: ",")
            .compactMap { Double($0) }
            .filter { now - $0 < 86400 }

        savedAttempts = (recent + [now])
            .map { String($0) }
            .joined(separator: ",")

        logEvent("attempt", appID: appID)
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


    private func continueToApp() {
        logEvent("continued", appID: currentAppID)

        UserDefaults.standard.set(
            Date().timeIntervalSince1970,
            forKey: "\(currentAppID)BypassTimestamp"
        )

        let appURLString: String

        switch currentAppID {
        case "instagram":
            appURLString = "instagram://"
        case "brave":
            appURLString = "brave://"
        default:
            return
        }

        guard let url = URL(string: appURLString) else { return }
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
                    .init(relativeTime: 0.0, value: 0.1),
                    .init(relativeTime: 0.7, value: 0.2),
                    .init(relativeTime: 1.4, value: 0.3),
                    .init(relativeTime: 2.1, value: 0.4),
                    .init(relativeTime: 3.0, value: 0.5)
                ],
                relativeTime: 0
            )

            let sharpnessCurve = CHHapticParameterCurve(
                parameterID: .hapticSharpnessControl,
                controlPoints: [
                    .init(relativeTime: 0.0, value: 0.1),
                    .init(relativeTime: 1.0, value: 0.25),
                    .init(relativeTime: 2.0, value: 0.55),
                    .init(relativeTime: 3.0, value: 0.7)
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
