/*
 * kernel/devices/acpi/amlparser.swift
 *
 * Created by Simon Evans on 05/07/2016.
 * Copyright © 2016 - 2025 Simon Evans. All rights reserved.
 *
 * AML Parser.
 *
 */


enum AMLParsedItem {
    case type1opcode(AMLType1Opcode)
    case type2opcode(AMLType2Opcode)
    case namespaceModifier(AMLNameSpaceModifier)
    case dataRefObject(AMLObject)
    case debugObj(AMLDebugObj)
    case termArg(AMLTermArg)

    var dataRefObject: AMLObject? {
        switch self {
            case let .dataRefObject(value): return  value
            default: return nil
        }
    }

    var isTermObj: Bool {
        switch self {
            case .type1opcode(_): return true
            case .type2opcode(_): return true
            case .namespaceModifier(_): return true
            case .termArg(_): return true
            default: return false
        }
    }

    var termArg: AMLTermArg? {
        switch self {
                //    case let .computationalData(data): return data as AMLTermArg
            case let .dataRefObject(amlValue): return AMLTermArg(amlValue)
            case let .termArg(value): return value
            case let .type2opcode(opcode): return AMLTermArg(opcode)
            default: return nil
        }
    }

    var amlTarget: AMLTarget? {
        if case let .type2opcode(opcode) = self {
            switch opcode {
                case .amlDefIndex(let index):
                    return AMLTarget.type6opcode(index.evaluator(), index.updater())
                case .amlDefDerefOf(let deRefOf):
                    return AMLTarget.type6opcode(deRefOf.evaluator(), deRefOf.updater())
                case .amlDefRefOf(let refOf):
                    return AMLTarget.type6opcode(refOf.evaluator(), refOf.updater())
                default: return nil
            }
        }
        if case let .debugObj(debugObj) = self {
            return AMLTarget.debugObj(debugObj)
        }
        else {
            return nil
        }
    }
}


struct AMLByteStream {
    private let buffer: AMLByteBuffer
    fileprivate var position = 0
    private var bytesRemaining: Int { return buffer.count - position }


    init(buffer: AMLByteBuffer) throws(AMLError) {
        guard buffer.count > 0 else {
            throw AMLError.endOfStream(reason: "Buffer count is 0")
        }
        self.buffer = buffer
    }


    mutating func reset() {
        position = 0
    }


    func endOfStream() -> Bool {
        return position == buffer.endIndex
    }


    mutating func nextByte() -> UInt8? {
        guard position < buffer.endIndex else {
            return nil
        }
        let byte = buffer[position]
        position += 1
        return byte
    }


    // get bytes in buffer from current pos to end
    mutating func bytesToEnd() -> AMLByteList {
        let bytes: AMLByteList = Array(buffer.suffix(bytesRemaining))
        position = buffer.endIndex

        return bytes
    }

    func dump() {
        #kprintf("AMLByteStream count: %d, position: %d\n", buffer.count, position)
        hexDump(buffer: UnsafeRawBufferPointer(start: buffer.baseAddress!.advanced(by: 0),
                                               count: buffer.count))
    }

    mutating func substreamOf(length: Int) throws(AMLError) -> AMLByteStream {
        guard length > 0 else {
            throw AMLError.invalidData(reason: "length < 1")
        }
        if let ba = buffer.baseAddress {
            guard length <= bytesRemaining else {
                throw AMLError.parseError
            }
            let substream = AMLByteBuffer(start: ba + position, count: length)
            position += length
            return try AMLByteStream(buffer: substream)
        }
        throw AMLError.endOfStream(reason: "buffer has nil baseAddress")
    }
}


final class AMLParser {
    private struct ParsedSymbol: CustomStringConvertible {
        var currentOpcode: AMLOpcode? = nil
        var currentChar: AMLCharSymbol? = nil
        var description: String {
            let opcodeStr = currentOpcode?.description ?? "nil"
            let charStr = currentChar?.description ?? "nil"
            return "ParsedSymbol: opcode: \(opcodeStr) char: \(charStr)"
        }
    }

    // Result from parseTermListSymbol: either a completed item or a
    // request to parse a sub-stream's term list iteratively.
    private enum ParseResult {
        case complete(AMLParsedItem)
        case needsSubTermList(subStream: AMLByteStream, newScope: AMLNameString?, continuation: TermListContinuation)
    }

    // Describes how to complete an AMLParsedItem once a sub-term-list
    // has been parsed. Each case captures the header data parsed before
    // the term list.
    private enum TermListContinuation {
        case elseOp
        case whileOp(predicate: AMLTermArg)
        case deviceOp(name: AMLNameString)
        case powerResOp(name: AMLNameString, systemLevel: UInt8, resourceOrder: UInt16)
        case processorOp(name: AMLNameString, procId: UInt8, pblkAddr: UInt32, pblkLen: UInt8)
        case thermalZoneOp(name: AMLNameString)
        case scopeOp(name: AMLNameString)
        case ifOp(predicate: AMLTermArg)
        case ifElseOp(predicate: AMLTermArg, ifTermList: AMLTermList)
    }

    // Saved state for one level of parseTermList nesting.
    private struct ParseFrame {
        let termList: AMLTermList
        let byteStream: AMLByteStream
        let scope: AMLNameString
        let continuation: TermListContinuation
    }

    private var byteStream: AMLByteStream!
    private var currentScope: AMLNameString
    let acpiGlobalObjects: ACPI.ACPIObjectNode

    init(globalObjects: ACPI.ACPIObjectNode) {
        currentScope = AMLNameString(String(AMLNameString.rootChar))
        acpiGlobalObjects = globalObjects
    }


    func parse(amlCode: AMLByteBuffer) throws(AMLError) -> AMLTermList {
        byteStream = try AMLByteStream(buffer: amlCode)
        return try parse()
    }


    // Carve out a pkg-length-delimited sub-stream from the current
    // byteStream. The parent stream's position is advanced past the
    // sub-stream bytes.
    private func createSubStream() throws(AMLError) -> AMLByteStream {
        let curPos = byteStream.position
        let pkgLength = try parsePkgLength()
        let bytesRead = byteStream.position - curPos
        let byteCount = Int(pkgLength) - bytesRead
        return try byteStream.substreamOf(length: byteCount)
    }

    // Parse a pkg-length-delimited sub-stream synchronously via a
    // closure. Used for opcodes that need a sub-stream but do NOT
    // call parseTermList() (e.g. bufferOp, packageOp, fieldOp).
    private func parseSubStream<T>(_ body: () throws(AMLError) -> T) throws(AMLError) -> T {
        let subStream = try createSubStream()
        let savedStream = byteStream!
        let savedScope = currentScope
        byteStream = subStream

        let result: T
        do {
            result = try body()
        } catch {
            byteStream = savedStream
            currentScope = savedScope
            throw error
        }
        byteStream = savedStream
        currentScope = savedScope
        return result
    }

    // Parse header bytes from a sub-stream (e.g. name, flags) without
    // consuming the remaining term-list bytes. Returns the parsed
    // header and the remaining sub-stream for iterative term-list parsing.
    private func parseSubStreamHeader<T>(_ parseHeader: () throws(AMLError) -> T) throws(AMLError) -> (T, AMLByteStream) {
        let subStream = try createSubStream()
        let savedStream = byteStream!
        byteStream = subStream
        let header: T
        do {
            header = try parseHeader()
        } catch {
            byteStream = savedStream
            throw error
        }
        let remainingStream = byteStream!
        byteStream = savedStream
        return (header, remainingStream)
    }

    // Used for methodOp deferred parsing, creates a standalone parser
    private func subParserForMethod() throws(AMLError) -> AMLParser {
        let stream = try createSubStream()
        return AMLParser(byteStream: stream,
                         scope: currentScope,
                         globalObjects: acpiGlobalObjects
        )
    }

    init(byteStream: AMLByteStream, scope: AMLNameString,
                 globalObjects: ACPI.ACPIObjectNode) {
        self.byteStream = byteStream
        self.currentScope = scope
        self.acpiGlobalObjects = globalObjects
    }


    private func parse() throws(AMLError) -> AMLTermList {
        byteStream.reset()
        return try parseTermList()
    }


    private func resolveNameToCurrentScope(path: AMLNameString) -> AMLNameString {
        return resolveNameTo(scope: currentScope, path: path)
    }


