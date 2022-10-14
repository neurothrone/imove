//
//  ContentView.swift
//  iMove Watch App
//
//  Created by Zaid Neurothrone on 2022-10-14.
//

import HealthKit
import SwiftUI

enum WorkoutActivityType: String {
  case cycling = "Cycling"
  case running = "Running"
  case wheelchair = "Wheelchair"
}

struct ContentView: View {
  @State private var selectedActivityIndex: Int = .zero
  
  @StateObject private var dataManager = DataManager()
  
  let activities: [(name: String, type: HKWorkoutActivityType)] = [
    (WorkoutActivityType.cycling.rawValue, .cycling),
    (WorkoutActivityType.running.rawValue, .running),
    (WorkoutActivityType.wheelchair.rawValue, .wheelchairRunPace),
  ]
  
  private var isHealthKitAvailable: Bool {
    HKHealthStore.isHealthDataAvailable()
  }

  var body: some View {
    NavigationStack {
      content
        .navigationTitle(dataManager.state == .inactive ? "iMove" : "Get to work")
        .navigationBarTitleDisplayMode(.inline)
    }
  }
  
  @ViewBuilder
  var content: some View {
    if dataManager.state == .inactive {
      activitySelection
    } else {
      WorkoutView(dataManager: dataManager)
    }
  }
  
  var activitySelection: some View {
    VStack {
      List(activities.indices, id: \.self) { index in
        Button {
          withAnimation(.default) {
            selectedActivityIndex = index
          }
        } label: {
          Text(activities[index].name)
            .foregroundColor(selectedActivityIndex == index ? .green : .primary)
        }
      }
      
      Button("Start Workout") {
        guard isHealthKitAvailable else { return }
        
        dataManager.activity = activities[selectedActivityIndex].type
        dataManager.start()
      }
      .buttonStyle(.borderedProminent)
      .tint(.purple)
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
