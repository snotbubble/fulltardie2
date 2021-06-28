//
//  SceneDelegate.swift
//  fulltardie3
//
//  Created by cpb on 27/6/21.
//

import UIKit
import SwiftUI

@main

struct Fulltardie: App {
    
    @Environment(\.scenePhase) var scenePhase
    
    //init() {
        // do stuff on start...
    //}
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) {
            newScenePhase in switch newScenePhase {
              case .active:
                print("scenephase: i am active")
              case .inactive:
                print("scenephase: i am inactive")
              case .background:
                print("scenephase: i am background")
              @unknown default:
                print("scenepahse: wut...")
            }
        }
    }
}


