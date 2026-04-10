import SwiftUI
import RealityKit
import RealityKitContent
import ARKit

extension Entity {
    func dumpTree(_ depth: Int = 0) {
        let pad = String(repeating: " ", count: depth)
        let entity_name = name.isEmpty ? "<unnamed>" : name
        print("\(pad)\u{2022} \(entity_name) [\(type(of: self))]")
        for c in children { c.dumpTree(depth + 1) }
    }
}

struct VanSetupTag: Component, Codable {}
struct CarSetupTag: Component, Codable {}

struct Arena: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.physicalMetrics) var physicalMetrics
    private var hudLayer = HUDLayerView()
    @EnvironmentObject var controller: FiducialController
    @State private var headAnchor: AnchorEntity?
    private let handsColliderGroup = CollisionGroup(rawValue: 1 << 1)
    @State private var immersive: Entity?
    
    /*-----------------------------------------------------------------------------------------*/
    /*Code for collision*/
    @State private var collisionBegan: EventSubscription?
    @State private var collisionEnded: EventSubscription?
    @State private var floorSub: EventSubscription?
    @State private var roadblockCollisionSub: EventSubscription?
    @State private var userCollisionSub: EventSubscription?
    @State private var globalCollisionSub: EventSubscription?
    @State var collisionBoard: Entity?
    @State var isCollision = false
    @State var isPaused = false
    @State var isResumed = false
    @State var isReset = false
    @State var isStart = false
    
    @Environment(\.realityKitScene) var scene
    let rknt = "RealityKit.NotificationTrigger"
    func notify(_ scene: RealityKit.Scene) {
        if model.isStart {
            let notification_start = Notification(name: .init(rknt), userInfo: ["\(rknt).Scene" : scene, "\(rknt).Identifier" : "start"])
            model.sendAnimationControl("start")
            NotificationCenter.default.post(notification_start)
        }
        
        if model.isPaused {
            let notification_pause = Notification(name: .init(rknt), userInfo: ["\(rknt).Scene" : scene, "\(rknt).Identifier" : "pause"])
            model.sendAnimationControl("pause")
            NotificationCenter.default.post(notification_pause)
        } /*else {
           let notification_resume = Notification(name: .init(rknt), userInfo: ["\(rknt).Scene" : scene, "\(rknt).Identifier" : "resume"])
           NotificationCenter.default.post(notification_resume)
           }*/
        
        if model.isResumed {
            let notification_resume = Notification(name: .init(rknt), userInfo: ["\(rknt).Scene" : scene, "\(rknt).Identifier" : "resume"])
            model.sendAnimationControl("resume")
            NotificationCenter.default.post(notification_resume)
        }
        
        // enables crash-audio on collision
        if model.isCollision {
            //let notification_collide = Notification(name: .init(rknt), userInfo: ["\(rknt).Scene" : scene, "\(rknt).Identifier" : "collision"])
            model.sendAnimationControl("collision")
            //NotificationCenter.default.post(notification_collide)
        }
        
        if model.isReset {
            model.sendAnimationControl("reset")
            NotificationCenter.default.post(Notification(name: .init(rknt), userInfo: ["\(rknt).Scene" : scene, "\(rknt).Identifier" : "resume"]))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                NotificationCenter.default.post(Notification(name: .init(rknt), userInfo: ["\(rknt).Scene" : scene, "\(rknt).Identifier" : "reset"]))
            }
            return
        }
    }
    
    /*-----------------------------------------------------------------------------------------*/
    
    var body: some View {
        RealityView { content, attachments in
            
            if controller.contentRootAnchor.parent == nil {
                content.add(controller.contentRootAnchor)
            }
            
            await model.ensureAmbientAudio(to: content, gain: 6, force: true)
            
            if controller.handSession == nil {
                controller.handSession = SpatialTrackingSession()
            }
            
            if controller.handSessionStarted == false {
                let configuration = SpatialTrackingSession.Configuration(tracking: [.hand])
                await controller.handSession?.run(configuration)
                controller.handSessionStarted = true
            }
            
            model.attachAudioEmitter(to: content)
            await model.loadErrorAudio()
            
            if headAnchor == nil {
                let headBillboard = AnchorEntity(.head)
                headBillboard.name = "HeadBillboardAnchor"
                headBillboard.anchoring.physicsSimulation = .none
                content.add(headBillboard)
                headAnchor = headBillboard
            }
            
            let rightHandTrigger = makeHandTrigger(in: content, name: "RightHandTrigger", chirality: .right)
            if var rightHandCollider = rightHandTrigger.components[CollisionComponent.self] {
                rightHandCollider.mode = .trigger
                rightHandCollider.filter = CollisionFilter(group: handsColliderGroup, mask: .default)
                rightHandTrigger.components.set(rightHandCollider)
            }
            let leftHandTrigger = makeHandTrigger(in: content, name: "LeftHandTrigger", chirality: .left)
            if var leftHandCollider = leftHandTrigger.components[CollisionComponent.self] {
                leftHandCollider.mode = .trigger
                leftHandCollider.filter = CollisionFilter(group: handsColliderGroup, mask: .default)
                leftHandTrigger.components.set(leftHandCollider)
            }
            
            //let bodyTrigger = ensureUserTrigger(in: content)
            //if var collider = bodyTrigger.components[CollisionComponent.self] { collider.filter = .default; bodyTrigger.components.set(collider)}
            //let leftHandTrigger = ensureUserTriggerLeftHand(in: content)
            //if var collider2 = leftHandTrigger.components[CollisionComponent.self] { collider2.filter = .default; leftHandTrigger.components.set(collider2)}
            
            /*userCollisionSub?.cancel()
            userCollisionSub = content.subscribe(to: CollisionEvents.Began.self, on: bodyTrigger) { event in
                if (event.entityA.name == "BodyTrigger" || event.entityB.name == "BodyTrigger") && !model.isCollided {
                    let otherEntity = (event.entityA.name == "BodyTrigger") ? event.entityB : event.entityA
                    print("User collision with: \(otherEntity.name)")
                    model.isCollided = true
                    model.showCollisionBillboard = true
                    
                    model.isCollision = true
                    model.isPaused = true
                    model.playErrorSound()
                    if let scene {
                        notify(scene)
                    }
                }
            }
             collisionEnded = content.subscribe(to: CollisionEvents.Ended.self, on: bodyTrigger) { collisionEvent in
                 //model.isCollided = true
             }*/
            
            userCollisionSub?.cancel()
            userCollisionSub = content.subscribe(to: CollisionEvents.Began.self) { collisionEvent in
                let names = [collisionEvent.entityA.name, collisionEvent.entityB.name]
                if names.contains(where: {$0 == "LeftHandTrigger" || $0 == "RightHandTrigger"}) {
                    model.isCollided = true
                    model.showCollisionBillboard = true
                    model.playErrorSound()
                    model.isCollision = true
                    model.isPaused = true
                    if let scene {
                        notify(scene)
                    }
                }
            }
            collisionEnded = content.subscribe(to: CollisionEvents.Ended.self) { collisionEvent in
                //model.isCollided = true
            }
            
            
            globalCollisionSub?.cancel()
            globalCollisionSub = content.subscribe(to: CollisionEvents.Began.self) { e in
                print("COLLISION:", e.entityA.name, "<->", e.entityB.name)
            }
            
            
            //var immersive: Entity? = controller.contentRootAnchor.findEntity(named: "Immersive")
            immersive = controller.contentRootAnchor.findEntity(named: "Immersive")
            if immersive == nil, let loaded = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                loaded.name = "Immersive"
                removeAnchoringRecursively(from: loaded)
                loaded.setParent(controller.contentRootAnchor, preservingWorldTransform: false)
                loaded.setTransformMatrix(matrix_identity_float4x4, relativeTo: controller.contentRootAnchor)
                
                let vbWorld = loaded.visualBounds(relativeTo: nil)
                if let floorY = controller.floorY {
                    let sceneOffsetDelta = floorY - vbWorld.min.y
                    loaded.position.y += sceneOffsetDelta
                }
                
                controller.immersiveLoaded = true
                immersive = loaded
            }
            guard let immersive else {return}
            
            model.attachImmersiveRoot(immersive)
            
            if model.selectedRole == .teacher {
                model.applyRoadOpacityIfNeeded(to: 0.25)
            }
                        
            /*let ambientAudioEmitter = Entity()
            ambientAudioEmitter.ambientAudio = AmbientAudioComponent(gain: 6)
            
            do {
                let ambientAudioResource = try AudioFileResource.load(
                    named: "traffic_sounds",
                    configuration: .init(shouldLoop: true)
                )
                print("Playing traffic_sounds")
                ambientAudioEmitter.playAudio(ambientAudioResource)
            } catch {
                print("Failed to load traffic_sounds")
            }
            content.add(ambientAudioEmitter)*/
            
            // Add roadblock to test for collision detection
            /* let roadPlane3 = immersive.findEntity(named: "Plane_003_Plane_003")
             let roadBlock1 = addRoadblockCentered(on: roadPlane3!, size: 0.30)
             let roadPlane1 = immersive.findEntity(named: "Plane_001_Plane_001")
             let roadBlock2 = addRoadblockCentered(on: roadPlane1!, size: 0.30)*/
            
            // find cars and subscribe
            let van = immersive.findEntity(named: "Van")
            if let van, van.components[VanSetupTag.self] == nil {
                let vanVisualBounds = van.visualBounds(relativeTo: van)
                van.addChild({ let m = ModelEntity(mesh: .generateBox(size: vanVisualBounds.extents), materials: [SimpleMaterial(color: .init(white: 1, alpha: 0.0), isMetallic: false)]); m.position = vanVisualBounds.center; m.name = "VanBoundsVis"; m.components.set(OpacityComponent(opacity: 0.0)); return m }())
                let vanBoundingBox = ShapeResource
                    .generateBox(size: vanVisualBounds.extents)
                    .offsetBy(translation: .init(vanVisualBounds.center))
                van.components.set(CollisionComponent(shapes: [vanBoundingBox], mode: .default))
                van.components.set(PhysicsBodyComponent(mode: .kinematic))
                if var collider = van.components[CollisionComponent.self] { collider.filter = .default; van.components.set(collider)}
                van.components.set(VanSetupTag())
            }
            
            let car = immersive.findEntity(named: "Car")
            if let car, car.components[CarSetupTag.self] == nil {
                let carVisualBounds = car.visualBounds(relativeTo: car)
                let extraHeight: Float = 0.90 //increase bounding box height by 3ft
                var size = carVisualBounds.extents
                size.y += extraHeight
                var center = carVisualBounds.center
                let deltaY = size.y - carVisualBounds.extents.y
                center.y += deltaY / 2
                car.addChild({ let m = ModelEntity(mesh: .generateBox(size: size), materials: [SimpleMaterial(color: .init(white: 1, alpha: 0.0), isMetallic: false)]); m.position = center; m.name = "CarBoundsVis"; m.components.set(OpacityComponent(opacity: 0.0)); return m }())
                /*car.addChild({ let m = ModelEntity(mesh: .generateBox(size: carVisualBounds.extents), materials: [SimpleMaterial(color: .init(white: 1, alpha: 0.0), isMetallic: false)]); m.position = carVisualBounds.center; m.name = "CarBoundsVis"; m.components.set(OpacityComponent(opacity: 0.0)); return m }())*/
                
                let carBoundingBox = ShapeResource
                    .generateBox(size: size)
                    .offsetBy(translation: center)
                car.components.set(CollisionComponent(shapes: [carBoundingBox], mode: .default))
                car.components.set(PhysicsBodyComponent(mode: .kinematic))
                /*let carBoundingBox = ShapeResource
                    .generateBox(size: carVisualBounds.extents)
                    .offsetBy(translation: .init(carVisualBounds.center))
                car.components.set(CollisionComponent(shapes: [carBoundingBox], mode: .default))
                car.components.set(PhysicsBodyComponent(mode: .kinematic))*/
                
                if var collider = car.components[CollisionComponent.self] { collider.filter = .default; car.components.set(collider)}
                car.components.set(CarSetupTag())
            }
            
            controller.immersiveLoaded = true
            
            if collisionBoard == nil, let headAnchor {
                if let billboard = attachments.entity(for: "collision-billboard") {
                    billboard.name = "CollisionBillboard"
                    billboard.components.set(BillboardComponent())
                    billboard.position = [0, 0.15, -1.5]
                    headAnchor.addChild(billboard)
                    billboard.isEnabled = false
                    collisionBoard = billboard
                }
            }
            
            /*dumpColliders("BodyTrigger", bodyTrigger)
             dumpColliders("Van", car)
             //dumpColliders("VanRootCollider", vanBody)
             dumpColliders("Roadblock", roadBlock)*/
            
            // cancel any prior sub to avoid duplicates
            /*roadblockCollisionSub?.cancel()
             roadblockCollisionSub = content.subscribe(to: CollisionEvents.Began.self, on: car) { e in
             if e.entityA.name == "Roadblock" || e.entityB.name == "Roadblock" {
             print("Roadblock hit")
             
             Task { @MainActor in
             model.showHUD("Roadblock hit", autoClearAfter: 10.0)
             }
             
             isCollision = true
             isPaused = true
             if let scene { notify(scene) }
             }
             }*/
            
        } //close of RealityView closure
        update: {content, attachments in
            model.tickAmbientLiveness(to: content)
            if collisionBoard == nil, let headAnchor {
                if let billboard = attachments.entity(for: "collision-billboard") {
                    billboard.name = "CollisionBillboard"
                    billboard.components.set(BillboardComponent())
                    billboard.position = [0.5, 0.15, -1.1]
                    headAnchor.addChild(billboard)
                    billboard.isEnabled = false
                    collisionBoard = billboard
                }
            }
            if model.isCollided {
                collisionBoard?.isEnabled = model.showCollisionBillboard
            }
            if !model.isCollided {
                collisionBoard?.isEnabled = false
            }
        }
        attachments: {
            Attachment(id: "collision-billboard") {
                CollisionBillboardView(
                    onReset: {
                        model.isPaused = false
                        model.isReset = true
                        if let scene {notify(scene)}
                        model.isCollision = false
                        model.isCollided = false
                        collisionBoard?.isEnabled = false
                        DispatchQueue.main.async {model.isReset = false}
                    }
                )
            }
        }
        
        .task {model.attachScene(scene)}
        
    } //close of bodyView closure
    
    
    private func removeAnchoringRecursively(from root: Entity) {
        root.components.remove(AnchoringComponent.self)
        for child in root.children {
            removeAnchoringRecursively(from: child)
        }
    }
    
    func dumpColliders(_ label: String, _ e: Entity) {
        let hasCollider = e.components.has(CollisionComponent.self)
        let hasPhysicsBody = e.components.has(PhysicsBodyComponent.self)
        var modeStr = "n/a"
        if hasCollider, let c: CollisionComponent = e.components[CollisionComponent.self] {
            modeStr = (c.mode == .trigger) ? "trigger" : "default"
        }
        print("[\(label)] Collision:\(hasCollider) (\(modeStr)) Body:\(hasPhysicsBody ? "\(e.components[PhysicsBodyComponent.self]!.mode)" : "none")")
    }
    
    func makeHandTrigger(in content: RealityViewContent, name: String, chirality: AnchoringComponent.Target.Chirality) -> Entity {
        if let existing = scene?.findEntity(named: name) {
            return existing
        }
        
        let handAnchor = AnchorEntity(.hand(chirality, location: .indexFingerTip))
        handAnchor.anchoring.physicsSimulation = .none
        
        let handTrigger = ModelEntity(
            mesh: .generateSphere(radius: 0.1),
            materials: [SimpleMaterial(color: .init(white: 1, alpha: 0.0), isMetallic: false)]
        )
        handTrigger.components.set(OpacityComponent(opacity: 0.0))
        handTrigger.name = name
        handTrigger.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.1)], mode: .trigger))
        handTrigger.position = [0,0,0]
        handAnchor.addChild(handTrigger)
        
        content.add(handAnchor)
        return handTrigger
    }
    
    func ensureUserTrigger(in content: RealityViewContent) -> Entity {
        if let existing = scene?.findEntity(named: "BodyTrigger") {
            return existing
        }
        
        /*let headAnchor = AnchorEntity(.head)
         headAnchor.name = "UserHeadAnchor"
         headAnchor.anchoring.physicsSimulation = .none*/
        
        let handAnchor = AnchorEntity(.hand(.right, location: .indexFingerTip))
        handAnchor.anchoring.physicsSimulation = .none
        
        let bodyTrigger = ModelEntity(
            mesh: .generateSphere(radius: 0.1),
            //materials: [SimpleMaterial(color: .init(white: 1, alpha: 0.1), isMetallic: false)]
            materials: [SimpleMaterial(color: .init(white: 1, alpha: 0.0), isMetallic: false)]
        )
        bodyTrigger.components.set(OpacityComponent(opacity: 0.0))
        bodyTrigger.name = "BodyTrigger"
        bodyTrigger.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.1)], mode: .trigger))
        //bodyTrigger.generateCollisionShapes(recursive: true)
        bodyTrigger.position = [0,0,0]
        //headAnchor.addChild(bodyTrigger)
        handAnchor.addChild(bodyTrigger)
        
        content.add(handAnchor)
        return bodyTrigger
        
    }
    
    func ensureUserTriggerLeftHand(in content: RealityViewContent) -> Entity {
        if let existing = scene?.findEntity(named: "LeftHandTrigger") {
            return existing
        }
        
        let handAnchor = AnchorEntity(.hand(.left, location: .indexFingerTip))
        handAnchor.anchoring.physicsSimulation = .none
        
        let bodyTrigger = ModelEntity(
            mesh: .generateSphere(radius: 0.1),
            //materials: [SimpleMaterial(color: .init(white: 1, alpha: 0.1), isMetallic: false)]
            materials: [SimpleMaterial(color: .init(white: 1, alpha: 0.0), isMetallic: false)]
        )
        bodyTrigger.components.set(OpacityComponent(opacity: 0.0))
        bodyTrigger.name = "LeftHandTrigger"
        bodyTrigger.components.set(CollisionComponent(shapes: [.generateSphere(radius: 0.1)], mode: .trigger))
        //bodyTrigger.generateCollisionShapes(recursive: true)
        bodyTrigger.position = [0,0,0]
        //headAnchor.addChild(bodyTrigger)
        handAnchor.addChild(bodyTrigger)
        
        content.add(handAnchor)
        return bodyTrigger
    }
} //close of Arena closure
        
