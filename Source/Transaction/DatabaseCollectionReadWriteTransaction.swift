// ----------------------------------------------------------------------------
//
//  DatabaseCollectionReadWriteTransaction.swift
//
//  @author Denis Kolyasev <kolyasev@gmail.com>
//
// ----------------------------------------------------------------------------

import YapDatabase

// ----------------------------------------------------------------------------

open class DatabaseCollectionReadWriteTransaction<T: DatabaseObject>: DatabaseCollectionReadTransaction<T>
{
// MARK: - Construction

    init(transaction: YapDatabaseReadWriteTransaction, collection: String)
    {
        // Init instance variables
        self.transaction = transaction

        // Parent processing
        super.init(transaction: transaction, collection: collection)
    }

// MARK: - Functions

    open func put(_ key: String, object: T)
    {
        let metadata = DatabaseObjectMetadata(hash: object.hash)
        self.transaction.setObject(object, forKey: key, inCollection: self.collection, withMetadata: metadata)
    }

    open func remove(_ key: String) {
        self.transaction.removeObject(forKey: key, inCollection: self.collection)
    }

    open func remove(_ keys: [String]) {
        self.transaction.removeObjects(forKeys: keys, inCollection: self.collection)
    }

    open func removeAll() {
        self.transaction.removeAllObjects(inCollection: self.collection)
    }

// MARK: - Variables

    fileprivate let transaction: YapDatabaseReadWriteTransaction

}

// ----------------------------------------------------------------------------