    // Package Length in bytes
    private func parsePkgLength() throws(AMLError) -> UInt {
        let leadByte = try nextByte()
        let byteCount: UInt8 = (leadByte & 0xC0) >> 6 // bits 6-7
        if byteCount == 0 {  // 1byte, length is 0-63
            let pkgLen = UInt(leadByte & 0x3f)
            return pkgLen
        }
        guard leadByte & 0x30 == 0 else {
            throw AMLError.invalidData(reason: "Bits 4,5 in PkgLength are not clear")
        }
        guard byteCount <= 3 else {
            throw AMLError.invalidData(reason: "byteCount is wrong \(byteCount)")
        }
        // bits 0-3 are lowest nibble
        var pkgLength = UInt(leadByte & 0x0f)

        for x in 0..<byteCount {
            let shift = (x * 8) + 4
            let byteData = try nextByte()
            pkgLength |= UInt(byteData) << UInt(shift)

        }
        return pkgLength
    }


    private func nextByte() throws(AMLError) -> UInt8 {
        if let byte = byteStream.nextByte() {
            return byte
        } else {
            throw AMLError.endOfStream(reason: "nextByte() returned nil")
        }
    }

    private func nextWord() throws(AMLError) -> UInt16 {
        let byte0 = try nextByte()
        let byte1 = try nextByte()
        return UInt16(byte0) | UInt16(byte1) << 8
    }


    private func nextDWord() throws(AMLError) -> UInt32 {
        let word0 = try nextWord()
        let word1 = try nextWord()
        return UInt32(word0) | UInt32(word1) << 16
    }


    private func nextQWord() throws(AMLError) -> UInt64 {
        let dword0 = try nextDWord()
        let dword1 = try nextDWord()
        return UInt64(dword0) | UInt64(dword1) << 32
    }


    // update currentChar and currentOpcode, returns true is there was
    // a symbol or false if end of stream
    private func nextSymbol() throws(AMLError) -> ParsedSymbol? {
        guard let byte = byteStream.nextByte() else {
            return nil    // end of stream
        }
        let currentChar = AMLCharSymbol(byte: byte)

        // some bytes (eg 0x00) are both chars and opcodes
        var currentOpcode: AMLOpcode? = nil // clear it now
        if let op = AMLOpcode(byte: byte) {
            if op.isTwoByteOpcode {
                if let byte2 = byteStream.nextByte() {
                    let value = UInt16(withBytes: byte2, byte)
                    currentOpcode = AMLOpcode(rawValue: value)
                    guard currentOpcode != nil else {
                        throw AMLError.invalidOpcode(value: value)
                    }
                } else {
                    // This is an error since opcode is missing 2nd byte
                    throw AMLError.endOfStream(reason: "byte2 is nil")
                }
            } else {
                currentOpcode = op
            }
        }
        if currentChar == nil && currentOpcode == nil {
            throw AMLError.invalidOpcode(value: byte)
        }
        return ParsedSymbol(currentOpcode: currentOpcode,
                            currentChar: currentChar)
    }


    // Iterative term-list parser. Uses an explicit stack instead of
    // recursion for opcodes that contain nested term lists (Device,
    // Scope, If/Else, While, Processor, PowerRes, ThermalZone).
    func parseTermList(newScope: AMLNameString? = nil) throws(AMLError) -> AMLTermList {

        if let name = newScope {
            let fqn = name.isFullPath ? name : resolveNameToCurrentScope(path: name)
            self.currentScope = fqn
        }

        var stack: [ParseFrame] = []
        var termList: AMLTermList = []

        mainLoop: while true {
            while let symbol = try nextSymbol() {
                let result = try parseTermListSymbol(symbol: symbol)
                switch result {
                case .complete(let item):
                    if item.isTermObj {
                        termList.append(item)
                    } else {
                        let r = "\(symbol.currentOpcode?.description ?? "nil") is Invalid for termobj in scope \(self.currentScope)"
                        throw AMLError.invalidSymbol(reason: r)
                    }
                case .needsSubTermList(let subStream, let subScope, let continuation):
                    // Save current state and switch to the sub-stream.
                    stack.append(ParseFrame(
                        termList: termList,
                        byteStream: byteStream,
                        scope: currentScope,
                        continuation: continuation
                    ))
                    byteStream = subStream
                    if let scope = subScope {
                        let fqn = scope.isFullPath ? scope : resolveNameToCurrentScope(path: scope)
                        currentScope = fqn
                    }
                    termList = []
                    continue mainLoop
                }
            }

            // Current stream finished, pop frame and complete the item.
            guard let frame = stack.popLast() else {
                return termList
            }
            let completedTermList = termList
            byteStream = frame.byteStream
            currentScope = frame.scope
            termList = frame.termList

            switch frame.continuation {
            case .elseOp:
                termList.append(.type1opcode(.amlDefElse(completedTermList.isEmpty ? nil : completedTermList)))

            case .whileOp(let predicate):
                termList.append(.type1opcode(.amlDefWhile(predicate, completedTermList)))

            case .deviceOp(let name):
                termList.append(.namespaceModifier(parseDefDevice(name, completedTermList)))

            case .powerResOp(let name, let systemLevel, let resourceOrder):
                termList.append(.namespaceModifier(parseDefPowerResource(name, systemLevel, resourceOrder, completedTermList)))

            case .processorOp(let name, let procId, let pblkAddr, let pblkLen):
                termList.append(.namespaceModifier(parseDefProcessor(name, procId, pblkAddr, pblkLen, completedTermList)))

            case .thermalZoneOp(let name):
                termList.append(.namespaceModifier(parseDefThermalZone(name, completedTermList)))

            case .scopeOp(let name):
                let resolvedScope = resolveNameToCurrentScope(path: name)
                termList.append(.namespaceModifier(.defScope(AMLDefScope(scope: resolvedScope, termList: completedTermList))))

            case .ifOp(let predicate):
                // If-body is done. Look ahead in parent stream for an elseOp.
                var defElse: AMLTermList? = nil
                if !byteStream.endOfStream() {
                    let curPosition = byteStream.position
                    if let symbol = try nextSymbol() {
                        if let op = symbol.currentOpcode, op == .elseOp {
                            if byteStream.endOfStream() {
                                // elseOp with empty else
                                defElse = nil
                            } else {
                                let elseSubStream = try createSubStream()
                                if elseSubStream.endOfStream() {
                                    defElse = nil
                                } else {
                                    // Push frame for else-body parsing.
                                    stack.append(ParseFrame(
                                        termList: termList,
                                        byteStream: byteStream,
                                        scope: currentScope,
                                        continuation: .ifElseOp(predicate: predicate, ifTermList: completedTermList)
                                    ))
                                    byteStream = elseSubStream
                                    termList = []
                                    continue mainLoop
                                }
                            }
                        } else {
                            byteStream.position = curPosition
                        }
                    }
                }
                termList.append(.type1opcode(.amlDefIfElse(predicate, completedTermList, defElse)))

            case .ifElseOp(let predicate, let ifTermList):
                let elseTermList = completedTermList.isEmpty ? nil : completedTermList
                termList.append(.type1opcode(.amlDefIfElse(predicate, ifTermList, elseTermList)))
            }
        }
    }


