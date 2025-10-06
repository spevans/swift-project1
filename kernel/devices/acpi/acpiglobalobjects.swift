//
//  kernel/devices/acpi/acpigloblobjects.swift
//
//  Created by Simon Evans on 28/04/2017.
//  Copyright © 2017 - 2019 Simon Evans. All rights reserved.
//
//  ACPI Global Namespace


extension ACPI {

    class ACPIObjectNode: Hashable, CustomStringConvertible {
        let name: AMLNameString
        private(set) var object: AMLObject
        /*unowned*/ private(set) var parent: ACPIObjectNode? // FIXME: Can this be non-nilable, would need a fix for walking up the partent
        // Use an array for the childnodes even though the lookups are on the name
        // segment as this keeps the order and the number of entries is small enough
        // that a linear scan is ok.
        fileprivate(set) var childNodes: [String : ACPIObjectNode]
        private(set) var device: Device?

        var description: String {
            var result = "ACPIObjectNode: \(name.description)"
            if let p = parent {
                result += " parent: \(p.name.description)"
            }
            result += " children ["
            result += childNodes.keys.joined(separator: ", ")
            result += "]"
            return result
        }

        init(name: AMLNameString, parent: ACPIObjectNode? = nil, object: AMLObject) {
            guard name.isNameSeg else {
                fatalError("\(type(of: self)) has invalid name: \(name.value)")
            }
            self.name = name
            self.object = object
            self.childNodes = [:]
            self.parent = parent
        }

        func setDevice(_ newDevice: Device) {
            guard self.device == nil else {
                fatalError("\(fullname()) already has a device set")
            }
            self.device = newDevice
        }

        func readValue(context: inout AMLExecutionContext) throws(AMLError) -> AMLObject {
            return try self.object.readValue(context: &context)
        }

        func readValue() throws(AMLError) -> AMLObject? {
            var context = ACPI.AMLExecutionContext(scope: AMLNameString(fullname()))
            return try readValue(context:&context)
        }

        func updateValue(to newValue: AMLObject, context: inout AMLExecutionContext) throws(AMLError) {
            // Some object types can be updated in place, others require the current object to be overwritten
            try self.object.updateValue(to: newValue, context: &context)
        }


        static func == (lhs: ACPIObjectNode, rhs: ACPIObjectNode) -> Bool {
            return lhs.name == rhs.name
        }


        func hash(into hasher: inout Hasher) {
            hasher.combine(name.value)
        }


