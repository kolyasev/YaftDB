// ----------------------------------------------------------------------------
//
//  DatabasePrimaryKeyObject.swift
//
//  @author Denis Kolyasev <kolyasev@gmail.com>
//
// ----------------------------------------------------------------------------

public protocol DatabasePrimaryKeyObject
{
// MARK: Construction

    var primaryKey: String { get }

}

// ----------------------------------------------------------------------------

extension DatabaseCollection where T: DatabasePrimaryKeyObject
{
// MARK: Functions

    public func put(object: T) {
        put(object.primaryKey, object: object)
    }

    public func put(objects: [T]) {
        self.database.put(collection: self.name, entities: objects.map { (key: $0.primaryKey, object: $0) })
    }

}

// ----------------------------------------------------------------------------
