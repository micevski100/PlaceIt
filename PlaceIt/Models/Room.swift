//
//  Room.swift
//  PlaceIt
//
//  Created by Aleksandar Micevski on 16.11.24.
//

import Foundation
import ARKit

enum RoomError: Error {
    
}

/// Represents a room in the ARKit application, including metadata and serialized data for AR world maps and virtual objects.
class Room: NSObject, NSSecureCoding {
    
    // MARK: - Properties
    
    /// Serialized ARWorldMap data.
    private var _worldMapData: Data?
    
    /// Serialized data for virtual objects in the room.
    private var _objectsData: Data?
     
    /// Unique identifier for the room.
    let id: UUID
    
    /// Name of the room.
    let name: String
    
    /// Type of the room, e.g., living room, kitchen, etc.
    let type: RoomType
    
    /// Indicates whether the room has been archived with both `worldMapData` and `objectsData`.
    lazy var isArchived = {
        return _worldMapData != nil && _objectsData != nil
    }()
    
    // MARK: - Initialization
    
    init(name: String, type: RoomType) {
        self.id = UUID()
        self.name = name
        self.type = type
    }
    
    // MARK: - NSSecureCoding
    
    enum CodingKeys: String {
       case id = "id"
       case name = "name"
       case type = "type"
       case worldMapData = "worldMapData"
       case objectsData = "objectsData"
   }
    
    required init?(coder aDecoder: NSCoder) {
        guard let id = aDecoder.decodeObject(of: [NSUUID.self], forKey: CodingKeys.id.rawValue) as? UUID else { return nil }
        guard let name = aDecoder.decodeObject(of: [NSString.self], forKey: CodingKeys.name.rawValue) as? String else { return nil }
        guard let rawType = aDecoder.decodeObject(of: [NSString.self], forKey: CodingKeys.type.rawValue) as? String else { return nil }
        guard let type: RoomType = RoomType(rawValue: rawType) else { return nil }
        
        self.id = id
        self.name = name
        self.type = type
        self._worldMapData = aDecoder.decodeObject(of: [NSData.self], forKey: CodingKeys.worldMapData.rawValue) as? Data
        self._objectsData = aDecoder.decodeObject(of: [NSData.self],forKey: CodingKeys.objectsData.rawValue) as? Data
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(id, forKey: CodingKeys.id.rawValue)
        aCoder.encode(name, forKey: CodingKeys.name.rawValue)
        aCoder.encode(type.rawValue, forKey: CodingKeys.type.rawValue)
        aCoder.encode(_worldMapData, forKey: CodingKeys.worldMapData.rawValue)
        aCoder.encode(_objectsData, forKey: CodingKeys.objectsData.rawValue)
    }
    
    static var supportsSecureCoding: Bool {
        return true
    }
}

// MARK: - Data Persistence
extension Room {
    /// Archives and sets the ARWorldMap data.
    func setWorldMap(_ worldMap: ARWorldMap) throws {
        let data = try NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true)
        self._worldMapData = data
    }
    
    /// Archives and sets the virtual objects data.
    func setObjects(_ objects: [VirtualObject]) throws {
        let data = try NSKeyedArchiver.archivedData(withRootObject: objects, requiringSecureCoding: true)
        self._objectsData = data
    }
    
    /// Unarchives and retrieves the ARWorldMap.
    func getWorldMap() throws -> ARWorldMap {
        guard let _worldMapData else { throw RoomManagerError.test }
        let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: _worldMapData)
        guard let worldMap else { throw RoomManagerError.test }
        
        return worldMap
    }
    
    // Unarchives and retrieves the virtual objects.
    func getObjects() throws -> [VirtualObject] {
        guard let _objectsData else { throw RoomManagerError.test }
        let objects = try NSKeyedUnarchiver.unarchivedArrayOfObjects(ofClass: VirtualObject.self, from: _objectsData)
        guard let objects else { throw RoomManagerError.test }
        
        return objects
    }
}
