# UserSpec Figma Plugin — Spec
*Version 1.0 — March 2026*
*Craig Clayton — mobiledesigndev.com*

---

## TABLE OF CONTENTS

1. Overview
2. Goals & Non-Goals
3. Tech Stack
4. GitHub Setup
5. Plugin UI & Workflow
6. Code Generation — SwiftUI View
7. Code Generation — Asset Catalog
8. Code Generation — UserSpec Stubs (Optional)
9. Figma API — Reading Designs
10. Design Token Mapping
11. Output File Structure
12. Error Handling
13. Documentation
14. Build Order
15. Version Roadmap

---

## 1. OVERVIEW

The UserSpec Figma Plugin is a Figma Community plugin that bridges design and development. A developer selects one or more screens (frames) in Figma, runs the plugin, and receives:

- One empty SwiftUI View file per screen
- One shared `.xcassets` file with all colors and images mapped from the Figma file
- Optionally, one UserSpec `@UserStory` / `@Scenario` stub file per screen

The output is a skeleton — not production code. The developer fills in the logic. The plugin handles the scaffolding so the developer starts from the design, not from a blank file.

This is Design-Driven Development made into a tool.

---

## 2. GOALS & NON-GOALS

### Goals
- Select one or more Figma frames and generate Swift files instantly
- Empty MV skeleton — View only, no architecture imposed beyond that
- Asset catalog generated from Figma design tokens (colors, images)
- Optional UserSpec story stubs — developer chooses before generating
- One file per screen — clean, predictable output
- Part of the UserSpec ecosystem — links back to framework and book
- Available in Figma Community for free

### Non-Goals
- Not a full code generator — output is a skeleton, not production SwiftUI
- Not MVVM or any other specific architecture
- Not a design-to-pixel-perfect-SwiftUI tool
- Not a standalone product — part of UserSpec
- Not a paid plugin
- Does not generate business logic
- Does not generate navigation or routing

---

## 3. TECH STACK

```
Language:         TypeScript
Runtime:          Figma Plugin API (sandboxed browser environment)
UI:               HTML + CSS (Figma plugin UI iframe)
Output:           Plain text Swift files + xcassets JSON
Distribution:     Figma Community (free)
Repo:             GitHub
```

---

## 4. GITHUB SETUP

### Repository
```
https://github.com/thedevme/userspec-figma-plugin
```

### Repository Structure
```
userspec-figma-plugin/
├── src/
│   ├── plugin/
│   │   ├── main.ts                 # Plugin entry point
│   │   ├── frameReader.ts          # Reads Figma frames and nodes
│   │   ├── tokenExtractor.ts       # Extracts colors, typography, images
│   │   └── generators/
│   │       ├── viewGenerator.ts    # Generates SwiftUI View files
│   │       ├── assetGenerator.ts   # Generates .xcassets structure
│   │       └── storyGenerator.ts   # Generates UserSpec stubs
│   └── ui/
│       ├── index.html              # Plugin UI
│       ├── styles.css
│       └── ui.ts                  # UI logic
├── manifest.json                   # Figma plugin manifest
├── package.json
├── tsconfig.json
├── webpack.config.js
└── README.md
```

### manifest.json
```json
{
  "name": "UserSpec — SwiftUI & Story Generator",
  "id": "userspec-swiftui-generator",
  "api": "1.0.0",
  "main": "dist/main.js",
  "ui": "dist/ui.html",
  "editorType": ["figma"],
  "documentAccess": "dynamic-page",
  "permissions": ["currentuser"]
}
```

---

## 5. PLUGIN UI & WORKFLOW

### Step 1 — Select Screens
Developer selects one or more frames in Figma before running the plugin. The plugin reads the current selection when it opens.

### Step 2 — Plugin Opens
Plugin UI shows:
- List of selected frames with checkboxes (all checked by default)
- Frame name shown — this becomes the Swift file name
- Option to rename any frame before generating

### Step 3 — Options
Two options the developer sets before generating:

**Generate UserSpec Stories**
Toggle — off by default. When on, generates a `@UserStory` stub file alongside each view file.

**Asset Catalog Name**
Text input — default value: `Assets`. Developer can change to match their existing project asset catalog name.

### Step 4 — Generate
Developer taps Generate. Plugin produces all files and displays them in the UI — one tab per file. Developer copies each file individually or downloads all as a zip.

