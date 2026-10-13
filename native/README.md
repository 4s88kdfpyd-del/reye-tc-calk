# REye TC Calk Native Core — 0.1.0-dev

Stage 1 native migration package containing the platform-independent timecode engine and unit tests.

## Scope

- 10 supported frame rates
- NDF and DF address validation
- 29.97 DF and 59.94 DF conversion
- TC ↔ frame count
- Duration calculation across midnight
- Add/Sub with 24-hour TC wrapping
- Total TC and Total Dur without 24-hour wrapping
- Duration values intentionally do not use DF skipped-address validation

## Run tests

```bash
cd native
swift test
```

The package is UI-independent and is intended to be imported by the future SwiftUI iPhone/iPad app and later shared with the Apple Silicon Mac target.
