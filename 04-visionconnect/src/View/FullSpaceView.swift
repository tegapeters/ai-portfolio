//
//  FullSpaceView.swift
//  masters_project
//
//  Modified by CKendrick on 9/13/25.
//

import SwiftUI

struct FullSpaceView: View {
    @EnvironmentObject var model: AppModel
    @StateObject private var fiducialController = FiducialController()
    
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    @Environment(\.openWindow) var openWindow
    
    var body: some View {
        ZStack {
            Group {
                if !fiducialController.droppedWorldPose {
                    // Align world to fiducial
                    ImageOriginAligner()
                        .environmentObject(fiducialController) //views share same controller
                        .transition(.opacity)
                } else {
                    
                    VStack(spacing: 12) {
                        //load scene under the same calibrated contentRootAnchor
                        Arena()
                            .environmentObject(fiducialController) //views share same controller
                    }
                    .overlay {
                        if model.selectedRole == .teacher {
                            HUDLayerView()
                                .environmentObject(fiducialController)
                        }
                    }
                    // Apply transforms ONLY to the Arena
                    .scaleEffect(self.model.activityState.viewScale, anchor: .bottom)
                    //.offset(z: self.model.spatialSharePlaying == true ? 0 : -1200)
                    .offset(z: 0)
                    .offset(y: -self.model.activityState.viewHeight)
                    .animation(.default, value: self.model.activityState.viewScale)
                    .animation(.default, value: self.model.activityState.viewHeight)
                }
                
                /*HUDLayerView()
                    .environmentObject(fiducialController)*/
            }
            
        }
        .onChange(of: self.model.queueToOpenScene) { _, newValue in
            if newValue == .volume {
                Task {
                    self.openWindow(id: "volume")
                    await self.dismissImmersiveSpace()
                    fiducialController.resetForNewSession()
                    self.model.resetForNewSession()
                    /*self.model.isExplicitExit = false
                    self.model.didApplyRoadOpacity = false
                    self.model.showCollisionBillboard = false
                    self.model.selectedRole = nil
                    self.model.clearQueueToOpenScene()*/
                }
            }
        }
        .onAppear {
            print("FullSpaceView using AppModel:", model.instanceID)
            self.model.isFullSpaceShown = true
            print("FullSpaceView: droppedWorldPose BEFORE reset =", fiducialController.droppedWorldPose)
            fiducialController.resetForNewSession()
            print("FullSpaceView: droppedWorldPose AFTER reset =", fiducialController.droppedWorldPose)        }
        .onDisappear { self.model.isFullSpaceShown = false }
    }
}
