//
//  Z7Extractor.swift
//  FileDownloadKit
//
//  Created by anddy on 2021/4/28.
//

import Foundation
import LzmaSDK_ObjC

class Z7Extractor: NSObject {
    private var progressHandler: ((Float) -> Void)?
    private var reader: LzmaSDKObjCReader!

    
    func start(archiveURL: URL, destinationURL: URL, progressHandler: ((Float) -> Void)?) throws {
        self.progressHandler = progressHandler
        reader = .init(fileURL: archiveURL)
        reader.delegate = self
        try reader.open()
        var items = [LzmaSDKObjCItem]()
        reader.iterate { item, error in
            items.append(item)
            return true
        }
        if let error = reader.lastError {
            throw error
        }
        if reader.extract(items, toPath: destinationURL.path, withFullPaths: true) == false {
            let error = reader.lastError ?? NSError.init(domain: "FileDownloadKit", code: -1,
                                                         userInfo: [NSLocalizedDescriptionKey: "Data Error"])
            throw error
        }
    }
}

extension Z7Extractor: LzmaSDKObjCReaderDelegate {
    func onLzmaSDKObjCReader(_ reader: LzmaSDKObjCReader, extractProgress progress: Float) {
        progressHandler?(progress)
    }
}
