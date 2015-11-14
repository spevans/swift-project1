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
        guard let srcLibData = MachOReader(filename: srcLib) else {
            print("Cannot parse \(srcLib)")
            exit(EXIT_FAILURE)
        }
        guard srcLibData.header.fileType == MachOReader.FileType.DYLIB  else {
            print("File is not a DYLIB, exiting")
            exit(EXIT_FAILURE)
        }
        for cmd in 0...srcLibData.header!.ncmds-1 {
            if let lcHdr : LoadCommand.LoadCommandHdr = try srcLibData.getLoadCommand(cmd) {
                if let loadCmd = LoadCommand(header: lcHdr, reader: srcLibData).parse() {
                    print("Cmd: \(cmd) loadCmd:", loadCmd.description)
                } else {
                    print("Cmd: \(cmd): \(lcHdr)")
                }
            } else {
                print("Cannot read load command header: \(cmd)")
            }
        }
    } catch {
        print("Parse Error")
        exit(EXIT_FAILURE)
    }
}


var args = Process.arguments
if (args.count > 2) {
    processDylib(args[1], destBinary:args[2])
} else {
    print("Usage: \(args[0]) srcLib destBinary")
}