    // Intercepts the 8 opcodes that require a nested parseTermList()
    // call and returns .needsSubTermList instead of recursing.
    // All other opcodes delegate to parseSymbol() and return .complete.
    private func parseTermListSymbol(symbol: ParsedSymbol) throws(AMLError) -> ParseResult {
        guard let opcode = symbol.currentOpcode else {
            return .complete(try parseSymbol(symbol: symbol))
        }

        switch opcode {
        case .elseOp:
            if byteStream.endOfStream() {
                return .complete(.type1opcode(.amlDefElse(nil)))
            }
            let subStream = try createSubStream()
            if subStream.endOfStream() {
                return .complete(.type1opcode(.amlDefElse(nil)))
            }
            return .needsSubTermList(subStream: subStream, newScope: nil, continuation: .elseOp)

        case .whileOp:
            let (predicate, remainingStream) = try parseSubStreamHeader { () throws(AMLError) in
                try self.parseTermArg()
            }
            return .needsSubTermList(subStream: remainingStream, newScope: nil,
                                     continuation: .whileOp(predicate: predicate))

        case .ifOp:
            let (predicate, remainingStream) = try parseSubStreamHeader { () throws(AMLError) in
                try self.parseTermArg()
            }
            return .needsSubTermList(subStream: remainingStream, newScope: nil,
                                     continuation: .ifOp(predicate: predicate))

        case .deviceOp:
            let (name, remainingStream) = try parseSubStreamHeader { () throws(AMLError) in
                try self.parseNameString()
            }
            return .needsSubTermList(subStream: remainingStream, newScope: name,
                                     continuation: .deviceOp(name: name))

        case .powerResOp:
            let (header, remainingStream) = try parseSubStreamHeader { () throws(AMLError) in
                let name = try self.parseNameString()
                let systemLevel = try self.nextByte()
                let resourceOrder = try self.nextWord()
                return (name, systemLevel, resourceOrder)
            }
            return .needsSubTermList(subStream: remainingStream, newScope: header.0,
                                     continuation: .powerResOp(name: header.0, systemLevel: header.1,
                                                               resourceOrder: header.2))

        case .processorOp:
            let (header, remainingStream) = try parseSubStreamHeader { () throws(AMLError) in
                let name = try self.parseNameString()
                let procId = try self.nextByte()
                let pblkAddr = try self.nextDWord()
                let pblkLen = try self.nextByte()
                return (name, procId, pblkAddr, pblkLen)
            }
            return .needsSubTermList(subStream: remainingStream, newScope: header.0,
                                     continuation: .processorOp(name: header.0, procId: header.1,
                                                                pblkAddr: header.2, pblkLen: header.3))

        case .thermalZoneOp:
            let (name, remainingStream) = try parseSubStreamHeader { () throws(AMLError) in
                try self.parseNameString()
            }
            return .needsSubTermList(subStream: remainingStream, newScope: name,
                                     continuation: .thermalZoneOp(name: name))

        case .scopeOp:
            let (name, remainingStream) = try parseSubStreamHeader { () throws(AMLError) in
                try self.parseNameString()
            }
            return .needsSubTermList(subStream: remainingStream, newScope: name,
                                     continuation: .scopeOp(name: name))

        default:
            return .complete(try parseSymbol(symbol: symbol))
        }
    }


    private func parseFieldList(fieldFlags: AMLFieldFlags) throws(AMLError) -> AMLFieldList {
        var bitOffset: UInt = 0
        var fieldList: AMLFieldList = []

        var accessField = AMLAccessField(type: AMLAccessType(value: 0), attrib: 0)
        var extendedAccessField: AMLExtendedAccessField? = nil

        func parseFieldElement() throws(AMLError) -> (AMLNameString, AMLFieldSettings)? {
            while let byte = byteStream.nextByte() {
                switch byte {
                    case 0x00:
                        let pkgLength = try parsePkgLength()
                        bitOffset += pkgLength
                        //return AMLReservedField(pkglen: pkgLength)

                    case 0x01:
                        let type = try AMLAccessType(value: nextByte())
                        let attrib = try nextByte()
                        accessField = AMLAccessField(type: type, attrib: attrib)

                    case 0x02: //ConnectField
                        throw AMLError.unimplemented()

                    case 0x03:
                        let type = try AMLAccessType(value: nextByte())
                        guard let attrib = try AMLExtendedAccessAttrib(rawValue: nextByte()) else {
                            let r = "Bad AMLExtendedAccessAttrib byte: \(byte)"
                            throw AMLError.invalidData(reason: r)
                        }
                        let length = try AMLInteger(nextByte())
                        extendedAccessField =  AMLExtendedAccessField(type: type, attrib: attrib, length: length)
                        throw AMLError.unimplemented()

                    default:
                        if let ch = AMLCharSymbol(byte: byte), ch.charType == .leadNameChar {
                            let name = try AMLNameString(parseNameSeg(1, startingWith: String(ch.character)))
                            let bitWidth = try parsePkgLength()
                            if name == "" || name == "    " {
                                bitOffset += bitWidth
                                continue
                            }
                            let fieldSettings = AMLFieldSettings(
                                bitOffset: bitOffset,
                                bitWidth: bitWidth, // fieldRef: fieldRef,
                                fieldFlags: fieldFlags,
                                accessField: accessField,
                                extendedAccessField: extendedAccessField
                            )
                            bitOffset += bitWidth
                            return (name, fieldSettings)
                        }
                        throw AMLError.invalidData(reason: "Bad byte: \(byte)")
                }
            }
            return nil
        }

        while let element = try parseFieldElement() {
            fieldList.append(element)
            // TODO: Add in field access defaults etc
        }
        return fieldList
    }


    private func parseTermArg() throws(AMLError) -> AMLTermArg {
        guard let symbol = try nextSymbol() else {
            throw AMLError.endOfStream(reason: "parseTermArg: no nextSymbol()")
        }

        if let ch = symbol.currentChar, ch.charType != .nullChar {
            let name = try parseNameStringWith(character: ch)

            if let methodInvocation = try parseMethodInvocation(name: name) {
                return AMLTermArg(.amlMethodInvocation(methodInvocation))
            } else {
                return AMLTermArg(name)
            }
        }

        if symbol.currentOpcode != nil {
            let p = try parseSymbol(symbol: symbol)
            if let arg = p.termArg {
                return arg
            } else {
                fatalError("")
            }
        }
        let r = "Invalid for termarg: \(symbol.description)"
        throw AMLError.invalidSymbol(reason: r)
    }


    private func parseSuperName(symbol s: ParsedSymbol? = nil) throws(AMLError) -> AMLTarget {

        let s = (s != nil) ? s : try nextSymbol()
        if let symbol = s {
            if let target = try parseSimpleName(symbol: symbol) {
                return target
            }

            if let target = try parseSymbol(symbol: symbol).amlTarget {
                return target
            }
        }
        throw AMLError.invalidSymbol(reason: "Expected a SuperName")
    }


