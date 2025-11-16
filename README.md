# ShazamPulse

**ShazamPulse** — a compact SwiftUI demo that reproduces a Shazam-style listening screen.  
A learning project focused on time-driven, shape-based animations in SwiftUI (TimelineView, oscillators + envelopes, phased reveals, gated pulses).

---

## Demo
Open `ShazamPulseView` in Xcode canvas or run the app in simulator to see:
- layered concentric disks
- breathing central button with icon
- expanding thin rings
- simple 3-bar loader and caption

(See `/assets` for the example icon used.)

---

## Why this project
This repo exists as a focused exercise to learn:
- how to drive multiple animated layers from a single deterministic time source (`TimelineView`)
- mixing fast oscillators (sin) with slow envelopes for predictable motion
- staging appearance (thresholds + fade) and gated pulses
- building a tunable, reusable animation subsystem in SwiftUI

---

## Features
- Deterministic time source (`TimelineView`)
- Tunable constants at top of `ShazamPulseView.swift`
- Layered architecture: disks, center, rings, UI
- Small helper `Bars` loader component
- Guidance for accessibility (Reduce Motion) and performance

---

## Requirements
- Xcode 15+ (recommended), tested on iOS 18
- Swift / SwiftUI (native)
- Minimum iOS target: 15.0 

---

## Quick start

1. Open the project in Xcode.
2. Ensure `Image("Shazam")` asset is available in `Assets.xcassets` or replace with a system image.
3. Run the app or preview `ShazamPulseView` in Canvas.

