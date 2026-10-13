# Vendor Locator design system

The design system lives in `Vendor Locator/DesignSystem`. It is native SwiftUI, compatible with the app's iOS 16 minimum, and has no package dependencies. Feature screens compose the controls with localized text and callbacks; design components do not fetch data or own feature state.

## Foundation

Use the `DS` namespace rather than repeating presentation values:

| Tokens | Purpose |
| --- | --- |
| `DS.Colors` | Semantic accent, text, surface, background, error, and favorite colors |
| `DS.Palette` | UIKit counterparts for the Google Maps adapter |
| `DS.Typography` | System text styles that scale with Dynamic Type |
| `DS.Spacing` | 4, 8, 12, 16, and 24 point spacing |
| `DS.Layout` | 44 point minimum control targets, 12 point corners, map heights |

The accent uses dark teal in light mode and light teal in dark mode. `onAccent` adapts alongside it. Native semantic text and surface colors follow system appearance. Apply `.appTheme()` to navigation roots and independently presented sheets. Native Form, List, toolbar buttons, secure fields, and navigation remain native controls.

## Components

Components are grouped by purpose so Xcode presents each category as a separate synchronized group:

```text
DesignSystem/
├── Components/
│   ├── Buttons/
│   ├── Loaders/
│   ├── States/
│   └── Text/
├── Foundation/
│   ├── Colors/
│   ├── Layout/
│   └── Typography/
├── Styling/
│   ├── Buttons/
│   ├── Loaders/
│   ├── Other/
│   ├── States/
│   └── Text/
└── Previews/
```

- `DSButtonStyle`: primary filled and secondary tinted actions, with disabled/pressed feedback and destructive role support. Use on standalone actions; retain native button styles inside Settings forms and toolbars.
- `DSFavoriteButton`: a minimum 44-point target with outlined/filled heart states and a caller-provided accessibility label.
- `DSLoadingView`: a progress indicator and scalable descriptive text.
- `DSMessageView`: information/error presentation with a symbol and readable wrapping text. Errors never rely on color alone.
- `DSEmptyState`: a decorative symbol, title, and explanatory message.

Feature components such as VendorRow, VendorMapSection, and LoadFailureView compose these foundations. Keep feature-specific copy and behaviors outside DesignSystem. Pass resolved `L10n` strings into component inputs; interpolate complete localized phrases before passing them in.

## Usage

```swift
Button(L10n.tryAgain, action: retry)
    .buttonStyle(DSButtonStyle(emphasis: .secondary))

DSMessageView(message: message, tone: .error)
DSLoadingView(title: L10n.findingVendors)
```

Avoid fixed-height text containers and custom font point sizes. Do not truncate essential copy to fit a token. Vendor names, provider attribution, and secure-token text remain content, not design-system strings. Keep Google attribution visible and preserve the native map's controls.

## Preview and validation

Open `DesignSystem/Previews/DesignSystemGallery.swift` in Xcode for standard and accessibility-size specimens; use Canvas’s appearance toggle for light/dark mode. The gallery includes interactive favorite state, primary/secondary actions, disabled and destructive controls, loading, messages, and empty state. Its developer-only sample copy is intentionally separate from app localization.

Swift syntax checks are available in this environment. Full compilation, rendered previews, VoiceOver behavior, contrast measurement, and device testing still require validation in Xcode; these have not been claimed as passed.

## Styling

`DesignSystem/Styling/` mirrors the component categories and separates reusable appearance from component layout and behavior:

- `DSButtonStyle`: SwiftUI ButtonStyle for primary and secondary actions.
- `DSAppTheme`: root tint and typography, exposed through `.appTheme()`.
- `DSFavoriteStyle`: favorite color and minimum hit-target geometry.
- `DSLoadingStyle`: progress tint and vertical spacing.
- `DSMessageStyle`: message tone and spacing, using `DSMessageTone`.
- `DSEmptyStateStyle`: wrapping behavior and spacing for empty content.

Components apply these styles even when they currently have only one consumer. Other components can reuse them directly without inheriting feature layout, text, or behavior:

```swift
Label(L10n.demoPlacesHint, systemImage: "info.circle")
    .modifier(DSMessageStyle(tone: .information))
```

Keep accessibility labels and grouping on the component that owns their meaning. Keep all `#Preview` bodies on separate lines for readability.

`PreviewCanvasModifier` is a debug-only reusable preview canvas. Apply `.previewCanvas()` to small component specimens for standard padding, a semantic background, and the app theme. It does not force a color scheme; Canvas controls appearance.
