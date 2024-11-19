//
//  IPHONE.swift
//
//  Created by Kelvin Wong on 2018/7/21.
//  Copyright © 2018年 nonamecat. All rights reserved.
//

import Foundation
import LoggerFactory
import SharedDeviceLib

public struct IPHONE {
    
    let logger = LoggerFactory.get(category: "IPHONE")
    
    /// singleton instance of this class
    public static let bridge = IPHONE()
    
    // URL of the embedded version of ExifTool
    fileprivate var ideviceid: URL
    fileprivate var ideviceinfo: URL
    fileprivate var ifuse: URL
    fileprivate var df: URL
    fileprivate var umount: URL
    
    // Verify access to the embedded version of ExifTool
    public init(path: String = "/opt/homebrew/bin") {
        ideviceid = URL(fileURLWithPath: "\(path)/idevice_id")
        ideviceinfo = URL(fileURLWithPath: "\(path)/ideviceinfo")
        ifuse = URL(fileURLWithPath: "\(path)/ifuse")
        df = URL(fileURLWithPath: "/bin/df")
        umount = URL(fileURLWithPath: "/sbin/umount")
    }
    
    public func validCommands() -> Bool {
        if !FileManager.default.fileExists(atPath: ideviceid.path) {
            return false
        }
        if !FileManager.default.fileExists(atPath: ideviceinfo.path) {
            return false
        }
        if !FileManager.default.fileExists(atPath: ifuse.path) {
            return false
        }
        if !FileManager.default.fileExists(atPath: umount.path) {
            return false
        }
        return true
    }
    
