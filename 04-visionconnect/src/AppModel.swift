import SwiftUI
import RealityKit
import GroupActivities
import Combine

@MainActor
class AppModel: ObservableObject {
    @Published private(set) var activityState = ActivityState()
    @Published private(set) var arena = Arena()
    //@Environment(\.realityKitScene) var scene
    weak var scene: RealityKit.Scene?
    private let rknt = "RealityKit.NotificationTrigger"
    private(set) var rootEntity = Entity()
    @Published private(set) var movingPieces: [Piece.ID] = []
    @Published var isFullSpaceShown: Bool = false
    @Published private(set) var groupSession: GroupSession<AppGroupActivity>?
    private var messenger: GroupSessionMessenger?
    private var subscriptions: Set<AnyCancellable> = []
    private var tasks: Set<Task<Void, Never>> = []
    @Published private(set) var spatialSharePlaying: Bool?
    //@Published private(set) var queueToOpenScene: TargetScene?
    @Published var queueToOpenScene: TargetScene?
    //private var anchorUpdateHandler: ((AnchorData) -> Void)?
    @Published var selectedRole: Role?
    @Published var isExplicitExit: Bool = false
    @Published var isRolePickerEntry: Bool = true
    @Published var showCollisionBillboard = false
    @Published var isCollided = false
    @Published private(set) var hudText: String = ""
    @Published var isCollision = false
    @Published var isPaused = false
    @Published var isResumed = false
    @Published var isReset = false
    @Published var isStart = false
    @Published var requestDismissVolume: Bool = false
    @Published var didOpenImmersive: Bool = false
    @Published var immersiveRoot: Entity?
    @Published var roadOpacity: Float = 1.0
    @Published var didApplyRoadOpacity = false
    private let errorAudioEmitter = Entity()
    private var errorAudioResource: AudioFileResource?
    //private var errorAudioController: AudioPlaybackController?
    private let ambientAudioEmitter = Entity()
    private var ambientAudioResource: AudioFileResource?
    private var ambientAudioController: AudioPlaybackController?
    
    let roadEntities: Array<String> = ["Plane_Material_001", "Plane_001_Plane_001", "Plane_002_Plane_002", "Plane_003_Plane_003", "Plane_004_Plane_004", "Plane_005_Plane_005"]
    
    func applyRoadOpacityIfNeeded(to alpha: Float) {
        guard !didApplyRoadOpacity else {return}
        for entity in roadEntities {
            if let roadEntity = self.immersiveRoot?.findEntity(named: entity) {
                setRoadOpacity(to: roadEntity, to: alpha)
            }
        }
        didApplyRoadOpacity = true
    }
    
    @MainActor
    func setRoadOpacity(to entity: Entity, to alpha: Float) {
        guard var model = (entity as? HasModel)?.model else {return}
        
        var materials = model.materials
        for i in materials.indices {
            if var physicallyBasedMaterial = materials[i] as? PhysicallyBasedMaterial {
                physicallyBasedMaterial.blending = .transparent(
                    opacity: PhysicallyBasedMaterial.Opacity(scale: alpha)
                )
                materials[i] = physicallyBasedMaterial
            } else if var shaderGraphMaterial = materials[i] as? ShaderGraphMaterial {
                try? shaderGraphMaterial.setParameter(name: "Opacity", value: .float(alpha))
                materials[i] = shaderGraphMaterial
            }
        }
        model.materials = materials
        (entity as? HasModel)?.model = model
    }
    
    @Published var uiActionBound = false
    private var openImmersiveSpace: ((String) async -> OpenImmersiveSpaceAction.Result)?
    private var dismissWindow: ((String) -> Void)?
    var isReadyToOpen: Bool {
        uiActionBound && messenger != nil && groupSession?.state == .joined
    }
    
    let instanceID = UUID()
    func bindUIActions(openImmersiveSpace: OpenImmersiveSpaceAction, dismissWindow: DismissWindowAction) {
        self.openImmersiveSpace = openImmersiveSpace.callAsFunction
        self.dismissWindow = dismissWindow.callAsFunction
        self.uiActionBound = true
    }
    
