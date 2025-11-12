// PulsRingsView4_fixed.swift
import SwiftUI

struct PulsRingsView4: View {
    // tuning
    let cycleDuration: Double = 2.0
    let growthEndFraction: Double = 0.70
    let maxGlobalScale: CGFloat = 1.9
    let squeezesDuringGrowth: Int = 2
    let squeezeAmount: CGFloat = 0.06
    let diskAppearThresholds: [Double] = [0.05, 0.18, 0.35, 0.50]
    let diskAppearWidth: Double = 0.18
    let centerBase: CGFloat = 90
    let diskBaseSizes: [CGFloat] = [140, 180, 220, 260]
    let diskMinOpacity: Double = 0.06
    let diskMaxOpacity: Double = 0.3
    let ringStartSize: CGFloat = 400
    let ringBaseOpacityMin: Double = 0.03
    let ringBaseOpacityMax: Double = 0.80
    let ringMaxScaleExtra: CGFloat = 1.8
    let ringLineWidth: CGFloat = 1
    let ringTriggerDiskIndex: Int = 2
    let diskLocalOscFreq: Double = 0.8
    let diskLocalOscAmp: CGFloat = 0.03
    let bgTop = Color(red: 0.02, green: 0.58, blue: 1.00)
    let bgBottom = Color(red: 0.00, green: 0.16, blue: 0.85)

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(gradient: Gradient(colors: [bgTop, bgBottom]),
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                TimelineView(.animation) { ctx in
                    let t = ctx.date.timeIntervalSinceReferenceDate
                    // overall phase 0..1
                    let phase = fmod(t, cycleDuration) / cycleDuration
                    let growthEnd = growthEndFraction
                    let isGrowing = phase < growthEnd

                    // growthProgress 0..1 during growth, otherwise 1.0
                    let growthProgress: Double = isGrowing ? (phase / growthEnd) : 1.0
                    // shrinkProgress 0..1 during shrink
                    let shrinkProgress: Double = isGrowing ? 0.0 : ((phase - growthEnd) / (1.0 - growthEnd))

                    // global scale: use ternary (no nested return)
                    let globalScale: CGFloat = isGrowing
                        ? 1.0 + (maxGlobalScale - 1.0) * CGFloat(growthProgress)
                        : 1.0 + (maxGlobalScale - 1.0) * CGFloat(1.0 - shrinkProgress)

                    // central pulse value (only during growth) — compute with expression, no top-level func
                    let pulseValue: Double = {
                        if !isGrowing { return 0.0 }
                        let raw = fmod(growthProgress * Double(squeezesDuringGrowth), 1.0)
                        let halfW = 0.12 * 0.5
                        let d = abs(raw - 0.5)
                        return d >= halfW ? 0.0 : 1.0 - (d / halfW)
                    }()

                    let centralSqueezeMultiplier: CGFloat = 1.0 - squeezeAmount * CGFloat(pulseValue)

                    // disk local oscillation as a local closure (no 'func' declaration)
                    let diskLocalOsc: (Int) -> CGFloat = { index in
                        let phaseOffset = Double(index) * 0.18
                        let osc = sin(2 * .pi * diskLocalOscFreq * t + phaseOffset) // -1..1
                        let norm = (osc + 1.0) / 2.0
                        return 1.0 + diskLocalOscAmp * CGFloat(norm - 0.5) * 2.0
                    }

                    // appearProgress as local closure (no 'func', no top-level return)
                    let appearProgress: (Double) -> Double = { threshold in
                        let raw = (growthProgress - threshold) / diskAppearWidth
                        let clamped = min(max(raw, 0.0), 1.0)
                        // if growthProgress < threshold, raw becomes negative and clamped -> 0
                        return clamped
                    }

                    // rings appear progress (linear across growth after trigger threshold)
                    let ringTriggerThreshold = diskAppearThresholds[min(ringTriggerDiskIndex, diskAppearThresholds.count - 1)]
                    let ringAppearRaw = (growthProgress - ringTriggerThreshold) / max(0.0001, (1.0 - ringTriggerThreshold))
                    let ringGrowProgress = isGrowing ? min(max(ringAppearRaw, 0.0), 1.0) : 1.0
                    let ringShrinkFade = isGrowing ? 1.0 : max(0.0, 1.0 - CGFloat(shrinkProgress))

                    // responsive
                    let minSide = min(geo.size.width, geo.size.height)
                    let centerScaleFit = minSide / 420.0

                    // DRAW
                    ZStack {
                        // disks (behind center)
                        ForEach(0..<diskBaseSizes.count, id: \.self) { i in
                            let base = diskBaseSizes[i]
                            let ap = appearProgress(diskAppearThresholds[i])   // 0..1
                            let appearOpacity = diskMinOpacity + (diskMaxOpacity - diskMinOpacity) * ap
                            let localOsc = diskLocalOsc(i)                     // independent small breathing
                            let appearScale: CGFloat = 0.95 + 0.05 * CGFloat(ap)
                            let diskScale = globalScale * appearScale * localOsc * centerScaleFit
                            let finalOpacity = isGrowing ? appearOpacity : appearOpacity * Double(max(0.0, 1.0 - shrinkProgress))

                            Circle()
                                .fill(Color.white.opacity(finalOpacity))
                                .frame(width: base, height: base)
                                .scaleEffect(diskScale)
                                .blendMode(.plusLighter)
                                .animation(nil, value: UUID())
                        }

                        // central disk (has squeeze)
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: centerBase, height: centerBase)
                                .overlay(Circle().stroke(Color.white, lineWidth: 1))
                                .scaleEffect(globalScale * centralSqueezeMultiplier * centerScaleFit)
                                .shadow(color: Color.blue.opacity(0.5), radius: 10, x: 0, y: 6)

                            Image(systemName: "waveform.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: centerBase * 0.6, height: centerBase * 0.6)
                                .foregroundColor(.white)
                                .scaleEffect(globalScale * centralSqueezeMultiplier * centerScaleFit)
                        }

                        // stroked rings
                        ForEach(0..<2, id: \.self) { idx in
                            let phaseOffset = CGFloat(idx) * 0.05
                            let ringScaleDuringGrowth = 1.0 + (ringMaxScaleExtra - 1.0) * (CGFloat(ringGrowProgress) + phaseOffset)
                            let ringScale = ringScaleDuringGrowth * globalScale * centerScaleFit
                            let ringOpacityDuringGrowth = ringBaseOpacityMin + (ringBaseOpacityMax - ringBaseOpacityMin) * Double(ringGrowProgress)
                            let ringOpacity = ringOpacityDuringGrowth * Double(ringShrinkFade)

                            Circle()
                                .stroke(Color.white.opacity(ringOpacity),
                                        style: StrokeStyle(lineWidth: ringLineWidth, lineCap: .round))
                                .frame(width: ringStartSize, height: ringStartSize)
                                .scaleEffect(ringScale)
                                .blendMode(.plusLighter)
                                .animation(nil, value: UUID())
                        }
                    }
                    .frame(width: minSide, height: minSide)
                    .position(x: geo.size.width / 2.0, y: geo.size.height / 2.0)
                } // TimelineView
            } // ZStack
        } // GeometryReader
    }
}

struct PulsRingsView4_fixed_Previews: PreviewProvider {
    static var previews: some View {
        PulsRingsView4()
    }
}
