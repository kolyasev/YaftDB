// ----------------------------------------------------------------------------
//
//  Database.swift
//
//  @author Denis Kolyasev <kolyasev@gmail.com>
//
// ----------------------------------------------------------------------------

import YapDatabase

// ----------------------------------------------------------------------------

open class Database
{
// MARK: - Construction

    public init(path: String)
    {
        // Init instance variables
        self.database = YapDatabase(path: path,
                objectSerializer: DatabaseObjectCoder.serializeObject,
                objectDeserializer: DatabaseObjectCoder.deserializerObject,
                metadataSerializer: DatabaseObjectMetadataCoder.serializeMetadata,
                metadataDeserializer: DatabaseObjectMetadataCoder.deserializerMetadata)
        self.connection = self.database.newConnection()
    }

// MARK: - Properties

    let database: YapDatabase

    let connection: YapDatabaseConnection

// MARK: - Public Functions

    open func collection<T>(_ type: T.Type = T.self, name: String) -> DatabaseCollection<T> {
        return DatabaseCollection<T>(name: name, database: self)
    }

}

// ----------------------------------------------------------------------------
