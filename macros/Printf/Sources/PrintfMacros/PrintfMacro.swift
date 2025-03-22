import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Implementation of the `printf` macro, which takes an expression
/// of any type and produces a tuple containing the value of that expression
/// and the source code that produced the value. For example
///
///     #stringify(x + y)
///
///  will expand to
///
///     (x + y, "x + y")
public struct PrintfMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard let argument = node.arguments.first?.expression else {
            fatalError("compiler bug: the macro does not have any arguments")
        }

        var args: [String] = ["\(argument)"]
        for argument in node.arguments.dropFirst() {
            //args.append("_PrintfArg(\(argument.expression))")
            args.append("(\(argument.expression))._printfArg")
        }
        let funcName = switch node.macroName.text {
            case "printf": "_printf"
            case "kprintf": "_kprintf"
            case "sprintf": "String._sprintf"
            case "serialPrintf": "_serialPrintf"
            default: fatalError("Unknown printf function: \(node.macroName.text)")
        }
        return "\(raw: funcName)(\(raw: args.joined(separator: ", ")))"
    }
}


public struct DebugMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard let argument = node.arguments.first?.expression else {
            fatalError("compiler bug: the macro does not have any arguments")
        }

        var args: [String] = ["\(argument)"]
        for argument in node.arguments.dropFirst() {
            //args.append("_PrintfArg(\(argument.expression))")
            args.append("(\(argument.expression)).description")
        }
        let funcName = "_\(node.macroName.text)"
        return "\(raw: funcName)(\(raw: args.joined(separator: ", ")))"
    }
}

public struct KPrintStaticStringMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard let argument = node.arguments.first?.expression else {
            fatalError("compiler bug: the macro does not have any arguments")
        }

        var args: [String] = ["\(argument)"]
        for argument in node.arguments.dropFirst() {
            args.append("(\(argument.expression)).description")
        }
        let funcName = "_\(node.macroName.text)"
        return "\(raw: funcName)(\(raw: args.joined(separator: ", ")))"
    }
}


public struct KPrintStringMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard let argument = node.arguments.first?.expression else {
            fatalError("compiler bug: the macro does not have any arguments")
        }

        var args: [String] = ["\(argument).description"]
        for argument in node.arguments.dropFirst() {
            args.append("(\(argument.expression)).description")
        }
        let funcName = "_\(node.macroName.text)"
        return "\(raw: funcName)(\(raw: args.joined(separator: ", ")))"
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
