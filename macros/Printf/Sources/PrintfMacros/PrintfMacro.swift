import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

// MARK: - Format string analysis

private enum PrintfDiagnostic: DiagnosticMessage {
    case tooFewArguments(specifiers: Int, arguments: Int)
    case tooManyArguments(specifiers: Int, arguments: Int)

    var message: String {
        switch self {
        case .tooFewArguments(let s, let a):
            return "format has \(s) specifier\(s == 1 ? "" : "s") but only \(a) argument\(a == 1 ? "" : "s") provided"
        case .tooManyArguments(let s, let a):
            return "format has \(s) specifier\(s == 1 ? "" : "s") but \(a) argument\(a == 1 ? "" : "s") provided"
        }
    }

    var diagnosticID: MessageID {
        switch self {
        case .tooFewArguments:  MessageID(domain: "PrintfMacro", id: "tooFewArguments")
        case .tooManyArguments: MessageID(domain: "PrintfMacro", id: "tooManyArguments")
        }
    }

    var severity: DiagnosticSeverity { .error }
}

// Extracts the string value of a static-string literal expression, processing
// basic Swift escape sequences. Returns nil if the expression is not a plain
// string literal (e.g. a computed value the macro can't inspect).
private func extractStringLiteral(from expr: ExprSyntax) -> String? {
    guard let strLit = expr.as(StringLiteralExprSyntax.self) else { return nil }
    var result = ""
    for segment in strLit.segments {
        switch segment {
        case .stringSegment(let s):
            result += processEscapes(s.content.text)
        case .expressionSegment:
            // String interpolation can't appear in a StaticString anyway.
            return nil
        }
    }
    return result
}

// Translates common Swift string literal escape sequences into their character
// values. Only sequences that could affect format-specifier scanning matter here
// (i.e. we only really care that \\ becomes \ so a stray \% can't arise, but
// % is not a Swift escape so that can't happen regardless).
private func processEscapes(_ text: String) -> String {
    var result = ""
    var i = text.startIndex
    while i < text.endIndex {
        guard text[i] == "\\" else {
            result.append(text[i])
            i = text.index(after: i)
            continue
        }
        let next = text.index(after: i)
        guard next < text.endIndex else { break }
        switch text[next] {
        case "n":  result.append("\n")
        case "t":  result.append("\t")
        case "r":  result.append("\r")
        case "0":  result.append("\0")
        case "\\": result.append("\\")
        case "\"": result.append("\"")
        case "'":  result.append("'")
        default:   result.append("\\"); result.append(text[next])
        }
        i = text.index(after: next)
    }
    return result
}

// Counts the number of format specifiers in a printf format string, mirroring
// the parsing logic in _printf / dispatchPrint so the compile-time count is
// identical to what the runtime would consume. Returns nil if the string
// contains an unrecognised format character (let the runtime report that).
private func countSpecifiers(in format: String) -> Int? {
    let flags: Set<Character> = ["-", "+", " ", "#", "0"]
    let modifiers: Set<Character> = ["h", "l", "z"]
    let conversions: Set<Character> = ["d", "i", "u", "b", "o", "x", "X", "p", "c", "s"]

    var count = 0
    var i = format.startIndex
    while i < format.endIndex {
        guard format[i] == "%" else {
            i = format.index(after: i)
            continue
        }
        i = format.index(after: i)
        guard i < format.endIndex else { return nil } // trailing %
        if format[i] == "%" {
            // %% — escaped literal percent, not a specifier
            i = format.index(after: i)
            continue
        }
        // Skip flags
        while i < format.endIndex && flags.contains(format[i]) {
            i = format.index(after: i)
        }
        // Skip width digits
        while i < format.endIndex && format[i].isNumber {
            i = format.index(after: i)
        }
        // Skip precision (.digits)
        if i < format.endIndex && format[i] == "." {
            i = format.index(after: i)
            while i < format.endIndex && format[i].isNumber {
                i = format.index(after: i)
            }
        }
        // Skip length modifier
        if i < format.endIndex && modifiers.contains(format[i]) {
            i = format.index(after: i)
        }
        guard i < format.endIndex else { return nil }
        guard conversions.contains(format[i]) else { return nil }
        count += 1
        i = format.index(after: i)
    }
    return count
}

// MARK: - Macro implementations