    public func devices() -> [String]{
        if ideviceid.path == "" {
            self.logger.log(.error, "ideviceid path is empty !!!")
            return []
        }
        if !ideviceid.path.isFileExists() {
            self.logger.log(.error, "ideviceid has not installed !!!")
            return []
        }
        var result:[String] = []
        let pipe = Pipe()
        autoreleasepool { () -> Void in
            let command = Process()
            command.standardOutput = pipe
            command.standardError = FileHandle.nullDevice
            command.launchPath = ideviceid.path
            command.arguments = ["-l"]
            command.launch()
            command.waitUntilExit()
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let string:String = String(data: data, encoding: String.Encoding.utf8)!
        pipe.fileHandleForReading.closeFile()
        let lines = string.components(separatedBy: "\n")
        for line in lines {
            if line != "" {
                result.append(line)
            }
        }
        return result
    }
    
    public func mount(path:String) -> Bool{
        self.logger.log(.trace, "START TO MOUNT")
        if ifuse.path == "" {
            self.logger.log(.error, "ifuse path is empty !!!")
            return false
        }
        if !ifuse.path.isFileExists() {
            self.logger.log(.error, "ifuse has not installed !!!")
            return false
        }
        let pipe = Pipe()
        autoreleasepool { () -> Void in
            let command = Process()
            command.standardOutput = pipe
            command.standardError = pipe
            command.launchPath = ifuse.path
            command.arguments = [path]
            do {
                try command.run()
            }catch{
                self.logger.log(.error, error)
            }
        }
        self.logger.log(.trace, "RUN MOUNT")
//        command.launch()
//        command.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let string:String = String(data: data, encoding: String.Encoding.utf8)!
        pipe.fileHandleForReading.closeFile()
        self.logger.log(string)
        if string.range(of: "No device found") != nil || string.range(of: "Input/output error") != nil {
            return false
        }else{
            return true
        }
    }
    
    public func unmountFuse(){
        if ifuse.path == "" {
            self.logger.log(.error, "umount path is empty !!!")
            return
        }
        if !ifuse.path.isFileExists() {
            self.logger.log(.error, "umount has not installed !!!")
            return
        }
        let pipe = Pipe()
        autoreleasepool { () -> Void in
            let command = Process()
            command.standardOutput = pipe
            command.standardError = FileHandle.nullDevice
            command.launchPath = umount.path
            command.arguments = ["ifuse@macfuse0"]
            do {
                try command.run()
            }catch{
                self.logger.log(.error, error)
            }
        }
        //        command.launch()
        //        command.waitUntilExit()
        let _ = pipe.fileHandleForReading.readDataToEndOfFile()
        pipe.fileHandleForReading.closeFile()
        //let _ = String(data: data, encoding: String.Encoding.utf8)!
        
    }
    
    public func unmount(path:String){
        if ifuse.path == "" {
            self.logger.log(.error, "umount path is empty !!!")
            return
        }
        if !ifuse.path.isFileExists() {
            self.logger.log(.error, "umount has not installed !!!")
            return
        }
        let pipe = Pipe()
        autoreleasepool { () -> Void in
            let command = Process()
            command.standardOutput = pipe
            command.standardError = FileHandle.nullDevice
            command.launchPath = umount.path
            command.arguments = [path]
            do {
                try command.run()
            }catch{
                self.logger.log(.error, error)
            }
        }
//        command.launch()
//        command.waitUntilExit()
        let _ = pipe.fileHandleForReading.readDataToEndOfFile()
        pipe.fileHandleForReading.closeFile()
        //let _ = String(data: data, encoding: String.Encoding.utf8)!
        self.unmountFuse()

    }
    
    public func mounted(path:String) -> Bool {
        guard devices().count > 0 else {return false}
        let pipe = Pipe()
        autoreleasepool { () -> Void in
            let command = Process()
            command.standardOutput = pipe
            command.standardError = FileHandle.nullDevice
            command.launchPath = df.path
            command.arguments = ["-H", path]
            do {
                try command.run()
            }catch{
                self.logger.log(.error, error)
            }
        }
//        command.launch()
//        command.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let string:String = String(data: data, encoding: String.Encoding.utf8)!
        pipe.fileHandleForReading.closeFile()
        self.logger.log(string)
        let lines = string.components(separatedBy: "\n")
        self.logger.log(.trace, "lines = \(lines.count)")
        for line in lines {
            if line.starts(with: "ifuse@macfuse") && line.range(of: path) != nil {
                self.logger.log(.trace, "mounted")
                return true
            }
        }
        self.logger.log(.trace, "no mount record")
        return false
    }
    
    public func device() -> PhoneDevice? {
        if ideviceinfo.path == "" {
            self.logger.log(.error, "ideviceinfo path is empty !!!")
            return nil
        }
        if !ideviceinfo.path.isFileExists() {
            self.logger.log(.error, "ideviceinfo has not installed !!!")
            return nil
        }
        let pipe = Pipe()
        autoreleasepool { () -> Void in
            let command = Process()
            command.standardOutput = pipe
            command.standardError = pipe
            command.launchPath = ideviceinfo.path
            command.arguments = ["-s"]
            command.launch()
            command.waitUntilExit()
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let string:String = String(data: data, encoding: String.Encoding.utf8)!
        pipe.fileHandleForReading.closeFile()
        self.logger.log(string)
        if string.starts(with: "ERROR: Could not connect to lockdownd") {
            self.logger.log(.trace, "Please unlock the screen of iOS device")
            self.logger.log(.trace, "If failed again, refer to https://github.com/libimobiledevice/libimobiledevice/issues/717 , please reinstall libimobiledevice and ideviceinstaller by brew")
//            MessageEventCenter.default.showMessage(type: "Device Error", name: "iPhone", message: "Please unlock screen of iOS device, otherwise may need to reinstall ideviceinfo by Homebrew")
            return nil
        }
        if string.starts(with: "ERROR") || string.starts(with: "No device found") || string.range(of: "Input/output error") != nil {
            return nil
        }
        var device:PhoneDevice
        var name:String = ""
        var deviceId:String = ""
        var model:String = ""
        var iccid:String = ""
        var meid:String = ""
        let lines = string.components(separatedBy: "\n")
        for line in lines {
            if line.starts(with: "DeviceName:") {
                let parts = line.components(separatedBy: " ")
                if parts.count == 2 {
                    name = parts[1]
                }
            }else if line.starts(with: "ProductType:") {
                let parts = line.components(separatedBy: " ")
                if parts.count == 2 {
                    model = parts[1]
                }
            }else if line.starts(with: "IntegratedCircuitCardIdentity:") {
                let parts = line.components(separatedBy: " ")
                if parts.count == 2 {
                    iccid = parts[1]
                }
            }else if line.starts(with: "InternationalMobileEquipmentIdentity:") {
                let parts = line.components(separatedBy: " ")
                if parts.count == 2 {
                    meid = parts[1]
                }
            }else if line.starts(with: "UniqueDeviceID:") {
                let parts = line.components(separatedBy: " ")
                if parts.count == 2 {
                    deviceId = parts[1]
                }
            }
        }
        if model != "" && deviceId != "" {
            device = PhoneDevice(type: .iPhone, deviceId: deviceId, manufacture: "Apple", model: model)
            device.iccid = iccid
            device.meid = meid
            device.name = name
            return device
        }else{
            return nil
        }
    }
    
    public func pull(mountPoint:String, in remoteFolder:String, to targetPath:String) -> Bool{
        guard mounted(path: mountPoint) else {return false}
        let remoteUrl:URL = URL(fileURLWithPath: mountPoint).appendingPathComponent(remoteFolder)
        let localUrl:URL = URL(fileURLWithPath: targetPath)
        
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: remoteUrl.path) && fileManager.fileExists(atPath: localUrl.path) {
            do{
                self.logger.log(.trace, "Pulling from \(remoteUrl.path) to \(localUrl.path)")
                let options: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants ]
                let resourceKeys = [URLResourceKey.isRegularFileKey, URLResourceKey.typeIdentifierKey, URLResourceKey.isDirectoryKey]
                let enumerator = fileManager.enumerator(at: remoteUrl,
                                                        includingPropertiesForKeys: resourceKeys,
                                                        options: options, errorHandler: { (url, error) -> Bool in
                                                            self.logger.log(.trace, "Remote directory enumerator error at \(url): ", error)
                                                            return false
                })!
                
                for case let remoteFileUrl as URL in enumerator {
                    self.logger.log(.trace, "Pulling from \(remoteFileUrl.path) to \(localUrl.path)")
                    try fileManager.copyItem(at: remoteFileUrl, to: localUrl)
                }
                return true
            }catch{
                self.logger.log(.error, error)
                return false
            }
        }else{
            self.logger.log(.trace, "URL not exists: \(remoteUrl.path) OR \(localUrl.path)")
            return false
        }
    }
    
    
    
