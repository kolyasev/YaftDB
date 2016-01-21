// ----------------------------------------------------------------------------
//
//  Cache.swift
//
//  @author Denis Kolyasev <kolyasev@gmail.com>
//
// ----------------------------------------------------------------------------

import YapDatabase

// ----------------------------------------------------------------------------

public class Cache
{
// MARK: Construction

    public init(path: String)
    {
        // Init instance variables
        self.database = YapDatabase(path: path,
                objectSerializer: CacheObjectCoder.serializeObject,
                objectDeserializer: CacheObjectCoder.deserializerObject,
                metadataSerializer: CacheObjectMetadataCoder.serializeMetadata,
                metadataDeserializer: CacheObjectMetadataCoder.deserializerMetadata)
        self.connection = self.database.newConnection()
    }

// MARK: Properties

    let database: YapDatabase

    let connection: YapDatabaseConnection

// MARK: Public Functions

    public func collection<T>(type: T.Type, name: String) -> CacheCollection<T> {
        return CacheCollection<T>(name: name, cache: self)
    }

// MARK: Internal Functions

    func put(collection collection: String, key: String, object: CacheObject)
    {
        let metadata = CacheObjectMetadata(hash: object.hash)

        // Write to database
        self.connection.asyncReadWriteWithBlock { transaction in
            if let existingMetadata = (transaction.metadataForKey(key, inCollection: collection) as? CacheObjectMetadata)
                where (existingMetadata.hash == metadata.hash)
            {
                // TODO: Update metadata only
            }
            else {
                transaction.setObject(object, forKey: key, inCollection: collection, withMetadata: metadata)
            }
        }
    }

    func put(collection collection: String, entities: [(key: String, object: CacheObject)])
    {
        // Write to database
        self.connection.asyncReadWriteWithBlock { transaction in
            for (key, object) in entities
            {
                let metadata = CacheObjectMetadata(hash: object.hash)

                if let existingMetadata = (transaction.metadataForKey(key, inCollection: collection) as? CacheObjectMetadata)
                   where (existingMetadata.hash == metadata.hash)
                {
                    // TODO: Update metadata only
                }
                else {
                    transaction.setObject(object, forKey: key, inCollection: collection, withMetadata: metadata)
                }
            }
        }
    }

    func get<T: CacheObject>(type: T.Type, collection: String, key: String) -> T?
    {
        var result: T?

        // Read from database
        self.connection.readWithBlock { transaction in
            result = transaction.objectForKey(key, inCollection: collection) as? T
        }

        // Done
        return result
    }

    func get<T: CacheObject>(type: T.Type, collection: String, keys: [String]) -> [String: T?]
    {
        var result: [String: T?] = [:]

        // Read from database
        self.connection.readWithBlock { transaction in
            for key in keys {
                result[key] = transaction.objectForKey(key, inCollection: collection) as? T
            }
        }

        // Done
        return result
    }

    func filterKeys<T: CacheObject>(type: T.Type, collection: String, block: (String) -> Bool) -> [String]
    {
        var result: [String] = []

        // Read from database
        self.connection.readWithBlock { transaction in
            transaction.enumerateKeysInCollection(collection) { key, stop in
                if block(key) {
                    result.append(key)
                }
            }
        }

        // Done
        return result
    }

    func filterByKey<T: CacheObject>(collection collection: String, block: (String) -> Bool) -> [T]
    {
        var result: [T] = []

        // Read from database
        self.connection.readWithBlock { transaction in
            transaction.enumerateKeysInCollection(collection) { key, stop in
                if block(key)
                {
                    if let object = transaction.objectForKey(key, inCollection: collection) as? T {
                        result.append(object)
                    }
                }
            }
        }

        // Done
        return result
    }

    func filter<T: CacheObject>(type: T.Type, collection: String, block: (T) -> Bool) -> [T]
    {
        var result: [T] = []

        // Read from database
        self.connection.readWithBlock { transaction in
            transaction.enumerateKeysAndObjectsInCollection(collection) { key, object, stop in
                if let object = (object as? T) where block(object) {
                    result.append(object)
                }
            }
        }

        // Done
        return result
    }

    func delete<T: CacheObject>(type: T.Type, collection: String, key: String) {
        delete(type, collection: collection, keys: [key])
    }

    func delete<T: CacheObject>(type: T.Type, collection: String, keys: [String])
    {
        // Write to database
        self.connection.readWriteWithBlock { transaction in
            transaction.removeObjectsForKeys(keys, inCollection: collection)
        }
    }

// MARK: Variables

    // ...

}

// ----------------------------------------------------------------------------