/*attachments: {
    Attachment(id: "board") {
    }
}
.rotation3DEffect(.degrees(self.model.activityState.boardAngle), axis: .y)
.animation(.default, value: self.model.activityState.boardAngle)
.frame(width: Size.Point.board(self.physicalMetrics), height: 0)
.frame(depth: Size.Point.board(self.physicalMetrics))
.overlay {
    if self.model.showProgressView {
        ProgressView()
            .offset(y: -200)
            .scaleEffect(3)
    }
}*/
//            .onReceive(NotificationCenter.default.publisher(for: .didReceiveSessionAction)) { notification in
//                if let action = notification.object as? SessionAction {
//                    switch action {
//                    case .start:
//                        statusText = "🚀 Started!"
//                    case .pause:
//                        statusText = "⏸️ Paused."
//                    case .reset:
//                        statusText = "🔄 Reset."
//                    case .resume:
//                        statusText = "▶️ Resumed."
//                    }
//                }
//            }
/*if(model.isFullSpaceShown) {
    HStack {
        Button("Start", systemImage: "play.fill") {
            //                        model.sendAction(.start)
            isPaused = true
            isStart = true
            if let scene {
                notify(scene)
            }
            isPaused = false
            isStart = false
        }
        
        if(isPaused) {
            Button("Resume", systemImage: "play.circle") {
                if let scene {
                    notify(scene)
                }
                isPaused = false
            }
        }
        else {
            Button("Pause", systemImage: "pause.circle") {
                if let scene {
                    notify(scene)
                }
                isPaused = true
            }
        }
        
        Button("Reset", systemImage: "backward.end.circle") {
            isReset = true
            isPaused = true
            if let scene {
                notify(scene)
            }
            isReset = false
            isPaused = false
        }
    }
}*/
//            if(isCollision) {
//                ZStack {
//                    Color.red
//
//                    Text("Warning! Collision has occurred")
//                }
//                .edgesIgnoringSafeArea(.all)
//            }