    func requestGroupOpenImmersiveSpace() {
        guard let open = self.openImmersiveSpace else {
            print("openImmersiveSpace nil; queueing .fullSpace")
            self.queueToOpenScene = .fullSpace
            return
        }
        print("I have been requested to openImmersiveSpace.")
        Task { @MainActor in
            print("Attempting to open immersive space...")
            let result = await open("immersiveSpace")
            print("openImmersiveSpace result: \(result)")
            switch result {
            case .opened:
                self.didOpenImmersive = true
                self.requestDismissVolume = true
                //self.dismissWindow?("volume")
                //try? await self.messenger?.send(ControlMessage.enterFullSpace)
            case .userCancelled:
                self.queueToOpenScene = .fullSpace
            case .error:
                self.queueToOpenScene = .fullSpace
            @unknown default:
                self.queueToOpenScene = .fullSpace
            }
        }
    }
    
    func showHUD(_ text: String, autoClearAfter seconds: Double = 2.0) {
        hudText = text
        guard seconds > 0 else { return }
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            if self?.hudText == text { self?.hudText = ""}
        }
    }
    
    func attachScene(_ scene: RealityKit.Scene?) {
        self.scene = scene
    }
    
    func attachImmersiveRoot(_ root: Entity?) {
        self.immersiveRoot = root
    }
    
    func resetForNewSession() {
        self.isExplicitExit = false
        self.didApplyRoadOpacity = false
        self.showCollisionBillboard = false
        self.selectedRole = nil
        self.clearQueueToOpenScene()
        self.immersiveRoot = nil
    }
    
    func ensureAmbientAudio(to content: RealityViewContent, gain: Float = 6, force: Bool = false) async {
        let needsRebind = force
        || ambientAudioEmitter.parent == nil
        
        if needsRebind {
            ambientAudioEmitter.removeFromParent()
            ambientAudioEmitter.ambientAudio = AmbientAudioComponent(gain: Audio.Decibel(gain))
            content.add(ambientAudioEmitter)
        }
        
        if ambientAudioResource == nil {
            do {
                ambientAudioResource = try await AudioFileResource(
                    named: "traffic_sounds",
                    configuration: .init(shouldLoop: true)
                )
                print("Loaded traffic_sounds")
            } catch {
                print("Failed to load traffic_sounds")
            }
        }
        startAmbientAudioIfNeeded()
    }
    
    func tickAmbientLiveness(to content: RealityViewContent) {
        if ambientAudioEmitter.parent == nil {
           // content.add(ambientAudioEmitter)
            Task { await ensureAmbientAudio(to: content, force: true) }
            return
        }
        if ambientAudioController?.isPlaying != true {
            startAmbientAudioIfNeeded()
        }
    }
    
    private func startAmbientAudioIfNeeded() {
        guard let ambientAudioClip = ambientAudioResource else {return}
        ambientAudioController?.stop()
        ambientAudioController = ambientAudioEmitter.playAudio(ambientAudioClip)
    }
    
    func attachAudioEmitter(to content: RealityViewContent) {
        errorAudioEmitter.spatialAudio = SpatialAudioComponent()
        content.add(errorAudioEmitter)
    }
    
    func loadErrorAudio() async {
        do {
            errorAudioResource = try await AudioFileResource(
                named: "error_sound_2.wav",
                configuration: .init(shouldLoop: false)
                
            )
            /*errorAudioController = errorAudioEmitter.prepareAudio(errorAudioResource!)
            errorAudioController?.gain = .init(-6)*/
        } catch {
            print("Failed to load error_sound_2")
        }
        
    }
    
    func playErrorSound() {
        guard let clip = errorAudioResource else {return}
        let controller = errorAudioEmitter.playAudio(clip)
        controller.gain = .init(-12)
    }
    
    init() {
        self.configureGroupSessions()
        self.setUpEntities()
    }
    
}

struct AnchorData: Codable {
    let position: SIMD3<Float>
}

//enum SessionAction: Codable {
//    case start
//    case pause
//    case reset
//    case resume
//}
//
//extension Notification.Name {
//    static let didReceiveSessionAction = Notification.Name("didReceiveSessionAction")
//}


