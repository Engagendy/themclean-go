# theMClean Go

theMClean Go is the iPhone and iPad companion to theMClean. It is not a system cleaner like the Mac app. iOS and iPadOS sandboxing means the app can only review files and folders the user explicitly selects from the Files app.

## Product Direction

- iPad-first file review workspace with a compact iPhone layout.
- Import files or folders from Files.
- Group review candidates by type, size, and risk.
- Move selected items to Stage before final action.
- Keep direct deletion guarded behind clear confirmations in a later phase.
- Avoid claiming access to system caches, other apps, or hidden OS storage.

## Current MVP

- Native SwiftUI iOS/iPadOS app.
- File and folder picker.
- Local scan of user-selected files.
- Large file, image, video, document, archive, and other categories.
- Review list with size, modified date, risk, and selection.
- Stage view with restore/remove actions.
- Basic settings for review and Stage preferences.

## Build

Requirements:

- Xcode 16 or newer
- XcodeGen
- iOS 17.0 or newer deployment target

Generate the Xcode project:

```bash
xcodegen generate
```

Build from Terminal:

```bash
xcodebuild -project theMCleanGo.xcodeproj -scheme theMCleanGo -destination 'generic/platform=iOS Simulator' build
```

Or open `theMCleanGo.xcodeproj` in Xcode and run on iPhone or iPad simulator.

## App Store Positioning

Suggested name: **theMClean Go**

Suggested subtitle: **File review for iPhone and iPad**

Suggested category: **Utilities**

The review notes should clearly say:

> theMClean Go only scans files and folders selected by the user through the Files picker. It does not scan iOS system caches, other apps, private app containers, or hidden operating system storage.

## Roadmap

See [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md).