// MARK: - Code for placing anchors

/*
Variables needed for anchoring
@State var previewSphere: Entity?
@State private var worldTracking = WorldTrackingProvider()
@State private var arSession = ARKitSession()
let contentRoot = Entity()
/// A dictionary that contains `WorldAnchor` structures.
@State var worldAnchors = [UUID: WorldAnchor]()
/// A dictionary that contains `ModelEntity` structures for spheres.
@State var sphereEntities = [UUID: ModelEntity]()
 
/// Removing anchors and children from parent
contentRoot.children.removeAll()
sphereEntities.removeAll()
worldAnchors.removeAll()
arSession.stop()
print(arSession.description)

Placed inside Reality View
/**Place 3 anchors for triangulation***/
await content.add(setupContentEntity())
do {
    try await arSession.run([worldTracking])
} catch let error {
    print("Error = \(error.localizedDescription)")
}
// print("WorldTracking state = \(worldTracking.state)")
// Creates a preview sphere that's attached to the head.
let sphere = createPreviewSphere()
// Places the preview one meter in front of the head.
sphere.position = [0, 0, -1]
previewSphere = sphere
// Creates a head anchor and attaches the preview sphere.
let headAnchor2 = AnchorEntity(.head)
content.add(headAnchor2)
headAnchor2.addChild(sphere)

