// ----------------------------------------------------------------------------
//
//  DatabaseCollectionReadTransaction.swift
//
//  @author Denis Kolyasev <kolyasev@gmail.com>
//
// ----------------------------------------------------------------------------

import YapDatabase

// ----------------------------------------------------------------------------

public class DatabaseCollectionReadTransaction<T: DatabaseObject>
{
// MARK: - Construction

    init(transaction: YapDatabaseReadTransaction, collection: String)
    {
        // Init instance variables
        self.transaction = transaction
        self.collection = collection
    }

// MARK: - Properties

    let collection: String

// MARK: - Functions

    public func get(key: String) -> T? {
        return self.transaction.objectForKey(key, inCollection: self.collection) as? T
    }

    public func enumerateKeys(block: (key: String, stop: inout Bool) -> Void)
    {
        self.transaction.enumerateKeysInCollection(self.collection) { key, stop in
            var s = false

            block(key: key, stop: &s)

            if s { stop.memory = true }
        }
    }

// MARK: - Variables

    private let transaction: YapDatabaseReadTransaction

}

// ----------------------------------------------------------------------------
