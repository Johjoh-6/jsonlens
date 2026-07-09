//
//  JSONDiff.swift
//  JsonLens
//
//  Created by Six Johann  on 08/07/2026.
//

import Foundation

enum DiffKind {
    case same, added, removed, changed
}

struct DiffEntry: Identifiable {
    let id = UUID()
    let path: String
    let kind: DiffKind
    let leftDescription: String?
    let rightDescription: String?
}

enum JSONDiffService {

    static func diff(left: JSONValue, right: JSONValue) -> [DiffEntry] {
        var entries: [DiffEntry] = []
        walk(left: left, right: right, path: "$", into: &entries)
        return entries
    }

    private static func walk(left: JSONValue?, right: JSONValue?, path: String, into entries: inout [DiffEntry]) {
        switch (left, right) {
        case (nil, let r?):
            entries.append(DiffEntry(path: path, kind: .added, leftDescription: nil, rightDescription: describe(r)))
        case (let l?, nil):
            entries.append(DiffEntry(path: path, kind: .removed, leftDescription: describe(l), rightDescription: nil))
        case (.some(let l), .some(let r)):
            switch (l, r) {
            case (.object(let lEntries), .object(let rEntries)):
                let lKeys = lEntries.map(\.key)
                let rKeys = rEntries.map(\.key)
                let allKeys = orderedUnion(lKeys, rKeys)
                for key in allKeys {
                    let lVal = lEntries.first(where: { $0.key == key })?.value
                    let rVal = rEntries.first(where: { $0.key == key })?.value
                    walk(left: lVal, right: rVal, path: "\(path).\(key)", into: &entries)
                }
            case (.array(let lItems), .array(let rItems)):
                let count = max(lItems.count, rItems.count)
                for i in 0..<count {
                    let lVal = i < lItems.count ? lItems[i] : nil
                    let rVal = i < rItems.count ? rItems[i] : nil
                    walk(left: lVal, right: rVal, path: "\(path)[\(i)]", into: &entries)
                }
            default:
                if l == r {
                    entries.append(DiffEntry(path: path, kind: .same, leftDescription: describe(l), rightDescription: describe(r)))
                } else {
                    entries.append(DiffEntry(path: path, kind: .changed, leftDescription: describe(l), rightDescription: describe(r)))
                }
            }
        case (nil, nil):
            break
        }
    }

    private static func orderedUnion(_ a: [String], _ b: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for k in a + b where !seen.contains(k) {
            seen.insert(k)
            result.append(k)
        }
        return result
    }

    private static func describe(_ value: JSONValue) -> String {
        switch value {
        case .string(let s): return "\"\(s)\""
        case .number(let n): return n
        case .bool(let b):   return b ? "true" : "false"
        case .null:          return "null"
        case .object(let e): return "{ \(e.count) key\(e.count == 1 ? "" : "s") }"
        case .array(let a):  return "[ \(a.count) item\(a.count == 1 ? "" : "s") ]"
        }
    }
}
