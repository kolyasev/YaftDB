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

    class func serializeMetadata(collection: String, key: String, metadata: AnyObject) -> NSData
    {
        let result = NSMutableData()

        if let metadata = (metadata as? DatabaseObjectMetadata)
        {
            let archiver = NSKeyedArchiver(forWritingWithMutableData: result)

            // Encode object
            archiver.encodeInteger(metadata.hash, forKey: ArchiverKeys.Hash)
            archiver.encodeObject(metadata.timestamp, forKey: ArchiverKeys.Timestamp)

            // Finish encoding
            archiver.finishEncoding()
        }
        else {
            fatalError("Can not serialize metadata of type '\(metadata.dynamicType)'.")
        }

        return result
    }

    class func deserializerMetadata(collection: String, key: String, data: NSData) -> AnyObject
    {
        let result: DatabaseObjectMetadata

        // Init unarchiver for reading data
        let unarchiver = NSKeyedUnarchiver(forReadingWithData: data)

        // Decode object
        let hash = unarchiver.decodeIntegerForKey(ArchiverKeys.Hash)
        if let timestamp = (unarchiver.decodeObjectForKey(ArchiverKeys.Timestamp) as? NSDate)
        {
            result = DatabaseObjectMetadata(hash: hash, timestamp: timestamp)
        }
        else {
            fatalError("Can not deserialize metadata from collection '\(collection)' with key '\(key)'.")
        }

        return result
    }

// MARK: Constants

    private struct ArchiverKeys
    {
        static let Hash = "hash"
        static let Timestamp = "timestamp"
    }
    
}

// ----------------------------------------------------------------------------
