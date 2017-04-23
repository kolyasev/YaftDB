// ----------------------------------------------------------------------------
//
//  DatabaseObjectMetadata.swift
//
//  @author Denis Kolyasev <kolyasev@gmail.com>
//
// ----------------------------------------------------------------------------

import Foundation

// ----------------------------------------------------------------------------

class DatabaseObjectMetadata
{
// MARK: Construction

    init(hash: Int, timestamp: Date = Date())
    {
        // Init instance variables
        self.hash = hash
        self.timestamp = timestamp
    }

// MARK: Properties

    let hash: Int

    let timestamp: Date

}

// ----------------------------------------------------------------------------
