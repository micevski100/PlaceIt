//
//  RoomManager.swift
//  PlaceIt
//
//  Created by Aleksandar Micevski on 16.11.24.
//

// TODO: Add documentation.
import Foundation
import ARKit

// TODO: Add proper error messages.
enum RoomManagerError: Error {
    case test
}

class Room: NSObject, NSSecureCoding{
    
    private var _worldMapData: Data?
    private var _objectsData: Data?
     
    let id: UUID
    var name: String
    var type: RoomType
    lazy var worldMap: ARWorldMap? = {
        guard let _worldMapData else { return nil }
        do {
            return try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: _worldMapData)
        } catch {
            fatalError("")
        }
        
    }()
    lazy var objects: [VirtualObject]? = {
        guard let _objectsData else { return nil }
        do {
            return try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, VirtualObject.self], from: _objectsData) as? [VirtualObject]
        } catch {
            fatalError("")
        }
    }()
    lazy var isArchived = {
        return _worldMapData != nil && _objectsData != nil
    }()
    
    init(name: String, type: RoomType) {
        self.id = UUID()
        self.name = name
        self.type = type
    }
    
    // MARK: - Serialization
    
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
    
    func setWorldMap(_ worldMap: ARWorldMap) throws {
        let data = try NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true)
        self._worldMapData = data
    }
    
    func getWorldMap() throws -> ARWorldMap {
        guard let _worldMapData else { throw RoomManagerError.test }
        let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: _worldMapData)
        guard let worldMap else { throw RoomManagerError.test }
        
        return worldMap
    }
    
    func setObjects(_ objects: [VirtualObject]) throws {
        let data = try NSKeyedArchiver.archivedData(withRootObject: objects, requiringSecureCoding: true)
        self._objectsData = data
    }
    
    func getObjects() throws -> [VirtualObject] {
        guard let _objectsData else { throw RoomManagerError.test }
        let objects = try NSKeyedUnarchiver.unarchivedArrayOfObjects(ofClass: VirtualObject.self, from: _objectsData)
        guard let objects else { throw RoomManagerError.test }
        
        return objects
    }
}

class RoomManager: NSObject {
    static let shared = RoomManager()
    
    private var roomSaveUrl: URL = {
        do {
            return try FileManager.default
                .url(for: .documentDirectory,
                     in: .userDomainMask,
                     appropriateFor: nil,
                     create: true)
                .appendingPathComponent("arexperience/rooms")
        } catch {
            fatalError("Can't get map file save URL: \(error.localizedDescription)")
        }
    }()
    
    private override init() {
        super.init()
        do {
            try createRoomDirectoryIfNeeded(for: roomSaveUrl)
        } catch {
            fatalError("Failed to initialize RoomManager: \(error.localizedDescription)")
        }
    }
    
    func save(room: Room) throws {
        let fileSaveUrl = roomSaveUrl.appendingPathComponent(room.id.uuidString)
        let data = try NSKeyedArchiver.archivedData(withRootObject: room, requiringSecureCoding: true)
        try data.write(to: fileSaveUrl, options: [.atomic])
    }
    
    func load(by id: String) throws -> Room? {
        let fileUrl = roomSaveUrl.appendingPathComponent(id)
        let data = try Data(contentsOf: fileUrl)
        return try NSKeyedUnarchiver.unarchivedObject(ofClass: Room.self, from: data)
    }
    
    func listAll() throws -> [Room] {
        var rooms: [Room] = []
        
        // room id's
        let fileUrls = try FileManager.default.contentsOfDirectory(at: roomSaveUrl, includingPropertiesForKeys: nil)
        for fileUrl in fileUrls {
            let data = try Data(contentsOf: fileUrl)
            let room = try NSKeyedUnarchiver.unarchivedObject(ofClass: Room.self, from: data)
            
            if let room {
                rooms.append(room)
            } else {
                print("Failed to load or decode room with index: \(fileUrl.lastPathComponent)")
            }
        }
        
        return rooms
    }
    
    private func createRoomDirectoryIfNeeded(for url: URL) throws {
        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: url.path) {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
    }
}
