/*
 * kernel/devices/acpi/amlparser.swift
 *
 * Created by Simon Evans on 05/07/2016.
 * Copyright © 2016 - 2025 Simon Evans. All rights reserved.
 *
 * AML Parser
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


    init(buffer: AMLByteBuffer) throws {
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
        print("AMLByteStream count: \(buffer.count), position: \(position)")
        hexDump(buffer: UnsafeRawBufferPointer(start: buffer.baseAddress!.advanced(by: 0),
                                               count: buffer.count))
    }

    mutating func substreamOf(length: Int) throws -> AMLByteStream {
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

    private var byteStream: AMLByteStream!
    private var currentScope: AMLNameString
    let acpiGlobalObjects: ACPI.ACPIObjectNode
    // FIXME, special handling for parsing a method is probably not needed as the namespace modifiers should be
    // done as part of execution and the top level block should be treasted as an anonymouns function
    let isParsingMethod: Bool
    // FIXME: If methods a re parsed when encountered or a context is passed around parsing
    // this can probably be removed

    init(globalObjects: ACPI.ACPIObjectNode) {
        currentScope = AMLNameString(String(AMLNameString.rootChar))
        acpiGlobalObjects = globalObjects
        isParsingMethod = false
    }


    func parse(amlCode: AMLByteBuffer) throws -> AMLTermList {
        byteStream = try AMLByteStream(buffer: amlCode)
        return try parse()
    }


    private func subParser(parsingMethod: Bool = false) throws -> AMLParser {
        //byteStream.dump()
        let curPos = byteStream.position
        let pkgLength = try parsePkgLength()
        let bytesRead = byteStream.position - curPos
        let byteCount = Int(pkgLength) - bytesRead
        let stream = try byteStream.substreamOf(length: byteCount)
        let parser = AMLParser(byteStream: stream,
                               scope: currentScope,
                               globalObjects: acpiGlobalObjects,
                               parsingMethod: parsingMethod
        )
        return parser
    }


    // Called by subParser
    init(byteStream: AMLByteStream, scope: AMLNameString,
                 globalObjects: ACPI.ACPIObjectNode, parsingMethod: Bool) {
        self.byteStream = byteStream
        self.currentScope = scope
        self.acpiGlobalObjects = globalObjects
        self.isParsingMethod = parsingMethod
    }


    private func parse() throws -> AMLTermList {
        byteStream.reset()
        return try parseTermList()
    }


    private func resolveNameToCurrentScope(path: AMLNameString) -> AMLNameString {
        return resolveNameTo(scope: currentScope, path: path)
    }


    // Package Length in bytes
    private func parsePkgLength() throws -> UInt {
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


    private func nextByte() throws -> UInt8 {
        if let byte = byteStream.nextByte() {
            return byte
        } else {
            throw AMLError.endOfStream(reason: "nextByte() returned nil")
        }
    }

    private func nextWord() throws -> UInt16 {
        let byte0 = try nextByte()
        let byte1 = try nextByte()
        return UInt16(byte0) | UInt16(byte1) << 8
    }


    private func nextDWord() throws -> UInt32 {
        let word0 = try nextWord()
        let word1 = try nextWord()
        return UInt32(word0) | UInt32(word1) << 16
    }


    private func nextQWord() throws -> UInt64 {
        let dword0 = try nextDWord()
        let dword1 = try nextDWord()
        return UInt64(dword0) | UInt64(dword1) << 32
    }


    // update currentChar and currentOpcode, returns true is there was
    // a symbol or false if end of stream
    private func nextSymbol() throws -> ParsedSymbol? {
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


    // parse funcs return, true = matched and ran ok, false = no match,
    // throw on error
    func parseTermList() throws -> AMLTermList {
        var termList: AMLTermList = []
        while let symbol = try nextSymbol() {
            do {
                let termObj = try parseTermObj(symbol: symbol)
                termList.append(termObj)
            }
        }
        return termList
    }


    private func parseFieldList(fieldFlags: AMLFieldFlags) throws -> AMLFieldList {
        var bitOffset: UInt = 0
        var fieldList: AMLFieldList = []

        var accessField = AMLAccessField(type: AMLAccessType(value: 0), attrib: 0)
        var extendedAccessField: AMLExtendedAccessField? = nil

        func parseFieldElement() throws -> (AMLNameString, AMLFieldSettings)? {
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


    private func parseTermObj(symbol: ParsedSymbol) throws -> AMLParsedItem {
        let x = try parseSymbol(symbol: symbol)
        if x.isTermObj {
            return x
        }

        let r = "\(symbol.currentOpcode?.description ?? "nil") is Invalid for termobj"
        throw AMLError.invalidSymbol(reason: r)
    }


    private func parseTermArgList(argCount: Int) throws -> AMLTermArgList {
        var termArgList: AMLTermArgList = []
        while termArgList.count < argCount {
            termArgList.append(try parseTermArg())
        }
        return termArgList
    }


    private func parseTermArg() throws -> AMLTermArg {
        guard let symbol = try nextSymbol() else {
            throw AMLError.endOfStream(reason: "parseTermArg: no nextSymbol()")
        }

        if let ch = symbol.currentChar, ch.charType != .nullChar {
            let name = try parseNameStringWith(character: ch)
            // FIXME is this needed, should .readValue on the object just work correctly?
            if try determineIfMethodOrName(name: name) {
                return try AMLTermArg(.amlMethodInvocation(parseMethodInvocation(name: name)))
            }
            return AMLTermArg(name)
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


    private func parseSuperName(symbol s: ParsedSymbol? = nil) throws -> AMLTarget {

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


    private func parseSymbol(symbol: ParsedSymbol) throws -> AMLParsedItem {
        // Check for method invocation first
        if let ch = symbol.currentChar, ch.charType != .nullChar {
            let name = try parseNameStringWith(character: ch)
            return try .type2opcode(.amlMethodInvocation(parseMethodInvocation(name: name)))
        }

        guard let opcode = symbol.currentOpcode else {
            throw(AMLError.invalidSymbol(reason: "No opcode"))
        }
        switch opcode {
            // Type1opcodes
            case .breakOp:      return .type1opcode(.amlDefBreak)
            case .breakPointOp: return .type1opcode(.amlDefBreakPoint)
            case .continueOp:   return .type1opcode(.amlDefContinue)
            case .elseOp:       return try .type1opcode(parseDefElse())
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
                let parser = try subParser(parsingMethod: isParsingMethod)
                return try .type1opcode(.amlDefWhile(parser.parseTermArg(), parser.parseTermList()))

            // Type2 opcodes
            case .acquireOp:            return try .type2opcode(.amlDefAcquire(parseSuperName(), nextWord()))
            case .addOp:                return try .type2opcode(.amlDefAdd(parseTermArg(), parseTermArg(), parseTarget()))
            case .andOp:                return try .type2opcode(.amlDefAnd(parseTermArg(), parseTermArg(), parseTarget()))
            case .bufferOp:             return try .type2opcode(.amlDefBuffer(parseDefBuffer()))
            case .concatOp:             return try .type2opcode(.amlDefConcat(parseTermArg(), parseTermArg(), parseTarget()))
            case .concatResOp:          return try .type2opcode(.amlDefConcatRes(parseTermArg(), parseTermArg(), parseTarget()))
            case .condRefOfOp:          return try .type2opcode(.amlDefCondRefOf(parseSuperName(), parseTarget()))
            case .copyObjectOp:         return try .type2opcode(parseDefCopyObject())
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
            case .loadTableOp:          return try .type2opcode(.amlDefLoadTable(parseTermArg(), parseTermArg(), parseTermArg(),
                                                                                 parseTermArg(), parseTermArg(), parseTermArg()))

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
            case .packageOp:            return try .type2opcode(.amlDefPackage(parseDefPackage()))
            case .varPackageOp:         return try .type2opcode(.amlDefPackage(parseDefVarPackage()))
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
            case .bytePrefix:           return .dataRefObject(try AMLByteConst(nextByte()))
            case .wordPrefix:           return .dataRefObject(try AMLWordConst(nextWord()))
            case .dwordPrefix:          return .dataRefObject(try AMLDWordConst(nextDWord()))
            case .qwordPrefix:          return .dataRefObject(try AMLQWordConst(nextQWord()))
            case .stringPrefix:         return try parseString()
            case .revisionOp:           return .dataRefObject(AMLRevisionOp())

            // Named objects
            case .dataRegionOp:         return .namespaceModifier(try parseDefDataRegion())
            case .deviceOp:             return .namespaceModifier(try parseDefDevice())
            case .externalOp:
                let name = try parseNameString().shortName
                let objectType = try nextByte()
                let argCount = try nextByte()

                let fullname = resolveNameTo(scope: currentScope, path: name)
                if objectType != 8 {
                    print("Ignoring External Objectype \(objectType)")
                }
                ACPI.methodArgumentCount[fullname] = Int(argCount)
                return .type1opcode(.amlDefNoop)

            case .methodOp:             return .namespaceModifier(try parseDefMethod())
            case .mutexOp:              return .namespaceModifier(try parseDefMutex())
            case .opRegionOp:           return .namespaceModifier(try parseDefOpRegion())
            case .powerResOp:           return .namespaceModifier(try parseDefPowerResource())
            case .processorOp:          return .namespaceModifier(try parseDefProcessor())
            case .thermalZoneOp:        return .namespaceModifier(try parseDefThermalZone())

            case .bankFieldOp:          return .namespaceModifier(try parseDefBankField())
            case .createBitFieldOp:     return .namespaceModifier(try parseDefCreateBitField())
            case .createByteFieldOp:    return .namespaceModifier(try parseDefCreateByteField())
            case .createDWordFieldOp:   return .namespaceModifier(try parseDefCreateDWordField())
            case .createFieldOp:        return .namespaceModifier(try parseDefCreateField())
            case .createQWordFieldOp:   return .namespaceModifier(try parseDefCreateQWordField())
            case .createWordFieldOp:    return .namespaceModifier(try parseDefCreateWordField())
            case .eventOp:              return .namespaceModifier(try parseDefEvent(name: parseNameString()))
            case .fieldOp:              return .namespaceModifier(try parseDefField())
            case .indexFieldOp:         return .namespaceModifier(try parseDefIndexField())

            // AMLDataObj
            case .zeroOp:   return .dataRefObject(AMLZeroOp())
            case .oneOp:    return .dataRefObject(AMLOneOp())
            case .onesOp:   return .dataRefObject(AMLOnesOp())

            // NameSpace Modifiers
            case .aliasOp:  return .namespaceModifier(try parseDefAlias())
            case .nameOp:   return .namespaceModifier(try parseDefName())
            case .scopeOp:  return .namespaceModifier(.defScope(try parseDefScope()))

            case .debugOp:  return .debugObj(AMLDebugObj())
            case .local0Op, .local1Op, .local2Op, .local3Op, .local4Op, .local5Op, .local6Op, .local7Op:
                return .termArg(AMLTermArg(try AMLLocalObj(localOp: opcode)))

            case .arg0Op, .arg1Op, .arg2Op, .arg3Op, .arg4Op, .arg5Op, .arg6Op:
                return .termArg(AMLTermArg(try AMLArgObj(argOp: opcode)))

            // Should already be consumed by nextSymbol()
            case .extendedOpPrefix: throw AMLError.invalidSymbol(reason: "extendedOp")
        }
    }


    private func checkForMethodInvocation(symbol: ParsedSymbol) throws -> AMLMethodInvocation? {
        if let ch = symbol.currentChar, ch.charType != .nullChar {
            let name = try parseNameStringWith(character: ch)
            return try parseMethodInvocation(name: name)
        }
        return nil
    }


    private func parseMethodInvocation(name: AMLNameString) throws -> AMLMethodInvocation {
        // TODO: Somehow validate the method at a later stage

        let fullname = resolveNameTo(scope: currentScope, path: name)
        let argCount: Int
        // FIXME: This needs to walk up the tree
        if let (_argCount, _) = walkUpFullPath(fullname, block: { name -> Int? in
            return ACPI.methodArgumentCount[AMLNameString(name)]
        }) {
            argCount = _argCount
        } else {
            guard let (node, _) = acpiGlobalObjects.getGlobalObject(currentScope: currentScope, name: name),
                  let method = node.object.methodValue else {
                let r = "No such method \(name.value) in \(currentScope.value)"
                throw AMLError.invalidMethod(reason: r)
            }
            argCount = method.flags.argCount
        }

        var args: AMLTermArgList = []
        if argCount > 0 {
            args = try parseTermArgList(argCount: argCount)
            guard args.count == argCount else {
                let r = "Method: \(name.value) has argCount of "
                    + "\(argCount) but only parsed \(args.count) args"
                throw AMLError.invalidData(reason: r)
            }
        }
        return try AMLMethodInvocation(method: name, args:  args)
    }


    private func parseString() throws -> AMLParsedItem {
        var result: String = ""
        // FIXME, simpliyfy this now that AMLString has an initialiser
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
        return .dataRefObject(AMLObject(try AMLString(result)))
    }


    func parsePackageElementList(numElements: Int?) throws -> [AMLParsedItem] {

        func parsePackageElement(_ symbol: ParsedSymbol) throws -> AMLParsedItem {
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


    // FIXME, can this go?
    private func determineIfMethodOrName(name: AMLNameString) throws -> Bool {
        if let (obj, _) = acpiGlobalObjects.getGlobalObject(currentScope: currentScope,
                                                            name: name),
           obj.object.methodValue != nil {
                return true
        }
        return false
    }

    // MARK: Parse Def
    private func parseDefPackage() throws -> AMLDefPackage {
        let parser = try subParser()
        let numElements = try parser.nextByte()
        let elements = try parser.parsePackageElementList(numElements: Int(numElements))

        return AMLDefPackage(numElements: numElements, packageElementList: elements)
    }


    private func parseDefVarPackage() throws -> AMLDefPackage {
        let parser = try subParser()
        let numElements = try parser.parseTermArg()
        let elements = try parser.parsePackageElementList(numElements: nil)
        return AMLDefPackage(varNumElements: numElements, packageElementList: elements)
    }


    private func parseDefAlias() throws -> AMLNameSpaceModifier {
        let sourceObject = try parseNameString()
        let aliasObject = try parseNameString()

        let closure = { (context: inout ACPI.AMLExecutionContext) throws -> [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)] in
            let fullname = resolveNameTo(scope: context.scope, path: sourceObject)
            guard let (node, _) = context.getObject(named: aliasObject) else {
                print("ACPI: Alias target \(aliasObject) does not exist")
                return []
            }
            return [(fullname, node, nil)]
        }
        return AMLNameSpaceModifier(name: aliasObject, closure: closure)
    }


    private func parseDefBuffer() throws -> AMLDefBuffer {
        let parser = try subParser()
        let bufSize = try parser.parseTermArg()
        let bytes = parser.byteStream.bytesToEnd()
        return AMLDefBuffer(bufferSize: bufSize, byteList: bytes)
    }


    private func parseDefName() throws -> AMLNameSpaceModifier {
        let name = try parseNameString()
        guard let symbol = try nextSymbol() else {
            throw AMLError.invalidSymbol(reason: "parseDefName")
        }
        let parsed = try parseSymbol(symbol: symbol)
        guard let objArg = parsed.termArg else {
            throw AMLError.invalidSymbol(reason: "\(symbol) is not an AMLDataRefObject")
        }

        let closure = { (context: inout ACPI.AMLExecutionContext) throws -> [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)] in
            let fullname = resolveNameTo(scope: context.scope, path: name)
            let dataRefObject = try objArg.dataRefObject(context: &context)
            let node = ACPI.ACPIObjectNode(name: name.shortName, parent: nil, object: dataRefObject)
            return [(fullname, node, nil)]
        }
        return AMLNameSpaceModifier(name: name, closure: closure)
    }


    // FIXME: Validate the location in the scope already exists. Also should DefScope
    // even exist as a type? parseDefScope has already altered the scope by the time its created.
    private func parseDefScope() throws -> AMLDefScope {
        let parser = try subParser()
        let nameString = try parser.parseNameString()
        let newScope = resolveNameToCurrentScope(path: nameString)
        parser.currentScope = newScope
        let termList = try parser.parseTermList()
        return AMLDefScope(scope: newScope, termList: termList)
    }


    private func parseDefIndexField() throws -> AMLNameSpaceModifier {
        let parser = try subParser()

        let indexName = try parser.parseNameString()
        let dataName = try parser.parseNameString()
        let flags = try AMLFieldFlags(flags: parser.nextByte())
        let fields = try parser.parseFieldList(fieldFlags: flags)

        let closure = { (context: inout ACPI.AMLExecutionContext) throws -> [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)] in
            var result: [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)] = []
            for (name, settings) in fields {
                let fullname = resolveNameTo(scope: context.scope, path: name)
                let object = AMLNamedField(name: name, indexField: indexName, dataField: dataName, fieldSettings: settings)
                let node = ACPI.ACPIObjectNode(name: name.shortName, parent: nil, object: AMLObject(object))
                result.append((fullname, node, nil))
            }
            return result
        }
        return AMLNameSpaceModifier(name: indexName, closure: closure)
    }


    private func parseDefMutex() throws -> AMLNameSpaceModifier {
        let name = try parseNameString()
        let flags = try AMLMutexFlags(flags: nextByte())

        let closure = { (context: inout ACPI.AMLExecutionContext) throws -> [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)] in
            let fullname = resolveNameTo(scope: context.scope, path: name)
            let mutex = AMLDefMutex(name: name, flags: flags)
            let node = ACPI.ACPIObjectNode(name: name.shortName, parent: nil, object: AMLObject(mutex))
            return [(fullname, node, nil)]
        }
        return AMLNameSpaceModifier(name: name, closure: closure)
    }


    private func parseDefBankField() throws -> AMLNameSpaceModifier {
        // BankFieldOp PkgLength NameString NameString BankValue FieldFlags FieldList
        let regionName = try parseNameString()
        let bankName = try parseNameString()
        let bankValue = try parseTermArg()
        let fieldFlags = try AMLFieldFlags(flags: nextByte())
        let fieldList = try parseFieldList(fieldFlags: fieldFlags)

        let closure = { (context: inout ACPI.AMLExecutionContext) throws -> [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)] in
            print("regionName: \(regionName)")
            print("bankName: \(bankName)")
            let value = try operandAsInteger(operand: bankValue, context: &context)
            print("bankValue: \(value)")
            print("fieldFlags: \(fieldFlags)")
            print("fieldList: \(fieldList)")
            fatalError("implement bank field")
        }
        return AMLNameSpaceModifier(name: regionName, closure: closure)
    }


    private func parseDefCreateBitField() throws -> AMLNameSpaceModifier {
        let sourceBuff = try parseTermArg() // => Buffer
        let bitIndex = try parseTermArg()   // => Integer
        let name = try parseNameString()

        let closure = { (context: inout ACPI.AMLExecutionContext) throws -> [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)] in
            let buffer = try operandAsBuffer(operand: sourceBuff, context: &context)
            let index = try operandAsInteger(operand: bitIndex, context: &context)
            let fullname = resolveNameTo(scope: context.scope, path: name)
            let object = try AMLBufferField(buffer: AMLSharedBuffer(buffer), bitIndex: index, bitLength: 1)
            let node = ACPI.ACPIObjectNode(name: name.shortName, parent: nil, object: AMLObject(object))
            return [(fullname, node, nil)]
        }
        return AMLNameSpaceModifier(name: name, closure: closure)
    }


    private func parseDefCreateByteField() throws -> AMLNameSpaceModifier {
        let sourceBuff = try parseTermArg()
        let byteIndex = try parseTermArg()
        let name = try parseNameString()

        let closure = { (context: inout ACPI.AMLExecutionContext) throws -> [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)] in
            let buffer = try operandAsBuffer(operand: sourceBuff, context: &context)
            let index = try operandAsInteger(operand: byteIndex, context: &context)
            let fullname = resolveNameTo(scope: context.scope, path: name)
            let object = try AMLBufferField(buffer: AMLSharedBuffer(buffer), byteIndex: index, bitLength: 8)
            let node = ACPI.ACPIObjectNode(name: name.shortName, parent: nil, object: AMLObject(object))
            return [(fullname, node, nil)]
        }
        return AMLNameSpaceModifier(name: name, closure: closure)
    }


    private func parseDefCreateWordField() throws -> AMLNameSpaceModifier {
        // CreateWordFieldOp SourceBuff ByteIndex NameString
        let sourceBuff = try parseTermArg()  // => Buffer
        let byteIndex  = try parseTermArg()  // => Integer
        let name = try parseNameString()

        let closure = { (context: inout ACPI.AMLExecutionContext) throws -> [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)] in
            let buffer = try operandAsBuffer(operand: sourceBuff, context: &context)
            let index = try operandAsInteger(operand: byteIndex, context: &context)
            let fullname = resolveNameTo(scope: context.scope, path: name)
            let object = try AMLBufferField(buffer: AMLSharedBuffer(buffer), byteIndex: index, bitLength: 16)
            let node = ACPI.ACPIObjectNode(name: name.shortName, parent: nil, object: AMLObject(object))
            return [(fullname, node, nil)]
        }
        return AMLNameSpaceModifier(name: name, closure: closure)
    }


    private func parseDefCreateDWordField() throws -> AMLNameSpaceModifier {
        // CreateDWordFieldOp SourceBuff ByteIndex NameString
        let sourceBuff = try parseTermArg()  // => Buffer
        let byteIndex  = try parseTermArg()  // => Integer
        let name = try parseNameString()

        let closure = { (context: inout ACPI.AMLExecutionContext) throws -> [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)] in
            let buffer = try operandAsBuffer(operand: sourceBuff, context: &context)
            let index = try operandAsInteger(operand: byteIndex, context: &context)
            let fullname = resolveNameTo(scope: context.scope, path: name)
            let object = try AMLBufferField(buffer: AMLSharedBuffer(buffer), byteIndex: index, bitLength: 32)
            let node = ACPI.ACPIObjectNode(name: name.shortName, parent: nil, object: AMLObject(object))
            return [(fullname, node, nil)]
        }
        return AMLNameSpaceModifier(name: name, closure: closure)
    }


    private func parseDefCreateQWordField() throws -> AMLNameSpaceModifier {
        // CreateQWordFieldOp SourceBuff ByteIndex NameString
        let sourceBuff = try parseTermArg()  // => Buffer
        let byteIndex  = try parseTermArg()  // => Integer
        let name = try parseNameString()

        let closure = {  (context: inout ACPI.AMLExecutionContext) throws -> [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)] in
            let buffer = try operandAsBuffer(operand: sourceBuff, context: &context)
            let index = try operandAsInteger(operand: byteIndex, context: &context)
            let fullname = resolveNameTo(scope: context.scope, path: name)
            let object = try AMLBufferField(buffer: AMLSharedBuffer(buffer), byteIndex: index, bitLength: 64)
            let node = ACPI.ACPIObjectNode(name: name.shortName, parent: nil, object: AMLObject(object))
            return [(fullname, node, nil)]
        }
        return AMLNameSpaceModifier(name: name, closure: closure)
    }


    private func parseDefCreateField() throws -> AMLNameSpaceModifier {
        // CreateFieldOp SourceBuff BitIndex NumBits NameString
        let sourceBuff = try parseTermArg() // => Buffer
        let bitIndex   = try parseTermArg() // => Integer
        let numBits    = try parseTermArg() // => Integer
        let name       = try parseNameString()

        let closure = {  (context: inout ACPI.AMLExecutionContext) throws -> [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)] in
            let buffer = try operandAsBuffer(operand: sourceBuff, context: &context)
            let index = try operandAsInteger(operand: bitIndex, context: &context)
            let bitLength = try operandAsInteger(operand: numBits, context: &context)
            let fullname = resolveNameTo(scope: context.scope, path: name)
            let object = try AMLBufferField(buffer: AMLSharedBuffer(buffer), bitIndex: index, bitLength: bitLength)
            let node = ACPI.ACPIObjectNode(name: name.shortName, parent: nil, object: AMLObject(object))
            return [(fullname, node, nil)]
        }
        return AMLNameSpaceModifier(name: name, closure: closure)
    }


    private func parseDefDataRegion() throws -> AMLNameSpaceModifier {
        // DataRegionOp NameString TermArg TermArg TermArg
        let regionName = try parseNameString()
        let arg1 = try parseTermArg()
        let arg2 = try parseTermArg()
        let arg3 = try parseTermArg()

        let closure = {  (context: inout ACPI.AMLExecutionContext) -> [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)] in

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


    private func parseDefDevice() throws -> AMLNameSpaceModifier {
        let parser = try subParser()
        let name = try parser.parseNameString()
        let fqn = name.isFullPath ? name : resolveNameToCurrentScope(path: name)
        // open a new scope.
        parser.currentScope = fqn
        let termList = try parser.parseTermList()

        let closure = {  (context: inout ACPI.AMLExecutionContext) -> [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)] in
            // No need to store any subobject as they get added to the tree as named objects themselves.
            let fullname = resolveNameTo(scope: context.scope, path: name)
            let dev = AMLDefDevice(name: name.shortName, value: termList)
            let node = ACPI.ACPIObjectNode(name: name.shortName, parent: nil, object: AMLObject(dev))
            return [(fullname, node, termList)]
        }
        return AMLNameSpaceModifier(name: name, closure: closure)
    }


    private func parseDefMethod() throws -> AMLNameSpaceModifier {
        let parser = try subParser(parsingMethod: true)
        let name = try parser.parseNameString()
        let fullPath = resolveNameToCurrentScope(path: name)
        parser.currentScope = fullPath
        let flags = try AMLMethodFlags(flags: parser.nextByte())

        let closure = {  (context: inout ACPI.AMLExecutionContext) -> [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)] in
            let fullname = resolveNameTo(scope: context.scope, path: name)
            let method = AMLMethod(name: name.shortName, flags: flags, parser: parser)
            let node = ACPI.ACPIObjectNode(name: name.shortName, parent: nil, object: AMLObject(method))
            return [(fullname, node, nil)]
        }
        let fullname = resolveNameTo(scope: currentScope, path: name)
        ACPI.methodArgumentCount[fullname] = flags.argCount
        return AMLNameSpaceModifier(name: name, closure: closure)
    }


    private func parseDefField() throws -> AMLNameSpaceModifier {
        // FieldOp PkgLength NameString FieldFlags FieldList
        let parser = try subParser()
        let regionName = try parser.parseNameString()
        let flags = try AMLFieldFlags(flags: parser.nextByte())
        let fields = try parser.parseFieldList(fieldFlags: flags)

        let closure = {  (context: inout ACPI.AMLExecutionContext) -> [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)] in
            var result: [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)] = []
            for (name, settings) in fields {
                let field = AMLNamedField(name: name, regionName: regionName, fieldSettings: settings)
                let fullname = resolveNameTo(scope: context.scope, path: name)
                let node = ACPI.ACPIObjectNode(name: name.shortName, parent: nil, object: AMLObject(field))
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
            let node = ACPI.ACPIObjectNode(name: name.shortName, parent: nil, object: AMLObject(event))
            return [(fullname, node, nil)]
        }
        return AMLNameSpaceModifier(name: name, closure: closure)
    }

    private func parseDefOpRegion() throws -> AMLNameSpaceModifier {
        // NameString RegionSpace RegionOffset RegionLen
        let name = try parseNameString().shortName
        let byte = try nextByte()
        guard let region = AMLRegionSpace(rawValue: byte) else {
            throw AMLError.invalidData(reason: "Bad AMLRegionSpace: \(byte)")
        }
        let offset = try parseTermArg() // => Integer
        let length = try parseTermArg() // => Integer

        let closure = {  (context: inout ACPI.AMLExecutionContext) -> [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)] in
            let fullname = resolveNameTo(scope: context.scope, path: name)
            let opRegion = AMLDefOpRegion(fullname: fullname, region: region, offset: offset, length: length)
            let node = ACPI.ACPIObjectNode(name: name.shortName, parent: nil, object: AMLObject(opRegion))
            return [(fullname, node, nil)]
        }
        return AMLNameSpaceModifier(name: name, closure: closure)
    }


    private func parseDefPowerResource() throws -> AMLNameSpaceModifier {
        let parser = try subParser()
        let name = try parser.parseNameString()
        parser.currentScope = resolveNameToCurrentScope(path: name)

        let powerResource = try AMLDefPowerResource(name: name.shortName,
                                                     systemLevel: parser.nextByte(),
                                                     resourceOrder: parser.nextWord(),
                                                     termList: parser.parseTermList())

        let closure = {  (context: inout ACPI.AMLExecutionContext) -> [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)] in
            let fullname = resolveNameTo(scope: context.scope, path: name)
            let node = ACPI.ACPIObjectNode(name: name.shortName, parent: nil, object: AMLObject(powerResource))
            return [(fullname, node, nil)]
        }
        return AMLNameSpaceModifier(name: name, closure: closure)
    }


    private func parseDefProcessor() throws -> AMLNameSpaceModifier {
        let parser = try subParser()
        let name = try parser.parseNameString()
        parser.currentScope = resolveNameToCurrentScope(path: name)

        let processor = try AMLDefProcessor(name: name.shortName,
                                            procId: parser.nextByte(),
                                            pblkAddr: parser.nextDWord(),
                                            pblkLen: parser.nextByte(),
                                            objects: parser.parseTermList())
        let closure = {  (context: inout ACPI.AMLExecutionContext) -> [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)] in
            let fullname = resolveNameTo(scope: context.scope, path: name)
            let node = ACPI.ACPIObjectNode(name: name.shortName, parent: nil, object: AMLObject(processor))
            return [(fullname, node, nil)]
        }
        return AMLNameSpaceModifier(name: name, closure: closure)
    }


    private func parseDefThermalZone() throws -> AMLNameSpaceModifier {
        let parser = try subParser()
        let name = try parser.parseNameString()
        let fqn = name.isFullPath ? name : resolveNameToCurrentScope(path: name)
        // open a new scope.
        parser.currentScope = fqn
        let termList = try parser.parseTermList()

        let closure = {  (context: inout ACPI.AMLExecutionContext) -> [(AMLNameString, ACPI.ACPIObjectNode, AMLTermList?)] in
            // No need to store any subobject as they get added to the tree as named objects themselves.
            let fullname = resolveNameTo(scope: context.scope, path: name)
            let thermalZone = AMLThermalZone(name: name.shortName, termList: termList)
            let node = ACPI.ACPIObjectNode(name: name.shortName, parent: nil, object: AMLObject(thermalZone))
            return [(fullname, node, termList)]
        }
        return AMLNameSpaceModifier(name: name, closure: closure)
    }


    private func parseDefElse() throws -> AMLType1Opcode {
        if byteStream.endOfStream() {
            return .amlDefElse(nil)
        }
        let parser = try subParser(parsingMethod: isParsingMethod)
        if parser.byteStream.endOfStream() {
            return .amlDefElse(nil)
        }
        let termList = try parser.parseTermList()
        return .amlDefElse(termList)
    }

    private func parseDefIfElse() throws -> AMLType1Opcode {
        let parser = try subParser(parsingMethod: isParsingMethod)
        let predicate = try parser.parseTermArg()
        let termList = try parser.parseTermList()
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


    private func parseDefObjectType() throws -> AMLTarget {
        //ObjectTypeOp <SimpleName | DebugObj | DefRefOf | DefDerefOf | DefIndex>

        func parseTarget(_ symbol: ParsedSymbol) throws -> AMLTarget? {
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

    private func parseDefCopyObject() throws -> AMLType2Opcode {
        let arg = try parseTermArg()
        guard let symbol = try nextSymbol() else {
            throw AMLError.endOfStream(reason: "parseDefCopyObject: end of stream")
        }
        guard let name = try parseSimpleName(symbol: symbol) else {
            throw AMLError.invalidSymbol(reason: "parseDefCopyObject expected a SimplName, not \(symbol)")
        }
        return .amlDefCopyObject(arg, name)
    }


    private func parseDefIndex() throws -> AMLDefIndex {
        return try AMLDefIndex(operand1: parseTermArg(),
                               operand2: parseTermArg(),
                               target: parseTarget())
    }


    // MARK: Name / String / Target parsing
    private func parseTarget() throws -> AMLTarget {
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
        print(symbol)
        if symbol.currentChar!.value == 0 {
            return .nullName
        }
        let r = "nextSymbol returned true but symbol: \(symbol)"
        throw AMLError.invalidSymbol(reason: r)
    }


    // Lead byte could be opcode or char
    private func parseSimpleName(symbol: ParsedSymbol) throws -> AMLTarget? {
        if let char = symbol.currentChar {
            return .nameString(try parseNameStringWith(character: char))
        }

        if let opcode = symbol.currentOpcode {
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


    private func nextChar() throws -> AMLCharSymbol {
        if let ch = try nextCharOrEOS() {
            return ch
        } else {
            throw AMLError.endOfStream(reason: "nextChar() has not next character") // End Of stream
        }
    }


    private func nextCharOrEOS() throws -> AMLCharSymbol? {
        guard let symbol = try nextSymbol() else {
            return nil // End of Stream
        }
        guard let char = symbol.currentChar else {
            let r = "next char is an opcode: \(symbol.currentOpcode?.description ?? "nil")"
            throw AMLError.invalidSymbol(reason: r)
        }
        return char
    }


    private func parseNameString() throws -> AMLNameString {
        return try parseNameStringWith(character: nextChar())
    }


    // NameString := <RootChar NamePath> | <PrefixPath NamePath>
    private func parseNameStringWith(character: AMLCharSymbol) throws -> AMLNameString {
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
    private func parseNamePath(ch: AMLCharSymbol) throws -> String {

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


    private func parseNameSeg(startingWith: String = "") throws -> String {
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


    private func parseNameSeg(_ count: UInt8, startingWith: String = "") throws -> String {
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


    private func parseNameChar(ch: AMLCharSymbol) throws -> AMLCharSymbol {
        if ch.charType == .digitChar || ch.charType == .leadNameChar {
            return ch
        }
        let r = "bad name char: 0x\(String(ch.value, radix: 16))"
        throw AMLError.invalidData(reason: r)
    }
}
