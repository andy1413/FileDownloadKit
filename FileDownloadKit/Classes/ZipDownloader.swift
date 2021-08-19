//
//  ZipDownloader.swift
//  PrimeStory
//
//  Created by anddy on 2020/4/15.
//  Copyright © 2020 chenyungui. All rights reserved.
//

import Zip
import Alamofire
import LzmaSDK_ObjC

open class ZipDownloader {
    private let queue = DispatchQueue.init(label: "com.FileDownloader.zip", qos: .background)
    private let downloader: FileDownloader
    private let unzipDirectory: URL
    private let unzipFileNameGenerator: (URL) -> String
    
    private var _downloaded: [String] = []//存储的是已下载的文件名
    private var downloaded: [String] {
        set {
            objc_sync_enter(self)
            defer { objc_sync_exit(self) }
            _downloaded = newValue
        }
        get {
            objc_sync_enter(self)
            defer { objc_sync_exit(self) }
            return _downloaded
        }
    }
    
    
    public init(zipDirectory: URL, unzipDirectory: URL, unzipFileNameGenerator: @escaping (URL) -> String = { $0.path.MD5() } ) {
        self.unzipDirectory = unzipDirectory
        self.unzipFileNameGenerator = unzipFileNameGenerator
        self.downloader = .init(saveDirectory: zipDirectory)
        self.downloaded = (try? FileManager.default.contentsOfDirectory(atPath: unzipDirectory.path)) ?? []
    }
    
    /// 下载文件后并解压
    /// - Parameters:
    ///   - url: 请求url
    ///   - timeoutInterval: 超时时间
    ///   - progress: 进度处理
    ///   - completion: 完成处理
    /// - Returns: 返回值是请求id，用来取消请求
    @discardableResult
    open func download(url: URL, timeoutInterval: TimeInterval = 30, progress: ((Double, ProgressStage) -> Void)? = nil, completion: @escaping (Result<URL, Swift.Error>) -> Void) -> String {
        let unzipFileName = unzipFileNameGenerator(url)
        let unzipURL = unzipDirectory.appendingPathComponent(unzipFileName)
        
        guard !downloaded.contains(unzipFileName) else {
            DispatchQueue.main.async {
                completion(.success(unzipURL))
            }
            return UUID().uuidString
        }
        
        let requestId = downloader.download(url: url, timeoutInterval: timeoutInterval, callbackQueue: queue, progress: { (p) in
            DispatchQueue.main.async {
                progress?(p, .download)
            }
        }) { [weak self] (result) in
            guard let self = self else { return }
            switch result {
                case .success(let zipURL):
                    let is7z = zipURL.absoluteString.hasSuffix(".7z")
                    if is7z {
                        do {
                            try Z7Extractor.init().start(archiveURL: zipURL, destinationURL: unzipURL) { (p) in
                                progress?(Double(p), .unzip)
                            }
                            DispatchQueue.main.async {
                                try? FileManager.default.removeItem(at: zipURL)
                                completion(.success(unzipURL))
                                self.downloaded.append(unzipFileName)
                            }
                        } catch {
                            DispatchQueue.main.async {
                                completion(.failure(error))
                            }
                            try? FileManager.default.removeItem(at: unzipURL)
                        }
                    } else {
                        do {
                            try Zip.unzipFile(zipURL, destination: unzipURL, overwrite: true, password: nil, progress: { (p) in
                                progress?(p, .unzip)
                                if p == 1 {
                                    DispatchQueue.main.async {
                                        try? FileManager.default.removeItem(at: zipURL)
                                        completion(.success(unzipURL))
                                        self.downloaded.append(unzipFileName)
                                    }
                                }
                            }, fileOutputHandler: nil)
                        } catch {
                            DispatchQueue.main.async {
                                completion(.failure(error))
                            }
                            try? FileManager.default.removeItem(at: unzipURL)
                        }
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
            }
        }
        return requestId
    }
    
    open func cancel(url: URL) {
        downloader.cancel(url: url)
    }
    
    open func cancel(requestId: String) {
        downloader.cancel(requestId: requestId)
    }
    
    open func isDownloading(url: URL) -> Bool {
        return downloader.isDownloading(url: url)
    }
    
    open func isDownloaded(url: URL) -> Bool {
        let fileName = unzipFileNameGenerator(url)
        return downloaded.contains(fileName)
    }
}

public extension ZipDownloader {
    enum ProgressStage {
        case download
        case unzip
    }
    
    enum FileType {
        case zip, z7
    }
}
