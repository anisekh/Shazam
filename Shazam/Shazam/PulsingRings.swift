//
//  PulsingRings.swift
//  Shazam
//
//  Created by Aniseh Khajuei on 10/11/25.
//

import SwiftUI

struct PulsingRings: View {
    let ringCount: Int = 4
    let baseSize: CGFloat = 180

    var body: some View {
        TimelineView(.animation) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            ZStack {
                // Background so the rings are visible
                Color.black.ignoresSafeArea()

                // pulsing concentric rings
                ForEach(0..<ringCount, id: \.self) { i in
                    // stagger each ring by a phase offset
                    let phase = Double(i) / Double(ringCount)
                    // progress cycles 0..1 based on time and phase
                    let progress = fmod(t * 0.8 + phase, 1.0)
                    // scale grows as progress increases
                    let scale = 1.0 + CGFloat(progress) * 1.6
                    // fade out as it expands
                    let alpha = Double(max(0, 1.0 - CGFloat(progress)))

                    Circle()
                        .stroke(Color.blue.opacity(alpha * 0.9), lineWidth: 3)
                        .frame(width: baseSize, height: baseSize)
                        .scaleEffect(scale)
                        .opacity(alpha)
                        // TimelineView controls animation frames, so disable implicit animations
                        .animation(nil, value: UUID())
                }

                // center "button" circle
                // replace the static center Circle with this breathing one
                // put this inside the existing TimelineView block (where the center circle was)
                let breathFrequency = 0.6 // cycles per second (tuneable)
                let breathAmplitude: CGFloat = 0.05 // how big the pulse is (0.05 => ±5%)
                let breath = sin(t * 2 * .pi * breathFrequency)
                let centerScale = 1.0 + breathAmplitude * CGFloat(breath)

                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .scaleEffect(centerScale)
                    .overlay(
                        Image(systemName: "waveform")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                            .foregroundColor(.white)
                    )
                    .shadow(color: Color.blue.opacity(0.6), radius: 10, x: 0, y: 6)

            }
        }
        .frame(width: 360, height: 360)
    }
}

struct PulsingRings_Previews: PreviewProvider {
    static var previews: some View {
        PulsingRings()
    }
}

