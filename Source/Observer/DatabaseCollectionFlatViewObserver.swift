// ----------------------------------------------------------------------------
//
//  DatabaseCollectionFlatViewObserver.swift
//
//  @author Denis Kolyasev <kolyasev@gmail.com>
//
// ----------------------------------------------------------------------------

import Foundation
import YapDatabase

// ----------------------------------------------------------------------------

public class DatabaseCollectionFlatViewObserver<V: DatabaseCollectionViewProtocol where V.Grouping == FlatGrouping>
{
// MARK: Construction

    init(view: V, connection: YapDatabaseConnection)
    {
        // Init instance variables
        self.viewObserver = DatabaseCollectionViewObserver(view: view, connection: connection)
    }

// MARK: Construction

    public func numberOfObjects() -> Int {
        return self.viewObserver.numberOfObjectsInGroup(.Root)
    }

    public func objectAtIndex(index: Int) -> T! {
        return self.viewObserver.objectInGroup(.Root, atIndex: index)
    }

    public func allObjects() -> [T] {
        return self.viewObserver.allObjectsInGroup(.Root)
    }

// MARK: Inner Types

    typealias T = V.Object

// MARK: Variables

    private let viewObserver: DatabaseCollectionViewObserver<V>

}

// ----------------------------------------------------------------------------

public protocol DatabaseCollectionFlatViewObserverDelegate: class
{
// MARK: Functions

    func databaseCollectionViewFlatObserverBeginUpdates()

    func databaseCollectionViewFlatObserverDidChange(change: DatabaseCollectionViewChange)

    func databaseCollectionViewFlatObserverEndUpdates()

}

// ----------------------------------------------------------------------------
// Default implementation for DatabaseCollectionFlatViewObserverDelegate
// ----------------------------------------------------------------------------

public extension DatabaseCollectionFlatViewObserverDelegate
{
// MARK: Functions

    func databaseCollectionViewFlatObserverBeginUpdates() {}

    func databaseCollectionViewFlatObserverDidChange(change: DatabaseCollectionViewChange) {}

    func databaseCollectionViewFlatObserverEndUpdates() {}

}

// ----------------------------------------------------------------------------

public class DatabaseCollectionFlatViewChange
{
// MARK: Construction

    init(rowChange: YapDatabaseViewRowChange)
    {
        // Init instance variables
        self.index = Int(rowChange.originalIndex)
        self.newIndex = Int(rowChange.finalIndex)
        self.type = DatabaseCollectionViewChangeType(type: rowChange.type)
    }

// MARK: Properties

    public let index: Int

    public let newIndex: Int

    public let type: DatabaseCollectionViewChangeType

}

// ----------------------------------------------------------------------------
