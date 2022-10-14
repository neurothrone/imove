//
//  DataManager.swift
//  iMove Watch App
//
//  Created by Zaid Neurothrone on 2022-10-14.
//

import HealthKit
import Foundation

final class DataManager: NSObject, ObservableObject {
  enum WorkoutState {
    case inactive, active, paused
  }
  
  @Published var state: WorkoutState = .inactive
  @Published var totalEnergyBurned: Double = .zero
  @Published var totalDistance: Double = .zero
  @Published var lastHeartRate: Double = .zero
  
  private var healthStore = HKHealthStore()
  private var workoutSession: HKWorkoutSession?
  private var workoutBuilder: HKLiveWorkoutBuilder?
  
  var activity: HKWorkoutActivityType = .cycling
  private var willSaveToHealthKit = false
  
  func start() {
    let sampleTypes: Set<HKSampleType> = [
      .workoutType(),
      HKQuantityType(.heartRate),
      HKQuantityType(.activeEnergyBurned),
      HKQuantityType(.distanceCycling),
      HKQuantityType(.distanceWalkingRunning),
      HKQuantityType(.distanceWheelchair)
    ]
    
    healthStore.requestAuthorization(toShare: sampleTypes, read: sampleTypes) { wasSuccessful, error in
      if wasSuccessful {
        self.beginWorkout()
      }
    }
  }
  
  private func beginWorkout() {
    let config = HKWorkoutConfiguration()
    config.activityType = activity
    config.locationType = .outdoor
    
    do {
      workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: config)
      workoutBuilder = workoutSession?.associatedWorkoutBuilder()
      workoutBuilder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: config)
      
      workoutSession?.delegate = self
      workoutBuilder?.delegate = self
    } catch {
      
    }
    
    workoutSession?.startActivity(with: .now)
    workoutBuilder?.beginCollection(withStart: .now) { wasSuccessful, error in
      guard wasSuccessful else { return }
      
      Task { @MainActor in
        self.state = .active
      }
    }
  }
  
  func pause() {
    workoutSession?.pause()
  }
  
  func resume() {
    workoutSession?.resume()
  }
  
  func end(saveToHealthKit: Bool = true) {
    willSaveToHealthKit = saveToHealthKit
    workoutSession?.end()
    
    totalEnergyBurned = .zero
    totalDistance = .zero
    lastHeartRate = .zero
  }
  
  func save() {
    guard willSaveToHealthKit else {
      Task { @MainActor in
        self.state = .inactive
      }
      
      return
    }
    
    workoutBuilder?.endCollection(withEnd: .now) { wasSuccessful, error in
      self.workoutBuilder?.finishWorkout { workout, error in
        Task { @MainActor in
          self.state = .inactive
        }
      }
    }
  }
}

extension DataManager: HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
  func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
    Task { @MainActor in
      switch toState {
      case .running:
        self.state = .active
      case .paused:
        self.state = .paused
      case .ended:
        self.save()
      default:
        break
      }
    }
  }
  
  func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {}
  
  func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
    for type in collectedTypes {
      guard let quantityType = type as? HKQuantityType else { continue }
      guard let statistics = workoutBuilder.statistics(for: quantityType) else { continue }
      
      Task { @MainActor in
        switch quantityType {
        case HKQuantityType(.heartRate):
          let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
          self.lastHeartRate = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit) ?? .zero
        case HKQuantityType(.activeEnergyBurned):
          let value = statistics.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? .zero
          self.totalEnergyBurned = value
        default:
          let value = statistics.sumQuantity()?.doubleValue(for: .meter()) ?? .zero
          self.totalDistance = value
        }
      }
    }
  }
  
  
  func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
}