### Plugin UI Layout
```
┌─────────────────────────────────┐
│  UserSpec                       │
│  SwiftUI & Story Generator      │
├─────────────────────────────────┤
│  Selected Screens               │
│  ☑ SeatSelectionScreen    ✎    │
│  ☑ FlightResultsScreen    ✎    │
│  ☑ BookingConfirmation    ✎    │
├─────────────────────────────────┤
│  Options                        │
│  ○ Generate UserSpec Stories    │
│  Asset Catalog: [Assets       ] │
├─────────────────────────────────┤
│  [        Generate         ]    │
└─────────────────────────────────┘

── After Generate ────────────────
│  Files                          │
│  SeatSelectionView.swift        │
│  FlightResultsView.swift        │
│  BookingConfirmationView.swift  │
│  Assets.xcassets/               │
│  SeatSelectionSpec.swift        │  ← only if stories toggled on
│  FlightResultsSpec.swift        │
│  BookingConfirmationSpec.swift  │
│                                 │
│  [Copy All]  [Download Zip]     │
└─────────────────────────────────┘
```

---

## 6. CODE GENERATION — SwiftUI View

### Naming Convention
Frame name in Figma → Swift file name

| Figma Frame Name | Generated File |
|---|---|
| Seat Selection Screen | SeatSelectionView.swift |
| Flight Results | FlightResultsView.swift |
| Booking Confirmation | BookingConfirmationView.swift |
| dashboard | DashboardView.swift |

Rules:
- Strip "Screen", "View", "Page" suffix if present
- PascalCase the result
- Always append `View` to the type name
- Always append `View.swift` to the file name

### Generated SwiftUI View
```swift
// SeatSelectionView.swift
// Generated by UserSpec Figma Plugin
// Source: Figma — [Frame Name]
// Generated: 2026-03-28
//
// This is an empty skeleton. Fill in your implementation.
// Learn more: https://github.com/thedevme/UserSpec

import SwiftUI

struct SeatSelectionView: View {

    // MARK: - Body

    var body: some View {
        Text("SeatSelectionView")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.appBackground))
    }
}

// MARK: - Preview

#Preview {
    SeatSelectionView()
}
```

### What the Generator Reads from Figma
To produce the background color in `body`:
- Frame fill color → mapped to nearest named color token in the asset catalog
- If no match found → defaults to `Color(.appBackground)`

Nothing else is generated in the view body. The skeleton is intentionally empty.

---

## 7. CODE GENERATION — ASSET CATALOG

### What Gets Generated
One `.xcassets` folder containing:
- All unique fill colors found across all selected frames → Color Sets
- All image layers found in selected frames → Image Sets
- `Contents.json` files at every level (required by Xcode)

### Color Set Structure
```
Assets.xcassets/
└── Colors/
    ├── Contents.json
    ├── AppBackground.colorset/
    │   └── Contents.json
    ├── AccentBlue.colorset/
    │   └── Contents.json
    ├── DarkText.colorset/
    │   └── Contents.json
    └── MutedText.colorset/
        └── Contents.json
```

### Color Set Contents.json
```json
{
  "colors": [
    {
      "color": {
        "color-space": "srgb",
        "components": {
          "red": "0.345",
          "green": "0.643",
          "blue": "0.690",
          "alpha": "1.000"
        }
      },
      "idiom": "universal"
    }
  ],
  "info": {
    "author": "UserSpec Figma Plugin",
    "version": 1
  }
}
```

### Color Naming
Colors are named from Figma style names when available:

