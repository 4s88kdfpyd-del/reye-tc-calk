# REye TC Calk — PWA Baseline

Baseline version: **β 0.0.3 r1**

This version is the current validated PWA baseline for future native migration.

## Confirmed behavior

- Default frame rate: **30 NDF**
- Supported frame rates:
  - 23.976 NDF
  - 24 NDF
  - 25 NDF
  - 29.97 NDF
  - 29.97 DF
  - 30 NDF
  - 50 NDF
  - 59.94 NDF
  - 59.94 DF
  - 60 NDF
- Main functions:
  - Duration
  - Add/Sub
  - Frames
  - Total TC
  - Total Dur
- Normal TC addresses wrap at 24 hours.
- Total TC and Total Dur intentionally continue beyond 24 hours for editorial total-duration use.
- Frames supports both TC → Frames and Frames → TC.
- Total TC / Total Dur recalculate automatically on input changes.
- TC inputs support full selection on first tap, cursor placement on subsequent taps, per-digit replacement, backspace behavior, and iOS paste interaction.
- iPhone and iPad portrait layouts have been validated in real-device testing.
- Landscape mode is intentionally unsupported.

## Stability status

β 0.0.3 r1 has passed the current iPhone and iPad real-device checks and is treated as the stable reference implementation for the next development phase.

## Migration rule

Future native versions should preserve this behavior unless a specification change is explicitly approved.
