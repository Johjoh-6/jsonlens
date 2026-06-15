//
//  JSONParser.swift
//  JsonLens
//
//  Created by Six Johann on 15/06/2026.
//

import Foundation

struct JSONParser {
    
    /// Builds a tree of JSONNode from raw JSON data
    /// - Parameters:
    ///   - json: The raw JSON (Dictionary or Array)
    ///   - path: The current path (starts as "root")
    /// - Returns: Array of  nodes
    static func buildNode(from json: Any, path: String = "") -> JSONNode {
          let type = self.type(of: json)

          switch json {
          case let dict as [String: Any]:
              let children = dict.map { key, value in
                  let childPath = path.isEmpty ? key : "\(path).\(key)"
                  return buildNode(from: value, path: childPath)
              }

              return JSONNode(
                  path: path,
                  value: json,
                  type: .object,
                  children: children.isEmpty ? nil : children
              )

          case let array as [Any]:
              let children = array.enumerated().map { index, value in
                  let childPath = path.isEmpty
                      ? "[\(index)]"
                      : "\(path)[\(index)]"

                  return buildNode(from: value, path: childPath)
              }

              return JSONNode(
                  path: path,
                  value: json,
                  type: .array,
                  children: children.isEmpty ? nil : children
              )

          default:
              return JSONNode(
                  path: path.isEmpty ? "value" : path,
                  value: json,
                  type: type
              )
          }
      }
    
    static func buildTree(from json: Any) -> [JSONNode] {
            let root = buildNode(from: json)

            switch root.type {
            case .object, .array:
                return root.children ?? []
            default:
                return [root]
            }
        }
    
    /// Determines the JSONType for a given value
    static func type(of value: Any) -> JSONType {
           switch value {
           case is [String: Any]: return .object
           case is [Any]: return .array
           case is String: return .string
           case is Int, is Double, is Float: return .number
           case is Bool: return .bool
           default: return .null
           }
       }
}
