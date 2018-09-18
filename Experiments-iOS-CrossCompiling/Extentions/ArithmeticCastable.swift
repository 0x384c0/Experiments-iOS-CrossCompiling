//
//  ArithmeticCastable
//  IOSExperiments
//
//  Created by 0x384c0 on 19.08.16.
//  Copyright © 2016 0x384c0 . All rights reserved.
//

import Foundation

public protocol ArithmeticCastable: Comparable, Equatable, Hashable {
    init(_ value: Int)
    init(_ value: Int8)
    init(_ value: Int16)
    init(_ value: Int32)
    init(_ value: Int64)
    init(_ value: UInt)
    init(_ value: UInt8)
    init(_ value: UInt16)
    init(_ value: UInt32)
    init(_ value: UInt64)
    init(_ value: Float)
    init(_ value: Double)
    //init(_ value: CGFloat)
}

extension Int: ArithmeticCastable{}
extension Int8: ArithmeticCastable{}
extension Int16: ArithmeticCastable{}
extension Int32: ArithmeticCastable{}
extension Int64: ArithmeticCastable{}
extension UInt: ArithmeticCastable{}
extension UInt8: ArithmeticCastable{}
extension UInt16: ArithmeticCastable{}
extension UInt32: ArithmeticCastable{}
extension UInt64: ArithmeticCastable{}
extension Float: ArithmeticCastable{}
extension Double: ArithmeticCastable{}
//extension CGFloat: ArithmeticCastable{}

extension ArithmeticCastable {
    func cast<R: ArithmeticCastable>() -> R {
        switch self {
        case let n as Int:
            return R(n)
        case let n as Int8:
            return R(n)
        case let n as Int16:
            return R(n)
        case let n as Int32:
            return R(n)
        case let n as Int64:
            return R(n)
        case let n as UInt:
            return R(n)
        case let n as UInt8:
            return R(n)
        case let n as UInt16:
            return R(n)
        case let n as UInt32:
            return R(n)
        case let n as UInt64:
            return R(n)
        case let n as Float:
            return R(n)
        case let n as Double:
            return R(n)
//        case let n as CGFloat:
//            return R(n)
        default:
            preconditionFailure("Couldn't cast to \(String(describing: R.self)) from \(String(describing: self))")
        }
    }
}
