// ----------------------------------------------------------------------------
//
//  Database.swift
//
//  @author Denis Kolyasev <kolyasev@gmail.com>
//
// ----------------------------------------------------------------------------

import YapDatabase

// ----------------------------------------------------------------------------

public class Database
{
// MARK: - Construction

    public init(path: String)
    {
        // Init instance variables
        self.database = YapDatabase(path: path,
                objectSerializer: DatabaseObjectCoder.serializeObject,
                objectDeserializer: DatabaseObjectCoder.deserializerObject,
                metadataSerializer: DatabaseObjectMetadataCoder.serializeMetadata,
                metadataDeserializer: DatabaseObjectMetadataCoder.deserializerMetadata)
        self.connection = self.database.newConnection()
    }

// MARK: - Properties

    let database: YapDatabase

    let connection: YapDatabaseConnection

// MARK: - Public Functions

    public func collection<T>(type: T.Type = T.self, name: String) -> DatabaseCollection<T> {
        return DatabaseCollection<T>(name: name, database: self)
    }

// MARK: - Internal Functions

    func put(collection collection: String, key: String, object: DatabaseObject)
    {
        // Write to database
        self.connection.asyncReadWriteWithBlock { transaction in
            Database.putObjectWithTransaction(transaction, collection: collection, key: key, object: object)
        }
    }

    func put(collection collection: String, entities: [(key: String, object: DatabaseObject)])
    {
        // Write to database
        self.connection.asyncReadWriteWithBlock { transaction in
            for (key, object) in entities {
                Database.putObjectWithTransaction(transaction, collection: collection, key: key, object: object)
            }
        }
    }

    func get<T: DatabaseObject>(type: T.Type, collection: String, key: String) -> T?
    {
        var result: T?

        // Read from database
        self.connection.readWithBlock { transaction in
            result = transaction.objectForKey(key, inCollection: collection) as? T
        }

        return result
    }

    func get<T: DatabaseObject>(type: T.Type, collection: String, keys: [String]) -> [String: T?]
    {
        var result: [String: T?] = [:]

        // Read from database
        self.connection.readWithBlock { transaction in
            for key in keys {
                result[key] = transaction.objectForKey(key, inCollection: collection) as? T
            }
        }

        return result
    }

    func filterKeys<T: DatabaseObject>(type: T.Type, collection: String, block: (String) -> Bool) -> [String]
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

        return result
    }

    func filterByKey<T: DatabaseObject>(collection collection: String, block: (String) -> Bool) -> [T]
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

        return result
    }

    func filter<T: DatabaseObject>(type: T.Type, collection: String, block: (T) -> Bool) -> [T]
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

        return result
    }

    func remove<T: DatabaseObject>(type: T.Type, collection: String, key: String) {
        remove(type, collection: collection, keys: [key])
    }

    func remove<T: DatabaseObject>(type: T.Type, collection: String, keys: [String])
    {
        // Write to database
        self.connection.asyncReadWriteWithBlock { transaction in
            transaction.removeObjectsForKeys(keys, inCollection: collection)
        }
    }

    func removeAll<T: DatabaseObject>(type: T.Type, collection: String)
    {
        // Write to database
        self.connection.asyncReadWriteWithBlock { transaction in
            transaction.removeAllObjectsInCollection(collection)
        }
    }

    func replaceAll(collection collection: String, entities: [(key: String, object: DatabaseObject)])
    {
        // Write to database
        self.connection.asyncReadWriteWithBlock { transaction in
            // TODO: Remove only objects that not contained in `entities`
            transaction.removeAllObjectsInCollection(collection)

            for (key, object) in entities {
                Database.putObjectWithTransaction(transaction, collection: collection, key: key, object: object)
            }
        }
    }

// MARK: - Private Functions

    private static func putObjectWithTransaction(transaction: YapDatabaseReadWriteTransaction,
                                                 collection: String, key: String, object: DatabaseObject)
    {
        let metadata = DatabaseObjectMetadata(hash: object.hash)

        if let existingMetadata = (transaction.metadataForKey(key, inCollection: collection) as? DatabaseObjectMetadata)
            where (existingMetadata.hash == metadata.hash)
        {
            // TODO: Update metadata only
        }
        else {
            transaction.setObject(object, forKey: key, inCollection: collection, withMetadata: metadata)
        }
    }

}

// ----------------------------------------------------------------------------
