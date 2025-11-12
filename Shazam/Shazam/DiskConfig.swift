//
//  DiskConfig.swift
//  Shazam
//
//  Created by Aniseh Khajuei on 12/11/25.
//


//
//  PulsRingsView2.swift
//  Shazam-like Pulsing Rings (cleaned, with preview)
//  Created by ChatGPT — refactor for PulsRingsView2
//

import SwiftUI

// MARK: - Small config models (keeps view code tidy)
struct DiskConfig {
    let id: String
    let baseSize: CGFloat
    let baseOpacity: Double
    let amplitude: CGFloat
    let color: Color
    let blendMode: BlendMode?
}

struct RingConfig {
    let id: String
    let startSize: CGFloat
    let lineWidth: CGFloat
    let baseOpacity: Double
    let extraOpacity: Double
    let maxScale: CGFloat
    let speed: Double
}

// MARK: - PulsRingsView2
struct PulsRingsView2: View {
    // MARK: - Global tuning (clear names)
    let breathingFrequency: Double = 0.04       // fast breathing (Hz)
    let breathingAmplitude: CGFloat = 0.02      // how much fast breathing affects scale (local multipliers)
    let swellFrequency: Double = 0.8            // slow envelope frequency (Hz)
    let swellAmplitude: CGFloat = 0.20          // how much swell multiplies sizes

    // MARK: - Layer configurations (semantic names)
    // central disk (main)
    let centralDisk = DiskConfig(
        id: "central",
        baseSize: 140,
        baseOpacity: 0.95,
        amplitude: 0.04,
        color: .blue,
        blendMode: nil
    )

    // four filled halo disks (stacked, behind central)
    let filledHaloDisks: [DiskConfig] = [
        DiskConfig(id: "halo-0", baseSize: 220, baseOpacity: 0.14, amplitude: 0.015, color: .white, blendMode: .plusLighter),
        DiskConfig(id: "halo-1", baseSize: 180, baseOpacity: 0.28, amplitude: 0.02,  color: .white, blendMode: .plusLighter),
        DiskConfig(id: "halo-2", baseSize: 150, baseOpacity: 0.10, amplitude: 0.01,  color: .white, blendMode: .plusLighter),
        DiskConfig(id: "halo-3", baseSize: 260, baseOpacity: 0.06, amplitude: 0.008, color: .white, blendMode: .plusLighter)
    ]

    // two thin stroked outer rings (expanding)
    let outerStrokedRings: [RingConfig] = [
        RingConfig(id: "ring-0", startSize: 300, lineWidth: 1.0, baseOpacity: 0.05, extraOpacity: 0.35, maxScale: 2.4, speed: 0.25),
        RingConfig(id: "ring-1", startSize: 340, lineWidth: 0.8, baseOpacity: 0.04, extraOpacity: 0.30, maxScale: 2.2, speed: 0.22)
    ]

    // Squeeze settings (tiny, growth-only pulses)
    let squeezesPerSwell: Int = 2
    let squeezeAmount: CGFloat = 0.02
    let squeezeWidthFraction: Double = 0.05

