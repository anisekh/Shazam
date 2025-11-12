//
//  PulsingRingsView.swift
//  Shazam
//
//  Created by Aniseh Khajuei on 11/11/25.
//

import SwiftUI

struct PulsingRingsView: View {
    // To Know
    @State private var animationAmount = 1.0

    let frequency: Double = 0.4 //Breathing Frequency
    let amplitude: CGFloat = 0.02
    
    let innerAmplitude: CGFloat = 0.04
    
    // slow "swell" that makes everything grow together
    let swellFrequency: Double = 0.8
    let swellAmplitude: CGFloat = 0.2
    
    //Outer Disk
    let secondAmplitude: CGFloat = 0.35
    let secondBaseOpacity: Double = 0.55
    
    // Middle Disk
    let midBaseSize: CGFloat = 80
    let midBaseOpacity: Double = 0.45
    let midAmplitude: CGFloat = 0.02
    
    // Second Middle Disk
    let mid2BaseSize: CGFloat = 120
    let mid2BaseOpacity: Double = 0.38
    let mid2Amplitude: CGFloat = 0.015
    
    let outerCount = 2
    let outerBaseExtra: CGFloat = 300   // how much larger than baseSize the outer rings start
    let outerMaxGrow: CGFloat = 1.5     // how big relative to their start size
    let outerSpeed: Double = 0.75      // cycles per second (slow)
    let outerBaseOpacity: Double = 0.05 // starting opacity (very subtle)
    let outerExtraOpacity: Double = 0.45 // extra opacity as they expand
    let outerLineWidth: CGFloat = 0.3   // thin stroke
    let baseSize: CGFloat = 8

    
    // SQUEEZE (two tiny quick shrink events per slow swell cycle)
    let pulsesPerSwell: Int = 2        // how many squeezes per swell cycle
    let squeezeStrength: CGFloat = 0.02 // max fractional shrink (0.08 => up to 8%)
    let squeezeWidth: Double = 0.05   // fraction of one pulse occupied by the dip (0.12 => narrow)

    
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.blue)
                .ignoresSafeArea()
       
            TimelineView(.animation) { ctx in
              
                let t = ctx.date.timeIntervalSinceReferenceDate

                // --- fast breathing oscillator (step 1) ---
                let fast = sin(2 * .pi * frequency * t)         // -1 .. +1 (fast inhale/exhale)
                let normFast = (fast + 1.0) / 2.0               // 0 .. 1 (1 when inner is max)

                // --- slow swell oscillator (step 2) ---
                let swell = sin(2 * .pi * swellFrequency * t)   // -1 .. +1 (slow envelope)
                let swellNorm = (swell + 1.0) / 2.0             // 0 .. 1
                let swellFactor = 1.0 + swellAmplitude * CGFloat(swellNorm) // >= 1.0, multiplies sizes
                // --- compute scales & opacities (with squeeze, only while swell is rising) ---
                // fast & swell already computed above

                // Check whether swell is currently rising (derivative > 0)
                // derivative of sin(2π f t) is cos(2π f t) * 2π f — we only need sign
                let swellSlope = cos(2 * .pi * swellFrequency * t)
                let isGrowing = swellSlope > 0.0 ? 1.0 : 0.0   // 1.0 when growing, 0.0 when shrinking

                // map swellNorm 0..1 into pulsesPerSwell pulses; find local phase inside a single pulse
                let rawPulsePos = fmod(swellNorm * Double(pulsesPerSwell), 1.0)

                // triangular pulse calculation (centered at 0.5, width = squeezeWidth)
                let halfWidth = squeezeWidth * 0.5
                let d = abs(rawPulsePos - 0.5)
                let basePulse: Double = d >= halfWidth ? 0.0 : 1.0 - (d / halfWidth)

                // Apply growth-only mask: pulse occurs only when swell is rising
                let pulseValue: Double = basePulse * isGrowing   // 0..1, zero when shrinking

                // squeezeMultiplier: 1.0 => no squeeze; min = 1 - squeezeStrength
                let squeezeMultiplier = 1.0 - squeezeStrength * CGFloat(pulseValue)

                // --- now compute scales & opacities using squeezeMultiplier ---
                // inner: breathes fast, then is amplified by the slow swell, then squeezed
                let innerScaleUnclamped = (1.0 + amplitude * CGFloat(fast)) * swellFactor
                let innerScale = innerScaleUnclamped * squeezeMultiplier

                // outer: inverse of fast breathing (grows when inner shrinks), also swells, then squeezed
                let outerScaleUnclamped = (1.0 + secondAmplitude * CGFloat(1.0 - normFast)) * swellFactor
                let outerScale = outerScaleUnclamped * squeezeMultiplier
                let outerOpacity = secondBaseOpacity * Double(1.0 - normFast) * Double(0.6 + 0.4 * swellNorm) * Double( (1.0 - 0.5 * pulseValue) )

                // middle disk: sits between inner & outer (average), slightly tuned
                let midScaleUnclamped = ((innerScaleUnclamped + outerScaleUnclamped) / 2.0) * 0.99
                let midScale = midScaleUnclamped * squeezeMultiplier
                let midOpacity = midBaseOpacity * Double((1.0 - normFast) * 0.9 + 0.1) * Double(0.6 + 0.4 * swellNorm) * Double( (1.0 - 0.4 * pulseValue) )

                // mid2Scale is the midpoint between inner & mid, slightly nudged
                let mid2ScaleUnclamped = ((innerScaleUnclamped + midScaleUnclamped) / 2.0) * 0.995
                let mid2Scale = mid2ScaleUnclamped * squeezeMultiplier
                let mid2Opacity = mid2BaseOpacity * Double((1.0 - normFast) * 0.85 + 0.15) * Double(0.6 + 0.4 * swellNorm) * Double( (1.0 - 0.45 * pulseValue) )



                ZStack {
                    
                    
                    ZStack {
                        // OUTER (largest pulse)
                        Circle()
                            .fill(Color.white.opacity(0.14))
                            .frame(width: 180, height: 180)
                            .scaleEffect(outerScale)
                            .opacity(outerOpacity)
                            .blendMode(.plusLighter)
                        
                        // MIDDLE (new disk between inner & outer)
                        Circle()
                        
                            .fill(Color.white.opacity(0.28))
                            .frame(width: 150, height: 150)
                            .scaleEffect(midScale)
                            .opacity(midOpacity)
                            .blendMode(.plusLighter)
                        
                        
                        // MID2 (new disk that appears between middle and inner)
                        Circle()
                            .fill(Color.white.opacity(mid2BaseOpacity))
                            .frame(width: mid2BaseSize, height: mid2BaseSize)
                            .scaleEffect(mid2Scale)
                            .opacity(mid2Opacity)
                            .blendMode(.plusLighter)
                        
                    }
                    
                    // faghat
                    .scaleEffect(animationAmount)
                    .animation(
                        .easeInOut(duration: 0.75)
                                    .repeatForever(autoreverses: true),
                                value: animationAmount
                            )
                    
                    // INNER: your breathing filled circle (unchanged behavior, but uses innerScale)
                    
                    ZStack {
                        
                            Circle()
                                .stroke(.white, lineWidth: 1)
                                .fill(.blue)
                                .frame(width: 90, height: 90)
                                .scaleEffect(innerScale)
                                .shadow(color: Color.blue.opacity(0.5), radius: 10, x: 0, y: 6)
                        
                        Image(systemName: "shazam.logo.fill")
                            .font(Font.system(size: 90).bold())
                            .scaleEffect(innerScale)
                            .foregroundStyle(.white)
                    }
                    
                    
                    
                    ForEach(0..<outerCount, id: \.self) { i in
                        // give a tiny phase offset so the two big rings are not perfectly identical
                        let phase = Double(i) * 0.18
                        // slower progress 0..1
                        let progress = fmod(t * outerSpeed + phase, 1.0)
                        // scale: start near 1 then expand a lot
                        let startSize = baseSize + outerBaseExtra + CGFloat(i) * 16
                        let scale = 1.0 + CGFloat(progress) * (outerMaxGrow - 1.0)
                        // opacity ramps up as the circle grows (linear ramp)
                        let opacity = Double(outerBaseOpacity + progress * outerExtraOpacity)

                        Circle()
                            .stroke(
                                Color.white.opacity(opacity),
                                style: StrokeStyle(lineWidth: outerLineWidth, lineCap: .round)
                            )
                            .frame(width: startSize, height: startSize)
                            .scaleEffect(scale)
                            .opacity(opacity) // redundant with stroke color but ok
                            .blendMode(.plusLighter)

                    }
                    
                    
                }
                .scaleEffect(1.5)
                
                // faghat
                .onAppear {
                    animationAmount = 1.1
                }
                
            }
        
        }
    }
}

#Preview {
    PulsingRingsView()
}
