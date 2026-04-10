//
//  RolePickerView.swift
//  masters_project
//
//  Created by CKendrick on 10/7/25.
//

import SwiftUI
import RealityKit

enum Role: String, Codable {
    case teacher
    case learner
}

struct RolePickerView: View {
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissWindow) var dismissWindow
    @EnvironmentObject private var model: AppModel
    
    var body: some View {
        VStack(spacing: 48) {
            //SharePlayMenu()
                //.frame(height: 300)

            Text("Select a role:")
                .font(.largeTitle.weight(.semibold))
            
            HStack(spacing: 20) {
                roleCard("Teacher \n\"I teach skills\"", role: .teacher)
                    /*.frame(width: 240, height: 300, alignment: .top)*/
                    .fixedSize(horizontal: false, vertical: true)
                roleCard("Learner \n\"I learn skills\"", role: .learner)
                    /*.frame(width: 240, height: 300, alignment: .top)*/
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: 700)
        .padding(40)
        .onAppear {
            print("RolePickerView .onAppear -> binding UI actions")
            print("RolePickerView using AppModel:", model.instanceID)
            model.bindUIActions(openImmersiveSpace: openImmersiveSpace, dismissWindow: dismissWindow)
        }
        /*.onChange(of: self.model.queueToOpenScene) { _, newValue in
            guard newValue == .fullSpace, model.selectedRole != nil else {return}
            //guard case .some(.fullSpace) = newValue else {return}
            Task { @MainActor in
                print("onChange: Attempting to open immersive space...")
                let result = await self.openImmersiveSpace(id: "immersiveSpace")
                print("onChange: openImmersiveSpace result: \(result)")
                if case .opened = result {
                    model.didOpenImmersive = true
                    model.requestDismissVolume = true
                    //self.dismissWindow(id: "volume")
                }
                model.clearQueueToOpenScene()
            }
        }*/
        .onChange(of: model.requestDismissVolume) { _, shouldDismiss in
            guard shouldDismiss else {return}
            print("Dismissing volume window")
            dismissWindow(id: "volume")
            model.requestDismissVolume = false
        }
        .task {
            print("in volume view register")
            SharePlayProvider.registerGroupActivity()
        }
        /*.task {
            model.bindUIActions(openImmersiveSpace: openImmersiveSpace, dismissWindow: dismissWindow)
        }*/
    }
    
    @ViewBuilder
    private func roleCard(_ title: String, role: Role) -> some View {
        Button {
            model.selectedRole = role
            /*Task { @MainActor in
                model.sendAnimationControl("openImmersiveSpace")            // test learner auto-entry to immersive space
                let result = await openImmersiveSpace(id: "immersiveSpace")
                if case .opened = result {self.dismissWindow(id: "volume")}
            }*/
            Task { @MainActor in
                model.requestGroupOpenImmersiveSpace()
                model.sendAnimationControl("openImmersiveSpace")
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.thinMaterial)
                Text(title)
                    .font(.system(size: 48, weight: .bold))
                    .padding(.horizontal, 24)
            }
            .frame(minWidth: 350, minHeight: 280)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .hoverEffect(.lift)
        .accessibilityLabel(Text("\(title) role"))
        
    }
}
