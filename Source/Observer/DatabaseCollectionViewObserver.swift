// ----------------------------------------------------------------------------
//
//  DatabaseObjectObserver.swift
//
//  @author Denis Kolyasev <kolyasev@gmail.com>
//
// ----------------------------------------------------------------------------

import Foundation
import YapDatabase

// ----------------------------------------------------------------------------

public class DatabaseCollectionViewObserver<V: DatabaseCollectionViewProtocol>
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
        self.mappings = YapDatabaseViewMappings(groups: ["root"], view: self.view.name())

        // Register for notifications
        weak var weakSelf = self
        self.notificationObserver = NSNotificationCenter.defaultCenter().addObserverForName(YapDatabaseModifiedNotification,
                object: self.connection.database, queue: nil,
                usingBlock: { notification in
                    weakSelf?.handleDatabaseModifiedNotification(notification)
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

    public weak var delegate: DatabaseCollectionViewDelegate?

// MARK: Functions

    public func numberOfObjects() -> Int {
        return Int(self.mappings.numberOfItemsInSection(0))
    }

    public func objectAtIndex(idx: Int) -> T!
    {
        var result: T!

        let viewName = self.view.name()
        let mappings = self.mappings

        self.connection.readWithBlock { transaction in
            if let viewTransactions = (transaction.ext(viewName) as? YapDatabaseViewTransaction)
            {
                result = viewTransactions.objectAtRow(UInt(idx), inSection: 0, withMappings: mappings) as? T
            }
        }

        return result
    }

// MARK: Private Functions

    private func handleDatabaseModifiedNotification(notification: NSNotification)
    {
        let notifications = self.connection.beginLongLivedReadTransaction()
        if  notifications.isEmpty { return }

        var sectionChanges: NSArray?
        var rowChanges: NSArray?

        self.databaseViewConnection().getSectionChanges(&sectionChanges, rowChanges: &rowChanges,
                forNotifications: notifications, withMappings: self.mappings)

        if let rowChanges = (rowChanges as? [YapDatabaseViewRowChange]) where !(rowChanges.isEmpty)
        {
            // Notify delegate
            self.delegate?.databaseCollectionViewBeginUpdates()

            for rowChange in rowChanges
            {
                let changeType = DatabaseCollectionViewChangeType(type: rowChange.type)
                let index = Int(rowChange.originalIndex)
                let newIndex = Int(rowChange.finalIndex)
                let change = DatabaseCollectionViewChange(index: index, newIndex: newIndex, changeType: changeType)

                // Notify delegate
                self.delegate?.databaseCollectionViewDidChange(change)
            }

            // Notify delegate
            self.delegate?.databaseCollectionViewEndUpdates()
        }
    }

    private func databaseViewConnection() -> YapDatabaseViewConnection {
        return self.connection.ext(self.view.name()) as! YapDatabaseViewConnection
    }

// MARK: Inner Types

    typealias T = V.Object

// MARK: Variables

    private let view: V

    private let connection: YapDatabaseConnection

    private let mappings: YapDatabaseViewMappings

    private var notificationObserver: AnyObject?

}

// ----------------------------------------------------------------------------

public protocol DatabaseCollectionViewDelegate: class
{
// MARK: Functions

    func databaseCollectionViewBeginUpdates()

    func databaseCollectionViewDidChange(change: DatabaseCollectionViewChange)

    func databaseCollectionViewEndUpdates()

}

// ----------------------------------------------------------------------------

public class DatabaseCollectionViewChange
{
// MARK: Construction

    init(index: Int, newIndex: Int, changeType: DatabaseCollectionViewChangeType)
    {
        // Init instance variables
        self.index = index
        self.newIndex = newIndex
        self.type = changeType
    }

// MARK: Properties

    public let index: Int

    public let newIndex: Int

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
