//
//  kernel/devices/acpi/acpigloblobjects.swift
//
//  Created by Simon Evans on 28/04/2017.
//  Copyright © 2017 Simon Evans. All rights reserved.
//
//  ACPI Global Namespace


final class ACPIGlobalObjects {

    final class ACPIObjectNode: Hashable {
        fileprivate(set) var childNodes: [ACPIObjectNode]   // FIXME: Should be a dictionary of [name: ACPIObjectNode]
        fileprivate(set) var object: AMLObject
        unowned private let parent: ACPIObjectNode?

        var name: String { return object.name.value }

        init(name: String, object: AMLObject, childNodes: [ACPIObjectNode], parent: ACPIObjectNode?) {
            guard name == object.name.shortName.value else {
                fatalError("ACPIObjectNode.init(): \(name) != \(object.name.shortName.value)")
            }
            self.object = object
            self.childNodes = childNodes
            self.parent = parent
        }


        static func == (lhs: ACPIGlobalObjects.ACPIObjectNode, rhs: ACPIGlobalObjects.ACPIObjectNode) -> Bool {
            return lhs.name == rhs.name
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(name)
        }

        subscript(index: String) -> ACPIObjectNode? {
            get {
                for node in childNodes {
                    if node.name == index {
                        return node
                    }
                }
                return nil
            }
        }

        fileprivate func addChildNode(_ node: ACPIObjectNode) {
            childNodes.append(node)
        }

        func scope() -> String {
            var node = self.parent
            var scope = node?.name ?? ""
            while let p = node?.parent {
                scope = p.name + ((p.parent == nil) ? "" : ".") + scope
                node = p
            }
            return scope
        }


        func fullname() -> String {
            return (self.parent == nil) ? name : scope() + "." + name
        }

        func childNode(named: String) -> ACPIObjectNode? {
            for child in childNodes {
                if child.name == named {
                    return child
                }
            }
            return nil
        }


        func status() -> AMLDefDevice.DeviceStatus {
            guard let node = childNode(named: "_STA") else {
                return .defaultStatus()
            }
            let sta = node.object
            if let obj = sta as? AMLDefName, let v = obj.value as? AMLIntegerData {
                return AMLDefDevice.DeviceStatus(v.value)
            }

            if let obj = sta as? AMLNamedObj {
                var context = ACPI.AMLExecutionContext(scope: AMLNameString(node.fullname()),
                                                       globalObjects: system.deviceManager.acpiTables.globalObjects)

                if let v = obj.readValue(context: &context) as? AMLIntegerData {
                    return AMLDefDevice.DeviceStatus(v.value)
                }
            }
            fatalError("Cant determine status of: \(sta))")
        }


        func currentResourceSettings() -> [AMLResourceSetting]? {
            guard let node = childNode(named: "_CRS") else {
                return nil
            }
            let crs = node.object

            let buffer: AMLBuffer?
            if let obj = crs as? AMLDefName {
                buffer = obj.value as? AMLBuffer
            } else {
                guard let crsObject = crs as? AMLMethod else {
                    fatalError("CRS object is an \(type(of: crs))")
                }
                var context = ACPI.AMLExecutionContext(scope: AMLNameString(node.fullname()),
                                                       globalObjects: system.deviceManager.acpiTables.globalObjects)
                buffer = crsObject.readValue(context: &context) as? AMLBuffer
            }
            if buffer != nil {
                return decodeResourceData(buffer!)
            } else {
                return nil
            }
        }


        func hardwareId() -> String? {
            guard let node = childNode(named: "_HID") else {
                return nil
            }
            let hid = node.object

            if let hidName = hid as? AMLDefName {
                return (decodeHID(obj: hidName.value) as? AMLString)?.value
            }
            return nil
        }


        func pnpName() -> String? {
            guard let node = childNode(named: "_CID") else {
                return nil
            }
            let cid = node.object

            if let cidName = cid as? AMLDefName {
                return (decodeHID(obj: cidName.value) as? AMLString)?.value
            }
            return nil
        }


        func addressResource() -> AMLInteger? {
            guard let node = childNode(named: "_ADR") else {
                return nil
            }
            if let adr = node.object as? AMLNamedObj {
                var context = ACPI.AMLExecutionContext(scope: AMLNameString(node.fullname()),
                                                       globalObjects: system.deviceManager.acpiTables.globalObjects)
                if let v = adr.readValue(context: &context) as? AMLIntegerData {
                    return v.value
                }
            }
            if let adr = node.object as? AMLDefName, let v = adr.value as? AMLIntegerData {
                return v.value
            }
            return nil
        }
    }