    private func parseSymbol(symbol: ParsedSymbol) throws(AMLError) -> AMLParsedItem {
        // Check for method invocation first
        if let ch = symbol.currentChar, ch.charType != .nullChar {
            let name = try parseNameStringWith(character: ch)
            if let methodInvocation = try parseMethodInvocation(name: name) {
                return .type2opcode(.amlMethodInvocation(methodInvocation))
            } else {
                throw AMLError.invalidSymbol(reason: "Cant find \(name.value) in \(currentScope.value)")
            }
        }

        guard let opcode = symbol.currentOpcode else {
            throw(AMLError.invalidSymbol(reason: "No opcode"))
        }
        switch opcode {
            // Type1opcodes
            case .breakOp:      return .type1opcode(.amlDefBreak)
            case .breakPointOp: return .type1opcode(.amlDefBreakPoint)
            case .continueOp:   return .type1opcode(.amlDefContinue)
            case .elseOp:
                if byteStream.endOfStream() {
                    return .type1opcode(.amlDefElse(nil))
                }
                let termList: AMLTermList? = try parseSubStream { () throws(AMLError) -> AMLTermList? in
                    if byteStream.endOfStream() {
                        return nil
                    }
                    return try parseTermList()
                }
                return .type1opcode(.amlDefElse(termList))

            case .fatalOp:      return try .type1opcode(.amlDefFatal(nextByte(), nextDWord(), parseTermArg()))
            case .ifOp:         return try .type1opcode(parseDefIfElse())
            case .noopOp:       return .type1opcode(.amlDefNoop)
            case .notifyOp:     return try .type1opcode(.amlDefNotify(parseSuperName(), parseTermArg()))

            case .releaseOp:    return try .type1opcode(.amlDefRelease(parseSuperName()))
            case .resetOp:      return try.type1opcode(.amlDefReset(parseSuperName()))
            case .returnOp:     return try .type1opcode(.amlDefReturn(parseTermArg()))
            case .signalOp:     return try .type1opcode(.amlDefSignal(parseSuperName()))
            case .sleepOp:      return try .type1opcode(.amlDefSleep(parseTermArg()))
            case .stallOp:      return try .type1opcode(.amlDefStall(parseTermArg()))
            case .unloadOp:     return try .type1opcode(.amlDefUnload(parseSuperName()))
            case .whileOp:
                return try .type1opcode(parseSubStream { () throws(AMLError) in
                    let predicate = try parseTermArg()
                    let termList = try parseTermList()
                    return .amlDefWhile(predicate, termList)
                })

            // Type2 opcodes
            case .acquireOp:            return try .type2opcode(.amlDefAcquire(parseSuperName(), nextWord()))
            case .addOp:                return try .type2opcode(.amlDefAdd(parseTermArg(), parseTermArg(), parseTarget()))
            case .andOp:                return try .type2opcode(.amlDefAnd(parseTermArg(), parseTermArg(), parseTarget()))
            case .bufferOp:
                return try .type2opcode(parseSubStream { () throws(AMLError) in
                    let bufSize = try parseTermArg()
                    let bytes = byteStream.bytesToEnd()
                    return .amlDefBuffer(
                        AMLDefBuffer(bufferSize: bufSize, byteList: bytes))
                })

            case .concatOp:             return try .type2opcode(.amlDefConcat(parseTermArg(), parseTermArg(), parseTarget()))
            case .concatResOp:          return try .type2opcode(.amlDefConcatRes(parseTermArg(), parseTermArg(), parseTarget()))
            case .condRefOfOp:          return try .type2opcode(.amlDefCondRefOf(parseSuperName(), parseTarget()))
            case .copyObjectOp:         return try .type2opcode(parseDefCopyObject(parseTermArg(), parseSimpleName()))
            case .decrementOp:          return try .type2opcode(.amlDefDecrement(parseSuperName()))
            case .derefOfOp:            return try .type2opcode(.amlDefDerefOf(AMLDefDerefOf(operand: parseTermArg())))
            case .divideOp:             return try .type2opcode(.amlDefDivide(parseTermArg(), parseTermArg(), parseTarget(), parseTarget()))
            case .findSetLeftBitOp:     return try .type2opcode(.amlDefFindSetLeftBit(parseTermArg(), parseTarget()))
            case .findSetRightBitOp:    return try .type2opcode(.amlDefFindSetRightBit(parseTermArg(), parseTarget()))
            case .fromBCDOp:            return try .type2opcode(.amlDefFromBCD(parseTermArg(), parseTarget()))
            case .incrementOp:          return try .type2opcode(.amlDefIncrement(parseSuperName()))
            case .indexOp:              return try .type2opcode(.amlDefIndex(parseDefIndex()))
            case .lAndOp:               return try .type2opcode(.amlDefLAnd(parseTermArg(), parseTermArg()))
            case .lEqualOp:             return try .type2opcode(.amlDefLEqual(parseTermArg(), parseTermArg()))
            case .lGreaterOp:           return try .type2opcode(.amlDefLGreater(parseTermArg(), parseTermArg()))
            case .lGreaterEqualOp:      return try .type2opcode(.amlDefLGreaterEqual(parseTermArg(), parseTermArg()))
            case .lLessOp:              return try .type2opcode(.amlDefLLess(parseTermArg(), parseTermArg()))
            case .lLessEqualOp:         return try .type2opcode(.amlDefLLessEqual(parseTermArg(), parseTermArg()))
            case .midOp:                return try .type2opcode(.amlDefMid(parseTermArg(), parseTermArg(), parseTermArg(), parseTarget()))
            case .lNotOp:               return try .type2opcode(.amlDefLNot(parseTermArg()))
            case .lNotEqualOp:          return try .type2opcode(.amlDefLNotEqual(parseTermArg(), parseTermArg()))
            case .loadOp:               return try .type2opcode(.amlDefLoad(parseNameString(), parseTarget()))
            case .loadTableOp:          return try .type2opcode(
                .amlDefLoadTable(parseTermArg(), parseTermArg(), parseTermArg(), parseTermArg(), parseTermArg(), parseTermArg()))

            case .lOrOp:                return try .type2opcode(.amlDefLOr(parseTermArg(), parseTermArg()))
            case .matchOp:              return try .type2opcode(.amlDefMatch(parseTermArg(), nextByte(), parseTermArg(),
                                                                             nextByte(), parseTermArg(), parseTermArg()))

            case .modOp:                return try .type2opcode(.amlDefMod(parseTermArg(), parseTermArg(), parseTarget()))
            case .multiplyOp:           return try .type2opcode(.amlDefMultiply(parseTermArg(), parseTermArg(), parseTarget()))
            case .nandOp:               return try .type2opcode(.amlDefNAnd(parseTermArg(), parseTermArg(), parseTarget()))
            case .norOp:                return try .type2opcode(.amlDefNOr(parseTermArg(), parseTermArg(), parseTarget()))
            case .notOp:                return try .type2opcode(.amlDefNot(parseTermArg(), parseTarget()))
            case .objectTypeOp:         return try .type2opcode(.amlDefObjectType(parseDefObjectType()))
            case .orOp:                 return try .type2opcode(.amlDefOr(parseTermArg(), parseTermArg(), parseTarget()))
            case .packageOp:
                return try .type2opcode(parseSubStream { () throws(AMLError) in
                    let numElements = try nextByte()
                    let elements = try parsePackageElementList(numElements: Int(numElements))
                    return .amlDefPackage(
                        AMLDefPackage(numElements: numElements, packageElementList: elements))
                })


            case .varPackageOp:
                return try .type2opcode(parseSubStream { () throws(AMLError) in
                    let numElements = try parseTermArg()
                    let elements = try parsePackageElementList(numElements: nil)
                    return .amlDefPackage(
                        AMLDefPackage(varNumElements: numElements, packageElementList: elements))
                })


            case .refOfOp:              return try .type2opcode(.amlDefRefOf(AMLDefRefOf(name: parseSuperName())))
            case .shiftLeftOp:          return try .type2opcode(.amlDefShiftLeft(parseTermArg(), parseTermArg(), parseTarget()))
            case .shiftRightOp:         return try .type2opcode(.amlDefShiftRight(parseTermArg(), parseTermArg(), parseTarget()))
            case .sizeOfOp:             return try .type2opcode(.amlDefSizeOf(parseSuperName()))
            case .storeOp:              return try .type2opcode(.amlDefStore(parseTermArg(), parseSuperName()))
            case .subtractOp:           return try .type2opcode(.amlDefSubtract(parseTermArg(), parseTermArg(), parseTarget()))
            case .timerOp:              return .type2opcode(.amlDefTimer)
            case .toBCDOp:              return try .type2opcode(.amlDefToBCD(parseTermArg(), parseTarget()))
            case .toBufferOp:           return try .type2opcode(.amlDefToBuffer(parseTermArg(), parseTarget()))
            case .toDecimalStringOp:    return try .type2opcode(.amlDefToDecimalString(parseTermArg(), parseTarget()))
            case .toHexStringOp:        return try .type2opcode(.amlDefToHexString(parseTermArg(), parseTarget()))
            case .toIntegerOp:          return try .type2opcode(.amlDefToInteger(parseTermArg(), parseTarget()))
            case .toStringOp:           return try .type2opcode(.amlDefToString(parseTermArg(), parseTermArg(), parseTarget()))
            case .waitOp:               return try .type2opcode(.amlDefWait(parseSuperName(), parseTermArg()))
            case .xorOp:                return try .type2opcode(.amlDefXor(parseTermArg(), parseTermArg(), parseTarget()))

            // AMLDataObject
            case .bytePrefix:           return try .dataRefObject(AMLByteConst(nextByte()))
            case .wordPrefix:           return try .dataRefObject(AMLWordConst(nextWord()))
            case .dwordPrefix:          return try .dataRefObject(AMLDWordConst(nextDWord()))
            case .qwordPrefix:          return try .dataRefObject(AMLQWordConst(nextQWord()))
            case .stringPrefix:         return try .dataRefObject(parseString())
            case .revisionOp:           return .dataRefObject(AMLRevisionOp())

            // Named objects
            case .dataRegionOp:
                return .namespaceModifier(try parseDefDataRegion(
                    parseNameString(), parseTermArg(), parseTermArg(), parseTermArg()))

            case .deviceOp:
                return try .namespaceModifier(parseSubStream { () throws(AMLError) in
                    let name = try parseNameString()
                    let termList = try parseTermList(newScope: name)
                    return parseDefDevice(name, termList)
                })

            case .externalOp:
                let fullName =  try parseNameString()
                let objectType = try nextByte()
                let argCount = try nextByte()

                let object = AMLObject(objectType, argCount)
                let node = ACPI.ACPIObjectNode(name: fullName.shortName, parent: nil, object: object)
                _ = ACPI.globalObjects.add(fullName.value, node)
                return .type1opcode(.amlDefNoop)

            // NameSpace Modifiers
            case .methodOp:
                return try .namespaceModifier(parseDefMethod(parser: subParserForMethod()))

            case .mutexOp:              return try .namespaceModifier(
                parseDefMutex(parseNameString(), nextByte()))

            case .opRegionOp:           return try .namespaceModifier(
                parseDefOpRegion(parseNameString(), nextByte(), parseTermArg(), parseTermArg()))

            case .powerResOp:
                return try .namespaceModifier(parseSubStream { () throws(AMLError) in
                    let name = try parseNameString()
                    let systemLevel = try nextByte()
                    let resourceOrder = try nextWord()
                    let termList = try parseTermList(newScope: name)
                    return parseDefPowerResource(name, systemLevel, resourceOrder, termList)
                })

            case .processorOp:
                return try .namespaceModifier(parseSubStream { () throws(AMLError) in
                    let name = try parseNameString()
                    let procId = try nextByte()
                    let pblkAddr = try nextDWord()
                    let pblkLen = try nextByte()
                    let objects = try parseTermList(newScope: name)
                    return parseDefProcessor(name, procId, pblkAddr, pblkLen, objects)
                })

            case .thermalZoneOp:
                return try .namespaceModifier(parseSubStream { () throws(AMLError) in
                    let name = try parseNameString()
                    let termList = try parseTermList(newScope: name)
                    return parseDefThermalZone(name, termList)
                })

            case .bankFieldOp:          return .namespaceModifier(try parseDefBankField(parseNameString(), parseNameString(), parseTermArg(), nextByte()))

            case .createBitFieldOp:
                return try .namespaceModifier(
                    parseDefCreateBitField(parseTermArg(), parseTermArg(), parseNameString()))

            case .createByteFieldOp:    return try .namespaceModifier(
                    parseDefCreateByteField(parseTermArg(), parseTermArg(), parseNameString()))

            case .createDWordFieldOp:   return try .namespaceModifier(
                parseDefCreateDWordField(parseTermArg(), parseTermArg(), parseNameString()))

            case .createFieldOp:        return try .namespaceModifier(
                parseDefCreateField(parseTermArg(), parseTermArg(), parseTermArg(), parseNameString()))

            case .createQWordFieldOp:   return try .namespaceModifier(
                parseDefCreateQWordField(parseTermArg(), parseTermArg(), parseNameString()))

            case .createWordFieldOp:    return try .namespaceModifier(
                parseDefCreateWordField(parseTermArg(), parseTermArg(), parseNameString()))

            case .eventOp:              return .namespaceModifier(try parseDefEvent(name: parseNameString()))
            case .fieldOp:
                return try .namespaceModifier(parseSubStream { () throws(AMLError) in
                    return try parseDefField(
                        parseNameString(),
                        parseFieldList(fieldFlags: AMLFieldFlags(flags: nextByte()))
                    )
                })

            case .indexFieldOp:
                return try .namespaceModifier(parseSubStream { () throws(AMLError) in
                    return try parseDefIndexField(
                        parseNameString(), parseNameString(),
                        parseFieldList(fieldFlags: AMLFieldFlags(flags: nextByte()))
                    )
                })

            case .aliasOp:              return try .namespaceModifier(parseDefAlias(parseNameString(), parseNameString()))
            case .nameOp:               return .namespaceModifier(try parseDefName())
            case .scopeOp:
                return try .namespaceModifier(parseSubStream { () throws(AMLError) in
                    let name = try parseNameString()
                    let termList = try parseTermList(newScope: name)
                    let newScope = resolveNameToCurrentScope(path: name)
                    return .defScope(AMLDefScope(scope: newScope, termList: termList))
                })


            // AMLDataObj
            case .zeroOp:   return .dataRefObject(AMLZeroOp())
            case .oneOp:    return .dataRefObject(AMLOneOp())
            case .onesOp:   return .dataRefObject(AMLOnesOp())

            case .debugOp:  return .debugObj(AMLDebugObj())
            case .local0Op, .local1Op, .local2Op, .local3Op, .local4Op, .local5Op, .local6Op, .local7Op:
                return .termArg(AMLTermArg(try AMLLocalObj(localOp: opcode)))

            case .arg0Op, .arg1Op, .arg2Op, .arg3Op, .arg4Op, .arg5Op, .arg6Op:
                return .termArg(AMLTermArg(try AMLArgObj(argOp: opcode)))

            // Should already be consumed by nextSymbol()
            case .extendedOpPrefix: throw AMLError.invalidSymbol(reason: "extendedOp")
        }
    }


