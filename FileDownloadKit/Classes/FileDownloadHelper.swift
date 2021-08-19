//
//  FileDownloadHelper.swift
//  FileDownloader
//
//  Created by anddy on 2020/4/15.
//  Copyright © 2020 anddy. All rights reserved.
//

import Foundation

extension URL {
    func createFileDirectory() {
        guard !FileManager.default.fileExists(atPath: path) else { return }
        let url = self.hasDirectoryPath ? self : self.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
    }
}



import CommonCrypto

extension String {
    public func MD5() -> String {
        let length = Int(CC_MD5_DIGEST_LENGTH)
        let messageData = data(using:.utf8)!
        var digestData = Data(count: length)

        _ = digestData.withUnsafeMutableBytes { digestBytes -> UInt8 in
            messageData.withUnsafeBytes { messageBytes -> UInt8 in
                if let messageBytesBaseAddress = messageBytes.baseAddress, let digestBytesBlindMemory = digestBytes.bindMemory(to: UInt8.self).baseAddress {
                    let messageLength = CC_LONG(messageData.count)
                    CC_MD5(messageBytesBaseAddress, messageLength, digestBytesBlindMemory)
                }
                return 0
            }
        }
        let result = digestData.map({ String.init(format: "%02hhx", $0) }).joined()
        return result
    }
}
