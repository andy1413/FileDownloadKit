//
//  FileDownloader.swift
//  PrimeStory
//
//  Created by anddy on 2020/4/13.
//  Copyright © 2020 chenyungui. All rights reserved.
//

import Alamofire
import CommonCrypto

open class FileDownloader {
    let saveDirectory: URL
    
    private var _completionHandler: [URL: [String: (Result<URL, AFError>) -> Void]] = [:]
    private var completionHandler: [URL: [String: (Result<URL, AFError>) -> Void]] {
        set {
            objc_sync_enter(self)
            defer { objc_sync_exit(self) }
            _completionHandler = newValue
        }
        get {
            objc_sync_enter(self)
            defer { objc_sync_exit(self) }
            return _completionHandler
        }
    }
    
    private var _progressHandler: [URL: [String: ((Double) -> Void)?]] = [:]
    private var progressHandler: [URL: [String: ((Double) -> Void)?]] {
        set {
            objc_sync_enter(self)
            defer { objc_sync_exit(self) }
            _progressHandler = newValue
        }
        get {
            objc_sync_enter(self)
            defer { objc_sync_exit(self) }
            return _progressHandler
        }
    }
    
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
    
    private var _downloading: [URL: Model] = [:]
    private var downloading: [URL: Model] {
        set {
            objc_sync_enter(self)
            defer { objc_sync_exit(self) }
            _downloading = newValue
        }
        get {
            return _downloading
        }
    }
    
    
    public init(saveDirectory: URL) {
        self.saveDirectory = saveDirectory
        self.saveDirectory.createFileDirectory()
        self.downloaded = (try? FileManager.default.contentsOfDirectory(atPath: saveDirectory.path)) ?? []
    }
    
    
    /// 下载文件
    /// - Parameters:
    ///   - url: 请求url
    ///   - timeoutInterval: 超时时间
    ///   - queue: 回调队列
    ///   - progress: 进度处理
    ///   - completion: 完成处理
    /// - Returns: 返回值是请求id，用来取消请求
    @discardableResult
    open func download(url: URL, timeoutInterval: TimeInterval = 30, callbackQueue queue: DispatchQueue = .main, progress: ((Double) -> Void)? = nil, completion: @escaping (Result<URL, AFError>) -> Void, md5: String? = nil) -> String {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        let fileName = url._correspondingFileName
        let desURL = saveDirectory.appendingPathComponent(fileName)
        let requestID = UUID().uuidString
        guard !downloaded.contains(fileName) else {
            DispatchQueue.main.async {
                completion(.success(desURL))
            }
            return requestID
        }
        var completionDict = completionHandler[url] ?? [:]
        var progressDict = progressHandler[url] ?? [:]
        completionDict[requestID] = completion
        progressDict[requestID] = progress
        completionHandler[url] = completionDict
        progressHandler[url] = progressDict
        
        if let model = downloading.first(where: { $0.key == url }) {
            switch model.value.status {
                case .downloading:
                    break
                case .paused:
                    model.value.status = .downloading
                    model.value.request.resume()
            }
        } else {
            let destination: DownloadRequest.Destination = { _, _ in
                return (desURL, [.removePreviousFile, .createIntermediateDirectories])
            }

            let request = AF.download(url, to: destination)
                .downloadProgress { [weak self] (progress) in
                    guard let self = self else { return }
                    let handlers = self.progressHandler[url]
                    handlers?.forEach { (_, handler) in
                        handler?(progress.fractionCompleted)
                    }
                }
                .responseData { [weak self] (response) in
                    guard let self = self else { return }
                    let handlers = self.completionHandler[url]
                    queue.async {
                        if case let .failure(error) = response.result {
                            handlers?.forEach { (_, handler) in
                                handler(.failure(error))
                            }
                            try? FileManager.default.removeItem(at: desURL)
                        } else if response.response?.statusCode == 200 {
                            if let md5 = md5 {
                                if md5 == self.md5(url: desURL) {
                                    handlers?.forEach { (_, handler) in
                                        handler(.success(desURL))
                                    }
                                    self.downloaded.append(fileName)
                                } else {
                                    //校验失败
                                    handlers?.forEach { (_, handler) in
                                        handler(.failure(.responseValidationFailed(reason: .dataFileNil)))
                                    }
                                    try? FileManager.default.removeItem(at: desURL)
                                }
                            } else {
                                handlers?.forEach { (_, handler) in
                                    handler(.success(desURL))
                                }
                                self.downloaded.append(fileName)
                            }
                        } else {
                            handlers?.forEach { (_, handler) in
                                let reason = AFError.ResponseValidationFailureReason.customValidationFailed(error: Error.unknown)
                                handler(.failure(AFError.responseValidationFailed(reason: reason)))
                            }
                            try? FileManager.default.removeItem(at: desURL)
                        }
                        self.downloading[url] = nil
                        self.completionHandler[url] = nil
                        self.progressHandler[url] = nil
                    }
                }
            
            let model = Model.init(url: url, status: .downloading, request: request)
            downloading[url] = model
        }
        return requestID
    }
    
