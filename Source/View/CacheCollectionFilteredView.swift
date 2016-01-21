// ----------------------------------------------------------------------------
//
//  CacheCollectionFilteredView.swift
//
//  @author Denis Kolyasev <kolyasev@gmail.com>
//
// ----------------------------------------------------------------------------

import YapDatabase
import YapDatabase.YapDatabaseView
import YapDatabase.YapDatabaseFilteredView

// ----------------------------------------------------------------------------

public class CacheCollectionFilteredView<T: CacheObject>: CacheCollectionView<T>
{
// MARK: Construction

    public required init(collection: String) {
        super.init(collection: collection)
    }

// MARK: Public Functions

    public func filter(key: String, object: T) -> Bool {
        return true
    }

// MARK: Inner Functions

    public override func registerExtensionInDatabase(database: YapDatabase) {
        super.registerExtensionInDatabase(database)

        // Init filtering
        let filter = self.filter
        let filtering = YapDatabaseViewFiltering.withObjectBlock { transaction, group, collection, key, object in
            return filter(key, object: object as! T)
        }

        // Init filtered database view
        let view = YapDatabaseFilteredView(parentViewName: super.name(), filtering: filtering, versionTag: nil)

        // Register extension
        database.registerExtension(view, withName: databaseExtensionName())
    }

    public override func name() -> String {
        return databaseExtensionName()
    }

// MARK: Private Functions

    private func databaseExtensionName() -> String {
        return String(CacheCollectionView<T>) + "_" + String(self.dynamicType)
                + "_" + String(self.dynamicType.version) + "_" + self.collection + "_" + String(T.version)
    }

}

// ----------------------------------------------------------------------------