| Figma Style Name | Generated Color Name |
|---|---|
| `Colors/Accent` | `Accent` |
| `Colors/Background/Primary` | `BackgroundPrimary` |
| `blue-500` | `Blue500` |
| (no name, raw hex #58A4B0) | `Color58A4B0` |

### Image Set Structure
```
Assets.xcassets/
└── Images/
    ├── Contents.json
    └── FlightIcon.imageset/
        ├── Contents.json
        └── FlightIcon@2x.png    ← exported from Figma at 2x
```

### Image Set Contents.json
```json
{
  "images": [
    { "idiom": "universal", "scale": "1x" },
    { "filename": "FlightIcon@2x.png", "idiom": "universal", "scale": "2x" },
    { "idiom": "universal", "scale": "3x" }
  ],
  "info": {
    "author": "UserSpec Figma Plugin",
    "version": 1
  }
}
```

### SwiftUI Color Extension
Generated alongside the asset catalog:

```swift
// Color+Assets.swift
// Generated by UserSpec Figma Plugin

import SwiftUI

extension Color {
    static let appBackground = Color("AppBackground")
    static let accentBlue = Color("AccentBlue")
    static let darkText = Color("DarkText")
    static let mutedText = Color("MutedText")
}

extension UIColor {
    static let appBackground = UIColor(named: "AppBackground")!
    static let accentBlue = UIColor(named: "AccentBlue")!
}
```

---

## 8. CODE GENERATION — USERSPEC STUBS (OPTIONAL)

Only generated when developer toggles "Generate UserSpec Stories" on.

### How Interactive Elements Are Detected
The plugin scans each frame for nodes that suggest user interaction:
- Nodes named with action words: "Button", "CTA", "Tap", "Select", "Submit", "Cancel", "Book", "Add", "Remove", "Search"
- Component instances that are buttons or input fields
- Any node with an interaction defined in Figma (prototype connections)

Each detected interactive element becomes one `@Scenario` stub.

### Generated UserSpec Stub
```swift
// SeatSelectionSpec.swift
// Generated by UserSpec Figma Plugin
// Source: Figma — Seat Selection Screen
// Generated: 2026-03-28
//
// Fill in the Given/When/Then bodies with your implementation.
// Learn more: https://github.com/thedevme/UserSpec

import Testing
import UserSpec

@UserStory("As a user, I want to [complete the story for: Seat Selection]")
struct SeatSelectionSpec {

    // Detected interactive element: "Book Seat Button"
    @Test
    @Scenario("User taps Book Seat")
    func userTapsBookSeat() {
        given("") { }
        .when("user taps Book Seat") { _ in }
        .then("") { _ in }
    }

    // Detected interactive element: "Cancel Button"
    @Test
    @Scenario("User taps Cancel")
    func userTapsCancel() {
        given("") { }
        .when("user taps Cancel") { _ in }
        .then("") { _ in }
    }

    // Detected interactive element: "Seat 1A"
    @Test
    @Scenario("User selects Seat 1A")
    func userSelectsSeat1A() {
        given("") { }
        .when("user selects Seat 1A") { _ in }
        .then("") { _ in }
    }
}
```

### Scenario Naming Rules
- Node name → scenario description
- Function name → camelCase of scenario description
- Strip common suffixes: "Button", "CTA", "Icon", "View"
- "Book Seat Button" → scenario: "User taps Book Seat" → function: `userTapsBookSeat()`

---

## 9. FIGMA API — READING DESIGNS

### Reading Selected Frames
```typescript
// main.ts
figma.on('run', () => {
  const selection = figma.currentPage.selection;
  const frames = selection.filter(node => node.type === 'FRAME');

  if (frames.length === 0) {
    figma.ui.postMessage({
      type: 'NO_SELECTION',
      message: 'Please select one or more frames before running the plugin.'
    });
    return;
  }

  const frameData = frames.map(frame => readFrame(frame));
  figma.ui.postMessage({ type: 'FRAMES_READY', frames: frameData });
});
```

### Reading Frame Contents
```typescript
// frameReader.ts
function readFrame(frame: FrameNode): FrameData {
  return {
    id: frame.id,
    name: frame.name,
    width: frame.width,
    height: frame.height,
    backgroundColor: extractFill(frame),
    colors: extractColors(frame),
    images: extractImages(frame),
    interactiveElements: extractInteractiveElements(frame)
  };
}

function extractInteractiveElements(frame: FrameNode): InteractiveElement[] {
  const elements: InteractiveElement[] = [];
  const actionKeywords = ['button', 'cta', 'tap', 'select', 'submit',
                          'cancel', 'book', 'add', 'remove', 'search'];

  frame.findAll(node => {
    const nameLower = node.name.toLowerCase();
    const isInteractive = actionKeywords.some(k => nameLower.includes(k));
    const hasPrototypeConnection = node.reactions?.length > 0;

    if (isInteractive || hasPrototypeConnection) {
      elements.push({ id: node.id, name: node.name, type: node.type });
    }
    return false;
  });

  return elements;
}
```

### Reading Colors
```typescript
// tokenExtractor.ts
function extractColors(frame: FrameNode): ColorToken[] {
  const colors: Map<string, ColorToken> = new Map();

  frame.findAll(node => {
    if ('fills' in node) {
      node.fills.forEach(fill => {
        if (fill.type === 'SOLID') {
          const hex = rgbToHex(fill.color);
          const styleName = getStyleName(node) ?? hex;
          colors.set(hex, { hex, name: styleName });
        }
      });
    }
    return false;
  });

  return Array.from(colors.values());
}
```

---

## 10. DESIGN TOKEN MAPPING

### Color Naming Priority
1. Figma local style name (best) — `Colors/Accent` → `Accent`
2. Figma variable name — `accent-blue` → `AccentBlue`
3. Fallback — raw hex → `Color58A4B0`

### Deduplication
Colors that appear across multiple frames are deduplicated. One color = one Color Set regardless of how many screens use it.

### Typography
Typography tokens are read but not currently used in code generation. Stored for future use in v1.1.0.

---

## 11. OUTPUT FILE STRUCTURE

### Example — 3 screens selected, stories on
```
UserSpec-Generated/
├── Views/
│   ├── SeatSelectionView.swift
│   ├── FlightResultsView.swift
│   └── BookingConfirmationView.swift
├── Specs/
│   ├── SeatSelectionSpec.swift
│   ├── FlightResultsSpec.swift
│   └── BookingConfirmationSpec.swift
├── Assets/
│   └── Assets.xcassets/
│       ├── Contents.json
│       ├── Colors/
│       │   ├── Contents.json
│       │   ├── AppBackground.colorset/
│       │   ├── AccentBlue.colorset/
│       │   └── DarkText.colorset/
│       └── Images/
│           └── Contents.json
└── Extensions/
    └── Color+Assets.swift
```

### Example — 3 screens selected, stories off
```
UserSpec-Generated/
├── Views/
│   ├── SeatSelectionView.swift
│   ├── FlightResultsView.swift
│   └── BookingConfirmationView.swift
├── Assets/
│   └── Assets.xcassets/
└── Extensions/
    └── Color+Assets.swift
```

---

## 12. ERROR HANDLING

| Scenario | Plugin Behavior |
|---|---|
| No frames selected | Shows message: "Select one or more frames to generate" |
| Frame has no fills | Defaults to `Color(.appBackground)` |
| Frame name has special characters | Sanitized to valid Swift identifier |
| Duplicate frame names | Appends index: `HomeView`, `HomeView2` |
| Image export fails | Skips image, logs warning in UI |
| No interactive elements found | Generates stub with one empty scenario and a comment |

---

## 13. DOCUMENTATION

### README Structure
```markdown
# UserSpec Figma Plugin

Generate SwiftUI skeletons and UserSpec story stubs directly from your Figma designs.

## What It Does
Select screens → Generate Swift files

## Installation
Search "UserSpec" in Figma Community → Install

## Usage
1. Select one or more frames in Figma
2. Run the plugin (Plugins → UserSpec)
3. Choose options
4. Generate and copy files into your Xcode project

## Output
- One SwiftUI View file per screen
- One Assets.xcassets with your design tokens
- Optional UserSpec story stubs per screen

## UserSpec Framework
[Link to UserSpec GitHub]

## The Book
[Link to The Swift Testing Handbook]
```

### Figma Community Listing
- Name: UserSpec — SwiftUI & Story Generator
- Category: Developer tools
- Tags: Swift, SwiftUI, iOS, Testing, BDD, UserSpec
- Description: Generate SwiftUI view skeletons and UserSpec BDD test stubs from your Figma designs. Part of the UserSpec testing framework ecosystem.

---

## 14. BUILD ORDER

```
1.  Init plugin: npm create figma-plugin
2.  Set up TypeScript + webpack config
3.  Build plugin UI — frame list, options, generate button
4.  Implement frame reading — selection, name extraction
5.  Implement color extraction — fills, style names, deduplication
6.  Implement image extraction
7.  Implement interactive element detection
8.  Implement SwiftUI View generator
9.  Implement Color+Assets.swift extension generator
10. Implement xcassets structure generator (JSON files)
11. Implement UserSpec stub generator
12. Implement file output — copy and download zip
13. Error handling for all edge cases
14. Test on airline ticketing app Figma file
15. Test on banking sample app Figma file
16. Submit to Figma Community
17. Tag v1.0.0
```

---

## 15. VERSION ROADMAP

### v1.0.0 — Launch
- Frame selection and reading
- Empty SwiftUI View generation per screen
- xcassets generation (colors + images)
- Color+Assets.swift extension
- Optional UserSpec story stubs
- Figma Community listing

### v1.1.0 — Typography Tokens
- Typography styles extracted from Figma
- Font extension generated: `Font+Assets.swift`
- Text styles mapped to SwiftUI Font values

### v1.2.0 — Component Detection
- Recognizes Figma components and variants
- Generates reusable SwiftUI subview stubs for repeated components
- e.g. a Card component used on 3 screens → one `CardView.swift`

### v2.0.0 — Two-Way Sync
- Changes to Swift file names reflected back in Figma
- Stale generated files flagged when Figma design changes

---

*Spec v1.0 — March 2026*
*Craig Clayton — mobiledesigndev.com*
*Part of the UserSpec ecosystem*
*Companion to The Swift Testing Handbook*