    public func md5(mountPoint:String, at remoteFile:String) -> String {
        guard mounted(path: mountPoint) else {return ""}
        let remoteUrl:URL = URL(fileURLWithPath: mountPoint).appendingPathComponent(remoteFile)
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: remoteUrl.path) {
            let pipe = Pipe()
            autoreleasepool { () -> Void in
            let cmd = Process()
                cmd.standardOutput = pipe
                cmd.standardError = pipe
                cmd.launchPath = "/sbin/md5"
                cmd.arguments = []
                cmd.arguments?.append(remoteUrl.path)
                cmd.launch()
                cmd.waitUntilExit()
            }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let string:String = String(data: data, encoding: String.Encoding.utf8)!
            pipe.fileHandleForReading.closeFile()
            if string != "" && string.starts(with: "MD5 (") {
                let comp:[String] = string.components(separatedBy: " = ")
                if comp.count == 2 {
                    return comp[1].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                }
            }
            return ""
        }else {
            return ""
        }
    }
    
    public func pull(mountPoint:String, sourcePath:String, from remoteFile:String, to targetPath:String) -> Bool{
        self.logger.log(.trace, "IOS PULL: from \(remoteFile) - to: \(targetPath)")
        //guard mounted(path: mountPoint) else {return false}
        let filename = URL(fileURLWithPath: remoteFile).lastPathComponent
        let mountedDeviceFilePath:URL = URL(fileURLWithPath: mountPoint).appendingPathComponent(remoteFile)
        let targetFileFolder:URL = URL(fileURLWithPath: targetPath)
        let targetFilePath = targetFileFolder.appendingPathComponent(filename)
        
        //let targetFilenameWithSubPath = remoteFile.replacingOccurrences(of: sourcePath, with: "", options: .literal, range: remoteFile.range(of: sourcePath))
        
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: mountedDeviceFilePath.path) {
            
            if !fileManager.fileExists(atPath: targetFileFolder.path) {
                do {
                    try fileManager.createDirectory(at: targetFileFolder, withIntermediateDirectories: true, attributes: nil)
                }catch{
                    self.logger.log(.trace, "Unable to create target path: \(targetFileFolder.path)")
                    self.logger.log(.error, error)
                }
            }
            if !fileManager.fileExists(atPath: targetFilePath.path) {
                do{
                    self.logger.log(.trace, "Pulling from \(mountedDeviceFilePath.path) to \(targetFilePath.path)")
                    try fileManager.copyItem(at: mountedDeviceFilePath, to: targetFilePath)
                    return true
                }catch{
                    self.logger.log(.error, error)
                    return false
                }
            }else{
                self.logger.log(.trace, "TARGET FILE EXISTS: \(targetFilePath.path), ignore copy")
                return false
            }
        }else{
            self.logger.log(.trace, "Mounted device file path not exists: \(mountedDeviceFilePath.path)")
            return false
        }
    }
    
    public func push(mountPoint:String, from filePath:String, to remoteFolder:String) -> Bool{
        //guard mounted(path: mountPoint) else {return false}
        let remoteUrl:URL = URL(fileURLWithPath: mountPoint).appendingPathComponent(remoteFolder)
        let localUrl:URL = URL(fileURLWithPath: filePath)
        
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: remoteUrl.path) && fileManager.fileExists(atPath: localUrl.path) {
            do{
                self.logger.log(.trace, "Pushing from \(localUrl.path) to \(remoteUrl.path)")
                try fileManager.copyItem(at: localUrl, to: remoteUrl)
                return true
            }catch{
                self.logger.log(.error, error)
                return false
            }
        }else{
            self.logger.log(.trace, "URL not exists: \(remoteUrl.path) OR \(localUrl.path)")
            return false
        }
    }
    
    
    public func datetime(of filename: String, in path:String, mountPoint:String) -> String {
        let workpath = URL(fileURLWithPath: mountPoint).appendingPathComponent(path).path
        let pipe = Pipe()
        autoreleasepool { () -> Void in
            let command = Process()
            command.standardOutput = pipe
            command.standardError = pipe
            command.currentDirectoryPath = workpath
            command.launchPath = "/usr/bin/stat"
            command.arguments = ["-l","-t","'%F %T'", filename]
            do {
                try command.run()
            }catch{
                self.logger.log(.error, error)
            }
        }
        //command.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let string:String = String(data: data, encoding: String.Encoding.utf8)!
        pipe.fileHandleForReading.closeFile()
        if string != "" {
            let columns = string.components(separatedBy: " ")
            if columns.count > 7 {
                let date = columns[5]
                let time = columns[6]
                let datetime = "\(date) \(time)"
                return datetime
            }
        }
        return ""
    }
    
    public func files(mountPoint:String, in path: String) -> [PhoneFile] {
        let workURL = URL(fileURLWithPath: mountPoint).appendingPathComponent(path)
        if !FileManager.default.fileExists(atPath: workURL.path) {
            return []
        }
        let workpath = workURL.path
        self.logger.log(.trace, "getting files from \(workpath)")
        var result:[PhoneFile] = []
        let pipe = Pipe()
        autoreleasepool { () -> Void in
            let command = Process()
            command.standardOutput = pipe
            command.standardError = pipe
            command.currentDirectoryPath = workpath
            command.launchPath = "/bin/ls"
            command.arguments = ["-goR"]
            do {
                try command.run()
            }catch{
                self.logger.log(.error, error)
            }
        }
        //command.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let string:String = String(data: data, encoding: String.Encoding.utf8)!
        pipe.fileHandleForReading.closeFile()
        self.logger.log(string)
        
        let filenamesForReference = self.filenamesForReference(mountPoint: mountPoint, in: path)
        
        result = DeviceShell.getFilenames(from: string,
                                          refer: filenamesForReference,
                                          basePath: path,
                                          excludeFilenames: ["directory", ".", ".."],
                                          allowedExt: FileTypeRecognizer.allowed,
                                          allowedSuffix: ["_backup_hd"], // wechat chatroom image/video thumbnails
                                          deviceOS: .mac)
        self.logger.log(.trace, "got \(result.count) files from \(workpath)")
        return result
    }
    
    
    
    public func folders(mountPoint:String, in path: String) -> [String] {
        let workpath = URL(fileURLWithPath: mountPoint).appendingPathComponent(path).path
        self.logger.log(.trace, "getting folders from \(workpath)")
        var result:[String] = []
        let pipe = Pipe()
        autoreleasepool { () -> Void in
            let command = Process()
            command.standardOutput = pipe
            command.standardError = pipe
            command.currentDirectoryPath = workpath
            command.launchPath = "/usr/bin/find"
            command.arguments = [".", "-type", "d","-maxdepth", "1"]
            do {
                try command.run()
            }catch{
                self.logger.log(.error, error)
            }
        }
        //command.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let string:String = String(data: data, encoding: String.Encoding.utf8)!
        pipe.fileHandleForReading.closeFile()
        //self.logger.log(string)
        result = DeviceShell.getFolderNames(from: string)
        self.logger.log(.trace, "got \(result.count) folders from \(workpath)")
        return result
    }
    
    
    fileprivate func filenamesForReference(mountPoint:String, in path: String, recursive:Bool=false) -> [String:[String]] {
        let workpath = URL(fileURLWithPath: mountPoint).appendingPathComponent(path).path
        self.logger.log(.trace, "getting folders from \(path)")
        var result:[String:[String]] = [:]
        let param = recursive ? "-1tR" : "-1"
        let pipe = Pipe()
        autoreleasepool { () -> Void in
            let command = Process()
            command.standardOutput = pipe
            command.standardError = pipe
            command.currentDirectoryPath = workpath
            command.launchPath = "/bin/ls"
            command.arguments = [param]
            do {
                try command.run()
            }catch{
                self.logger.log(.error, error)
            }
        }
        //command.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let string:String = String(data: data, encoding: String.Encoding.utf8)!
        pipe.fileHandleForReading.closeFile()
        
        let lines = string.components(separatedBy: "\n")
        var subFolder = ""
        for line in lines {
            if line == "" {
                continue
            }
            if line.hasPrefix(".") && line.hasSuffix(":") {
                if line == ".:" {
                    subFolder = ""
                }else{
                    let indexStartOfText = line.index(line.startIndex, offsetBy: 2)
                    let indexEndOfText = line.index(line.endIndex, offsetBy: -1)
                    subFolder = String(line[indexStartOfText..<indexEndOfText])
                }
                continue
            }
            let folder = subFolder == "" ? "." : subFolder
            var filenames = result[folder]
            if filenames == nil {
                filenames = [line]
                result[folder] = filenames
            }else{
                filenames!.append(line)
                result[folder] = filenames
            }
        }
        return result
    }
    
    
    public func filenames(mountPoint:String, in path: String) -> [String] {
        let workpath = URL(fileURLWithPath: mountPoint).appendingPathComponent(path).path
        self.logger.log(.trace, "getting folders from \(workpath)")
        var result:[String] = []
        let pipe = Pipe()
        autoreleasepool { () -> Void in
            let command = Process()
            command.standardOutput = pipe
            command.standardError = pipe
            command.currentDirectoryPath = workpath
            command.launchPath = "/bin/ls"
            command.arguments = ["-go"]
            do {
                try command.run()
            }catch{
                self.logger.log(.error, error)
            }
        }
        //command.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let string:String = String(data: data, encoding: String.Encoding.utf8)!
        pipe.fileHandleForReading.closeFile()
        
        let filenamesForReference = self.filenamesForReference(mountPoint: mountPoint, in: path)
        
        result = DeviceShell.getFilenames(from: string,
                                          refer: filenamesForReference,
                                          excludeFilenames: ["directory", ".", ".."],
                                          allowedExt: FileTypeRecognizer.allowed,
                                          allowedSuffix: ["_backup_hd"], // wechat chatroom image/video thumbnails
                                          deviceOS: .mac)
        self.logger.log(.trace, "got \(result.count) files from \(workpath)")
        return result
    }
}
