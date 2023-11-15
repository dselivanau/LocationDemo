//
//  Double+Extension.swift
//  LocationDemo
//
//  Created by Denis Selivanov on 10/24/23.
//

import Foundation

extension Double {
    func toRadians() -> Double {
        return self * .pi / 180.0
    }

    func toDegrees() -> Double {
        return self * 180.0 / .pi
    }
    
    func asString(style: DateComponentsFormatter.UnitsStyle) -> String {
      let formatter = DateComponentsFormatter()
      formatter.allowedUnits = [.hour, .minute, .second, .nanosecond]
      formatter.unitsStyle = style
      return formatter.string(from: self) ?? ""
    }
}
