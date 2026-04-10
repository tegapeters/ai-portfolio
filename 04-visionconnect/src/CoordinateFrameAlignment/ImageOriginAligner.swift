//
//  ImageOriginAligner.swift
//  masters_project
//
//  Runs AR
//
//  Created by CKendrick on 9/13/25.
//

import SwiftUI
import ARKit
import RealityKit
import simd

@MainActor
final class FiducialController: ObservableObject {
    @EnvironmentObject var model: AppModel
    private let session = ARKitSession()
    private let world = WorldTrackingProvider()
    private var worldStarted = false
    private var images: ImageTrackingProvider!
    var handSession: SpatialTrackingSession?
    var handSessionStarted = false
    private var started = false
    @Published private(set) var droppedWorldPose: Bool = false
    @Published var floorY: Float? = nil
    @Published var isAligning: Bool = false
    var immersiveLoaded = false
    private var startedAfterFloor = false
    
    // Hook to RealityKit
    let contentRootAnchor = AnchorEntity(world: .zero)
    init() {
        contentRootAnchor.anchoring.physicsSimulation = .none
    }
    
    let floorAnchor = AnchorEntity(.plane(.horizontal, classification: .floor, minimumBounds: [1.0,1.0]))
    
    func resetForNewSession() {
        started = false
        startedAfterFloor = false
        droppedWorldPose = false
        immersiveLoaded = false
        handSessionStarted = false
        floorY = nil
        isAligning = false
        worldStarted = false
        contentRootAnchor.children.removeAll()
        contentRootAnchor.transform = .init()
    }
    
    func startAfterFloorYSet(desiredY: Float) {
        guard !startedAfterFloor, floorY != nil else { return }
        startedAfterFloor = true
        
        Task {
            do { try await startWorldToImageAnchor(desiredY: desiredY) }
            catch{ print("startWorldToImageAnchor failed: \(error)")}
        }
    }
    
    func ensureWorldTrackingRunning() async {
        guard !worldStarted else {return}
        _ = await session.requestAuthorization(for: [.worldSensing])
        do {
            try await session.run([world])
            worldStarted = true
            print("Fiducial: world tracking started")
        } catch {
            print("Fiducial: failed to start world tracking:", error)
        }
    }
    
    func startWorldToImageAnchor(desiredY: Float) async throws {
        guard !started else {return}
        started = true
        
        isAligning = true
        defer { isAligning = false }
        
        // request to visionOS -> access to world sensing
        //_ = await session.requestAuthorization(for: [.worldSensing])
        
        images = ImageTrackingProvider(referenceImages: ReferenceImage.loadReferenceImages(inGroupNamed: "AR Resources"))
        
        // run session with both providers [world, images] to detect the fiducial
        try await session.run([world, images])
        
        print("Aligner: starting image tracking (have floorY =", self.floorY as Any, ")")
        
        // listen for image anchor
        for await imageAnchorUpdate in images.anchorUpdates {
            switch imageAnchorUpdate.event {
            case .added:
                await self.dropAlignmentAnchor(imageAnchorUpdate.anchor, desiredY: desiredY)
            default:
                    break
            }
        }
        
        if droppedWorldPose {
           print("world anchor dropped")}
    }
    
    private func dropAlignmentAnchor(_ anchor: ImageAnchor, desiredY: Float) async {
        guard !droppedWorldPose else { return } //only drop once
        
        // capture pose of the fiducial once registered
        let pose = makeUprightTransform(from: anchor.originFromAnchorTransform, desiredY: desiredY)
        
        contentRootAnchor.transform = pose
        
        self.droppedWorldPose = true
        
        // Since we only want to drop the world anchor once on the fiducial, stop the image tracking
        try? await session.run([world]) //image provider off
        
    }
}