    // Predefined objects
    private var globalObjects: ACPIObjectNode = {
        let parent = ACPIObjectNode(
            name: "\\",
            object: AMLDefName(name: AMLNameString("\\"), value: AMLIntegerData(0)),
            childNodes: [],
            parent: nil
        )

        let children = [
            ACPIObjectNode(name: "_OSI",
                           object: AMLMethod(name: AMLNameString("_OSI"),
                                             flags: AMLMethodFlags(flags: 1),
                                             parser: nil),
                           childNodes: [],
                           parent: parent),

            ACPIObjectNode(name: "_GL",
                           object: AMLDefMutex(
                            name: AMLNameString("_GL"),
                            flags: AMLMutexFlags()),
                           childNodes: [],
                           parent: parent),

            ACPIObjectNode(name: "_REV",
                           object: AMLDefName(name: AMLNameString("_REV"),
                                              value: AMLIntegerData(2)),
                           childNodes: [],
                           parent: parent),

            ACPIObjectNode(name: "_OS",
                           object: AMLDefName(name: AMLNameString("_OS"),
                                              value: AMLString("Darwin")),
                           childNodes: [],
                           parent: parent)
        ]
        parent.childNodes = children
        return parent
    }()


    private func findNode(named: String, parent: ACPIObjectNode) -> ACPIObjectNode? {
        for node in parent.childNodes {
            if node.name == named {
                return node
            }
        }
        return nil
    }

    // Remove leading '\\'
    private func removeRootChar(name: String) -> String {
        if let f = name.first, f == "\\" {
            var name2 = name
            name2.remove(at: name2.startIndex)
            return name2
        }
        return name
    }


    func add(_ name: String, _ object: AMLObject) {
        print("Adding \(name) -> \(object.name.value) \(type(of: object))")
        var parent = globalObjects
        var nameParts = removeRootChar(name: name).components(
            separatedBy: AMLNameString.pathSeparatorChar)
        guard let nodeName = nameParts.last else {
            fatalError("\(name) has no last segment")
        }

        while nameParts.count > 0 {
            let part = nameParts.removeFirst()
            if let childNode = findNode(named: part, parent: parent) {
                parent = childNode
            } else {
                let tmpScope = AMLDefScope(name: AMLNameString(part), value: [])
                let newNode = ACPIObjectNode(name: part,
                                             object: tmpScope,
                                             childNodes: [], parent: parent)
                    parent.addChildNode(newNode)
                    parent = newNode
            }
        }

        guard parent.name == nodeName else {
            fatalError("bad node")
        }
        parent.object = object
    }


    // needs to be a full path starting with \\
    func get(_ name: String) -> ACPIObjectNode? {
        var name2 = name
        guard name2.remove(at: name2.startIndex) == "\\" else {
            return nil
        }
        var parent = globalObjects
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


    func getDataRefObject(_ name: String) -> AMLDataRefObject? {
        if let node = get(name) {
            if let o = node.object as? AMLDataRefObject {
                return o
            }
            if let o = node.object as? AMLDefName {
                return o.value
            }
        }
        return nil
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
        node.childNodes.forEach {
            let child = $0
            let fullName = (name == "\\") ? name + child.name :
                name + String(AMLNameString.pathSeparatorChar) + child.name
            walkNode(name: fullName, node: child, body)
        }
    }


    func dumpObjects() {
        walkNode(name: "\\", node: globalObjects) { (path, node) in
            print("ACPI: \(path)")
        }
    }


    func runBody(root: String, body: (String, AMLNamedObj) -> ()) {
        guard let sb = get("\\") else {
            fatalError("\\ not found")
        }
        walkNode(name: root, node: sb) { (path, node) in
            if let obj = node.object as? AMLNamedObj {
                body(path, obj)
            }
        }
    }
}


// Device methods
extension ACPIGlobalObjects {

    func getDevices() -> [(String, ACPIObjectNode)] {
        guard let sb = get("\\_SB") else {
            fatalError("No \\_SB system bus node")
        }
        var devices: [(String, ACPIObjectNode)] = []
        walkNode(name: "\\_SB", node: sb) { (path, node) in
            if node.object is AMLDefDevice {
                devices.append((path, node))
            }
        }
        return devices
    }
}
