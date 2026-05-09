# theMClean Go Implementation Plan

## Phase 1 - Foundation

- [x] Create separate iPhone/iPad project.
- [x] Define App Store-safe product positioning.
- [x] Add file/folder import from Files.
- [x] Add first-pass scan model for selected files.
- [x] Add review list with category, size, date, risk, and selection.
- [x] Add Stage view with restore/remove.
- [x] Add settings shell.
- [ ] Add app icon and launch branding.
- [ ] Add screenshots for README and App Store.

## Phase 2 - Review Depth

- [ ] Add duplicate detection by file size and content hash.
- [ ] Add grouping by category, folder, age, and duplicate group.
- [ ] Add filters for size range, modified date, file type, and path contains.
- [ ] Add preview support for images, text, PDFs, and video metadata.
- [ ] Add “keep newest / oldest / folder original” helper actions for duplicate groups.

## Phase 3 - Safer Stage

- [ ] Copy staged items into the app container when the user chooses Stage.
- [ ] Preserve security-scoped bookmarks for original file locations.
- [ ] Add restore-to-original-location when permission is available.
- [ ] Add explicit delete confirmation for staged originals.
- [ ] Add stale Stage reminders.

## Phase 4 - iPad Experience

- [ ] Add multi-column review layout with detail inspector.
- [ ] Add keyboard shortcuts for select, stage, restore, and reveal details.
- [ ] Add drag-and-drop import on iPad.
- [ ] Add split-view optimized metrics and charts.

## Phase 5 - Mac Companion Sync

- [ ] Define optional iCloud sync model for scan summaries.
- [ ] Sync Stage reminders and review history.
- [ ] Add handoff links to the Mac app README and support pages.

## Phase 6 - Release

- [ ] Add privacy policy page.
- [ ] Add support URL.
- [ ] Prepare App Store screenshots for iPhone and iPad.
- [ ] Add App Review notes explaining sandbox limits.
- [ ] Submit TestFlight build.