extension AppModel {
    func upScale() {
        self.activityState.viewScale *= self.floorMode ? 1.4 : 1.1
        self.sendMessage()
    }
    func downScale() {
        self.activityState.viewScale *= self.floorMode ? 0.75 : 0.9
        self.sendMessage()
    }
    func raiseBoard() {
        self.activityState.viewHeight += 50
        self.sendMessage()
    }
    func lowerBoard() {
        self.activityState.viewHeight -= 50
        self.sendMessage()
    }
    func lowerToFloor() {
        self.activityState.viewHeight = 0
        self.sendMessage()
    }
    func separateFromFloor() {
        self.activityState.viewHeight = 1000
        self.sendMessage()
    }
    func rotateBoard() {
        self.activityState.boardAngle += 90
        self.sendMessage()
    }
    func expandToolbar(_ position: ToolbarPosition) {
        self.activityState.expandedToolbar.append(position)
        self.sendMessage()
    }
    func closeToolbar(_ position: ToolbarPosition) {
        self.activityState.expandedToolbar.removeAll { $0 == position }
        self.sendMessage()
    }
    func clearQueueToOpenScene() {
        self.queueToOpenScene = nil
    }
    var isSharePlayStateNotSet: Bool {
        self.groupSession?.state == .joined
        &&
        self.activityState.mode == .localOnly
    }
    var floorMode: Bool {
        self.isFullSpaceShown
        &&
        self.activityState.viewHeight == 0
    }
}

private extension AppModel {
    private func setUpEntities() {
        self.activityState.chess.setPreset()
    }
}

//MARK: ==== SharePlay ====
extension AppModel {
    
    var showProgressView: Bool {
        self.groupSession != nil
        &&
        self.activityState.mode == .localOnly
    }
    private func configureGroupSessions() {
        Task {
            for await groupSession in AppGroupActivity.sessions() {
                self.activityState.clear()
                self.activityState.chess.setPreset()
                
                self.groupSession = groupSession
                let messenger = GroupSessionMessenger(session: groupSession)
                self.messenger = messenger
                
                groupSession.$state
                    .sink {
                        if case .invalidated = $0 {
                            self.messenger = nil
                            self.tasks.forEach { $0.cancel() }
                            self.tasks = []
                            self.subscriptions = []
                            self.groupSession = nil
                            self.spatialSharePlaying = nil
                            self.activityState.chess.clearLog()
                            self.activityState.chess.setPreset()
                            self.activityState.mode = .localOnly
                        }
                    }
                    .store(in: &self.subscriptions)
                
                groupSession.$activeParticipants
                    .sink {
                        if $0.count == 1 { self.activityState.mode = .sharePlay }
                        let newParticipants = $0.subtracting(groupSession.activeParticipants)
                        Task {
                            try? await messenger.send(self.activityState,
                                                      to: .only(newParticipants))
                        }
                    }
                    .store(in: &self.subscriptions)
                
                self.tasks.insert(
                    Task {
                        for await (message, _) in messenger.messages(of: ActivityState.self) {
                            self.receive(message)
                        }
                    }
                )
                
                self.tasks.insert(
                    Task {
                        for await (message, _) in messenger.messages(of: String.self) {
                            print("Message event received: \(message)")
                            //print("Message event received: openImmersiveSpace on AppModel:", self.instanceID)
                            if message == "openImmersiveSpace" {
                                await MainActor.run {
                                    print("Awaiting MainActor...")
                                    if self.selectedRole == nil {
                                        self.selectedRole = .learner
                                    }
                                    self.requestGroupOpenImmersiveSpace()
                                }
                            } else {
                                self.receiveAnimation(message)
                            }
                        }
                    }
                )
                
#if os(visionOS)
                self.tasks.insert(
                    Task {
                        if let systemCoordinator = await groupSession.systemCoordinator {
                            for await localParticipantState in systemCoordinator.localParticipantStates {
                                self.spatialSharePlaying = localParticipantState.isSpatial
                            }
                        }
                    }
                )
                
                /*self.tasks.insert(
                    Task {
                        if let systemCoordinator = await groupSession.systemCoordinator {
                            for await immersionStyle in systemCoordinator.groupImmersionStyle {
                                if immersionStyle != nil {
                                    self.queueToOpenScene = .fullSpace
                                } else {
                                    self.queueToOpenScene = .volume
                                }
                            }
                        }
                    }
                )*/
                
                self.tasks.insert(
                    Task {
                        if let systemCoordinator = await groupSession.systemCoordinator {
                            for await immersionStyle in systemCoordinator.groupImmersionStyle {
                                if immersionStyle != nil {
                                    self.queueToOpenScene = .fullSpace
                                } else if immersionStyle == nil && !isExplicitExit {
                                    self.queueToOpenScene = .fullSpace
                                } else {
                                    self.queueToOpenScene = .volume
                                }
                            }
                        }
                    }
                )
                
                self.tasks.insert(
                    Task {
                        if let systemCoordinator = await groupSession.systemCoordinator {
                            var configuration = SystemCoordinator.Configuration()
                            configuration.supportsGroupImmersiveSpace = true
                            systemCoordinator.configuration = configuration
                            groupSession.join()
                        }
                    }
                )
#else
                groupSession.join()
#endif
            }
        }
    }
    
