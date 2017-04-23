// ----------------------------------------------------------------------------
//
//  DatabaseCollectionFilteredView.swift
//
//  @author Denis Kolyasev <kolyasev@gmail.com>
//
// ----------------------------------------------------------------------------

import YapDatabase
import YapDatabase.YapDatabaseView
import YapDatabase.YapDatabaseFilteredView

// ----------------------------------------------------------------------------

open class DatabaseCollectionFilteredView<T: DatabaseObject, G: RawRepresentable>: DatabaseCollectionView<T, G> where G.RawValue == String
{
// MARK: Construction

    public required init(collection: String) {
        super.init(collection: collection)
    }

// MARK: Public Functions

    open func filter(_ key: String, object: T) -> Bool {
        return true
    }

    open func filterVersionTag() -> String {
        return UUID().uuidString
    }

// MARK: Inner Functions

    open override func registerExtensionInDatabase(_ database: YapDatabase) {
        super.registerExtensionInDatabase(database)

        // Init filtering
        let filter = self.filter
        let filtering = YapDatabaseViewFiltering.withObjectBlock { transaction, group, collection, key, object in
            return filter(key, object as! T)
        }

        // Init filtered database view
        let view = YapDatabaseFilteredView(parentViewName: super.name(), filtering: filtering, versionTag: filterVersionTag())

        // Register extension
        database.register(view, withName: databaseExtensionName())
    }

    open override func name() -> String {
        return databaseExtensionName()
    }

// MARK: Private Functions

    fileprivate func databaseExtensionName() -> String {
        return String(describing: DatabaseCollectionFilteredView<T, G>.self) + "_" + String(ImplementationVersion) + "_" + String(describing: type(of: self))
                + "_" + String(type(of: self).version) + "_" + self.collection + "_" + String(T.version)
    }

// MARK: Constants

    fileprivate let ImplementationVersion: Int = 1

}

// ----------------------------------------------------------------------------
