// ----------------------------------------------------------------------------
//
//  DatabaseCollection.swift
//
//  @author Denis Kolyasev <kolyasev@gmail.com>
//
// ----------------------------------------------------------------------------

public class DatabaseCollection<T: DatabaseObject>
{
// MARK: Construction

    init(name: String, database: Database)
    {
        self.name = name
        self.database = database
    }

// MARK: Properties

    let name: String

    let database: Database

// MARK: Functions: Observing

    public func observe(key: String) -> DatabaseObjectObserver<T>
    {
        let connection = self.database.database.newConnection()
        return DatabaseObjectObserver<T>(collection: self.name, key: key, connection: connection)
    }

    public func observe<V: DatabaseCollectionViewProtocol where V.Object == T>(viewType: V.Type) -> DatabaseCollectionViewObserver<V>
    {
        let view = viewType.init(collection: self.name)

        view.registerExtensionInDatabase(self.database.database)

        let connection = self.database.database.newConnection()
        return DatabaseCollectionViewObserver<V>(view: view, connection: connection)
    }

// MARK: Functions: Operations

    public func put(key: String, object: T) {
        self.database.put(collection: self.name, key: key, object: object)
    }

    public func put(entities: [(key: String, object: T)]) {
        self.database.put(collection: self.name, entities: entities.map { (key: $0.key, object: $0.object) })
    }

    public func get(key: String) -> T? {
        return self.database.get(T.self, collection: self.name, key: key)
    }

    public func get(keys: [String]) -> [String: T?] {
        return self.database.get(T.self, collection: self.name, keys: keys)
    }

    public func filterKeys(block: (String) -> Bool) -> [String] {
        return self.database.filterKeys(T.self, collection: self.name, block: block)
    }

    public func filterByKey(block: (String) -> Bool) -> [T] {
        return self.database.filterByKey(collection: self.name, block: block)
    }

    public func filter(block: (T) -> Bool) -> [T] {
        return self.database.filter(T.self, collection: self.name, block: block)
    }

    public func delete(key: String) {
        self.database.delete(T.self, collection: self.name, key: key)
    }
    
    public func delete(keys: [String]) {
        self.database.delete(T.self, collection: self.name, keys: keys)
    }

// MARK: Inner Types

    typealias ObjectType = T

}

// ----------------------------------------------------------------------------
