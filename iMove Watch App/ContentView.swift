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
    if dataManager.state == .inactive {
      content
    } else {
      WorkoutView(dataManager: dataManager)
    }
  }
  
  var content: some View {
    VStack {
      Picker("Choose an activity", selection: $selectedActivityIndex) {
        ForEach(activities.indices, id: \.self) { index in
          Text(activities[index].name)
        }
      }
      
      Button("Start Workout") {
        guard isHealthKitAvailable else { return }
        
        dataManager.activity = activities[selectedActivityIndex].type
        dataManager.start()
      }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
