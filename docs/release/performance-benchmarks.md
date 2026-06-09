# Fire Performance Benchmarks

These benchmark definitions are release gates. Current scripts provide repeatable measurement workflows, but final baselines must be recorded on real release builds before submission.

## Targets

| Metric | Target | Failure Threshold |
| --- | --- | --- |
| Cold start to home visible | < 3.0s | > 5.0s |
| Home feed scroll fluency | >= 58 fps average | < 55 fps average or > 5% janky frames |
| Topic detail first screen | < 2.0s | > 3.0s |
| Home feed memory | < 200 MB | > 300 MB |
| Topic detail memory after 100 posts | < 350 MB | > 500 MB |

## Required Devices

| Platform | Preferred Device | Fallback |
| --- | --- | --- |
| iOS | Current physical iPhone Pro device | iPhone simulator for smoke runs only |
| Android | Pixel 8-class physical device | Pixel emulator for smoke runs only |

## Scripts

```bash
scripts/benchmark-cold-start.sh ios
scripts/benchmark-cold-start.sh android
scripts/benchmark-scroll-fps.sh ios
scripts/benchmark-scroll-fps.sh android
scripts/benchmark-topic-load.sh ios
scripts/benchmark-topic-load.sh android
scripts/benchmark-memory-peak.sh ios
scripts/benchmark-memory-peak.sh android
```

## Results Log

| Date | Commit | Platform | Device | Build Type | Metric | Result | Pass/Fail | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| | | | | | | | | |

## Release Rule

Do not mark P4 performance complete until this log contains release-build measurements for iOS and Android, and any failures have an explicit owner or ship/no-ship decision.
