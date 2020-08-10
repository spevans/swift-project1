//
//  kernel/devices/acpi/acpigloblobjects.swift
//
//  Created by Simon Evans on 28/04/2017.
//  Copyright © 2017 - 2019 Simon Evans. All rights reserved.
//
//  ACPI Global Namespace


extension ACPI {
    class ACPIObjectNode: AMLTermObj, Hashable {
        let name: AMLNameString
        fileprivate(set) var childNodes: [AMLNameString: ACPIObjectNode]
        unowned private(set) var parent: ACPIObjectNode?

        init(name: AMLNameString, parent: ACPIObjectNode? = nil) {
            self.name = name
            self.childNodes = [:]
            self.parent = parent
            guard name.isNameSeg else {
                fatalError("\(type(of: self)) has invalid name: \(name.value)")
            }
        }

        func readValue(context: inout AMLExecutionContext) -> AMLTermArg {
            fatalError("Requires concrete implementation")
        }

        func updateValue(to: AMLTermArg, context: inout AMLExecutionContext) {
            fatalError("Requires concrete implementation")
        }

        func createNamedObject(context: inout AMLExecutionContext) throws {
            let fullPath = resolveNameTo(scope: context.scope, path: name)
            let globalObjects = system.deviceManager.acpiTables.globalObjects!
            globalObjects.add(fullPath.value, self)
        }


        static func == (lhs: ACPIObjectNode, rhs: ACPIObjectNode) -> Bool {
            return lhs.name == rhs.name
        }


        func hash(into hasher: inout Hasher) {
            hasher.combine(name.value)
        }


        fileprivate func addChildNode(_ node: ACPIObjectNode) {
            if let child = childNodes[node.name] {
                node.childNodes = child.childNodes
                node.childNodes.forEach { (key, value) in
                    value.parent = node
                }
                child.childNodes = [:]
                child.parent = nil
            }
            childNodes[node.name] = node
            node.parent = self
        }


        func removeChildNode(_ name: AMLNameString) {
            if childNodes[name] == nil {
                fatalError("Cant remove unknown child node: \(name)")
            }
            childNodes.removeValue(forKey: name)
        }


        func scope() -> String {
            var node = self.parent
            var scope = node?.name.value ?? ""
            while let p = node?.parent {
                scope = p.name.value + ((p.parent == nil) ? "" : ".") + scope
                node = p
            }
            return scope
        }


        func fullname() -> String {
            if parent == nil { return name.value }
            let s = scope()
            return (s == "\\") ? "\\" + name.value : s + "." + name.value
        }


        func childNode(named: String) -> ACPIObjectNode? {
            childNodes[AMLNameString(named)]
        }


        // Create an initial ACPI tree with default nodes
        static func createGlobalObjects() -> ACPIObjectNode {

            let parent = ACPIObjectNode(name: AMLNameString("\\"))

            let children: [AMLNamedObj] = [
                AMLMethod(name: AMLNameString("_OSI"),
                          flags: AMLMethodFlags(flags: 1),
                          parser: nil),

                AMLDefMutex(name: AMLNameString("_GL"),
                            flags: AMLMutexFlags()),

                AMLNamedValue(name: AMLNameString("_REV"),
                           value: AMLDataRefObject(integer: 2)),

                AMLNamedValue(name: AMLNameString("_OS"),
                           value: AMLDataRefObject(string: "Darwin")),

                // Root namespaces
                AMLNamedObj(name: AMLNameString("_GPE")),
                AMLNamedObj(name: AMLNameString("_PR")),
                AMLNamedObj(name: AMLNameString("_SB")),
                AMLNamedObj(name: AMLNameString("_SI")),
                AMLNamedObj(name: AMLNameString("_TZ")),
                ]

            children.forEach { parent.addChildNode($0) }
            return parent
        }


        private func findNode(named: String, parent: ACPIObjectNode) -> ACPIObjectNode? {
            parent.childNodes[AMLNameString(named)]
        }


        func add(_ name: String, _ object: AMLNamedObj) {

            // Remove leading '\\'
            func removeRootChar(name: String) -> String {
                if let f = name.first, f == "\\" {
                    var name2 = name
                    name2.remove(at: name2.startIndex)
                    return name2
                }
                return name
            }

            var parent = self
            var nameParts = removeRootChar(name: name).components(
                separatedBy: AMLNameString.pathSeparatorChar)
            guard nameParts.count > 0 else {
                fatalError("\(name) has no last segment")
            }

            while nameParts.count > 1 {
                let part = nameParts.removeFirst()
                if let node = findNode(named: part, parent: parent) {
                    parent = node
                } else {
                    // FIXME: Adding a missing part of the path directly is not the correct way as
                    // The missing part should probably generate its own subtree to add to. This
                    // occurs when eg parsing a Device and the methods in the device are added to the
                    // global tree before the device itself. The device later over writes this object.
                    let newNode = AMLNamedObj(name: AMLNameString(part))
                    parent.addChildNode(newNode)
                    parent = newNode
                }
            }

            parent.addChildNode(object)
        }


        // needs to be a full path starting with \\
        func get(_ name: String) -> ACPIObjectNode? {
            var name2 = name
            guard name2.remove(at: name2.startIndex) == "\\" else {
                return nil
            }
            var parent = self
            var nameParts = name2.components(separatedBy: AMLNameString.pathSeparatorChar)
            while nameParts.count > 0 {
                let part = nameParts.removeFirst()
                if let childNode = findNode(named: part, parent: parent) {
                    parent = childNode
                } else {
                    return nil
                }
            }
            return parent
        }


        func getGlobalObject(currentScope: AMLNameString, name: AMLNameString)
            -> (ACPIObjectNode, String)? {
                let nameStr = name.value
                guard nameStr.first != nil else {
                    fatalError("string is empty")
                }

                let fullPath = resolveNameTo(scope: currentScope, path: name)
                if let obj = get(fullPath.value) {
                    return (obj, fullPath.value)
                }
                // Do a search up the tree
                guard name.isNameSeg else {
                    return nil
                }
                let seperator = AMLNameString.pathSeparatorChar
                var nameSegs = currentScope.value.components(separatedBy: seperator)
                while nameSegs.count > 1 {
                    _ = nameSegs.popLast()
                    var tmpName = nameSegs.joined(separator: String(seperator))
                    tmpName.append(AMLNameString.pathSeparatorChar)
                    tmpName.append(name.value)
                    if let obj = get(tmpName) {
                        return (obj, tmpName)
                    }
                }
                if nameSegs.count == 1 {
                    var tmpName = "\\"
                    tmpName.append(name.value)
                    if let obj =  get(tmpName) {
                        return (obj, tmpName)
                    }
                }
                return nil
        }


        func walkNode(name: String, node: ACPIObjectNode, _ body: (String, ACPIObjectNode) -> Void) {
            body(name, node)
            for (_, child) in node.childNodes {
                let fullName = (name == "\\") ? name + child.name.value :
                    name + String(AMLNameString.pathSeparatorChar) + child.name.value
                walkNode(name: fullName, node: child, body)
            }
        }

        func walkNode( _ body: (String, ACPIObjectNode) -> Void) {
            body(self.fullname(), self)
            for (_, child) in self.childNodes {
                child.walkNode(body)
            }
        }
    }
}

