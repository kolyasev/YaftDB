// ----------------------------------------------------------------------------
//
//  DatabaseCollectionReadTransaction.swift
//
//  @author Denis Kolyasev <kolyasev@gmail.com>
//
// ----------------------------------------------------------------------------

import YapDatabase

// ----------------------------------------------------------------------------

open class DatabaseCollectionReadTransaction<T: DatabaseObject>
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

    open func get(_ key: String) -> T? {
        return self.transaction.object(forKey: key, inCollection: self.collection) as? T
    }

    open func enumerateKeys(_ block: @escaping (_ key: String, _ stop: inout Bool) -> Void)
    {
        self.transaction.enumerateKeys(inCollection: self.collection) { key, stop in
            var s = false

            block(key, &s)

            if s { stop.pointee = true }
        }
    }

    open func enumerateObjects(_ block: @escaping (_ key: String, _ object: T, _ stop: inout Bool) -> Void)
    {
        self.transaction.enumerateKeysAndObjects(inCollection: self.collection) { key, object, stop in
            var s = false

            if let object = (object as? T) {
                block(key, object, &s)
            }

            if s { stop.pointee = true }
        }
    }

// MARK: - Variables

    fileprivate let transaction: YapDatabaseReadTransaction

}

// ----------------------------------------------------------------------------
