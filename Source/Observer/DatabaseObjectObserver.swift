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

open class DatabaseObjectObserver<T: DatabaseObject>
{
// MARK: Construction

    init(collection: String, key: String, connection: YapDatabaseConnection)
    {
        // Init instance variables
        self.collection = collection
        self.key = key
        self.connection = connection

        // Create new long lived transaction
        self.connection.beginLongLivedReadTransaction()

        // Register for notifications
        weak var weakSelf = self
        self.notificationObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.YapDatabaseModified,
                object: self.connection.database, queue: nil,
                using: { notification in
                    dispatch.async.bg {
                        weakSelf?.handleDatabaseModifiedNotification(notification)
                    }
                })
    }

    deinit {
        // Unregister from notifications
        if let observer = self.notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

// MARK: Properties

    open weak var delegate: DatabaseObjectObserverDelegate?

    open var callback: CallbackBlock?

    open var object: T?
    {
        var result: T?

        let collection = self.collection
        let key = self.key

        // Read from database
        self.connection.read { transaction in
            result = transaction.object(forKey: key, inCollection: collection) as? T
        }

        return result
    }

// MARK: Private Functions

    fileprivate func handleDatabaseModifiedNotification(_ notification: Notification)
    {
        let notifications = self.connection.beginLongLivedReadTransaction()
        if  notifications.isEmpty { return }

        if self.connection.hasChange(forKey: self.key, inCollection: self.collection, in: notifications)
        {
            dispatch.async.main { [weak self] in
                // Notify delegate
                self?.delegate?.databaseObjectObserverDidUpdateObject()
                self?.callback?(self?.object)
            }
        }
    }

// MARK: Inner Types

    public typealias CallbackBlock = (T?) -> Void

// MARK: Variables

    fileprivate let collection: String

    fileprivate let key: String

    fileprivate let connection: YapDatabaseConnection

    fileprivate var notificationObserver: AnyObject?

}

// ----------------------------------------------------------------------------

public protocol DatabaseObjectObserverDelegate: class
{
// MARK: - Functions

    func databaseObjectObserverDidUpdateObject()

}

// ----------------------------------------------------------------------------
