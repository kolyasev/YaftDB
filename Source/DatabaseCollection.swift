// ----------------------------------------------------------------------------
//
//  DatabaseCollection.swift
//
//  @author Denis Kolyasev <kolyasev@gmail.com>
//
// ----------------------------------------------------------------------------

import YapDatabase

// ----------------------------------------------------------------------------

public class DatabaseCollection<T: DatabaseObject>
{
// MARK: - Construction

    init(name: String, database: Database)
    {
        self.name = name
        self.database = database
    }

// MARK: - Properties

    let name: String

    let database: Database

// MARK: - Functions: Observing

    public func observe(key: String) -> DatabaseObjectObserver<T>
    {
        let connection = self.database.database.newConnection()
        return DatabaseObjectObserver<T>(collection: self.name, key: key, connection: connection)
    }

    public func observe<V: DatabaseCollectionViewProtocol where V.Object == T>(viewType: V.Type) -> DatabaseCollectionViewObserver<V>
    {
        let view = viewType.init(collection: self.name)

        view.registerExtensionInDatabase(self.database.database)

        let connection = self.database.database.newConnection()
        return DatabaseCollectionViewObserver<V>(view: view, connection: connection)
    }

// MARK: - Functions: Read Transactions

    public func read(block: (DatabaseCollectionReadTransaction<T>) -> Void)
    {
        self.database.connection.readWithBlock { transaction in
            block(self.collectionReadTransaction(transaction))
        }
    }

    public func read<R>(block: (DatabaseCollectionReadTransaction<T>) -> R) -> R
    {
        var result: R!

        self.database.connection.readWithBlock { transaction in
            result = block(self.collectionReadTransaction(transaction))
        }

        return result
    }

    public func asyncRead(block: (DatabaseCollectionReadTransaction<T>) -> Void)
    {
        weak var weakSelf = self
        self.database.connection.asyncReadWithBlock { transaction in
            if let collectionTransaction = weakSelf?.collectionReadTransaction(transaction) {
                block(collectionTransaction)
            }
        }
    }

// MARK: - Functions: Write Transactions

    public func write(block: (DatabaseCollectionReadWriteTransaction<T>) -> Void)
    {
        self.database.connection.readWriteWithBlock { transaction in
            block(self.collectionReadWriteTransaction(transaction))
        }
    }

    public func write<R>(block: (DatabaseCollectionReadWriteTransaction<T>) -> R) -> R
    {
        var result: R!

        self.database.connection.readWriteWithBlock { transaction in
            result = block(self.collectionReadWriteTransaction(transaction))
        }

        return result
    }

    public func asyncWrite(block: (DatabaseCollectionReadWriteTransaction<T>) -> Void)
    {
        weak var weakSelf = self
        self.database.connection.asyncReadWriteWithBlock { transaction in
            if let collectionTransaction = weakSelf?.collectionReadWriteTransaction(transaction) {
                block(collectionTransaction)
            }
        }
    }

// MARK: - Private Functions

    private func collectionReadTransaction(transaction: YapDatabaseReadTransaction) -> DatabaseCollectionReadTransaction<T> {
        return DatabaseCollectionReadTransaction<T>(transaction: transaction, collection: self.name)
    }

    private func collectionReadWriteTransaction(transaction: YapDatabaseReadWriteTransaction) -> DatabaseCollectionReadWriteTransaction<T> {
        return DatabaseCollectionReadWriteTransaction<T>(transaction: transaction, collection: self.name)
    }

// MARK: - Inner Types

    typealias ObjectType = T

}

// ----------------------------------------------------------------------------

extension DatabaseCollection
{
// MARK: - Functions: Operations

    public func put(key: String, object: T)
    {
        asyncWrite { transaction in
            transaction.put(key, object: object)
        }
    }

    public func put(entities: [Entity])
    {
        asyncWrite { transaction in
            for entity in entities {
                transaction.put(entity.key, object: entity.object)
            }
        }
    }

    public func get(key: String) -> T?
    {
        return read { transaction in
            return transaction.get(key)
        }
    }

    public func get(keys: [String]) -> [String: T?]
    {
        return read { transaction in
            var result: [String: T?] = [:]

            for key in keys {
                result[key] = transaction.get(key)
            }

            return result
        }
    }

    // TODO: ...
//    public func filterKeys(block: (String) -> Bool) -> [String]
//    {
//        var result: [String] = []
//
//        // Read from database
//        self.connection.readWithBlock { transaction in
//            transaction.enumerateKeysInCollection(collection) { key, stop in
//                if block(key) {
//                    result.append(key)
//                }
//            }
//        }
//
//        return result
//    }

    // TODO: ...
//    public func filterByKey(block: (String) -> Bool) -> [T]
//    {
//        var result: [T] = []
//
//        // Read from database
//        self.connection.readWithBlock { transaction in
//            transaction.enumerateKeysInCollection(collection) { key, stop in
//                if block(key)
//                {
//                    if let object = transaction.objectForKey(key, inCollection: collection) as? T {
//                        result.append(object)
//                    }
//                }
//            }
//        }
//
//        return result
//    }

    // TODO: ...
//    public func filter(block: (T) -> Bool) -> [T]
//    {
//        var result: [T] = []
//
//        // Read from database
//        self.connection.readWithBlock { transaction in
//            transaction.enumerateKeysAndObjectsInCollection(collection) { key, object, stop in
//                if let object = (object as? T) where block(object) {
//                    result.append(object)
//                }
//            }
//        }
//
//        return result
//    }

    public func remove(key: String)
    {
        asyncWrite { transaction in
            transaction.remove(key)
        }
    }

    public func remove(keys: [String])
    {
        asyncWrite { transaction in
            transaction.remove(keys)
        }
    }

    public func removeAll()
    {
        asyncWrite { transaction in
            transaction.removeAll()
        }
    }

    public func replaceAll(entities: [Entity])
    {
        asyncWrite { transaction in
            transaction.removeAll()
            for entity in entities {
                transaction.put(entity.key, object: entity.object)
            }
        }
    }

// MARK: - Inner Types

    public typealias Entity = (key: String, object: T)

}

// ----------------------------------------------------------------------------