    private func parseMethodInvocation(name: AMLNameString) throws(AMLError) -> AMLMethodInvocation? {
        // TODO: Somehow validate the method at a later stage

        guard let (node, _) = acpiGlobalObjects.getGlobalObject(currentScope: currentScope, name: name) else {
            return nil
        }

        let argCount: Int
        // Check if node is a Method or External Method
        if let method = node.object.methodValue {
            argCount = Int(method.flags.argCount)
        } else if let externalObj = node.object.externalObject, externalObj.0 == 8 {
            argCount = Int(externalObj.1)
        } else {
            return nil
        }

        var args: AMLTermArgList = []
        if argCount > 0 {
            while args.count < argCount {
                args.append(try parseTermArg())
            }

            guard args.count == argCount else {
                let r = "Method: \(name.value) has argCount of "
                    + "\(argCount) but only parsed \(args.count) args"
                throw AMLError.invalidData(reason: r)
            }
        }
        return try AMLMethodInvocation(method: name, args:  args)
    }


    private func parseString() throws(AMLError) -> AMLObject {
        var result: String = ""
        // FIXME, simplify this now that AMLString has an initialiser
        while true {
            let byte = try nextByte()
            if byte == 0x00 { // NullChar
                break
            }
            else if byte >= 0x01 && byte <= 0x7F {
                result.append(Character(UnicodeScalar(byte)))
            } else {
                throw AMLError.invalidData(reason: "Bad asciichar \(byte)")
            }
        }
        return AMLObject(AMLString(asciiString: result))
    }


    private func parsePackageElementList(numElements: Int?) throws(AMLError) -> [AMLParsedItem] {

        func parsePackageElement(_ symbol: ParsedSymbol) throws(AMLError) -> AMLParsedItem {
            if let ch = symbol.currentChar, ch.charType != .nullChar {
                let nameString = try parseNameStringWith(character: ch)
                let object = AMLObject(nameString)
                return .dataRefObject(object)
            }

            guard symbol.currentOpcode != nil else {
                throw AMLError.invalidData(reason: "No opcode or valid string found")
            }
            let parsed = try parseSymbol(symbol: symbol)
            switch parsed {
                case .dataRefObject:
                    return parsed
                case .type2opcode(let opcode):
                    switch opcode {
                        case .amlDefBuffer, .amlDefPackage:
                            return parsed
                        default:
                            break
                    }
                default: break
            }
            throw AMLError.invalidSymbol(reason: "\(symbol) is not a valid package element")
        }

        var elements: [AMLParsedItem] = []
        while let symbol = try nextSymbol() {
            let element = try parsePackageElement(symbol)
            elements.append(element)
            if let required = numElements, required == elements.count {
                // FIXME: Is it an error if the number of elements is greater then numElements?
                break
            }
        }
        return elements
    }

