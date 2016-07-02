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

public class DatabaseCollectionObserver<T: DatabaseObject>
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
        self.notificationObserver = NSNotificationCenter.defaultCenter().addObserverForName(YapDatabaseModifiedNotification,
                object: self.connection.database, queue: nil,
                usingBlock: { notification in
                    dispatch.async.bg {
                        weakSelf?.handleDatabaseModifiedNotification(notification)
                    }
                })
    }

    deinit {
        // Unregister from notifications
        if let observer = self.notificationObserver {
            NSNotificationCenter.defaultCenter().removeObserver(observer)
        }
    }

// MARK: - Functions

    public weak var delegate: DatabaseCollectionObserverDelegate?

    public var callback: CallbackBlock?

    public var objects: [T]
    {
        var result: [T] = []

        let collection = self.collection

        // Read from database
        self.connection.readWithBlock { transaction in
            transaction.enumerateRowsInCollection(collection) { key, object, metadata, stop in
                if let object = (object as? T) {
                    result.append(object)
                }
            }
        }

        return result
    }

// MARK: Private Functions

    private func handleDatabaseModifiedNotification(notification: NSNotification)
    {
        let notifications = self.connection.beginLongLivedReadTransaction()
        if  notifications.isEmpty { return }

        if self.connection.hasChangeForCollection(self.collection, inNotifications: notifications)
        {
            let objects = self.objects

            dispatch.async.main { [weak self] in
                // Notify delegate
                self?.delegate?.databaseCollectionObserverDidUpdateObject()
                self?.callback?(objects)
            }
        }
    }

// MARK: Inner Types

    public typealias CallbackBlock = ([T]) -> Void

// MARK: Variables

    private let collection: String

    private let connection: YapDatabaseConnection

    private var notificationObserver: AnyObject?

}

// ----------------------------------------------------------------------------

public protocol DatabaseCollectionObserverDelegate: class
{
// MARK: - Functions

    func databaseCollectionObserverDidUpdateObject()

}

// ----------------------------------------------------------------------------
