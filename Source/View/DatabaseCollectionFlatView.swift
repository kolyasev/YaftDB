// ----------------------------------------------------------------------------
//
//  DatabaseCollectionFlatView.swift
//
//  @author Denis Kolyasev <kolyasev@gmail.com>
//
// ----------------------------------------------------------------------------

import YapDatabase
import YapDatabase.YapDatabaseView

// ----------------------------------------------------------------------------

public class DatabaseCollectionFlatView<T: DatabaseObject>: DatabaseCollectionViewProtocol
{
// MARK: Construction

    public required init(collection: String) {
        self.collectionView = DatabaseCollectionView(collection: collection)
    }

// MARK: Functions

    public func name() -> String {
        return String(self.dynamicType) + "_" + self.collectionView.name()
    }

    public func registerExtensionInDatabase(database: YapDatabase) {
        self.collectionView.registerExtensionInDatabase(database)
    }

    public class func allGroups() -> [FlatGrouping] {
        return [.Root]
    }

// MARK: Inner Types

    public typealias Object = T
    
    public typealias Grouping = FlatGrouping

// MARK: Variables

    private let collectionView: DatabaseCollectionView<T, FlatGrouping>

}

// ----------------------------------------------------------------------------

class DatabaseCollectionFlatViewImpl<T: DatabaseObject>: DatabaseCollectionView<T, FlatGrouping>
{
    // TODO: ...
}

// ----------------------------------------------------------------------------

public enum FlatGrouping: String
{
    case Root = "root"
}

// ----------------------------------------------------------------------------
