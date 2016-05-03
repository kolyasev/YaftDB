// ----------------------------------------------------------------------------
//
//  DatabasePrimaryKeyObject.swift
//
//  @author Denis Kolyasev <kolyasev@gmail.com>
//
// ----------------------------------------------------------------------------

public protocol DatabasePrimaryKeyObject
{
// MARK: - Properties

    var primaryKey: String { get }

}

// ----------------------------------------------------------------------------

extension DatabaseCollection where T: DatabasePrimaryKeyObject
{
// MARK: - Functions

    public func put(object: T) {
        put(object.primaryKey, object: object)
    }

    public func put(objects: [T])
    {
        asyncWrite { transaction in
            for object in objects {
                transaction.put(object.primaryKey, object: object)
            }
        }
    }

    public func replaceAll(objects: [T])
    {
        asyncWrite { transaction in
            transaction.removeAll()

            for object in objects {
                transaction.put(object.primaryKey, object: object)
            }
        }
    }

}

// ----------------------------------------------------------------------------
