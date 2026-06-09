# Prepare Fire Release Materials

> **For agentic workers:** Use this plan as the P4 release-preparation source of truth. Checkbox state tracks repository artifacts only; store-console actions, real screenshots/videos, legal review, device benchmarks, and accessibility audits remain manual gates.

## Feasibility Assessment

P4 is process-heavy and does not require changes to the Rust/native architecture. The repository can hold listing drafts, privacy/data-safety drafts, benchmark scripts, accessibility checklists, license inventories, and marketing asset folders now. Final App Store / Play Store readiness still requires human store access and real-device validation. Feasible with caveats: repository scaffolding is complete, but release acceptance remains blocked on manual evidence.

## Current Surface Inventory

- `docs/release/` -- release copy, compliance drafts, testing guides, benchmark definitions, accessibility checklist, and license inventory.
- `native/ios-app/marketing/` -- App Store screenshot and preview-video folder structure.
- `native/android-app/marketing/` -- Play Store screenshot and feature-graphic folder structure.
- `scripts/ios/archive_release.sh` -- existing iOS archive/upload path used by the TestFlight guide.
- `scripts/ios/verify_xcode26_toolchain.sh` -- existing App Store Connect toolchain guard used before iOS uploads.
- `scripts/collect-licenses.sh` -- generated third-party dependency inventory.
- `scripts/benchmark-*.sh` -- benchmark workflows for cold start, scroll fluency, topic load, and memory.
- `native/android-app/src/main/AndroidManifest.xml` -- release-relevant Android `allowBackup="true"` fact.
- `native/ios-app/Sources/FireAppSession/APM/FireAPMManager.swift` -- local PLCrashReporter / MetricKit diagnostic behavior.
- `native/ios-app/App/DeveloperTools/FirePushDiagnosticsView.swift` -- APNs token is local-only at this stage.
- `native/android-app/src/main/java/com/fire/app/push/FireFirebaseMessagingService.kt` -- FCM token registration API is not available; payloads are local notification input.
- `rust/crates/fire-core/tests/session_flow.rs` -- documents that current "redacted" session export still returns a full session snapshot.

## Design

### Key Design Decisions

1. **Version release source material, not fake final media.** The repo now includes marketing directories and `.gitkeep` placeholders, but no fabricated screenshots, preview videos, or feature graphics. Real assets must come from release-candidate builds.
2. **Keep privacy drafts conservative.** Privacy documents state local diagnostics, widget snapshots, offline cache, local push token handling, Android backup status, and the unsafe redacted-export behavior instead of overclaiming.
3. **Make benchmark scripts honest about prerequisites.** Android scripts use `adb` when available; iOS scripts print required Instruments/xctrace workflows because reliable iOS FPS/memory/topic measurements require device tooling.
4. **Generate license inventory from current declarations.** `scripts/collect-licenses.sh` inventories Rust, Swift Package, vendored iOS, Android Gradle, and repository license sources. Full legal review and transitive license verification remain required.
5. **Separate repository completion from release acceptance.** P4 acceptance boxes in the roadmap remain unchecked until real store/test/performance/accessibility evidence exists.

## Phased Implementation

### Phase 1: Store Listing And Marketing Structure

**Files:**
- `docs/release/app-store-description.md`
- `docs/release/play-store-description.md`
- `native/ios-app/marketing/README.md`
- `native/ios-app/marketing/screenshots/iPhone6.5/.gitkeep`
- `native/ios-app/marketing/screenshots/iPhone5.5/.gitkeep`
- `native/ios-app/marketing/screenshots/iPad12.9/.gitkeep`
- `native/ios-app/marketing/screenshots/iPad11/.gitkeep`
- `native/ios-app/marketing/preview-video/.gitkeep`
- `native/android-app/marketing/README.md`
- `native/android-app/marketing/screenshots/phone/.gitkeep`
- `native/android-app/marketing/screenshots/tablet7/.gitkeep`
- `native/android-app/marketing/screenshots/tablet10/.gitkeep`

- [x] Create App Store and Play Store listing drafts.
- [x] Create iOS and Android marketing asset folder structures.
- [x] Document that real release-candidate media is still required.
- [ ] Capture and validate final App Store screenshots.
- [ ] Capture or decide not to ship an App Preview video.
- [ ] Capture and validate final Play Store screenshots.
- [ ] Create and approve the Play Store 1024x500 feature graphic.

### Phase 2: Privacy, Data Safety, And Licenses

**Files:**
- `docs/release/privacy-policy.md`
- `docs/release/app-store-data-collection.md`
- `docs/release/play-store-data-safety.md`
- `docs/release/third-party-licenses.md`
- `scripts/collect-licenses.sh`

