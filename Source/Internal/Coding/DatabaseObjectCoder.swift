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

    class func serializeObject(collection: String, key: String, object: AnyObject) -> NSData
    {
        let result = NSMutableData()

        if let DatabaseObject = (object as? DatabaseObject)
        {
            let archiver = NSKeyedArchiver(forWritingWithMutableData: result)

            // Encode object class name
            let className = NSStringFromClass(object.dynamicType)
            archiver.encodeObject(className, forKey: ArchiverKeys.ClassName)

            // Encode class version
            let classVersion = DatabaseObject.dynamicType.version
            archiver.encodeInteger(classVersion, forKey: ArchiverKeys.ClassVersion)

            // Encode object
            let dict = DatabaseObject.serialize()
            archiver.encodeObject(dict, forKey: ArchiverKeys.Object)

            // Finish encoding
            archiver.finishEncoding()
        }
        else {
            fatalError("Can not serialize object of type '\(object.dynamicType)'.")
        }

        return result
    }

    class func deserializerObject(collection: String, key: String, data: NSData) -> AnyObject
    {
        var result: DatabaseObject

        // Init unarchiver for reading data
        let unarchiver = NSKeyedUnarchiver(forReadingWithData: data)

        // Decode object
        if let className = (unarchiver.decodeObjectForKey(ArchiverKeys.ClassName) as? String),
           let objectClass = (NSClassFromString(className) as? DatabaseObject.Type),
           let dict = (unarchiver.decodeObjectForKey(ArchiverKeys.Object) as? [String: AnyObject])
           where (unarchiver.decodeIntegerForKey(ArchiverKeys.ClassVersion) == objectClass.version)
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
