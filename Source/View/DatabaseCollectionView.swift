// ----------------------------------------------------------------------------
//
//  DatabaseCollectionView.swift
//
//  @author Denis Kolyasev <kolyasev@gmail.com>
//
// ----------------------------------------------------------------------------

import YapDatabase
import YapDatabase.YapDatabaseView

// ----------------------------------------------------------------------------

open class DatabaseCollectionView<T: DatabaseObject, G: RawRepresentable>: DatabaseCollectionViewProtocol where G.RawValue == String
{
// MARK: Construction

    public required init(collection: String)
    {
        // Init instance variables
        self.collection = collection
    }

// MARK: Properties

    open let collection: String

    open class var version: Int { return 1 }

// MARK: Public Functions

    open class func filter(_ key: String, object: T) -> G? {
        return nil
    }

    open class func isOrderedBefore(key1: String, object1: T, key2: String, object2: T) -> Bool {
        return true
    }

    open class func allGroups() -> [G] {
        return []
    }

// MARK: Inner Functions

    open func registerExtensionInDatabase(_ database: YapDatabase)
    {
        let grouping = type(of: self).createGrouping(self.collection)
        let sorting = type(of: self).createSorting()

        // Use only current collection
        let options = YapDatabaseViewOptions()
        options.allowedCollections = YapWhitelistBlacklist(whitelist: Set(arrayLiteral: self.collection))

        // Init database view
        let view = YapDatabaseView(grouping: grouping, sorting: sorting, versionTag: nil, options: options)

        // Register extension
        database.register(view, withName: databaseExtensionName())
    }

    open func name() -> String {
        return databaseExtensionName()
    }

// MARK: Private Functions

    fileprivate class func createGrouping(_ collection: String) -> YapDatabaseViewGrouping
    {
        return YapDatabaseViewGrouping.withObjectBlock { transaction, collection, key, object in
            // Filter by collection
            guard (collection == collection) else { return nil }

            // Filter by type
            guard let object = (object as? T) else { return nil }

            // Filter and group by class filter function
            return self.filter(key, object: object)?.rawValue
        }
    }

    fileprivate class func createSorting() -> YapDatabaseViewSorting
    {
        return YapDatabaseViewSorting.withObjectBlock { transaction, group, collection1, key1, object1, collection2, key2, object2 in
            return self.isOrderedBefore(key1: key1, object1: object1 as! T, key2: key2, object2: object2 as! T) ? .orderedAscending : .orderedDescending
        }
    }

    fileprivate func databaseExtensionName() -> String {
        return String(describing: DatabaseCollectionView<T, G>.self) + "_" + String(ImplementationVersion) + "_" + String(describing: type(of: self))
                + "_" + String(type(of: self).version) + "_" + self.collection + "_" + String(T.version)
    }

// MARK: Inner Types

    public typealias Object = T

    public typealias Grouping = G

// MARK: Constants

    fileprivate let ImplementationVersion: Int = 1

}

// ----------------------------------------------------------------------------

public protocol DatabaseCollectionViewProtocol
{
// MARK: Construction

    init(collection: String)

// MARK: Functions

    func name() -> String

    func registerExtensionInDatabase(_ database: YapDatabase)

    static func allGroups() -> [Grouping]

// MARK: Inner Types

    associatedtype Object

    associatedtype Grouping

}

// ----------------------------------------------------------------------------
