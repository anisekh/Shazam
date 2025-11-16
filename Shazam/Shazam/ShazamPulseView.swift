// ShazamPulseView.swift
//  Shazam
//
//  Created by Aniseh Khajuei on 10/11/25.
//




import SwiftUI

struct ShazamPulseView: View {
    // ---------- tuning (configuration parameters) ----------
    // Duration of a full cycle (seconds) = grow + shrink
    let cycleDuration: Double = 2.5
    // Fraction of the cycle allocated to growth (rest is for shrink)
    let growthEndFraction: Double = 0.70
    // How much the whole set can scale up (global scale)
    let maxGlobalScale: CGFloat = 2.2

    // Number of central "squeezes" during growth and their strength
    let squeezesDuringGrowth: Int = 3
    let squeezeAmount: CGFloat = 0.04

    // Thresholds and fade-in width for disks (when they appear and how fast)
    let diskAppearThresholds: [Double] = [0.05, 0.18, 0.35, 0.50]
    let diskAppearWidth: Double = 0.18

    // Central circle base size and disk base sizes
    let centerBase: CGFloat = 100
    let diskBaseSizes: [CGFloat] = [140, 180, 220, 260]

    // Minimum and maximum opacity for disks
    let diskMinOpacity: Double = 0.06
    let diskMaxOpacity: Double = 0.2

    // Large thin outline rings
    // ringStartSize is base for the first ring; second ring uses its own base by spacing
    let ringStartSize: CGFloat = 300
    // Fixed spacing between the two rings (kept constant)
    let ringSpacing: CGFloat = 80
    // Minimum/maximum opacity for rings
    let ringBaseOpacityMin: Double = 0.03
    let ringBaseOpacityMax: Double = 0.80
    // Maximum extra scale for rings during growth
    let ringMaxScaleExtra: CGFloat = 1.8
    let ringLineWidth: CGFloat = 1
    // Which disk index triggers the rings (index into diskAppearThresholds)
    let ringTriggerDiskIndex: Int = 2

    // Small local oscillation for disks (makes them feel more alive)
    let diskLocalOscFreq: Double = 0.8
    let diskLocalOscAmp: CGFloat = 0.03
    
    
    
    
    

    // Background colors — close to Shazam blue
    // Shazam usually has a bright blue gradient; these two colors were chosen to be close and high-contrast
    let bgTop = Color(red: 5.0/255.0, green: 148/255.0, blue: 255.0/255.0)   // #007AFF-ish
    let bgBottom = Color(red: 0.0/255.0, green: 42/255.0, blue: 217.0/255.0) // darker for depth

