// ----------------------------------------------------------------------------
//
//  DatabaseObjectCoder.swift
//
//  @author Denis Kolyasev <kolyasev@gmail.com>
//
// ----------------------------------------------------------------------------

import Foundation

// ----------------------------------------------------------------------------

class DatabaseObjectMetadataCoder
{
// MARK: Functions

    class func serializeMetadata(_ collection: String, key: String, metadata: Any) -> Data
    {
        let result = NSMutableData()

        if let metadata = (metadata as? DatabaseObjectMetadata)
        {
            let archiver = NSKeyedArchiver(forWritingWith: result)

            // Encode object
            archiver.encode(metadata.hash, forKey: ArchiverKeys.Hash)
            archiver.encode(metadata.timestamp, forKey: ArchiverKeys.Timestamp)

            // Finish encoding
            archiver.finishEncoding()
        }
        else {
            fatalError("Can not serialize metadata of type '\(type(of: metadata))'.")
        }

        return result as Data
    }

    class func deserializerMetadata(_ collection: String, key: String, data: Data) -> AnyObject
    {
        let result: DatabaseObjectMetadata

        // Init unarchiver for reading data
        let unarchiver = NSKeyedUnarchiver(forReadingWith: data)

        // Decode object
        let hash = unarchiver.decodeInteger(forKey: ArchiverKeys.Hash)
        if let timestamp = (unarchiver.decodeObject(forKey: ArchiverKeys.Timestamp) as? Date)
        {
            result = DatabaseObjectMetadata(hash: hash, timestamp: timestamp)
        }
        else {
            fatalError("Can not deserialize metadata from collection '\(collection)' with key '\(key)'.")
        }

        return result
    }

// MARK: Constants

    fileprivate struct ArchiverKeys
    {
        static let Hash = "hash"
        static let Timestamp = "timestamp"
    }
    
}

// ----------------------------------------------------------------------------
