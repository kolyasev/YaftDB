// ----------------------------------------------------------------------------
//
//  DatabaseObject.swift
//
//  @author Denis Kolyasev <kolyasev@gmail.com>
//
// ----------------------------------------------------------------------------

public protocol DatabaseObject: class
{
// MARK: Construction

    init(params: [String: AnyObject])

// MARK: Properties

    static var version: Int { get }

    var hash: Int { get }

// MARK: Functions

    func serialize() -> [String: AnyObject]

}

// ----------------------------------------------------------------------------
