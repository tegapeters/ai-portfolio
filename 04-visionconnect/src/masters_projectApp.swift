//
//  masters_projectApp.swift
//  masters_project
//
//  Created by AK Puvvada on 11/5/24.
//

import SwiftUI

@main
struct masters_project: App {
    @StateObject private var model = AppModel()
    //@State private var immersion: ImmersionStyle = .full
    var body: some Scene {
        VolumeWindow(self.model)        
        ImmersiveSpace(id: "immersiveSpace") {
            FullSpaceView()
                .environmentObject(self.model)
        }
        //.immersionStyle(selection: $immersion, in: .full)
    }
}
