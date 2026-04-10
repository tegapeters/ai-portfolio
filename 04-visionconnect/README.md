# VisionConnect

**MS Capstone Project — Apple Vision Pro spatial multiplayer application**

Collaborative spatial computing experience built for visionOS. Two users share the same 3D environment in real time through FaceTime and Apple's SharePlay framework, with coordinate-aligned spatial objects that appear in the same physical position for both participants.

## What It Does

Users join a shared spatial session where they occupy different roles in a 3D road environment. A spatial chess board is rendered in RealityKit and synced between participants — each move, collision, and game state update is transmitted and applied across both headsets in real time. The environment includes ambient traffic audio, a HUD layer for collision alerts, and role-based access control enforced throughout the session.

## Technical Highlights

**Real-time multiplayer sync**
- Built on Apple's `GroupActivities` framework (SharePlay)
- `GroupSessionMessenger` transmits game state deltas between participants
- Handles session join, disconnect, and reconnect gracefully

**Coordinate Frame Alignment**
- Key challenge: two Vision Pro headsets in different physical spaces must agree on where virtual objects are in the world
- `ImageOriginAligner.swift` uses ARKit world tracking anchors to align coordinate frames between devices — so a chess piece moved by User A appears in the same relative position for User B

**Spatial Environment**
- Full immersive space rendered with RealityKit
- Road scene with physics materials and opacity control
- Ambient audio (traffic) + error audio on collision events
- Dynamic road opacity adjustment at runtime via `PhysicallyBasedMaterial`

**HUD Layer**
- Heads-up display overlay for collision state, game status, and role info
- Collision billboard with dismissal flow

**Role System**
- Users select a role on entry (`RolePickerView`)
- Role governs interaction permissions and UI state throughout the session

## Architecture

```
VisionConnect/
├── AppModel.swift                  ← Central state + SharePlay session management
├── masters_projectApp.swift        ← App entry + scene routing
├── SharePlay/
│   ├── SharePlayProvider.swift     ← GroupSession lifecycle, messenger setup
│   └── AppGroupActivity.swift      ← Activity definition
├── CoordinateFrameAlignment/
│   └── ImageOriginAligner.swift    ← ARKit-based world anchor alignment
├── View/
│   ├── FullSpaceView.swift         ← Immersive space root
│   ├── RolePickerView.swift        ← Entry role selection
│   ├── HUDLayerView.swift          ← HUD overlay
│   ├── Arena.swift                 ← 3D chess arena + piece logic
│   ├── BoardView.swift             ← Board rendering
│   └── SharePlayMenu.swift         ← Session invite/join UI
└── ActivityState/
    ├── Chess.swift                 ← Game rules and move validation
    ├── Piece.swift                 ← Piece model
    └── ActivityState.swift         ← Shared game state (synced via SharePlay)
```

## Stack

Swift · visionOS · RealityKit · GroupActivities (SharePlay) · ARKit · Combine · Xcode

## Key Challenges Solved

1. **World anchor alignment across headsets** — most spatial demos assume a single device. Aligning two independent ARKit sessions into the same coordinate frame required custom anchor-matching logic.
2. **Conflict-free state sync** — concurrent moves from two players must not corrupt game state. The activity state model is designed for serializable updates.
3. **Immersive space lifecycle** — visionOS manages immersive spaces differently from standard windows; `isFullSpaceShown`, `queueToOpenScene`, and `requestDismissVolume` flags coordinate the transition without race conditions.