Placed as closures on RealityView
.task{
 await processWorldTrackingUpdates()
}
.gesture(
 SpatialTapGesture()
     .targetedToAnyEntity()
     .onEnded { event in
         if event.entity == previewSphere {
             Task {
                 // To place a sphere you need to:
                 // 1. Create a world anchor with the translation of that offset transform and add the anchor to the world tracking provider.
                 // 2. Create the sphere's geometry in `processWorldTrackingUpdates()` after you have successfully added the world anchor.
                 if(worldAnchors.count == 3){
                     previewSphere?.isEnabled = false
                     print("3 anchors already exist")
                 }
                 await addWorldAnchor(at: event.entity.transformMatrix(relativeTo: nil))
             }
         }
})
 
Functions for placing spheres and anchors
 func setupContentEntity() async -> Entity {
     return contentRoot
 }
 
 func createPreviewSphere() -> ModelEntity {
     let sphereMesh = MeshResource.generateSphere(radius: 0.1)
     let sphereMaterial = SimpleMaterial(color: .gray.withAlphaComponent(0.5), roughness: 0.2, isMetallic: false)
     let sphere = ModelEntity(mesh: sphereMesh, materials: [sphereMaterial])
     
     // Enables gestures on the preview sphere.
     // Looking at the preview and using a pinch gesture causes a world anchored sphere to appear.
     sphere.generateCollisionShapes(recursive: false, static: true)
     // Ensures the preview only accepts indirect input (for tap gestures).
     sphere.components.set(InputTargetComponent(allowedInputTypes: [.indirect]))
     
     return sphere
 }
 
 func processWorldTrackingUpdates() async {
     for await update in worldTracking.anchorUpdates {
         let worldAnchor = update.anchor
         let sphereMesh = MeshResource.generateSphere(radius: 0.1)
         let material = SimpleMaterial(color: .green, roughness: 0.2, isMetallic: true)
         let sphereEntity = ModelEntity(mesh: sphereMesh, materials: [material])
         sphereEntity.transform = Transform(matrix: worldAnchor.originFromAnchorTransform)
         
         if(worldAnchors.count < 3){
             worldAnchors[worldAnchor.id] = worldAnchor
             sphereEntities[worldAnchor.id] = sphereEntity
             contentRoot.addChild(sphereEntity)
         }
         else{
             print("More than 3 anchors")
         }
     }
 }
 
 func addWorldAnchor(at transform: simd_float4x4) async {
     print(worldTracking.description)
     
     while worldTracking.state != .running {
         print("⏳ Waiting for tracking to become active...")
         do {
             try await Task.sleep(nanoseconds: 500_000_000)
         } catch {
            
         }
     }
     
     let worldAnchor = WorldAnchor(originFromAnchorTransform: transform)
     do {
         try await worldTracking.addAnchor(worldAnchor)
     } catch let error {
         print("The app has encountered an unexpected error: \(error.localizedDescription)")
     }
 }
