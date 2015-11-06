//
//  main.swift
//  static_linker
//
//  Created by Simon Evans on 03/11/2015.
//  Copyright © 2015 Simon Evans. All rights reserved.
//

import Foundation


func processDylib(srcLib: String, destBinary: String)
{
    print("Converting \(srcLib) to \(destBinary)")
    do {
        let srcLibData = try MachOReader(filename: srcLib)
        if srcLibData.header!.fileType != MachOReader.FileType.DYLIB {
            print("File is not a DYLIB, exiting")
            return
        }
        for cmd in 0...srcLibData.header!.ncmds-1 {
            if let lcHdr : LoadCommand.LoadCommandHdr = try srcLibData.getLoadCommand(cmd) {
                print("Cmd: \(cmd): \(lcHdr)")
                if let loadCmd = LoadCommand(header: lcHdr, reader: srcLibData).parse() {
                    print("Cmd: \(cmd) loadCmd:", loadCmd.description)
                }
            } else {
                print("Cannot read load command header: \(cmd)")
            }
        }
    } catch {
        print("Error")
    }
}


var args = Process.arguments
if (args.count > 2) {
    processDylib(args[1], destBinary:args[2])
} else {
    print("Usage: \(args[0]) srcLib destBinary")
}