public struct PrintfMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard let firstArg = node.arguments.first else {
            fatalError("compiler bug: the macro does not have any arguments")
        }
        let formatExpr = firstArg.expression

        let formatArg = "\(formatExpr)"
        var argExprs: [String] = []
        for argument in node.arguments.dropFirst() {
            argExprs.append("(\(argument.expression))._printfArg")
        }
        let funcName = switch node.macroName.text {
            case "printf": "_printf"
            case "sprintf": "String._sprintf"
            default: if node.macroName.text.wholeMatch(of: /[A-Za-z]+[pP]rintf/) != nil {
                "_" + node.macroName.text
            } else {
                fatalError("Unknown printf function: \(node.macroName.text)")
            }
        }

        // Compile-time argument count validation.
        if let formatStr = extractStringLiteral(from: formatExpr),
           let specCount = countSpecifiers(in: formatStr) {
            let argCount = argExprs.count
            if specCount != argCount {
                let diag: PrintfDiagnostic = specCount > argCount
                    ? .tooFewArguments(specifiers: specCount, arguments: argCount)
                    : .tooManyArguments(specifiers: specCount, arguments: argCount)
                context.diagnose(Diagnostic(node: formatExpr, message: diag))
            }
        }

        if argExprs.isEmpty {
            return "\(raw: funcName)(\(raw: formatArg))"
        }
        let argCount = argExprs.count
        let argsLiteral = argExprs.joined(separator: ", ")
        return "\(raw: funcName)(\(raw: formatArg), args: ([\(raw: argsLiteral)] as InlineArray<\(raw: argCount), _PrintfArg>).span)"
    }
}


public struct DebugMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard node.arguments.first != nil else {
            fatalError("compiler bug: the macro does not have any arguments")
        }

        let descExprs = node.arguments.enumerated().map { i, arg in
            i == 0 ? "\(arg.expression).description" : "(\(arg.expression)).description"
        }
        let count = descExprs.count
        let argsLiteral = descExprs.joined(separator: ", ")
        let funcName = "_\(node.macroName.text)"
        return "\(raw: funcName)(([\(raw: argsLiteral)] as InlineArray<\(raw: count), String>).span)"
    }
}

public struct KPrintStaticStringMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard node.arguments.first != nil else {
            fatalError("compiler bug: the macro does not have any arguments")
        }

        var positionalExprs: [String] = []
        var separatorArg: String? = nil
        var terminatorArg: String? = nil
        for arg in node.arguments {
            switch arg.label?.text {
            case "separator":  separatorArg  = "\(arg.expression)"
            case "terminator": terminatorArg = "\(arg.expression)"
            default:           positionalExprs.append("\(arg.expression)")
            }
        }

        let funcName = "_\(node.macroName.text)"
        var labeledArgs = ""
        if let s = separatorArg  { labeledArgs += ", separator: \(s)" }
        if let t = terminatorArg { labeledArgs += ", terminator: \(t)" }

        if positionalExprs.count == 1 {
            // Single StaticString — call the StaticString overload directly.
            return "\(raw: funcName)(\(raw: positionalExprs[0])\(raw: labeledArgs))"
        }

        // Multiple items — pass all as String descriptions via a Span.
        let descExprs = positionalExprs.enumerated().map { i, e in
            i == 0 ? "\(e).description" : "(\(e)).description"
        }
        let count = descExprs.count
        let argsLiteral = descExprs.joined(separator: ", ")
        return "\(raw: funcName)(([\(raw: argsLiteral)] as InlineArray<\(raw: count), String>).span\(raw: labeledArgs))"
    }
}


public struct KPrintStringMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard node.arguments.first != nil else {
            fatalError("compiler bug: the macro does not have any arguments")
        }

        var positionalExprs: [String] = []
        var separatorArg: String? = nil
        var terminatorArg: String? = nil
        for arg in node.arguments {
            switch arg.label?.text {
            case "separator":  separatorArg  = "\(arg.expression)"
            case "terminator": terminatorArg = "\(arg.expression)"
            default:           positionalExprs.append("\(arg.expression)")
            }
        }

        let funcName = "_\(node.macroName.text)"
        var labeledArgs = ""
        if let s = separatorArg  { labeledArgs += ", separator: \(s)" }
        if let t = terminatorArg { labeledArgs += ", terminator: \(t)" }

        let descExprs = positionalExprs.enumerated().map { i, e in
            i == 0 ? "\(e).description" : "(\(e)).description"
        }
        let count = descExprs.count
        let argsLiteral = descExprs.joined(separator: ", ")
        return "\(raw: funcName)(([\(raw: argsLiteral)] as InlineArray<\(raw: count), String>).span\(raw: labeledArgs))"
    }
}

@main
struct PrintfMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        PrintfMacro.self,
        DebugMacro.self,
        KPrintStaticStringMacro.self,
        KPrintStringMacro.self,
    ]
}
