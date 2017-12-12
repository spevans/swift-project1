//
//  kernel/devices/acpi/acpigloblobjects.swift
//
//  Created by Simon Evans on 28/04/2017.
//  Copyright © 2017 Simon Evans. All rights reserved.
//
//  ACPI Global Namespace


final class ACPIGlobalObjects {

    final class ACPIObjectNode: Hashable {
        private(set) var childNodes: [ACPIObjectNode]   // FIXME: Should be a dictionary of [name: ACPIObjectNode]
        fileprivate(set) var object: AMLObject

        var name: String { return object.name.value }
        var hashValue: Int { return object.name.value.hashValue }


        init(name: String, object: AMLObject, childNodes: [ACPIObjectNode]) {
            guard name == object.name.shortName.value else {
                fatalError("ACPIObjectNode.init(): \(name) != \(object.name.shortName.value)")
            }
            self.object = object
            self.childNodes = childNodes
        }


        static func == (lhs: ACPIGlobalObjects.ACPIObjectNode, rhs: ACPIGlobalObjects.ACPIObjectNode) -> Bool {
            return lhs.name == rhs.name
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
    }

    // Predefined objects
    private var globalObjects = ACPIObjectNode(
        name: "\\",
        object: AMLDefName(name: AMLNameString("\\"), value: AMLIntegerData(0)),
        childNodes: [
            ACPIObjectNode(name: "_OSI",
                           object: AMLMethod(name: AMLNameString("_OSI"),
                                             flags: AMLMethodFlags(flags: 1),
                                             parser: nil),
                           childNodes: []),

            ACPIObjectNode(name: "_GL",
                           object: AMLDefMutex(
                            name: AMLNameString("_GL"),
                            flags: AMLMutexFlags()),
                           childNodes: []),

            ACPIObjectNode(name: "_REV",
                           object: AMLDefName(name: AMLNameString("_REV"),
                                              value: AMLIntegerData(2)),
                           childNodes: []),

            ACPIObjectNode(name: "_OS",
                           object: AMLDefName(name: AMLNameString("_OS"),
                                              value: AMLString("Darwin")),
                           childNodes: [])
        ])


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
        print("Adding \(name) -> \(object.name.value)", type(of: object))
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
                                             childNodes: [])
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

    func dumpDevices() {
        let devices = getDevices()
        for device in devices {
            print(device)
        }
        print("Have \(devices.count) devices")
        return
    }


    func getDevices() -> [(String, AMLDefDevice)] {
        guard let sb = get("\\_SB") else {
            fatalError("No \\_SB system bus node")
        }
        var devices: [(String, AMLDefDevice)] = []
        walkNode(name: "\\_SB", node: sb) { (path, node) in
            if let device = node.object as? AMLDefDevice {
                devices.append((path, device))
            }
        }
        return devices
    }


    // Find all of the PNP devices and call a closure with the PNP name and resource settings
    func pnpDevices(_ closure: (String, String, [AMLResourceSetting]) -> Void) {
        getDevices().forEach { (fullName, device) in
            var context = ACPI.AMLExecutionContext(scope: AMLNameString(fullName),
                                                   args: [],
                                                   globalObjects: self)
            if let pnpName = device.pnpName(context: &context),
                let crs = device.currentResourceSettings(context: &context) {
                closure(fullName, pnpName, crs)
            }
        }
    }
}
