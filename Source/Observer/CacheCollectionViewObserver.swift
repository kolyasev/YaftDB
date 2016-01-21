// ----------------------------------------------------------------------------
//
//  CacheObjectObserver.swift
//
//  @author Denis Kolyasev <kolyasev@gmail.com>
//
// ----------------------------------------------------------------------------

import Foundation
import YapDatabase

// ----------------------------------------------------------------------------

public class CacheCollectionViewObserver<V: CacheCollectionViewProtocol>
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

    public weak var delegate: CacheCollectionViewDelegate?

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

        // Done
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
            self.delegate?.cacheCollectionViewBeginUpdates()

            for rowChange in rowChanges
            {
                let changeType = CacheCollectionViewChangeType(type: rowChange.type)
                let index = Int(rowChange.originalIndex)
                let newIndex = Int(rowChange.finalIndex)
                let change = CacheCollectionViewChange(index: index, newIndex: newIndex, changeType: changeType)

                // Notify delegate
                self.delegate?.cacheCollectionViewDidChange(change)
            }

            // Notify delegate
            self.delegate?.cacheCollectionViewEndUpdates()
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

public protocol CacheCollectionViewDelegate: class
{
// MARK: Functions

    func cacheCollectionViewBeginUpdates()

    func cacheCollectionViewDidChange(change: CacheCollectionViewChange)

    func cacheCollectionViewEndUpdates()

}

// ----------------------------------------------------------------------------

public class CacheCollectionViewChange
{
// MARK: Construction

    init(index: Int, newIndex: Int, changeType: CacheCollectionViewChangeType)
    {
        // Init instance variables
        self.index = index
        self.newIndex = newIndex
        self.type = changeType
    }

// MARK: Properties

    public let index: Int

    public let newIndex: Int

    public let type: CacheCollectionViewChangeType

}

// ----------------------------------------------------------------------------

public enum CacheCollectionViewChangeType
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
