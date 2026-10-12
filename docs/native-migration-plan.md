# REye TC Calk — Native Migration Plan

## Goal

Create a native Apple-platform version based on the validated PWA behavior, targeting App Store distribution while keeping the current PWA as the reference implementation.

## Target platforms

1. iPhone portrait
2. iPad portrait
3. Apple Silicon Mac support as a later step, preferably by sharing the same SwiftUI codebase where practical

## Architecture

Use SwiftUI for the interface and a platform-independent timecode engine for all calculations.

Recommended modules:

- `TimecodeEngine`
  - frame-rate definitions
  - TC parsing / formatting
  - NDF calculations
  - 29.97 DF calculations
  - 59.94 DF calculations
  - 24-hour wrapping rules
  - non-wrapping total-duration rules
- `InputEditing`
  - digit selection
  - cursor editing
  - backspace
  - paste validation
- `Views`
  - Duration
  - Add/Sub
  - Frames
  - Total TC
  - Total Dur
  - custom keypad
- `State`
  - selected frame rate
  - per-mode result state
  - Total TC / Total Dur cut lists

## Locked product rules

- Default frame rate is 30 NDF.
- Frame-rate list matches the PWA baseline.
- Normal TC addresses never exceed 24 hours and wrap to `00:00:00:00`.
- Total TC and Total Dur may exceed 24 hours.
- Drop-frame validity applies to TC addresses, not ordinary duration values.
- Total TC and Total Dur update results automatically while editing.
- Frames is a switchable TC → Frames / Frames → TC interface.
- Add/Sub and Frames select the source input after calculation to support rapid repeat entry.
- Portrait is the supported phone/tablet orientation for the first native release.

## Development stages

### Stage 1 — Core engine

Reimplement timecode calculations in Swift with unit tests before recreating the UI.

Minimum tests:

- every supported NDF rate
- 29.97 DF minute boundary
- 29.97 DF ten-minute boundary
- 59.94 DF minute boundary
- 59.94 DF ten-minute boundary
- 24-hour wrap
- Total values beyond 24 hours
- TC ↔ frame-count round trips

### Stage 2 — Core UI

Recreate the five current modes in SwiftUI while preserving the validated workflow rather than redesigning it.

### Stage 3 — Device adaptation

Validate across representative compact and large iPhones and multiple iPad sizes. Avoid fixed coordinates tied to one device.

### Stage 4 — App Store preparation

- native app icon assets
- bundle identifier
- version/build numbering
- signing
- privacy declarations
- App Store screenshots and metadata
- TestFlight build

### Stage 5 — Mac

After iPhone/iPad behavior is stable, evaluate Mac Catalyst versus a direct SwiftUI macOS target. Keep the calculation engine shared.

## Versioning suggestion

- PWA reference: β 0.0.3 r1
- First native engineering build: 0.1.0-dev
- First TestFlight candidate: 0.1.0 beta

## Important principle

Do not port the PWA by embedding it in a WebView as the final App Store architecture. The native version should use native controls and shared Swift calculation logic so it remains maintainable and suitable for future iPad and Mac development.