        fileprivate func addChildNode(_ newNode: ACPIObjectNode) -> Bool {
            // If there is already a node there check that it is an ExternalObj placeholder

            if let current = childNodes[newNode.name.value] {
                // This is mostly for debugging. Check if the object is being overwritten
                // with a more specific one. External Unknown -> External Known -> Not-external
                let fromExternal: Bool
                let fromType: AMLInteger
                let toExternal: Bool
                let toType: AMLInteger
                if let currentExternal = current.object.externalObject {
                    fromExternal = true
                    fromType = AMLInteger(currentExternal.0)
                } else {
                    fromExternal = false
                    fromType = current.object.objectType
                }

                if let newExternal = newNode.object.externalObject {
                    toExternal = true
                    toType = AMLInteger(newExternal.0)
                } else {
                    toExternal = false
                    toType = newNode.object.objectType
                }

                switch (fromExternal, toExternal) {
                    case (true, true):
                        if toType == 0 || fromType == toType {
                            // newNode is Unknown External or types match, do nothing
                            return false
                        }
                    case (true, false):
                        if fromType != 0 && fromType != toType {
                            // currentNode is External, newNode is concrete type of another type
                            #kprintf("acpi: addChild warning: %s from %s to %s\n",
                                     newNode.name.value, current.object.description, newNode.object.description)
                        }

                    case (false, true):
                        // From concrete object to external object, do nothing
                        if toType != 0 && fromType != toType {
                            // IF going a specific type and it doesnt match, print a warning
                            #kprintf("acpi: addChild warning: %s from %s to %s\n",
                                     newNode.name.value, current.object.description, newNode.object.description)
                        }
                        return false

                    case (false, false):
                        // From concrete object to concrete object of different type
                        if fromType != toType {
                            #kprintf("acpi: addChild warning: %s from %s to %s\n",
                                     newNode.name.value, current.object.description, newNode.object.description)
                            return false
                        }
                }
            }
            childNodes[newNode.name.value] = newNode
            newNode.parent = self
            return true
        }


        func removeChildNode(_ name: AMLNameString) {
            guard childNodes.removeValue(forKey: name.value) != nil else {
                fatalError("Cant remove unknown child node: \(name)")
            }
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
            return childNodes[named]
        }


        func amlObject() throws(AMLError) -> AMLObject {
            // FIXME, might need derefrerencing
            var context = ACPI.AMLExecutionContext(scope: AMLNameString(fullname()))
            return try self.object.readValue(context: &context)
        }


        // Create an initial ACPI tree with default nodes
        static func createGlobalObjects() -> ACPIObjectNode {

            let parent = ACPIObjectNode(name: AMLNameString("\\"),
                                        object: AMLObject())

            let children: [ACPIObjectNode] = [
                ACPIObjectNode(name: AMLNameString("_OSI"),
                               object: AMLObject(AMLMethod(name: AMLNameString("_OSI"),
                                                         flags: AMLMethodFlags(flags: 1),
                                                         handler: _OSI_Method))),

                ACPIObjectNode(name: AMLNameString("_GL"),
                               object: AMLObject(AMLDefMutex(name: AMLNameString("_GL"),
                                                          flags: AMLMutexFlags()))),

                ACPIObjectNode(name: AMLNameString("_REV"), object: AMLObject(2)),

                ACPIObjectNode(name: AMLNameString("_OS"), object: AMLObject(try! AMLString("Darwin"))),

                // Root namespaces
                ACPIObjectNode(name: AMLNameString("_GPE"), object: AMLObject()),
                ACPIObjectNode(name: AMLNameString("_PR"), object: AMLObject()),
                ACPIObjectNode(name: AMLNameString("_SB"), object: AMLObject()),
                ACPIObjectNode(name: AMLNameString("_SI"), object: AMLObject()),
                ACPIObjectNode(name: AMLNameString("_TZ"), object: AMLObject()),
            ]

            children.forEach { _ = parent.addChildNode($0) }
            return parent
        }


        private func findNode(named: String, parent: ACPIObjectNode) -> ACPIObjectNode? {
            return parent.childNodes[named]
        }


        func add(_ name: String, _ newNode: ACPIObjectNode) -> Bool {

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
                    guard newNode.object.externalObject != nil else {
                        #kprint("ACPI: Ignoring invalid path", name, "for object of type:", newNode.object)
                        return false
                    }
                    // FIXME: Adding a missing part of the path directly is not the correct way as
                    // The missing part should probably generate its own subtree to add to. This
                    // occurs when eg parsing a Device and the methods in the device are added to the
                    // global tree before the device itself. The device later overwrites this object.
                    // Use an External UnknownObj as a placeholder
                    let intermediateNode = ACPIObjectNode(name: AMLNameString(part), object: AMLObject.init(0, 0))
                    _ = parent.addChildNode(intermediateNode)
                    parent = intermediateNode
                }
            }

            return parent.addChildNode(newNode)
        }


        // needs to be a full path starting with \\
        func getObject(_ name: String) -> ACPIObjectNode? {
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


        // FIXME, this is only temporary until getGlobalObject() understands how to walk up to the parent.
        func topParent() -> ACPIObjectNode {
            var result = self
            while let parent = result.parent {
                result = parent
            }
            return result
        }


        // FIXME: This should walk up the parent if needed
        func getGlobalObject(currentScope: AMLNameString, name: AMLNameString) -> (ACPIObjectNode, String)? {
            let nameStr = name.value
            guard nameStr.first != nil else {
                fatalError("string is empty")
            }
            let fullPath = resolveNameTo(scope: currentScope, path: name)
            return walkUpFullPath(fullPath, block: getObject)
        }


        func walkNode(name: String, node: ACPIObjectNode, _ body: (String, ACPIObjectNode) -> Bool) {
            let keepWalking = body(name, node)
            guard keepWalking else { return }
            for key in node.childNodes.keys.sorted() {
                guard let child = node.childNodes[key] else { continue }
                let fullname = (name == "\\") ? name + child.name.value :
                    name + String(AMLNameString.pathSeparatorChar) + child.name.value
                walkNode(name: fullname, node: child, body)
            }
        }

        func walkNode( _ body: (String, ACPIObjectNode) -> Bool) {
            let keepWalking = body(self.fullname(), self)
            guard keepWalking else { return }
            for key in self.childNodes.keys.sorted() {
                guard let child = self.childNodes[key] else { continue }
                child.walkNode(body)
            }
        }

        func findNodes(name: AMLNameString, _ body: (String, ACPIObjectNode) -> Bool) {
            walkNode { (fullname, obj) in
                if obj.name == name {
                    let keepWalking = body(fullname, obj)
                    guard keepWalking else { return false }
                }
                return true
            }
        }
    }
}

