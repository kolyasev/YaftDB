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

open class DatabaseCollectionViewObserver<V: DatabaseCollectionViewProtocol> where V.Grouping: RawRepresentable, V.Grouping.RawValue == String
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
        let allGroups = type(of: view).allGroups().map{ $0.rawValue }
        self.mappings = YapDatabaseViewMappings(groups: allGroups, view: self.view.name())

        // Register for notifications
        weak var weakSelf = self
        self.notificationObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.YapDatabaseModified,
                object: self.connection.database, queue: nil,
                using: { notification in
                    dispatch.async.bg {
                        weakSelf?.handleDatabaseModifiedNotification(notification)
                    }
                })

        // Update mappings
        self.connection.read { transaction in
            weakSelf?.mappings.update(with: transaction)
        }
    }

    deinit {
        // Unregister from notifications
        if let observer = self.notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

// MARK: Properties

    open weak var delegate: DatabaseCollectionViewObserverDelegate?

    open var onBeginUpdates: OnBeginUpdatesCallback?

    open var onChange: OnChangeCallback?

    open var onEndUpdates: OnEndUpdatesCallback?

// MARK: Functions

    open func numberOfGroups() -> Int {
        return self.mappings.allGroups.count
    }

    open func numberOfObjectsInGroup(_ group: G) -> Int {
        return Int(self.mappings.numberOfItems(inGroup: group.rawValue))
    }

    open func objectInGroup(_ group: G, atIndex index: Int) -> T!
    {
        let section = mappings.section(forGroup: group.rawValue)
        return objectInSection(Int(section), atIndex: index)
    }

    open func allObjectsInGroup(_ group: G) -> [T]
    {
        var result: [T] = []

        let viewName = self.view.name()

        self.connection.read { transaction in
            if let viewTransactions = (transaction.ext(viewName) as? YapDatabaseViewTransaction)
            {
                viewTransactions.enumerateRows(inGroup: group.rawValue, with: [], using: { collection, key, object, metadata, idx, stop in
                    if let object = (object as? T) {
                        result.append(object)
                    }
                })
            }
        }

        return result
    }

// MARK: Functions: Section Helpers

    open func numberOfSections() -> Int {
        return Int(self.mappings.numberOfSections())
    }

    open func numberOfObjectsInSection(_ section: Int) -> Int {
        return Int(self.mappings.numberOfItems(inSection: UInt(section)))
    }

    open func objectInSection(_ section: Int, atIndex index: Int) -> T!
    {
        var result: T!

        let viewName = self.view.name()
        let mappings = self.mappings

        self.connection.read { transaction in
            if let viewTransactions = (transaction.ext(viewName) as? YapDatabaseViewTransaction)
            {
                result = viewTransactions.object(atRow: UInt(index), inSection: UInt(section), with: mappings) as? T
            }
        }

        return result
    }

// MARK: Private Functions

    fileprivate func handleDatabaseModifiedNotification(_ notification: Notification)
    {
        weak var weakSelf = self

        let notifications = self.connection.beginLongLivedReadTransaction()
        if  notifications.isEmpty { return }

        var sectionChanges: NSArray?
        var rowChanges: NSArray?

        self.databaseViewConnection().getSectionChanges(&sectionChanges!, rowChanges: &rowChanges!,
                for: notifications, with: self.mappings)

        if let rowChanges = (rowChanges as? [YapDatabaseViewRowChange]), !(rowChanges.isEmpty)
        {
            dispatch.sync.main {
                // Notify delegate
                weakSelf?.delegate?.databaseCollectionViewObserverBeginUpdates()
                weakSelf?.onBeginUpdates?()
            }

            for rowChange in rowChanges
            {
                let change = DatabaseCollectionViewChange(rowChange: rowChange)

                dispatch.sync.main {
                    // Notify delegate
                    weakSelf?.delegate?.databaseCollectionViewObserverDidChange(change)
                    weakSelf?.onChange?(change)
                }
            }

            dispatch.sync.main {
                // Notify delegate
                weakSelf?.delegate?.databaseCollectionViewObserverEndUpdates()
                weakSelf?.onEndUpdates?()
            }
        }
    }

    fileprivate func databaseViewConnection() -> YapDatabaseViewConnection {
        return self.connection.ext(self.view.name()) as! YapDatabaseViewConnection
    }

// MARK: Inner Types

    typealias T = V.Object

    typealias G = V.Grouping

    public typealias OnBeginUpdatesCallback = () -> Void

    public typealias OnChangeCallback = (_ change: DatabaseCollectionViewChange) -> Void

    public typealias OnEndUpdatesCallback = () -> Void

// MARK: Variables

    fileprivate let view: V

    fileprivate let connection: YapDatabaseConnection

    fileprivate let mappings: YapDatabaseViewMappings

    fileprivate var notificationObserver: AnyObject?

}

// ----------------------------------------------------------------------------

public protocol DatabaseCollectionViewObserverDelegate: class
{
// MARK: Functions

    func databaseCollectionViewObserverBeginUpdates()

    func databaseCollectionViewObserverDidChange(_ change: DatabaseCollectionViewChange)

    func databaseCollectionViewObserverEndUpdates()

}

// ----------------------------------------------------------------------------
// Default implementation for DatabaseCollectionViewObserverDelegate
// ----------------------------------------------------------------------------

public extension DatabaseCollectionViewObserverDelegate
{
// MARK: Functions

    public func databaseCollectionViewObserverBeginUpdates() {}

    public func databaseCollectionViewObserverDidChange(_ change: DatabaseCollectionViewChange) {}

    public func databaseCollectionViewObserverEndUpdates() {}

}

// ----------------------------------------------------------------------------

open class DatabaseCollectionViewChange
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

    open let indexPath: IndexPath

    open let newIndexPath: IndexPath

    open let type: DatabaseCollectionViewChangeType

}

// ----------------------------------------------------------------------------

public enum DatabaseCollectionViewChangeType
{
// MARK: Construction

    init(type: YapDatabaseViewChangeType)
    {
        switch type
        {
            case .insert: self = .insert
            case .delete: self = .delete
            case .move:   self = .move
            case .update: self = .update
        }
    }

// MARK: Cases

    case insert
    case delete
    case move
    case update

}

// ----------------------------------------------------------------------------
