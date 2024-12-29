//
//  RoomManager.swift
//  PlaceIt
//
//  Created by Aleksandar Micevski on 16.11.24.
//


import Foundation
import ARKit

enum RoomManagerError: Error {
    case test
    case test2(String)
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
    
    private func createRoomDirectoryIfNeeded(for url: URL) throws {
        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: url.path) {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
    }
}

extension RoomManager {
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
}
