// ----------------------------------------------------------------------------
//
//  DatabaseObjectCoder.swift
//
//  @author Denis Kolyasev <kolyasev@gmail.com>
//
// ----------------------------------------------------------------------------

import Foundation

// ----------------------------------------------------------------------------

class DatabaseObjectCoder
{
// MARK: Functions

    class func serializeObject(collection: String, key: String, object: Any) -> Data
    {
        let result = NSMutableData()

        if let databaseObject = (object as? DatabaseObject)
        {
            let archiver = NSKeyedArchiver(forWritingWith: result)

            // Encode object class name
            let className = NSStringFromClass(type(of: databaseObject))
            archiver.encode(className, forKey: ArchiverKeys.ClassName)

            // Encode class version
            let classVersion = type(of: databaseObject).version
            archiver.encode(classVersion, forKey: ArchiverKeys.ClassVersion)

            // Encode object
            let dict = databaseObject.serialize()
            archiver.encode(dict, forKey: ArchiverKeys.Object)

            // Finish encoding
            archiver.finishEncoding()
        }
        else {
            fatalError("Can not serialize object of type '\(type(of: object))'.")
        }

        return result as Data
    }

    class func deserializerObject(collection: String, key: String, data: Data) -> AnyObject
    {
        var result: DatabaseObject

        // Init unarchiver for reading data
        let unarchiver = NSKeyedUnarchiver(forReadingWith: data)

        // Decode object
        if let className = (unarchiver.decodeObject(forKey: ArchiverKeys.ClassName) as? String),
           let objectClass = (NSClassFromString(className) as? DatabaseObject.Type),
           let dict = (unarchiver.decodeObject(forKey: ArchiverKeys.Object) as? [String: Any]),
           (unarchiver.decodeInteger(forKey: ArchiverKeys.ClassVersion) == objectClass.version)
        {
            result = objectClass.init(params: dict)
        }
        else {
            result = InvalidDatabaseObject()
            NSLog("Can not deserialize object from collection '\(collection)' with key '\(key)'.")
        }

        return result
    }

// MARK: Constants

    private struct ArchiverKeys
    {
        static let ClassName = "class_name"
        static let ClassVersion = "class_version"
        static let Object = "object"
    }

}

// ----------------------------------------------------------------------------
