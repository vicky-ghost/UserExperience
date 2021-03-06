//
// Copyright (c) Vatsal Manot
//

import Merge
import Foundation
import SwiftUIX

public struct URLRemoteImage<Placeholder: View>: View {
    @usableFromInline
    let placeholder: Placeholder
    
    @usableFromInline
    let url: URL?
    
    @usableFromInline
    let urlSession = URLSession.images
    
    @usableFromInline
    @State var urlTask: AnyCancellable?
    
    @usableFromInline
    @State var image: Image?
    
    @inlinable
    public init(url: URL?, @ViewBuilder placeholder: () -> Placeholder) {
        self.url = url
        self.placeholder = placeholder()
    }
        
    @inlinable
    public var body: some View {
        image.ifSome { image in
            image.resizable()
        }.else {
            placeholder.onAppear {
                if let url = self.url {
                    self.urlTask = self.urlSession
                        .dataTaskPublisher(for: url)
                        .map({ $0.data })
                        .replaceError(with: nil)
                        .receive(on: DispatchQueue.main)
                        .eraseToAnyPublisher()
                        .sink(receiveValue: {
                            self.image = $0.flatMap(Image.init(data:))
                        })
                }
            }
        }
    }
}

private extension URLSession {
    static let images: URLSession = {
        let cachePath = try? FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).absoluteString
        
        #if targetEnvironment(macCatalyst)
        let cache = URLCache(memoryCapacity: 1_024 * 1_024 * 8, diskCapacity: 1_024 * 1_024 * 64, directory: URL(fileURLWithPath: cachePath!))
        #else
        let cache = URLCache(memoryCapacity: 1_024 * 1_024 * 8, diskCapacity: 1_024 * 1_024 * 64, diskPath: cachePath)
        #endif
        
        let configuration = URLSessionConfiguration.default
        
        configuration.urlCache = cache
        configuration.requestCachePolicy = .useProtocolCachePolicy
        
        return URLSession(configuration: configuration)
    }()
}

extension View {
    @inlinable
    public func remoteImage(from url: URL?) -> some View {
        URLRemoteImage(url: url) {
            self
        }
        .id(url)
    }
}
