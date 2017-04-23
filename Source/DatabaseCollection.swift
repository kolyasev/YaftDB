// ----------------------------------------------------------------------------
//
//  DatabaseCollection.swift
//
//  @author Denis Kolyasev <kolyasev@gmail.com>
//
// ----------------------------------------------------------------------------

import YapDatabase

// ----------------------------------------------------------------------------

open class DatabaseCollection<T: DatabaseObject>
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

    open func observe(_ key: String) -> DatabaseObjectObserver<T>
    {
        let connection = self.database.database.newConnection()
        return DatabaseObjectObserver<T>(collection: self.name, key: key, connection: connection)
    }

    open func observe<V: DatabaseCollectionViewProtocol>(_ viewType: V.Type) -> DatabaseCollectionViewObserver<V> where V.Object == T
    {
        let view = viewType.init(collection: self.name)

        view.registerExtensionInDatabase(self.database.database)

        let connection = self.database.database.newConnection()
        return DatabaseCollectionViewObserver<V>(view: view, connection: connection)
    }

    open func observe() -> DatabaseCollectionObserver<T>
    {
        let connection = self.database.database.newConnection()
        return DatabaseCollectionObserver<T>(collection: self.name, connection: connection)
    }

// MARK: - Functions: Read Transactions

    open func read(_ block: @escaping (DatabaseCollectionReadTransaction<T>) -> Void)
    {
        self.database.connection.read { transaction in
            block(self.collectionReadTransaction(transaction))
        }
    }

    open func read<R>(_ block: @escaping (DatabaseCollectionReadTransaction<T>) -> R) -> R
    {
        var result: R!

        self.database.connection.read { transaction in
            result = block(self.collectionReadTransaction(transaction))
        }

        return result
    }

    open func asyncRead(_ block: @escaping (DatabaseCollectionReadTransaction<T>) -> Void)
    {
        weak var weakSelf = self
        self.database.connection.asyncRead { transaction in
            if let collectionTransaction = weakSelf?.collectionReadTransaction(transaction) {
                block(collectionTransaction)
            }
        }
    }

// MARK: - Functions: Write Transactions

    open func write(_ block: @escaping (DatabaseCollectionReadWriteTransaction<T>) -> Void)
    {
        self.database.connection.readWrite { transaction in
            block(self.collectionReadWriteTransaction(transaction))
        }
    }

    open func write<R>(_ block: @escaping (DatabaseCollectionReadWriteTransaction<T>) -> R) -> R
    {
        var result: R!

        self.database.connection.readWrite { transaction in
            result = block(self.collectionReadWriteTransaction(transaction))
        }

        return result
    }

    open func asyncWrite(_ block: @escaping (DatabaseCollectionReadWriteTransaction<T>) -> Void)
    {
        weak var weakSelf = self
        self.database.connection.asyncReadWrite { transaction in
            if let collectionTransaction = weakSelf?.collectionReadWriteTransaction(transaction) {
                block(collectionTransaction)
            }
        }
    }

// MARK: - Private Functions

    fileprivate func collectionReadTransaction(_ transaction: YapDatabaseReadTransaction) -> DatabaseCollectionReadTransaction<T> {
        return DatabaseCollectionReadTransaction<T>(transaction: transaction, collection: self.name)
    }

    fileprivate func collectionReadWriteTransaction(_ transaction: YapDatabaseReadWriteTransaction) -> DatabaseCollectionReadWriteTransaction<T> {
        return DatabaseCollectionReadWriteTransaction<T>(transaction: transaction, collection: self.name)
    }

// MARK: - Inner Types

    typealias ObjectType = T

}

// ----------------------------------------------------------------------------

extension DatabaseCollection
{
// MARK: - Functions: Operations

    public func put(_ key: String, object: T)
    {
        asyncWrite { transaction in
            transaction.put(key, object: object)
        }
    }

    public func put(_ entities: [Entity])
    {
        asyncWrite { transaction in
            for entity in entities {
                transaction.put(entity.key, object: entity.object)
            }
        }
    }

    public func get(_ key: String) -> T?
    {
        return read { transaction in
            return transaction.get(key)
        }
    }

    public func get(_ keys: [String]) -> [String: T?]
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

    public func filter(_ block: @escaping (T) -> Bool) -> [T]
    {
        return read { transaction in
            var result: [T] = []

            transaction.enumerateObjects { key, object, stop in
                if block(object) {
                    result.append(object)
                }
            }

            return result
        }
    }

    public func remove(_ key: String)
    {
        asyncWrite { transaction in
            transaction.remove(key)
        }
    }

    public func remove(_ keys: [String])
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

    public func replaceAll(_ entities: [Entity])
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