    open func suspend(url: URL) {
        guard let model = downloading.first(where: { $0.key == url && $0.value.status == .downloading }) else { return }
        model.value.request.suspend()
        model.value.status = .paused
    }

    @discardableResult
    open func suspendAll() -> [URL] {
        downloading.values.forEach({
            $0.request.suspend()
            $0.status = .paused
        })
        let urls = Array(downloading.keys)
        return urls
    }

    open func suspendAll(exclude url: URL) {
        downloading.values.filter({ $0.url != url }).forEach({ $0.request.suspend() })
    }

    open func resume(url: URL) {
        resume(urls: [url])
    }

    open func resume(urls: [URL]) {
        urls.forEach { (url) in
            if let model = downloading.first(where: { $0.key == url }) {
                model.value.request.resume()
                model.value.status = .downloading
            }
        }
    }
    
    open func cancel(url: URL) {
        completionHandler[url] = nil
        progressHandler[url] = nil
        let model = downloading[url]
        model?.request.cancel()
        downloading[url] = nil
    }
    
    open func cancel(requestId: String) {
        guard let handler = completionHandler.first(where: { $0.value.contains(where: { $0.key == requestId }) }) else {
            return
        }
        let url = handler.key
        completionHandler[url]?[requestId] = nil
        progressHandler[url]?[requestId] = nil
        // 如果没有在请求了
        guard completionHandler[url]?.isEmpty == true else {
            return
        }
        cancel(url: url)
    }
    
    open func cancelAll() {
        completionHandler = [:]
        progressHandler = [:]
        downloading.values.forEach({ $0.request.cancel() })
        downloading = [:]
    }
    
    open func cancelAll(exclude url: URL) {
        if let handler = completionHandler[url] {
            completionHandler = [url: handler]
            if let ph = progressHandler[url] {
                progressHandler = [url: ph]
            } else {
                progressHandler = [:]
            }
        } else {
            completionHandler = [:]
            progressHandler = [:]
        }
        
        if let model = downloading[url] {
            downloading.filter({ $0.key != url }).forEach({ $0.value.request.cancel() })
            downloading = [url: model]
        } else {
            downloading.forEach({ $0.value.request.cancel() })
            downloading = [:]
        }
    }
    
    open func isDownloading(url: URL) -> Bool {
        return downloading[url] != nil
    }
    
    open func isDownloaded(url: URL) -> Bool {
        let fileName = url._correspondingFileName
        return downloaded.contains(fileName)
    }
    
    func md5(url: URL) -> String {
        let bufferSize = 1024*1024
        do {
            let file = try FileHandle.init(forReadingFrom: url)
            defer {
                file.closeFile()
            }

            var context = CC_MD5_CTX.init()
            CC_MD5_Init(&context)
            while case let data = file.readData(ofLength: bufferSize), data.count > 0 {
                data.withUnsafeBytes { (poiner) -> Void in
                    _ = CC_MD5_Update(&context, poiner, CC_LONG(data.count))
                }
            }

            // 计算MD5摘要
            var digest = Data(count: Int(CC_MD5_DIGEST_LENGTH))
            digest.withUnsafeMutableBytes { (pointer) -> Void in
                _ = CC_MD5_Final(pointer, &context)
            }
            let result = digest.map { (byte) -> String in
                String.init(format: "%02hhx", byte)
            }.joined()
            return result
        } catch {
            return ""
        }
    }
}

public extension FileDownloader {
    class Model {
        let url: URL//资源的原始链接
        var status: Status
        let request: DownloadRequest
        
        
        enum Status {
            case downloading, paused
        }
        
        init(url: URL, status: Status, request: DownloadRequest) {
            self.url = url
            self.status = status
            self.request = request
        }
    }
    
    enum Error: Swift.Error {
        case cancel, unknown
    }
}
 
public extension URL {
    var _correspondingFileName: String {
        return path.MD5() + "." + pathExtension
    }
}
