// ----------------------------------------------------------------------------
//
//  InvalidDatabaseObject.swift
//
//  @author Denis Kolyasev <kolyasev@gmail.com>
//
// ----------------------------------------------------------------------------

class InvalidDatabaseObject: DatabaseObject
{
// MARK: Construction

    init() {}

    required init(params: [String: AnyObject]) {
        fatalError()
    }

// MARK: Properties

    static var version: Int { return Int() }

    var hash: Int { return Int() }

// MARK: Functions

    func serialize() -> [String: AnyObject] {
        fatalError()
    }

}

// ----------------------------------------------------------------------------