    // ---------- New parameters for Shazam-like pulsing (optional) ----------
    let diskPulseFrequency: Double = 3.0 // how many pulses inside the growth phase
    let diskPulseScaleAmplitude: CGFloat = 0.03
    let diskPulseOpacityAmplitude: Double = 0.15

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // background gradient
                LinearGradient(gradient: Gradient(colors: [bgTop, bgBottom]),
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                // TimelineView for time-driven animation
                TimelineView(.animation) { ctx in
                    // reference time (seconds since reference date)
                    let t = ctx.date.timeIntervalSinceReferenceDate

                    // ---------- compute overall phase 0..1 ----------
                    // phase: value between 0 and 1 indicating progress through the whole cycle
                    let phase = fmod(t, cycleDuration) / cycleDuration
                    // growth end fraction
                    let growthEnd = growthEndFraction
                    // are we currently in the growth phase or shrink?
                    let isGrowing = phase < growthEnd

                    // growthProgress: 0..1 during growth, otherwise 1.0
                    let growthProgress: Double = isGrowing ? (phase / growthEnd) : 1.0
                    // shrinkProgress: 0..1 during shrink phase
                    let shrinkProgress: Double = isGrowing ? 0.0 : ((phase - growthEnd) / (1.0 - growthEnd))

                    // ---------- global scale for the whole set ----------
                    // increases during growth, returns to base during shrink
                    let globalScale: CGFloat = isGrowing
                        ? 1.0 + (maxGlobalScale - 1.0) * CGFloat(growthProgress)
                        : 1.0 + (maxGlobalScale - 1.0) * CGFloat(1.0 - shrinkProgress)

                    // ---------- compute central pulse value (squeezes) ----------
                    // pulseValue between 0..1; active only during growth
                    let pulseValue: Double = {
                        if !isGrowing { return 0.0 }
                        let raw = fmod(growthProgress * Double(squeezesDuringGrowth), 1.0)
                        let halfW = 0.12 * 0.5
                        let d = abs(raw - 0.5)
                        return d >= halfW ? 0.0 : 1.0 - (d / halfW)
                    }()
                    // squeeze multiplier for the central circle
                    let centralSqueezeMultiplier: CGFloat = 1.0 - squeezeAmount * CGFloat(pulseValue)

                    // ---------- surface pulse for disks (Shazam-like effect) ----------
                    let diskPulseValue: Double = {
                        if !isGrowing { return 0.0 }
                        let raw = fmod(growthProgress * diskPulseFrequency, 1.0)
                        return sin(raw * .pi * 2) * 0.5 + 0.5 // convert to 0..1
                    }()

                    // ---------- local oscillation function for each disk ----------
                    let diskLocalOsc: (Int) -> CGFloat = { index in
                        let phaseOffset = Double(index) * 0.18
                        let osc = sin(2 * .pi * diskLocalOscFreq * t + phaseOffset) // -1..1
                        let norm = (osc + 1.0) / 2.0
                        return 1.0 + diskLocalOscAmp * CGFloat(norm - 0.5) * 2.0
                    }

                    // ---------- helper for appear progress (0..1) for each disk ----------
                    let appearProgress: (Double) -> Double = { threshold in
                        let raw = (growthProgress - threshold) / diskAppearWidth
                        let clamped = min(max(raw, 0.0), 1.0)
                        return clamped
                    }

                    // ---------- rings: compute progress for them ----------
                    // rings should start when a specific disk begins to appear
                    let ringTriggerThreshold = diskAppearThresholds[min(ringTriggerDiskIndex, diskAppearThresholds.count - 1)]
                    // ringAppearRaw: 0..1 during growth (up to 1.0) — during shrink it remains 1.0 and then fades
                    let ringAppearRaw = (growthProgress - ringTriggerThreshold) / max(0.0001, (1.0 - ringTriggerThreshold))
                    let ringGrowProgress = isGrowing ? min(max(ringAppearRaw, 0.0), 1.0) : 1.0
                    // during shrink, rings should fade out smoothly
                    let ringShrinkFade = isGrowing ? 1.0 : max(0.0, 1.0 - CGFloat(shrinkProgress))

                    // responsive fit: overall scaling for different screen sizes
                    let minSide = min(geo.size.width, geo.size.height)
                    let centerScaleFit = minSide / 420.0
                    
                  


                     

                    // ---------- DRAW: main structure ----------
                   
                    
                    
                    VStack {
                        ZStack {
                            // --- disks (behind center) ---
                            ForEach(0..<diskBaseSizes.count, id: \.self) { i in
                                let base = diskBaseSizes[i]
                                let ap = appearProgress(diskAppearThresholds[i])   // appear 0..1
                                let appearOpacity = diskMinOpacity + (diskMaxOpacity - diskMinOpacity) * ap
                                let localOsc = diskLocalOsc(i)                     // small local oscillation
                                
                                // apply disk pulse to scale and opacity for Shazam-like feel
                                let pulseScaleMultiplier = 1.0 + diskPulseScaleAmplitude * CGFloat(diskPulseValue)
                                let pulseOpacityMultiplier = 1.0 + diskPulseOpacityAmplitude * diskPulseValue
                                
                                let appearScale: CGFloat = (0.95 + 0.05 * CGFloat(ap)) * pulseScaleMultiplier
                                // combine scales: global * appear * localOsc * fit
                                let diskScale = globalScale * appearScale * localOsc * centerScaleFit
                                // final opacity: fades during shrink
                                let finalOpacity = (isGrowing ? appearOpacity : appearOpacity * Double(max(0.0, 1.0 - shrinkProgress))) * pulseOpacityMultiplier
                                
                                Circle()
                                    .fill(Color.white.opacity(finalOpacity))
                                    .frame(width: base, height: base)
                                    .scaleEffect(diskScale)
                                    .blendMode(.plusLighter)
                                    .animation(nil, value: UUID()) // Timeline itself drives the timing; prevent implicit animations
                            }
                            
                            // --- central disk (with central squeeze) ---
                            ZStack {
                                Circle()
                                    .stroke(Color.white)
                                    .fill(Color.blue)
                                    .frame(width: centerBase, height: centerBase)
                                    .overlay(Circle().stroke(Color.white, lineWidth: 1))
                                // center is scaled only by centralSqueezeMultiplier and globalScale
                                    .scaleEffect(globalScale * centralSqueezeMultiplier * centerScaleFit)
                                    .shadow(color: Color.blue.opacity(0.5), radius: 10, x: 0, y: 6)
                                    .opacity(0.5)
                                
                                
                                Image("Shazam")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: centerBase * 0.6, height: centerBase * 0.6)
                                    .foregroundColor(.white)
                                    .scaleEffect(globalScale * centralSqueezeMultiplier * centerScaleFit)
                            }
                            
                            // --- two thin outer rings ---
                            // Important: to avoid rings "merging" into one, each ring has a different base size (ringStartSize + idx * ringSpacing)
                            // and both grow with the same ringGrowProgress (no phase offset), so their spacing remains consistent.
                            ForEach(0..<2, id: \.self) { idx in
                                // base size for this ring (fixed)
                                let baseWidth = ringStartSize + CGFloat(idx) * ringSpacing
                                
                                // final ring scale: based on ring's growth (same rate for both)
                                let ringScaleDuringGrowth = 1.0 + (ringMaxScaleExtra - 1.0) * CGFloat(ringGrowProgress)
                                // final multiplier: combined with globalScale * centerScaleFit
                                let ringScale = ringScaleDuringGrowth * globalScale * centerScaleFit
                                
                                // ring opacity: from min->max during growth, then fades during shrink
                                let ringOpacityDuringGrowth = ringBaseOpacityMin + (ringBaseOpacityMax - ringBaseOpacityMin) * Double(ringGrowProgress)
                                let ringOpacity = ringOpacityDuringGrowth * Double(ringShrinkFade)
                                
                                Circle()
                                    .stroke(Color.white.opacity(ringOpacity),
                                            style: StrokeStyle(lineWidth: ringLineWidth, lineCap: .round))
                                // fixed frame for each ring (base size difference creates fixed spacing)
                                    .frame(width: baseWidth, height: baseWidth)
                                // scale applied to the entire frame
                                    .scaleEffect(ringScale)
                                    .blendMode(.plusLighter)
                                    .animation(nil, value: UUID()) // prevent implicit animation
                            }
                        } // END ZSTACK
                        .padding(50)
                        
                   Bars()
                            .frame(height: 40)
                                
                                Text("Listening for music")
                                    .font(.title2)
                                    .bold()
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
                                
                                Text("Make sure your device can hear the song clearly")
                                    .font(.subheadline)
                                    .foregroundColor(Color.white.opacity(0.9))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                    }//END VSTACK
                    
                    
                    .frame(width: minSide, height: minSide)
                    .position(x: geo.size.width / 2.0, y: geo.size.height / 2.0)
                } // TimelineView
            } // ZStack
        } // GeometryReader
    }
}

// Simple preview
struct PulseAnimation_Preview: PreviewProvider {
    static var previews: some View {
        ShazamPulseView()
   
    }
}