    private func parseDefAlias(_ sourceObject: AMLNameString, _ aliasObject: AMLNameString) throws(AMLError) -> AMLNameSpaceModifier {

        let closure = { (context: inout ACPI.AMLExecutionContext) throws(AMLError) -> [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)] in
            let fullname = resolveNameTo(scope: context.scope, path: aliasObject)
            guard let (node, _) = context.getObject(named: sourceObject) else {
                #kprint("ACPI: Alias target", aliasObject, "does not exist")
                return []
            }
            let aliasNode = ACPI.ACPIObjectNode(name: fullname.shortName, object: node.object)
            return [(fullname, aliasNode, nil)]
        }
        return AMLNameSpaceModifier(name: aliasObject, closure: closure)
    }


    private func parseDefName() throws(AMLError) -> AMLNameSpaceModifier {
        let name = try parseNameString()

        guard let symbol = try nextSymbol() else {
            throw AMLError.invalidSymbol(reason: "parseDefName")
        }
        let parsed = try parseSymbol(symbol: symbol)
        // FIXME: This should only a DataRefObject but currently some are held as type2opcodes
        // instead of .dataRefObject (but both are term args). Probably needs to better store packages
        // an other data NOT as type2opcodes.
        guard let objArg = parsed.termArg else {
            throw AMLError.invalidSymbol(reason: "\(symbol) is not an AMLDataRefObject")
        }

        let closure = { (context: inout ACPI.AMLExecutionContext) throws(AMLError) -> [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)] in
            let fullname = resolveNameTo(scope: context.scope, path: name)
            let dataRefObject = try objArg.dataRefObject(context: &context)
            let node = ACPI.ACPIObjectNode(name: fullname.shortName, parent: nil, object: dataRefObject)
            return [(fullname, node, nil)]
        }
        return AMLNameSpaceModifier(name: name, closure: closure)
    }

    private func parseDefIndexField(_ indexName: AMLNameString, _ dataName: AMLNameString,
                                    _ fields: AMLFieldList) -> AMLNameSpaceModifier {

        let closure = { (context: inout ACPI.AMLExecutionContext) throws(AMLError) -> [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)] in
            var result: [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)] = []
            for (name, settings) in fields {
                // TODO: Hoist ouside of loop
                let fullname = resolveNameTo(scope: context.scope, path: name)
                guard
                    let (indexObject, _) = context.getObject(named: indexName),
                    let (dataObject, _) = context.getObject(named: dataName) else {
                    throw AMLError.invalidSymbol(reason: "Failed to find \(indexName.value) or \(dataName.value)")
                }

                let object = AMLNamedField(name: name, indexField: indexObject, dataField: dataObject, fieldSettings: settings)
                let node = ACPI.ACPIObjectNode(name: fullname.shortName, parent: nil, object: AMLObject(object))
                result.append((fullname, node, nil))
            }
            return result
        }
        return AMLNameSpaceModifier(name: indexName, closure: closure)
    }


    private func parseDefMutex(_ name: AMLNameString, _ byte: AMLByteData) throws(AMLError) -> AMLNameSpaceModifier {
        let flags = try AMLMutexFlags(flags: byte)
        let mutex = AMLDefMutex(name: name, flags: flags)

        let closure = { (context: inout ACPI.AMLExecutionContext) throws(AMLError) -> [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)] in
            let fullname = resolveNameTo(scope: context.scope, path: name)
            let node = ACPI.ACPIObjectNode(name: fullname.shortName, parent: nil, object: AMLObject(mutex))
            return [(fullname, node, nil)]
        }
        return AMLNameSpaceModifier(name: name, closure: closure)
    }


    private func parseDefBankField(_ regionName: AMLNameString, _ bankName: AMLNameString,
                                   _ bankValue: AMLTermArg, _ byte: AMLByteData) throws(AMLError) -> AMLNameSpaceModifier {
        // BankFieldOp PkgLength NameString NameString BankValue FieldFlags FieldList
        let fieldFlags = AMLFieldFlags(flags: byte)
        let fieldList = try parseFieldList(fieldFlags: fieldFlags)

        let closure = { (context: inout ACPI.AMLExecutionContext) throws(AMLError) -> [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)] in
            #kprint("regionName:", regionName)
            #kprint("bankName:", bankName)
            let value = try operandAsInteger(operand: bankValue, context: &context)
            #kprint("bankValue:", value)
            #kprint("fieldFlags:", fieldFlags)
            #kprint("fieldList:")
            for field in fieldList {
                #kprintf("    %s: %s\n", field.0.description, field.1.description)
            }
            fatalError("implement bank field")
        }
        return AMLNameSpaceModifier(name: regionName, closure: closure)
    }


    private func parseDefCreateBitField(_ sourceBuff: AMLTermArg, _ bitIndex: AMLTermArg,
                                        _ name: AMLNameString) -> AMLNameSpaceModifier {
        let closure = { (context: inout ACPI.AMLExecutionContext) throws(AMLError) -> [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)] in
            let sharedBuffer = try operandAsSharedBuffer(operand: sourceBuff, context: &context)
            let index = try operandAsInteger(operand: bitIndex, context: &context)
            let fullname = resolveNameTo(scope: context.scope, path: name)
            let object = try AMLBufferField(buffer: sharedBuffer, bitIndex: index, bitLength: 1)
            let node = ACPI.ACPIObjectNode(name: fullname.shortName, parent: nil, object: AMLObject(object))
            return [(fullname, node, nil)]
        }
        return AMLNameSpaceModifier(name: name, closure: closure)
    }


    private func parseDefCreateByteField(_ sourceBuff: AMLTermArg, _ byteIndex: AMLTermArg, _ name: AMLNameString) -> AMLNameSpaceModifier {
        let closure = { (context: inout ACPI.AMLExecutionContext) throws(AMLError) -> [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)] in
            let sharedBuffer = try operandAsSharedBuffer(operand: sourceBuff, context: &context)
            let index = try operandAsInteger(operand: byteIndex, context: &context)
            let fullname = resolveNameTo(scope: context.scope, path: name)
            let object = try AMLBufferField(buffer: sharedBuffer, byteIndex: index, bitLength: 8)
            let node = ACPI.ACPIObjectNode(name: fullname.shortName, parent: nil, object: AMLObject(object))
            return [(fullname, node, nil)]
        }
        return AMLNameSpaceModifier(name: name, closure: closure)
    }


    private func parseDefCreateWordField(_ sourceBuff: AMLTermArg, _ byteIndex: AMLTermArg, _ name: AMLNameString) -> AMLNameSpaceModifier {
        let closure = { (context: inout ACPI.AMLExecutionContext) throws(AMLError) -> [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)] in
            let sharedBuffer = try operandAsSharedBuffer(operand: sourceBuff, context: &context)
            let index = try operandAsInteger(operand: byteIndex, context: &context)
            let fullname = resolveNameTo(scope: context.scope, path: name)
            let object = try AMLBufferField(buffer: sharedBuffer, byteIndex: index, bitLength: 16)
            let node = ACPI.ACPIObjectNode(name: fullname.shortName, parent: nil, object: AMLObject(object))
            return [(fullname, node, nil)]
        }
        return AMLNameSpaceModifier(name: name, closure: closure)
    }


    private func parseDefCreateDWordField(_ sourceBuff: AMLTermArg, _ byteIndex: AMLTermArg, _ name: AMLNameString) -> AMLNameSpaceModifier {

        let closure = { (context: inout ACPI.AMLExecutionContext) throws(AMLError) -> [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)] in
            let sharedBuffer = try operandAsSharedBuffer(operand: sourceBuff, context: &context)
            let index = try operandAsInteger(operand: byteIndex, context: &context)
            let fullname = resolveNameTo(scope: context.scope, path: name)
            let object = try AMLBufferField(buffer: sharedBuffer, byteIndex: index, bitLength: 32)
            let node = ACPI.ACPIObjectNode(name: fullname.shortName, parent: nil, object: AMLObject(object))
            return [(fullname, node, nil)]
        }
        return AMLNameSpaceModifier(name: name, closure: closure)
    }


    private func parseDefCreateQWordField(_ sourceBuff: AMLTermArg, _ byteIndex: AMLTermArg, _ name: AMLNameString) -> AMLNameSpaceModifier {

        let closure = {  (context: inout ACPI.AMLExecutionContext) throws(AMLError) -> [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)] in
            let sharedBuffer = try operandAsSharedBuffer(operand: sourceBuff, context: &context)
            let index = try operandAsInteger(operand: byteIndex, context: &context)
            let fullname = resolveNameTo(scope: context.scope, path: name)
            let object = try AMLBufferField(buffer: sharedBuffer, byteIndex: index, bitLength: 64)
            let node = ACPI.ACPIObjectNode(name: fullname.shortName, parent: nil, object: AMLObject(object))
            return [(fullname, node, nil)]
        }
        return AMLNameSpaceModifier(name: name, closure: closure)
    }


    private func parseDefCreateField(_ sourceBuff: AMLTermArg, _ bitIndex: AMLTermArg, _ numBits: AMLTermArg, _ name: AMLNameString) -> AMLNameSpaceModifier {
        // CreateFieldOp SourceBuff BitIndex NumBits NameString

        let closure = {  (context: inout ACPI.AMLExecutionContext) throws(AMLError) -> [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)] in
            let sharedBuffer = try operandAsSharedBuffer(operand: sourceBuff, context: &context)
            let index = try operandAsInteger(operand: bitIndex, context: &context)
            let bitLength = try operandAsInteger(operand: numBits, context: &context)
            let fullname = resolveNameTo(scope: context.scope, path: name)
            let object = try AMLBufferField(buffer: sharedBuffer, bitIndex: index, bitLength: bitLength)
            let node = ACPI.ACPIObjectNode(name: fullname.shortName, parent: nil, object: AMLObject(object))
            return [(fullname, node, nil)]
        }
        return AMLNameSpaceModifier(name: name, closure: closure)
    }


    private func parseDefDataRegion(_ regionName: AMLNameString, _ arg1: AMLTermArg,
                                    _ arg2: AMLTermArg, _ arg3: AMLTermArg) -> AMLNameSpaceModifier {
        // DataRegionOp NameString TermArg TermArg TermArg

        let closure = {  (context: inout ACPI.AMLExecutionContext) throws(AMLError) -> [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)] in

            let signature = try operandAsString(operand: arg1, context: &context)
            let oemId = try operandAsString(operand: arg2, context: &context)
            let oemTableId = try operandAsString(operand: arg3, context: &context)
            let dataRegion = AMLDataRegion(name: regionName,
                                           signature: signature,
                                           oemId: oemId,
                                           oemTableId: oemTableId)
            let fullname = resolveNameTo(scope: context.scope, path: regionName)

            let node = ACPI.ACPIObjectNode(name: regionName.shortName, parent: nil, object: AMLObject(dataRegion))
            return [(fullname, node, nil)]
        }
        return AMLNameSpaceModifier(name: regionName.shortName, closure: closure)
    }


    private func parseDefDevice(_ name: AMLNameString, _ termList: AMLTermList) -> AMLNameSpaceModifier {

        let dev = AMLDefDevice(name: name.shortName, value: termList)

        let closure = {  (context: inout ACPI.AMLExecutionContext) -> [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)] in
            // No need to store any subobject as they get added to the tree as named objects themselves.
            let fullname = resolveNameTo(scope: context.scope, path: name)
            let node = ACPI.ACPIObjectNode(name: fullname.shortName, parent: nil, object: AMLObject(dev))
            return [(fullname, node, termList)]
        }
        return AMLNameSpaceModifier(name: name, closure: closure)
    }


    private func parseDefMethod( parser: AMLParser) throws(AMLError) -> AMLNameSpaceModifier {
        let name = try parser.parseNameString()
        let fullPath = resolveNameToCurrentScope(path: name)
        parser.currentScope = fullPath
        let flags = try AMLMethodFlags(flags: parser.nextByte())

        let closure = {  (context: inout ACPI.AMLExecutionContext) -> [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)] in
            let fullname = resolveNameTo(scope: context.scope, path: name)
            // FIXME, can this be parsed before the closure
            let method = AMLMethod(name: name.shortName, flags: flags, parser: parser)
            let node = ACPI.ACPIObjectNode(name: fullname.shortName, parent: nil, object: AMLObject(method))
            return [(fullname, node, nil)]
        }

        let node = ACPI.ACPIObjectNode(name: fullPath.shortName, object: AMLObject(8, flags.argCount))
        _ = self.acpiGlobalObjects.add(fullPath.value, node)
        return AMLNameSpaceModifier(name: name, closure: closure)
    }


    private func parseDefField(_ regionName: AMLNameString, _ fields: AMLFieldList) -> AMLNameSpaceModifier {
        // FieldOp PkgLength NameString FieldFlags FieldList

        let closure = {  (context: inout ACPI.AMLExecutionContext) throws (AMLError) -> [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)] in
            var result: [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)] = []

            let fullRegionName = resolveNameTo(scope: context.scope, path: regionName)
            guard let (opRegion, _) = context.getObject(named: fullRegionName),
                  let region = opRegion.object.operationRegionValue else {
                throw AMLError.invalidSymbol(reason: fullRegionName.value)
            }
            for (name, settings) in fields {

                let field = AMLNamedField(name: name, opRegion: region, fieldSettings: settings)
                let fullname = resolveNameTo(scope: context.scope, path: name)
                let node = ACPI.ACPIObjectNode(name: fullname.shortName, parent: nil, object: AMLObject(field))
                result.append((fullname, node, nil))
            }
            return result
        }
        return AMLNameSpaceModifier(name: regionName, closure: closure)
    }

    private func parseDefEvent(name: AMLNameString) -> AMLNameSpaceModifier {
        let closure = {  (context: inout ACPI.AMLExecutionContext) -> [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)] in
            let fullname = resolveNameTo(scope: context.scope, path: name)
            let event = AMLEvent(name: fullname)
            let node = ACPI.ACPIObjectNode(name: fullname.shortName, parent: nil, object: AMLObject(event))
            return [(fullname, node, nil)]
        }
        return AMLNameSpaceModifier(name: name, closure: closure)
    }

    private func parseDefOpRegion(_ name: AMLNameString, _ byte: AMLByteData, _ offsetArg: AMLTermArg,
                                  _ lengthArg: AMLTermArg) throws(AMLError) -> AMLNameSpaceModifier {
        // NameString RegionSpace RegionOffset RegionLen
        let region = AMLRegionSpace(rawValue: byte)
        if case .reserved(_) = region {
            throw AMLError.invalidData(reason: "Bad AMLRegionSpace: \(byte)")
        }

        let closure = {  (context: inout ACPI.AMLExecutionContext) throws(AMLError) -> [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)] in
            let fullname = resolveNameTo(scope: context.scope, path: name)
            let opRegion = try AMLDefOpRegion(fullname: fullname, regionType: region, offset: offsetArg, length: lengthArg)
            let node = ACPI.ACPIObjectNode(name: fullname.shortName, parent: nil, object: AMLObject(opRegion))
            return [(fullname, node, nil)]
        }
        return AMLNameSpaceModifier(name: name, closure: closure)
    }


    private func parseDefPowerResource(_ name: AMLNameString, _ systemLevel: AMLByteData, _ resourceOrder: AMLWordData, _ termList: AMLTermList) -> AMLNameSpaceModifier {

        let powerResource = AMLDefPowerResource(
            name: name.shortName,
            systemLevel: systemLevel,
            resourceOrder: resourceOrder,
            termList: termList
        )

        let closure = {  (context: inout ACPI.AMLExecutionContext) -> [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)] in
            let fullname = resolveNameTo(scope: context.scope, path: name)
            let node = ACPI.ACPIObjectNode(name: fullname.shortName, parent: nil, object: AMLObject(powerResource))
            return [(fullname, node, nil)]
        }
        return AMLNameSpaceModifier(name: name, closure: closure)
    }


    private func parseDefProcessor(_ name: AMLNameString, _ procId: AMLByteData, _ pblkAddr: AMLDWordData,
                                   _ pblkLen: AMLByteData, _ objects: AMLTermList) -> AMLNameSpaceModifier {

        let processor = AMLDefProcessor(
            name: name.shortName,
            procId: procId,
            pblkAddr: pblkAddr,
            pblkLen: pblkLen,
            objects: objects
        )

        let closure = {  (context: inout ACPI.AMLExecutionContext) -> [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)] in
            let fullname = resolveNameTo(scope: context.scope, path: name)
            let node = ACPI.ACPIObjectNode(name: fullname.shortName, parent: nil, object: AMLObject(processor))
            return [(fullname, node, nil)]
        }
        return AMLNameSpaceModifier(name: name, closure: closure)
    }


    private func parseDefThermalZone(_ name: AMLNameString, _ termList: AMLTermList) -> AMLNameSpaceModifier {
        let thermalZone = AMLThermalZone(name: name.shortName, termList: termList)

        let closure = {  (context: inout ACPI.AMLExecutionContext) -> [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)] in
            // No need to store any subobject as they get added to the tree as named objects themselves.
            let fullname = resolveNameTo(scope: context.scope, path: name)
            let node = ACPI.ACPIObjectNode(name: fullname.shortName, parent: nil, object: AMLObject(thermalZone))
            return [(fullname, node, termList)]
        }
        return AMLNameSpaceModifier(name: name, closure: closure)
    }


    private func parseDefIfElse() throws(AMLError) -> AMLType1Opcode {
        let (predicate, termList) = try parseSubStream { () throws(AMLError) in
            let predicate = try parseTermArg()
            let termList = try parseTermList()
            return (predicate, termList)
        }
        var defElse: AMLTermList? = nil

        // Look ahead to see if the next opcode is an elseOp otherwise there
        // is nothing more to process in this IfElse so return an empty else block
        if !byteStream.endOfStream() {
            let curPosition = byteStream.position
            if let symbol = try nextSymbol() {
                if let op = symbol.currentOpcode, op == .elseOp {
                    let _symbol = try parseSymbol(symbol: symbol)
                    guard case let .type1opcode(opcode) = _symbol,
                case let .amlDefElse(_defElse) = opcode else {
                        fatalError("should be DefElse but got  \(symbol)")
                    }
                    defElse = _defElse
                } else {
                    byteStream.position = curPosition
                }
            }
        }
        return .amlDefIfElse(predicate, termList, defElse)
    }


    private func parseDefObjectType() throws(AMLError) -> AMLTarget {
        //ObjectTypeOp <SimpleName | DebugObj | DefRefOf | DefDerefOf | DefIndex>

        func parseTarget(_ symbol: ParsedSymbol) throws(AMLError) -> AMLTarget? {
            //NameString | ArgObj | LocalObj
            if let char = symbol.currentChar {
                return .nameString(try parseNameStringWith(character: char))
            }

            if let opcode = symbol.currentOpcode {
                switch opcode {
                    case .local0Op, .local1Op, .local2Op, .local3Op, .local4Op, .local5Op, .local6Op, .local7Op:
                        return try .localObj(AMLLocalObj(localOp: opcode))

                    case .arg0Op, .arg1Op, .arg2Op, .arg3Op, .arg4Op, .arg5Op, .arg6Op:
                        return .argObj(try AMLArgObj(argOp: opcode))

                    case .debugOp:
                        return .debugObj(AMLDebugObj())

                    case .derefOfOp:
                        let op = try AMLDefDerefOf(operand: parseTermArg())
                        return .type6opcode(op.evaluator(), op.updater())

                    case .refOfOp:
                        let op = try AMLDefRefOf(name: parseSuperName())
                        return .type6opcode(op.evaluator(), op.updater())

                    case .indexOp:
                        let op = try parseDefIndex()
                        return .type6opcode(op.evaluator(), op.updater())

                    default: break
                }
            }
            return nil // Not a SimpleName
        }

        guard let symbol = try nextSymbol(),  let target = try parseTarget(symbol) else {
            throw AMLError.invalidSymbol(reason: "Expected an AMLTarget")
        }
        return target
    }

    private func parseDefCopyObject(_ arg: AMLTermArg, _ name: AMLTarget?) throws(AMLError) -> AMLType2Opcode {
        /*
        let arg = try parseTermArg()
        guard let symbol = try nextSymbol() else {
            throw AMLError.endOfStream(reason: "parseDefCopyObject: end of stream")
        }*/
        guard let name = name else {
            throw AMLError.invalidSymbol(reason: "parseDefCopyObject expected a SimplName")
        }
        return .amlDefCopyObject(arg, name)
    }


    private func parseDefIndex() throws(AMLError) -> AMLDefIndex {
        return try AMLDefIndex(operand1: parseTermArg(),
                               operand2: parseTermArg(),
                               target: parseTarget())
    }


    // MARK: Name / String / Target parsing
    private func parseTarget() throws(AMLError) -> AMLTarget {
        guard let symbol = try nextSymbol() else {
            throw AMLError.endOfStream(reason: "parseTarget: no nextSymbol")
        }
        if symbol.currentChar?.charType == .nullChar {
            return .nullName
        }

        if let name = try? parseSuperName(symbol: symbol) {
            return name
        }

        // HACK, should not be needed, should be covered with .nullChar above
        if symbol.currentChar!.value == 0 {
            return .nullName
        }
        let r = "nextSymbol returned true but symbol: \(symbol)"
        throw AMLError.invalidSymbol(reason: r)
    }


    // Lead byte could be opcode or char
    private func parseSimpleName(symbol: ParsedSymbol? = nil) throws(AMLError) -> AMLTarget? {

        let s: ParsedSymbol
        if let symbol {
            s = symbol
        } else {
            guard let symbol = try nextSymbol() else {
                throw AMLError.endOfStream(reason: "parseSimpleName: end of stream")
            }
            s = symbol
        }
        if let char = s.currentChar {
            return .nameString(try parseNameStringWith(character: char))
        }

        if let opcode = s.currentOpcode {
            switch opcode {
                case .local0Op, .local1Op, .local2Op, .local3Op, .local4Op, .local5Op, .local6Op, .local7Op:
                    return try .localObj(AMLLocalObj(localOp: opcode))

                case .arg0Op, .arg1Op, .arg2Op, .arg3Op, .arg4Op, .arg5Op, .arg6Op:
                    return .argObj(try AMLArgObj(argOp: opcode))

                default: break
            }
        }

        return nil // Not a SimpleName
    }


    private func nextChar() throws(AMLError) -> AMLCharSymbol {
        if let ch = try nextCharOrEOS() {
            return ch
        } else {
            throw AMLError.endOfStream(reason: "nextChar() has not next character") // End Of stream
        }
    }


    private func nextCharOrEOS() throws(AMLError) -> AMLCharSymbol? {
        guard let symbol = try nextSymbol() else {
            return nil // End of Stream
        }
        guard let char = symbol.currentChar else {
            let r = "next char is an opcode: \(symbol.currentOpcode?.description ?? "nil")"
            throw AMLError.invalidSymbol(reason: r)
        }
        return char
    }


    private func parseNameString() throws(AMLError) -> AMLNameString {
        return try parseNameStringWith(character: nextChar())
    }


    // NameString := <RootChar NamePath> | <PrefixPath NamePath>
    private func parseNameStringWith(character: AMLCharSymbol) throws(AMLError) -> AMLNameString {
        var result = ""
        var ch = character
        switch ch.charType {
        case .rootChar:
            result = String(ch.character)
            ch = try nextChar()

        case .parentPrefixChar:
            var c: AMLCharSymbol? = ch
            while c != nil {
                result.append(c!.character)
                ch = try nextChar()
                c = (ch.charType == .parentPrefixChar) ? ch : nil
            }
        default: break
        }
        // result is now RootChar | PrefixChar 0+
        result += try parseNamePath(ch: ch)
        return AMLNameString(result)
    }


    // FIXME: All of the functions should return AMLString or AMLNameString, not a String
    // Namepath might start with a char or a prefix
    private func parseNamePath(ch: AMLCharSymbol) throws(AMLError) -> String {

        switch ch.charType {
        case .leadNameChar:
            return try parseNameSeg(1, startingWith: String(ch.character))

        case .dualNamePrefix:
            return try parseNameSeg(2)

        case .multiNamePrefix:
            let segCount = try nextByte()
            guard segCount != 0 else {
                throw AMLError.invalidData(reason: "segCount cannot be 0")
            }
            return try parseNameSeg(segCount)

        case .nullChar:
            return "" // fixme should be nullname
            //return AMLNullName

        default:
            let r = "Bad char \(ch.description)"
            throw AMLError.invalidData(reason: r)
        }
    }


    private func parseNameSeg(startingWith: String = "") throws(AMLError) -> String {
        var name = startingWith

        if let ch = try nextCharOrEOS() {
            if name == "" {
                guard ch.charType == .leadNameChar else {
                    let r = "Expected .leadNameChar but char was \(ch)"
                    throw AMLError.invalidSymbol(reason: r)
                }
            }
            name.append(ch.character)
            let nameLen = name.count
            for _ in nameLen...3 {
                if let currentChar = try nextCharOrEOS() {
                    let ch = try parseNameChar(ch: currentChar)
                    name.append(ch.character)
                }
            }
            // Strip trailing '_' padding characters
            while let e = name.last, e == "_" {
                name.remove(at: name.index(before: name.endIndex))
            }
        }
        // FIXME: This is a hack to work around the fact that String.remove(at:)
        // will return allocated UTF8 string even if the source was an ASCII SSO
        // which causes problems with Unicode normalisation later on.
        var name2 = ""
        for ch in name { name2 += String(ch) }
        return name2
    }


    private func parseNameSeg(_ count: UInt8, startingWith: String = "") throws(AMLError) -> String {
        let pathSeperator = "."

        guard count > 0 else {
            throw AMLError.invalidData(reason: "Name paths has 0 segments")
        }
        var name = try parseNameSeg(startingWith: startingWith)
        for _ in 1..<count {
            name += pathSeperator
            name += try parseNameSeg()
        }
        return name
    }


    private func parseNameChar(ch: AMLCharSymbol) throws(AMLError) -> AMLCharSymbol {
        if ch.charType == .digitChar || ch.charType == .leadNameChar {
            return ch
        }
        let r = "bad name char: 0x\(String(ch.value, radix: 16))"
        throw AMLError.invalidData(reason: r)
    }
}
