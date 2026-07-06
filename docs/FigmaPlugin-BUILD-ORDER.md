# UserSpec Figma Plugin — Build Order

## Implementation Steps

1. Init plugin: `npm create figma-plugin`
2. Set up TypeScript + webpack config
3. Build plugin UI — frame list, options, generate button
4. Implement frame reading — selection, name extraction
5. Implement color extraction — fills, style names, deduplication
6. Implement image extraction
7. Implement interactive element detection
8. Implement SwiftUI View generator
9. Implement Color+Assets.swift extension generator
10. Implement xcassets structure generator (JSON files)
11. Implement UserSpec stub generator
12. Implement file output — copy and download zip
13. Error handling for all edge cases
14. Test on airline ticketing app Figma file
15. Test on banking sample app Figma file
16. Submit to Figma Community
17. Tag v1.0.0

---

## Repository Structure

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
│       └── ui.ts                   # UI logic
├── manifest.json                   # Figma plugin manifest
├── package.json
├── tsconfig.json
├── webpack.config.js
└── README.md
```

---

*See FigmaPlugin-SPEC.md for full specification*
