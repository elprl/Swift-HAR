//
//  FIRFileUploader.swift
//  ActivityExporter
//
//  Created by Paul Leo on 06/06/2019.
//  Copyright © 2019 BDAC. All rights reserved.
//

import Foundation
import Firebase

class FIRFileUploader {
    // Get a reference to the storage service using the default Firebase App
    static let storage = Storage.storage()
    
    static func uploadFile(withFile fileURL: URL, storagePath: String? = nil) {
        // Create a storage reference from our storage service
        let storageRef: StorageReference
        if let storagePath = storagePath {
            storageRef = storage.reference(forURL: storagePath)
        } else {
            storageRef = storage.reference()
        }
        
        let dataRef = storageRef.child("trainingData/iOS/\(fileURL.lastPathComponent)")

        // File located on disk
//        let localFile = URL(string: filePath)!
        
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: fileURL.path) {
            print("File exists")
            
            // Upload the file to the path "images/rivers.jpg"
            dataRef.putFile(from: fileURL, metadata: nil) { metadata, error in
                if let error = error {
                    print(error)
                    return
                } else {
                    print("Successfully uploaded file to: \(dataRef.fullPath)")
                }
            }
        } else {
            print("File doesn't exists")

        }        
    }
}
