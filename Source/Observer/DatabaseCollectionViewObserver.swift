// ----------------------------------------------------------------------------
//
//  DatabaseCollectionViewObserver.swift
//
//  @author Denis Kolyasev <kolyasev@gmail.com>
//
// ----------------------------------------------------------------------------

import Foundation
import YapDatabase

// ----------------------------------------------------------------------------

public class DatabaseCollectionViewObserver<V: DatabaseCollectionViewProtocol where V.Grouping: RawRepresentable, V.Grouping.RawValue == String>
{
// MARK: Construction

    init(view: V, connection: YapDatabaseConnection)
    {
        // Init instance variables
        self.view = view
        self.connection = connection

        // Create new long lived transaction
        self.connection.beginLongLivedReadTransaction()

        // Create mappings
        let allGroups = view.dynamicType.allGroups().map{ $0.rawValue }
        self.mappings = YapDatabaseViewMappings(groups: allGroups, view: self.view.name())

        // Register for notifications
        weak var weakSelf = self
        self.notificationObserver = NSNotificationCenter.defaultCenter().addObserverForName(YapDatabaseModifiedNotification,
                object: self.connection.database, queue: nil,
                usingBlock: { notification in
                    dispatch.async.bg {
                        weakSelf?.handleDatabaseModifiedNotification(notification)
                    }
                })

        // Update mappings
        self.connection.readWithBlock { transaction in
            weakSelf?.mappings.updateWithTransaction(transaction)
        }
    }

    deinit {
        // Unregister from notifications
        if let observer = self.notificationObserver {
            NSNotificationCenter.defaultCenter().removeObserver(observer)
        }
    }

// MARK: Properties

    public weak var delegate: DatabaseCollectionViewObserverDelegate?

// MARK: Functions

    public func numberOfGroups() -> Int {
        return self.mappings.allGroups.count
    }

    public func numberOfObjectsInGroup(group: G) -> Int {
        return Int(self.mappings.numberOfItemsInGroup(group.rawValue))
    }

    public func objectInGroup(group: G, atIndex index: Int) -> T!
    {
        let section = mappings.sectionForGroup(group.rawValue)
        return objectInSection(Int(section), atIndex: index)
    }

    public func allObjectsInGroup(group: G) -> [T]
    {
        var result: [T] = []

        let viewName = self.view.name()

        self.connection.readWithBlock { transaction in
            if let viewTransactions = (transaction.ext(viewName) as? YapDatabaseViewTransaction)
            {
                viewTransactions.enumerateRowsInGroup(group.rawValue, usingBlock: { collection, key, object, metadata, idx, stop in
                    if let object = (object as? T) {
                        result.append(object)
                    }
                })
            }
        }

        return result
    }

// MARK: Functions: Section Helpers

    public func numberOfSections() -> Int {
        return Int(self.mappings.numberOfSections())
    }

    public func numberOfObjectsInSection(section: Int) -> Int {
        return Int(self.mappings.numberOfItemsInSection(UInt(section)))
    }

    public func objectInSection(section: Int, atIndex index: Int) -> T!
    {
        var result: T!

        let viewName = self.view.name()
        let mappings = self.mappings

        self.connection.readWithBlock { transaction in
            if let viewTransactions = (transaction.ext(viewName) as? YapDatabaseViewTransaction)
            {
                result = viewTransactions.objectAtRow(UInt(index), inSection: UInt(section), withMappings: mappings) as? T
            }
        }

        return result
    }

// MARK: Private Functions

    private func handleDatabaseModifiedNotification(notification: NSNotification)
    {
        weak var weakSelf = self

        let notifications = self.connection.beginLongLivedReadTransaction()
        if  notifications.isEmpty { return }

        var sectionChanges: NSArray?
        var rowChanges: NSArray?

        self.databaseViewConnection().getSectionChanges(&sectionChanges, rowChanges: &rowChanges,
                forNotifications: notifications, withMappings: self.mappings)

        if let rowChanges = (rowChanges as? [YapDatabaseViewRowChange]) where !(rowChanges.isEmpty)
        {
            dispatch.sync.main {
                // Notify delegate
                weakSelf?.delegate?.databaseCollectionViewObserverBeginUpdates()
            }

            for rowChange in rowChanges
            {
                let change = DatabaseCollectionViewChange(rowChange: rowChange)

                dispatch.sync.main {
                    // Notify delegate
                    weakSelf?.delegate?.databaseCollectionViewObserverDidChange(change)
                }
            }

            dispatch.sync.main {
                // Notify delegate
                weakSelf?.delegate?.databaseCollectionViewObserverEndUpdates()
            }
        }
    }

    private func databaseViewConnection() -> YapDatabaseViewConnection {
        return self.connection.ext(self.view.name()) as! YapDatabaseViewConnection
    }

// MARK: Inner Types

    typealias T = V.Object

    typealias G = V.Grouping

// MARK: Variables

    private let view: V

    private let connection: YapDatabaseConnection

    private let mappings: YapDatabaseViewMappings

    private var notificationObserver: AnyObject?

}

// ----------------------------------------------------------------------------

public protocol DatabaseCollectionViewObserverDelegate: class
{
// MARK: Functions

    func databaseCollectionViewObserverBeginUpdates()

    func databaseCollectionViewObserverDidChange(change: DatabaseCollectionViewChange)

    func databaseCollectionViewObserverEndUpdates()

}

// ----------------------------------------------------------------------------
// Default implementation for DatabaseCollectionViewObserverDelegate
// ----------------------------------------------------------------------------

public extension DatabaseCollectionViewObserverDelegate
{
// MARK: Functions

    public func databaseCollectionViewObserverBeginUpdates() {}

    public func databaseCollectionViewObserverDidChange(change: DatabaseCollectionViewChange) {}

    public func databaseCollectionViewObserverEndUpdates() {}

}

// ----------------------------------------------------------------------------

public class DatabaseCollectionViewChange
{
// MARK: Construction

    init(rowChange: YapDatabaseViewRowChange)
    {
        // Init instance variables
        self.indexPath = rowChange.indexPath
        self.newIndexPath = rowChange.newIndexPath
        self.type = DatabaseCollectionViewChangeType(type: rowChange.type)
    }

// MARK: Properties

    public let indexPath: NSIndexPath

    public let newIndexPath: NSIndexPath

    public let type: DatabaseCollectionViewChangeType

}

// ----------------------------------------------------------------------------

public enum DatabaseCollectionViewChangeType
{
// MARK: Construction

    init(type: YapDatabaseViewChangeType)
    {
        switch type
        {
            case .Insert: self = .Insert
            case .Delete: self = .Delete
            case .Move:   self = .Move
            case .Update: self = .Update
        }
    }

// MARK: Cases

    case Insert
    case Delete
    case Move
    case Update

}

// ----------------------------------------------------------------------------