    private func sendMessage() {
        Task {
            try? await self.messenger?.send(self.activityState)
        }
    }
    private func receive(_ message: ActivityState) {
        guard message.mode == .sharePlay else { return }
        Task { @MainActor in
            self.activityState = message
        }
    }
    
    /*func sendAnimationControl(_ animation: Bool) {
        Task {
            print("animation send")
            try? await messenger?.send(animation)
        }
    }*/
    
    /*private func receiveAnimation(_ animation: Bool) {
     Task { @MainActor in
         print("animation received")
         arena.isStart = animation
         if let scene {
             arena.notify(scene)
         }
     }
    }*/
    
    func sendAnimationControl(_ animation: String) {
        Task {
            print("animation send")
            try? await messenger?.send(animation)
        }
    }
        
    private func receiveAnimation(_ animation: String) {
        guard !animation.isEmpty else {return}
        post(animation)
    }
    
    private func post(_ id: String) {
        guard let scene else { return }
                
        switch id {
        case "collision":
            self.playErrorSound()
            self.isCollided = true
            showCollisionBillboard = true
        case "reset":
            self.isPaused = false
            showCollisionBillboard = false
            NotificationCenter.default.post(
                name: Notification.Name("\(self.rknt)"),
                object: nil,
                userInfo: ["\(self.rknt).Scene": scene, "\(self.rknt).Identifier": "reset"]
            )
            self.isCollision = false
            self.isCollided = false
            return
        case "exit_scene":
            self.queueToOpenScene = .volume
            return
        case "opacity":
            self.didApplyRoadOpacity = false
            if self.roadOpacity == 1.0 {
                self.roadOpacity = 0.25
            } else {
                self.roadOpacity = 1.0
            }
            applyRoadOpacityIfNeeded(to: self.roadOpacity)
        default:
            NotificationCenter.default.post(
                name: Notification.Name("\(rknt)"),
                object: nil,
                userInfo: ["\(rknt).Scene": scene, "\(rknt).Identifier": id]
            )
        }
    }
             
#if os(iOS)
    func   activateGroupActivity() {
        Task {
            do {
                let result = try await AppGroupActivity().activate()
                switch result {
                    case true: self.activityState.mode = .sharePlay
                    default: break
                }
            } catch {
                print("Failed to activate activity: \(error)")
            }
        }
    }
#endif
}

//Ref: Drawing content in a group session | Apple Developer Documentation
//https://developer.apple.com/documentation/groupactivities/drawing_content_in_a_group_session
//Ref: Design spatial SharePlay experiences - WWDC23 - Videos - Apple Developer
//https://developer.apple.com/videos/play/wwdc2023/10075
//Ref: Build spatial SharePlay experiences - WWDC23 - Videos - Apple Developer
//https://developer.apple.com/videos/play/wwdc2023/10087
