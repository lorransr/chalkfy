# Why a Firefox-based screen share misses the overlay

Answers [#9](https://github.com/lorransr/chalkfy/issues/9). Sources were read on 2026-10-27:

- Firefox: [mozilla-firefox/firefox@5a78f45](https://github.com/mozilla-firefox/firefox/tree/5a78f4525f81f7323c2c044965096723318af6e6). `FF/` below is that tree.
- Chromium: [chromium/chromium@d2b146e](https://github.com/chromium/chromium/tree/d2b146ea217c532610c36b20134302c41f231521).
- Zen 1.24b is built on Firefox 159.0 ([surfer.json](https://github.com/zen-browser/desktop/blob/5d8c3d52b280cfc4af56c882942efea043a5ff1e/surfer.json#L6-L11)). GitHub code search finds no `screencapturekit` or `getdisplaymedia` pref override in the Zen repo.

## Capture path by Firefox version (macOS)

| Firefox | Screen capture backend | Who builds the `SCContentFilter` |
|---|---|---|
| ≤ 130 | libwebrtc `ScreenCapturerMac` (CoreGraphics) | no SCK |
| 131–134 | libwebrtc `ScreenCapturerSck` with Firefox's own picker ([bug 1915562](https://bugzilla.mozilla.org/show_bug.cgi?id=1915562)) | Firefox: `initWithDisplay:excludingWindows:@[]` ([FF screen_capturer_sck.mm#L522-L524](https://github.com/mozilla-firefox/firefox/blob/5a78f4525f81f7323c2c044965096723318af6e6/third_party/libwebrtc/modules/desktop_capture/mac/screen_capturer_sck.mm#L522-L524)) |
| ≥ 135, macOS ≥ 14 | `ScreenCapturerSck` + `SCContentSharingPicker`, the Control Center picker ([bug 1918096](https://bugzilla.mozilla.org/show_bug.cgi?id=1918096), on by default since [bug 1918648](https://bugzilla.mozilla.org/show_bug.cgi?id=1918648)) | **macOS**. The picker hands a filter to `contentSharingPicker:didUpdateWithFilter:forStream:`, and Firefox passes it to `SCStream` unchanged ([#L832-L839](https://github.com/mozilla-firefox/firefox/blob/5a78f4525f81f7323c2c044965096723318af6e6/third_party/libwebrtc/modules/desktop_capture/mac/screen_capturer_sck.mm#L832-L839), [#L391-L402](https://github.com/mozilla-firefox/firefox/blob/5a78f4525f81f7323c2c044965096723318af6e6/third_party/libwebrtc/modules/desktop_capture/mac/screen_capturer_sck.mm#L391-L402)) |
| Brave / Chrome (contrast) | own picker, then SCK. `kUseSCContentSharingPicker` is disabled by default ([media_switches.cc#L1561-L1564](https://github.com/chromium/chromium/blob/d2b146ea217c532610c36b20134302c41f231521/media/base/media_switches.cc#L1561-L1564)) | Chromium: `initWithDisplay:excludingWindows:` with nothing, or only its own PiP window ([screen_capture_kit_device_mac.mm#L320-L328](https://github.com/chromium/chromium/blob/d2b146ea217c532610c36b20134302c41f231521/content/browser/media/capture/screen_capture_kit_device_mac.mm#L320-L328)) |

The switches are three startup prefs (`mirror: once`, so a change needs a restart) ([StaticPrefList.yaml#L13925-L13952](https://github.com/mozilla-firefox/firefox/blob/5a78f4525f81f7323c2c044965096723318af6e6/modules/libpref/init/StaticPrefList.yaml#L13925-L13952), read in [desktop_capture_impl.cc#L94-L102](https://github.com/mozilla-firefox/firefox/blob/5a78f4525f81f7323c2c044965096723318af6e6/dom/media/systemservices/video_engine/desktop_capture_impl.cc#L94-L102)):

| Pref | Default | Effect when `false` |
|---|---|---|
| `media.getdisplaymedia.screencapturekit.enabled` | `true` | CoreGraphics backend |
| `media.getdisplaymedia.screencapturekit.picker.enabled` | `true` | Firefox's own picker. SCK builds the display filter itself, the same way Chromium does |
| `media.getdisplaymedia.screencapturekit.enumeration.enabled` | `false` | — |

## What this means for the overlay

- In Zen the overlay is lost **inside the filter that the macOS picker returns**. Firefox adds no exclusions and never reads window level or `sharingType`. Its only picker setup is `allowedPickerModes` (SingleDisplay | MultipleWindows) and a content style ([#L361-L388](https://github.com/mozilla-firefox/firefox/blob/5a78f4525f81f7323c2c044965096723318af6e6/third_party/libwebrtc/modules/desktop_capture/mac/screen_capturer_sck.mm#L361-L388), [#L776-L782](https://github.com/mozilla-firefox/firefox/blob/5a78f4525f81f7323c2c044965096723318af6e6/third_party/libwebrtc/modules/desktop_capture/mac/screen_capturer_sck.mm#L776-L782)).
- Apple does not document how the picker builds a display filter. Since macOS 15.2 the result is inspectable through [`SCContentFilter.includedApplications`](https://developer.apple.com/documentation/screencapturekit/sccontentfilter/includedapplications) / [`includedWindows`](https://developer.apple.com/documentation/screencapturekit/sccontentfilter/includedwindows).
- The frontmost blip is not explained by any source. A Firefox comment says the macOS 15 picker in its `None` style "behaves like Window in 14", and that on 14 the Window style "automatically hides our current window to show others" ([#L366-L374](https://github.com/mozilla-firefox/firefox/blob/5a78f4525f81f7323c2c044965096723318af6e6/third_party/libwebrtc/modules/desktop_capture/mac/screen_capturer_sck.mm#L366-L374)). If Zen is hidden, macOS may activate the next app, which would be ChalkfyRing. This is unverified.
- No Bugzilla bug matches. Searches covered the SCK meta bug [1854382](https://bugzilla.mozilla.org/show_bug.cgi?id=1854382) and its dependencies, plus every `Core :: WebRTC: Audio/Video` bug filed since 2024-08 with mac/picker/screen-share in the summary. Apple forums have one related open report: an `NSWindowSharingNone` window missing from an SCK display filter until it is reconfigured (FB21115847, [thread 808016](https://developer.apple.com/forums/thread/808016)).
- Turning the picker off costs something. Chromium's flag comment says the system picker "is required to avoid recurring permission dialogs" on macOS 15 ([media_switches.cc#L1561-L1563](https://github.com/chromium/chromium/blob/d2b146ea217c532610c36b20134302c41f231521/media/base/media_switches.cc#L1561-L1563)).

## Next tests (not run)

1. Zen `about:config`: set `media.getdisplaymedia.screencapturekit.picker.enabled = false`, restart, and share the whole screen in Meet. If the overlay shows, the cause is confirmed to be the picker's filter.
2. If (1) confirms it, build a small Swift harness that calls `SCContentSharingPicker.shared.present()`, then logs `filter.style`, `includedApplications` and `includedWindows` for a display pick and saves one frame. Run it with ChalkfyRing on `.accessory` vs `.regular`, and with `level` at 1001 vs `.statusBar` / `.floating`. This shows whether any window or app setting gets the overlay into the picker's filter.
