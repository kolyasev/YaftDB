// ----------------------------------------------------------------------------
//
//  DatabaseCollectionReadWriteTransaction.swift
//
//  @author Denis Kolyasev <kolyasev@gmail.com>
//
// ----------------------------------------------------------------------------

import YapDatabase

// ----------------------------------------------------------------------------

public class DatabaseCollectionReadWriteTransaction<T: DatabaseObject>: DatabaseCollectionReadTransaction<T>
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

    public func put(key: String, object: T)
    {
        let metadata = DatabaseObjectMetadata(hash: object.hash)

        if let existingMetadata = (self.transaction.metadataForKey(key, inCollection: self.collection) as? DatabaseObjectMetadata)
           where (existingMetadata.hash == metadata.hash)
        {
            // TODO: Update metadata only
        }
        else {
            self.transaction.setObject(object, forKey: key, inCollection: self.collection, withMetadata: metadata)
        }
    }

    public func remove(key: String) {
        self.transaction.removeObjectForKey(key, inCollection: self.collection)
    }

    public func remove(keys: [String]) {
        self.transaction.removeObjectsForKeys(keys, inCollection: self.collection)
    }

    public func removeAll() {
        self.transaction.removeAllObjectsInCollection(self.collection)
    }

// MARK: - Variables

    private let transaction: YapDatabaseReadWriteTransaction

}

// ----------------------------------------------------------------------------
