//
//  HUDLayerView.swift
//  masters_project
//
//  Created by CKendrick on 9/6/25.
//

import SwiftUI
import RealityKit

struct HUDControlsView: View {
    @EnvironmentObject var model: AppModel
    @EnvironmentObject var controller: FiducialController
    @Environment(\.openWindow) var openWindow
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    
    @State private var started = false
    @State private var paused = false
    @State private var handlingReset = false
    @State private var roadOpacity = 0
    var onStart: () -> Void = {}
    var onPause: () -> Void = {}
    var onResume: () -> Void = {}
    var onReset: () -> Void = {}
    
    var body: some View {
        VStack(spacing: 20) {
            if !model.hudText.isEmpty {
                Text(model.hudText)
                    .font(.title3.weight(.semibold))
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            Button(action: {
                if !started {
                    started = true
                    onStart()
                }
            }){
                Label("Start", systemImage: "play.fill")
            }
            .disabled(started)
            /*Button(action: { onPause()} ) {
                Label("Pause", systemImage: "pause.circle")
            }*/
            Button(action: { onResume() }) {
                Label("Resume", systemImage: "play.circle")
            }
            Button(action: {
                started = false
                paused = false
                onReset()
                model.showCollisionBillboard = false
            }) {
                Label("Reset", systemImage: "backward.end.circle")
            }
            HStack(spacing: 8) {
                Text("Dim Learner road")
                Toggle("", isOn: Binding(
                    get: {model.roadOpacity < 0.999},
                    set: {on in
                        Task { @MainActor in
                            model.roadOpacity = on ? 0.25 : 1.0
                            model.sendAnimationControl("opacity")
                        }
                    }
                ))
                .labelsHidden()
                .toggleStyle(.switch)
            }
            .fixedSize(horizontal: true, vertical: true)
            Button {
                Task {
                    model.isExplicitExit = true
                    model.sendAnimationControl("exit_scene")
                    model.queueToOpenScene = .volume
                }
            } label: {
                Label("Exit Crosswalk Scene", systemImage: "escape")
                    .padding(8)
            }
        }
        .buttonStyle(.borderedProminent)
        .frame(minWidth: 180, minHeight: 200)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.yellow.opacity(0.35))
                .shadow(radius: 40)
        )
        .contentShape(Rectangle())
        
        // Listen for NotificationCenter publisher actions to keep HUD labels in sync
        .onReceive(NotificationCenter.default.publisher(
            for: Notification.Name("RealityKit.NotificationTrigger")))
        { note in
            guard let id = note.userInfo?["RealityKit.NotificationTrigger.Identifier"] as? String else { return }
            if id == "pause" {paused = true}
            if id == "resume" {paused = false}
            if id == "start" {started = true}
            if id == "reset" {paused = false; started = false}
        }
    }
}


struct HUDLayerView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.realityKitScene) private var scene
    
    @State private var headAnchor: AnchorEntity?
    @State private var hudAdded = false
    
    private let rknt = "RealityKit.NotificationTrigger"
    
    var body: some View {
        RealityView {content, attachments in
            if headAnchor == nil {
                let anchor = AnchorEntity(.head)
                content.add(anchor)
                headAnchor = anchor
            }
            
            DispatchQueue.main.async {
                guard !hudAdded,
                      let anchor = headAnchor,
                      let hud = attachments.entity(for: "hud") else {return}
                
                hud.position = [-0.15, -0.15, -1]
                hud.components.set(BillboardComponent())
                hud.components.set(InputTargetComponent()) //ensure taps route
                hud.setScale(SIMD3<Float>(repeating: 1.25), relativeTo: nil)
                
                anchor.addChild(hud)
                hudAdded = true
            }
        } attachments: {
            Attachment(id: "hud") {
                HUDControlsView(
                    onStart: { post("start") },
                    onPause: { post("pause") },
                    onResume: { post("resume") },
                    onReset: {
                        model.isPaused = false
                        post("reset")
                        model.isCollision = false
                        model.isCollided = false
                        model.showCollisionBillboard = false
                    }
                )
                .environmentObject(model)
            }
        }
    }
    
    private func post(_ id: String) {
        guard let scene else { return }
                  
        model.sendAnimationControl(id)
            
        NotificationCenter.default.post(
           name: Notification.Name("\(rknt)"),
           object: nil,
           userInfo: ["\(rknt).Scene": scene, "\(rknt).Identifier": id]
        )
    }
}
