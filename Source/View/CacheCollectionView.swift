// ----------------------------------------------------------------------------
//
//  CacheCollectionView.swift
//
//  @author Denis Kolyasev <kolyasev@gmail.com>
//
// ----------------------------------------------------------------------------

import YapDatabase
import YapDatabase.YapDatabaseView

// ----------------------------------------------------------------------------

public class CacheCollectionView<T: CacheObject>: CacheCollectionViewProtocol
{
// MARK: Construction

    public required init(collection: String)
    {
        // Init instance variables
        self.collection = collection
    }

// MARK: Properties

    public let collection: String

    public class var version: Int { return 1 }

// MARK: Public Functions

    public class func filter(key: String, object: T) -> Bool {
        return true
    }

    public class func isOrderedBefore(key1 key1: String, object1: T, key2: String, object2: T) -> Bool {
        return true
    }

// MARK: Inner Functions

    public func registerExtensionInDatabase(database: YapDatabase)
    {
        let grouping = self.dynamicType.createGrouping(self.collection)
        let sorting = self.dynamicType.createSorting()

        // Use only current collection
        let options = YapDatabaseViewOptions()
        options.allowedCollections = YapWhitelistBlacklist(whitelist: Set(arrayLiteral: self.collection))

        // Init database view
        let view = YapDatabaseView(grouping: grouping, sorting: sorting, versionTag: nil, options: options)

        // Register extension
        database.registerExtension(view, withName: databaseExtensionName())
    }

    public func name() -> String {
        return databaseExtensionName()
    }

// MARK: Private Functions

    private class func createGrouping(collection: String) -> YapDatabaseViewGrouping
    {
        return YapDatabaseViewGrouping.withObjectBlock { transaction, collection, key, object in
            // Filter by collection
            guard (collection == collection) else { return nil }

            // Filter by type
            guard let object = (object as? T) else { return nil }

            // Filter by class filter function
            guard self.filter(key, object: object) else { return nil }

            // Use root group
            return "root"
        }
    }

    private class func createSorting() -> YapDatabaseViewSorting
    {
        return YapDatabaseViewSorting.withObjectBlock { transaction, group, collection1, key1, object1, collection2, key2, object2 in
            return self.isOrderedBefore(key1: key1, object1: object1 as! T, key2: key2, object2: object2 as! T) ? .OrderedAscending : .OrderedDescending
        }
    }

    private func databaseExtensionName() -> String {
        return String(CacheCollectionView<T>) + "_" + String(self.dynamicType)
                + "_" + String(self.dynamicType.version) + "_" + self.collection + "_" + String(T.version)
    }

// MARK: Inner Types

    public typealias Object = T

}

// ----------------------------------------------------------------------------

public protocol CacheCollectionViewProtocol
{
// MARK: Construction

    init(collection: String)

// MARK: Functions

    func name() -> String

    func registerExtensionInDatabase(database: YapDatabase)

// MARK: Inner Types

    typealias Object

}

// ----------------------------------------------------------------------------
