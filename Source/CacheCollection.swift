// ----------------------------------------------------------------------------
//
//  CacheCollection.swift
//
//  @author Denis Kolyasev <kolyasev@gmail.com>
//
// ----------------------------------------------------------------------------

public class CacheCollection<T: CacheObject>
{
// MARK: Construction

    init(name: String, cache: Cache)
    {
        self.name = name
        self.cache = cache
    }

// MARK: Properties

    let name: String

    let cache: Cache

// MARK: Functions: Observing

    public func observe(key: String) -> CacheObjectObserver<T>
    {
        let connection = self.cache.database.newConnection()
        return CacheObjectObserver<T>(collection: self.name, key: key, connection: connection)
    }

    public func observe<V: CacheCollectionViewProtocol where V.Object == T>(viewType: V.Type) -> CacheCollectionViewObserver<V>
    {
        let view = viewType.init(collection: self.name)

        view.registerExtensionInDatabase(self.cache.database)

        let connection = self.cache.database.newConnection()
        return CacheCollectionViewObserver<V>(view: view, connection: connection)
    }

// MARK: Functions: Cache

    public func put(key: String, object: T) {
        self.cache.put(collection: self.name, key: key, object: object)
    }

    public func put(entities: [(key: String, object: T)]) {
        self.cache.put(collection: self.name, entities: entities.map { (key: $0.key, object: $0.object) })
    }

    public func get(key: String) -> T? {
        return self.cache.get(T.self, collection: self.name, key: key)
    }

    public func get(keys: [String]) -> [String: T?] {
        return self.cache.get(T.self, collection: self.name, keys: keys)
    }

    public func filterKeys(block: (String) -> Bool) -> [String] {
        return self.cache.filterKeys(T.self, collection: self.name, block: block)
    }

    public func filterByKey(block: (String) -> Bool) -> [T] {
        return self.cache.filterByKey(collection: self.name, block: block)
    }

    public func filter(block: (T) -> Bool) -> [T] {
        return self.cache.filter(T.self, collection: self.name, block: block)
    }

    public func delete(key: String) {
        self.cache.delete(T.self, collection: self.name, key: key)
    }
    
    public func delete(keys: [String]) {
        self.cache.delete(T.self, collection: self.name, keys: keys)
    }

// MARK: Inner Types

    typealias ObjectType = T

}

// ----------------------------------------------------------------------------