struct ImageOriginAligner: View {
    @EnvironmentObject var model: AppModel
    @EnvironmentObject var controller: FiducialController
    @State private var planeAdded = false
    @State private var floorSub: EventSubscription?
    @State private var headAnchor: AnchorEntity?
    @State private var headHUD: Entity?
        
    
    var body: some View {
        RealityView { content in
            content.add(controller.floorAnchor)
            print("Aligner: floorAnchor added; waiting to anchor...")
            
            let head = AnchorEntity(.head)
            let hud = makeHeadHUD(text: "Look at image.")
            hud.position = [0, 0, -0.90]
            head.addChild(hud)
            content.add(head)
            headAnchor = head
            headHUD = hud
            
            floorSub = content.subscribe(to: SceneEvents.AnchoredStateChanged.self, on: controller.floorAnchor) { event in
                print("Aligner: floor anchor state =", event.isAnchored)
                guard event.isAnchored else {return}
                controller.floorY = controller.floorAnchor.position(relativeTo: nil).y
                print("ImageOriginAligner: attempting fiducial-based world alignment.")
                controller.startAfterFloorYSet(desiredY: controller.floorY!)
                floorSub?.cancel()
            }
            
        } update: { content in
            //headHUD?.isEnabled = controller.isAligning
            headHUD?.isEnabled = (controller.floorY == nil) || controller.isAligning
            
            if controller.droppedWorldPose /*, !planeAdded*/ {
                /*Task {@MainActor in
                    model.showHUD("plane->fiducial pose", autoClearAfter: 5.0)
                }*/
                let plane = makePlane(size: 0.17) //meters
                plane.position.y += 0.001  // lifts plane 1mm to avoid conflicts in z-axis
                controller.contentRootAnchor.addChild(plane)  // plane rides with the frozen world pose
                //planeAdded = true
            }
        }
        .task { await controller.ensureWorldTrackingRunning() }
    }
        
    
    func makePlane(size: Float) -> ModelEntity {
        let mesh = MeshResource.generatePlane(width: size, depth: size, cornerRadius: 0.002)
        var unlit = UnlitMaterial()
        unlit.color = .init(tint: .green)
        let plane = ModelEntity(mesh: mesh, materials: [unlit])
        plane.components.set(OpacityComponent(opacity: 0.80))
        
        return plane
    }
    
    func makeHeadHUD(text: String) -> Entity {
        let panelMesh = MeshResource.generatePlane(width: 0.30, height: 0.06, cornerRadius: 0.01)
        var bg = UnlitMaterial()
        bg.color = .init(tint: .black, texture: nil)
        let panel = ModelEntity(mesh: panelMesh, materials: [bg])
        panel.components.set(OpacityComponent(opacity: 0.85))
        
        let textMesh = MeshResource.generateText(
                    text,
                    extrusionDepth: 0.001,
                    font: .systemFont(ofSize: 0.028, weight: .semibold),
                    containerFrame: .zero,
                    alignment: .center,
                    lineBreakMode: .byClipping
        )
        var textMat = UnlitMaterial()
        textMat.color = .init(tint: .white)
        let textEntity = ModelEntity(mesh: textMesh, materials: [textMat])
        
        let textBounds = textEntity.visualBounds(relativeTo: nil)
        textEntity.position = [-Float(textBounds.extents.x) * 0.5, -Float(textBounds.extents.y) * 0.5, 0.002]

        panel.addChild(textEntity)
        panel.components.set(BillboardComponent())

        return panel
    }
}

extension simd_float4x4 {
    var position: SIMD3<Float> {.init(columns.3.x, columns.3.y, columns.3.z)}
    var yAxis: SIMD3<Float> {.init(columns.1.x, columns.1.y, columns.1.z)}
    var rot3x3: simd_float3x3 {
        .init(columns: (
            SIMD3(columns.0.x, columns.0.y, columns.0.z),
            SIMD3(columns.1.x, columns.1.y, columns.1.z),
            SIMD3(columns.2.x, columns.2.y, columns.2.z)
        ))
    }
}

@inline(__always)
func quatAlign(_ aIn: SIMD3<Float>, to bIn: SIMD3<Float>) -> simd_quatf {
    let a = simd_normalize(aIn), b = simd_normalize(bIn)
    let v = simd_cross(a, b)
    let w = 1.0 + simd_dot(a, b)
    return simd_normalize(simd_quatf(ix: v.x, iy: v.y, iz: v.z, r: w))
}

func makeUprightTransform(from imageMatrix: simd_float4x4, desiredY: Float) -> Transform {
    let up = SIMD3<Float>(0,1,0)
    let qImage = simd_quatf(imageMatrix.rot3x3)
    let qAlign = quatAlign(imageMatrix.yAxis, to: up)
    let qUpright = simd_normalize(qAlign * qImage)
    let p = imageMatrix.position
    return Transform(scale: .one, rotation: qUpright, translation: .init(p.x, desiredY, p.z))
}