*/

// MARK: - Code for image anchoring

/*
 
 let arSession = ARKitSession()
 let imageInfo = ImageTrackingProvider(referenceImages: ReferenceImage.loadReferenceImages(inGroupNamed: "CardDeck20"))
 var entity = Entity()
 var rootEntity = Entity()
 let simpleMaterial = SimpleMaterial(
     color: .red, isMetallic: true
 )
 let anchoring = AnchoringComponent(.image(group: "CardDeck20", name: "IMG_4108"))
 
 
 let _ = await arSession.requestAuthorization(for: [.worldSensing, .handTracking, .cameraAccess])

//Img tracking/detection
var imgDetected = await implementImgAnchor(content: content)
 let imgAncEnt = AnchorEntity(components: self.anchoring)
 
immersiveContentEntity.setPosition(SIMD3<Float>(x: 0, y: 0, z: 0), relativeTo: imgAncEnt)


func implementImgAnchor(content: RealityViewContent) async -> Bool  {
    
    var entityMap : [UUID: ModelEntity] = [:]
    var toPrint: Bool = true
    var isDetected: Bool = false
    
    if true {
        do {
            try await arSession.run([imageInfo])
        } catch {
            print("error in img tracking provider")
        }
        
        for await update in imageInfo.anchorUpdates {
//                let _ = print(update.anchor.description)
            let entity = ModelEntity(mesh: .generateSphere(radius: 0.25), materials: [simpleMaterial])
            entityMap[update.anchor.id] = entity
            rootEntity.addChild(entity)
            entityMap[update.anchor.id]?.transform = Transform(matrix: update.anchor.originFromAnchorTransform)
            content.add(entity)
            if (toPrint){
//                    print("Image anchor detected!");
//                    toPrint = false;
                isDetected = true
                return isDetected
            }
            
        }
    }
    return isDetected
}*/
