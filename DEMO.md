# Seven-minute demo guide

Before recording: configure and verify a live Google Maps key; keep Places mock mode if no Places key is available and say so explicitly. Use a disposable token, never a real credential. Set `--vendors-fail-refresh-once`. Open the project and source files before recording. Use Loom or a screen recorder with your microphone.

| Time | Demonstration and narration |
| --- | --- |
| 0:00–0:45 | Introduce the focused SwiftUI app, iOS 16 deployment target, sample Cape Town vendors, Google map, and mock REST source. State whether Places is live or mocked. |
| 0:45–1:45 | Select two vendors to move the camera. Favorite one. Refresh to show the one-time failure with existing data retained, then retry. Show the favorite remains selected. |
| 1:45–2:45 | Search “Waterfront”, add the result and show its marker/selection. Search/add it again to demonstrate deduplication. For live mode choose a real South African place instead. |
| 2:45–3:30 | Switch simulator appearance between light/dark while running. Show both the list and map adapt. Briefly show larger text. |
| 3:30–4:15 | Open Settings; save a disposable token, reveal it, relaunch and read it again, then clear it. Explain Keychain accessibility and per-request Bearer authentication. |
| 4:15–5:15 | Walk through VendorViewModel and the three injected service protocols. Explain refresh merging, main-actor UI state, async URLSession, and cancellation. |
| 5:15–6:15 | Show GoogleMapView coordinator marker reconciliation and camera revision. Show Places mock/live adapters, continuation bridging, debouncing, and autocomplete session token. |
| 6:15–7:00 | Run the focused XCTest or show its result. Explain in-memory favorites/additions, pinned SDKs, no backend requirement, and live-key verification limits. Finish with README/SOLUTION. |

Delivery checklist: push this repository to the chosen GitHub destination; record a 5–10 minute voiceover; add the video URL to the submission. Do not claim live Maps validation while showing the setup panel.
