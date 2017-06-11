// ----------------------------------------------------------------------------
//
//  DatabaseCollectionObserver.swift
//
//  @author Denis Kolyasev <kolyasev@gmail.com>
//
// ----------------------------------------------------------------------------

import Foundation
import YapDatabase

// ----------------------------------------------------------------------------

open class DatabaseCollectionObserver<T: DatabaseObject>
{
// MARK: Construction

    init(collection: String, connection: YapDatabaseConnection)
    {
        // Init instance variables
        self.collection = collection
        self.connection = connection

        // Create new long lived transaction
        self.connection.beginLongLivedReadTransaction()

        // Register for notifications
        weak var weakSelf = self
        self.notificationObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.YapDatabaseModified,
                object: self.connection.database, queue: nil,
                using: { notification in
                    DispatchQueue.global().async {
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

// MARK: - Functions

    open weak var delegate: DatabaseCollectionObserverDelegate?

    open var callback: CallbackBlock?

    open var objects: [T]
    {
        var result: [T] = []

        let collection = self.collection

        // Read from database
        self.connection.read { transaction in
            transaction.enumerateRows(inCollection: collection) { key, object, metadata, stop in
                if let object = (object as? T) {
                    result.append(object)
                }
            }
        }

        return result
    }

// MARK: Private Functions

    fileprivate func handleDatabaseModifiedNotification(_ notification: Notification)
    {
        let notifications = self.connection.beginLongLivedReadTransaction()
        if  notifications.isEmpty { return }

        if self.connection.hasChange(forCollection: self.collection, in: notifications)
        {
            let objects = self.objects

            DispatchQueue.main.async { [weak self] in
                // Notify delegate
                self?.delegate?.databaseCollectionObserverDidUpdateObject()
                self?.callback?(objects)
            }
        }
    }

// MARK: Inner Types

    public typealias CallbackBlock = ([T]) -> Void

// MARK: Variables

    fileprivate let collection: String

    fileprivate let connection: YapDatabaseConnection

    fileprivate var notificationObserver: AnyObject?

}

// ----------------------------------------------------------------------------

public protocol DatabaseCollectionObserverDelegate: class
{
// MARK: - Functions

    func databaseCollectionObserverDidUpdateObject()

}

// ----------------------------------------------------------------------------