    // Local state for a subtle appear animation (optional)
    @State private var appearScale: CGFloat = 1.0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background gradient (Shazam-like blue)
                LinearGradient(
                    gradient: Gradient(colors: [Color(red: 0.02, green: 0.58, blue: 1.00),
                                                Color(red: 0.00, green: 0.16, blue: 0.85)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // TimelineView drives per-frame time-based calculations
                TimelineView(.animation) { ctx in
                    let t = ctx.date.timeIntervalSinceReferenceDate

                    // --- FAST breathing oscillator (for inner/main motion) ---
                    let fast = sin(2 * .pi * breathingFrequency * t)    // -1 .. +1
                    let normFast = (fast + 1.0) / 2.0                    // 0 .. 1

                    // --- SLOW swell envelope (global) ---
                    let swell = sin(2 * .pi * swellFrequency * t)       // -1 .. +1
                    let swellNorm = (swell + 1.0) / 2.0                 // 0 .. 1
                    let swellFactor = 1.0 + swellAmplitude * CGFloat(swellNorm)

                    // --- SQUEEZE / PULSE (triangular pulses only while swell is rising) ---
                    let swellSlope = cos(2 * .pi * swellFrequency * t)
                    let isGrowingMask = swellSlope > 0.0 ? 1.0 : 0.0
                    let rawPulsePos = fmod(swellNorm * Double(squeezesPerSwell), 1.0)
                    let halfWidth = squeezeWidthFraction * 0.5
                    let d = abs(rawPulsePos - 0.5)
                    let basePulse: Double = d >= halfWidth ? 0.0 : 1.0 - (d / halfWidth)
                    let pulseValue: Double = basePulse * isGrowingMask
                    let squeezeMultiplier = 1.0 - squeezeAmount * CGFloat(pulseValue)

                    // --- COMPUTE SCALES & OPACITIES FOR EACH LAYER ---
                    // Central disk (directly driven by fast)
                    let innerScaleUnclamped = (1.0 + centralDisk.amplitude * CGFloat(fast)) * swellFactor
                    let innerScale = innerScaleUnclamped * squeezeMultiplier
                    let innerOpacity: Double = centralDisk.baseOpacity

                    // Halo (filled) disks: computed per-disk below using their amplitude + swellFactor
                    // Outer stroked rings: computed in their ForEach (progress-based)

                    // Compute a responsive multiplier to scale center block by available space
                    let minSide = min(geo.size.width, geo.size.height)
                    let centerBlockScale = minSide / 400.0 // 400 chosen as an arbitrary design base

                    // --- DRAW: Filled halo disks + central disk ---
                    ZStack {
                        // Filled halo disks (loop)
                        ForEach(filledHaloDisks, id: \.id) { d in
                            let diskScale = (1.0 + d.amplitude * CGFloat(fast)) * swellFactor * centerBlockScale
                            Circle()
                                .fill(d.color.opacity(d.baseOpacity))
                                .frame(width: d.baseSize, height: d.baseSize)
                                .scaleEffect(diskScale)
                                .blendMode(d.blendMode ?? .normal)
                        }

                        // Central disk (top of stack)
                        ZStack {
                            Circle()
                                .fill(centralDisk.color)
                                .frame(width: centralDisk.baseSize, height: centralDisk.baseSize)
                                .overlay(Circle().stroke(Color.white, lineWidth: 1))
                                .scaleEffect(innerScale * centerBlockScale)
                                .shadow(color: Color.blue.opacity(0.5), radius: 10, x: 0, y: 6)

                            // Icon (SF Symbol) — replace with asset if you have real logo
                            Image(systemName: "waveform.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: centralDisk.baseSize * 0.5, height: centralDisk.baseSize * 0.5)
                                .foregroundColor(.white)
                                .scaleEffect(innerScale * centerBlockScale)
                        }
                    }
                    .frame(width: minSide * 0.7, height: minSide * 0.7)
                    .position(x: geo.size.width / 2.0, y: geo.size.height / 2.0 * 0.95)

                    // --- DRAW: outer stroked rings (expanding rings) ---
                    ForEach(outerStrokedRings, id: \.id) { r in
                        let phase = Double(outerStrokedRings.firstIndex(where: { $0.id == r.id }) ?? 0) * 0.18
                        let progress = fmod(t * r.speed + phase, 1.0)
                        let ringScale = 1.0 + CGFloat(progress) * (r.maxScale - 1.0)
                        let ringOpacity = r.baseOpacity + progress * r.extraOpacity

                        Circle()
                            .stroke(Color.white.opacity(ringOpacity), style: StrokeStyle(lineWidth: r.lineWidth, lineCap: .round))
                            .frame(width: r.startSize, height: r.startSize)
                            .scaleEffect(ringScale)
                            .opacity(ringOpacity)
                            .blendMode(.plusLighter)
                            .position(x: geo.size.width / 2.0, y: geo.size.height / 2.0)
                    }

                } // TimelineView
                // subtle appear animation (independent)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.75).repeatForever(autoreverses: true)) {
                        appearScale = 1.03
                    }
                }

            } // ZStack
        } // GeometryReader
    }
}

// MARK: - Preview
struct PulsRingsView2_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PulsRingsView2()
                .previewDevice("iPhone 14 Pro")
                .previewDisplayName("PulsRingsView2 - iPhone 14 Pro")
            PulsRingsView2()
                .previewLayout(.sizeThatFits)
                .frame(width: 400, height: 800)
                .previewDisplayName("PulsRingsView2 - SizeThatFits")
        }
    }
}
