//
//  WorkoutView.swift
//  iMove Watch App
//
//  Created by Zaid Neurothrone on 2022-10-14.
//

import SwiftUI

struct WorkoutView: View {
  enum DisplayMode {
    case distance, energy, heartRate
  }
  
  @ObservedObject var dataManager: DataManager
  @State private var displayMode: DisplayMode = .distance
  @State private var isAlertPresented = false
  
  var quantity: String {
    switch displayMode {
    case .distance:
      let amount = Measurement(value: dataManager.totalDistance / 1000, unit: UnitLength.kilometers)
      return amount.formatted(.measurement(width: .abbreviated, usage: .road))
    case .energy:
      let amount = Measurement(value: dataManager.totalEnergyBurned, unit: UnitEnergy.kilocalories)
      return amount.formatted(.measurement(width: .abbreviated, usage: .workout))
    case .heartRate:
      return "\(Int(dataManager.lastHeartRate)) BPM"
    }
  }
  
  var body: some View {
    content
      .alert("Save to HealthKit?", isPresented: $isAlertPresented) {
        Group {
          Button("Discard", role: .cancel) {
            dataManager.end(saveToHealthKit: false)
          }
          Button("Save") {
            dataManager.end()
          }
          .tint(.purple)
        }
        .buttonStyle(.borderedProminent)
      }
  }
  
  var content: some View {
    VStack {
      Button(action: changeDisplayMode) {
        Text(quantity)
          .font(.largeTitle)
      }
      .buttonStyle(.plain)
      
      if dataManager.state == .active {
        Button("Stop", action: dataManager.pause)
      } else {
        Button("Resume", action: dataManager.resume)
        Button("End") {
          isAlertPresented.toggle()
        }
      }
    }
  }
}

extension WorkoutView {
  private func changeDisplayMode() {
    switch displayMode {
    case .distance:
      displayMode = .energy
    case .energy:
      displayMode = .heartRate
    case .heartRate:
      displayMode = .distance
    }
  }
}

struct WorkoutView_Previews: PreviewProvider {
  static var previews: some View {
    WorkoutView(dataManager: .init())
  }
}