- [x] Create privacy policy draft aligned with current code facts.
- [x] Create App Store privacy questionnaire draft.
- [x] Create Play Store Data Safety draft.
- [x] Add license collection script.
- [x] Generate current third-party dependency inventory.
- [ ] Install `cargo-license` and regenerate with full Rust license names.
- [ ] Verify Android transitive license metadata with Gradle tooling.
- [ ] Complete maintainer/legal privacy review.
- [ ] Decide Android `allowBackup` release behavior and update docs/store answers.
- [ ] Add an iOS privacy manifest if required by Apple policy or linked SDK review.
- [ ] Fix or rename redacted session export before any public diagnostic workflow claims redaction.

### Phase 3: Internal Testing Guides

**Files:**
- `docs/release/testflight-setup.md`
- `docs/release/play-store-testing-setup.md`
- `docs/release/test-feedback-template.md`

- [x] Document TestFlight build/upload flow using existing iOS release scripts.
- [x] Document Play Store internal/closed/open testing setup.
- [x] Add a tester feedback template.
- [ ] Create App Store Connect app record.
- [ ] Create Play Console app record.
- [ ] Upload release-candidate builds to internal testing tracks.
- [ ] Invite testers and collect feedback.

### Phase 4: Performance Regression Gates

**Files:**
- `docs/release/performance-benchmarks.md`
- `scripts/benchmark-cold-start.sh`
- `scripts/benchmark-scroll-fps.sh`
- `scripts/benchmark-topic-load.sh`
- `scripts/benchmark-memory-peak.sh`

- [x] Define release benchmark targets and failure thresholds.
- [x] Add Android `adb` benchmark workflows.
- [x] Add iOS measurement workflows for Instruments/xctrace.
- [ ] Record release-build iOS measurements on a physical device.
- [ ] Record release-build Android measurements on a physical device.
- [ ] Resolve or explicitly accept any threshold failures.

### Phase 5: Accessibility Audit

**Files:**
- `docs/release/accessibility-audit-checklist.md`

- [x] Add a cross-platform accessibility audit checklist.
- [ ] Run VoiceOver full-flow audit.
- [ ] Run TalkBack full-flow audit.
- [ ] Run Dynamic Type / font-scale audit.
- [ ] Run Reduce Motion and haptic audit.
- [ ] Run high-contrast and color-blindness checks.
- [ ] Record results and fix blocking failures.

## Architectural Notes

- No Rust/native architecture changes are part of P4 release-prep scaffolding.
- The platform/Rust ownership split remains unchanged.
- `references/fluxdo/` and `third_party/` are not edited by this plan.
- Generated release media is intentionally absent until captured from real release-candidate builds.
- Privacy and data-safety drafts are conservative working documents, not final legal text.
- Roadmap P4 acceptance remains unchecked until manual evidence exists.

## File Change Summary

- `docs/release/README.md` -- release materials index and manual-gate note.
- `docs/release/accessibility-audit-checklist.md` -- cross-platform accessibility release checklist.
- `docs/release/app-store-data-collection.md` -- App Store privacy questionnaire draft.
- `docs/release/app-store-description.md` -- App Store listing draft.
- `docs/release/performance-benchmarks.md` -- benchmark targets and results log.
- `docs/release/play-store-data-safety.md` -- Play Store data-safety draft.
- `docs/release/play-store-description.md` -- Play Store listing draft.
- `docs/release/play-store-testing-setup.md` -- Play Store testing guide.
- `docs/release/privacy-policy.md` -- privacy policy draft aligned to current code.
- `docs/release/test-feedback-template.md` -- beta feedback template.
- `docs/release/testflight-setup.md` -- TestFlight setup guide.
- `docs/release/third-party-licenses.md` -- generated dependency inventory.
- `native/android-app/marketing/README.md` -- Play Store asset requirements.
- `native/android-app/marketing/screenshots/phone/.gitkeep` -- phone screenshot folder placeholder.
- `native/android-app/marketing/screenshots/tablet7/.gitkeep` -- 7" tablet screenshot folder placeholder.
- `native/android-app/marketing/screenshots/tablet10/.gitkeep` -- 10" tablet screenshot folder placeholder.
- `native/ios-app/marketing/README.md` -- App Store asset requirements.
- `native/ios-app/marketing/preview-video/.gitkeep` -- App Preview folder placeholder.
- `native/ios-app/marketing/screenshots/iPad11/.gitkeep` -- iPad 11" screenshot folder placeholder.
- `native/ios-app/marketing/screenshots/iPad12.9/.gitkeep` -- iPad 12.9" screenshot folder placeholder.
- `native/ios-app/marketing/screenshots/iPhone5.5/.gitkeep` -- iPhone 5.5" screenshot folder placeholder.
- `native/ios-app/marketing/screenshots/iPhone6.5/.gitkeep` -- iPhone 6.5" screenshot folder placeholder.
- `scripts/benchmark-cold-start.sh` -- cold-start benchmark workflow.
- `scripts/benchmark-memory-peak.sh` -- memory benchmark workflow.
- `scripts/benchmark-scroll-fps.sh` -- scroll fluency benchmark workflow.
- `scripts/benchmark-topic-load.sh` -- topic detail load benchmark workflow.
- `scripts/collect-licenses.sh` -- dependency license inventory generator.
