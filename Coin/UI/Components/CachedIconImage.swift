//
//  CachedIconImage.swift
//  Coin
//

import SwiftUI

/// AsyncImage перезапускает свою полную state machine (проверка URL → загрузка → декод) при
/// каждой пересборке view, даже для одного и того же локального файла — на экране с десятками
/// кружков счетов это заметно грузит main thread при каждом свайпе страниц (TabView(.page)
/// пересобирает содержимое страниц не лениво). Иконки — маленькие локальные файлы на диске,
/// которые не меняются, поэтому декодированный UIImage можно закэшировать в памяти по имени файла
/// и не декодировать заново, пока не перезапустится процесс.
private let iconImageCache = NSCache<NSString, UIImage>()

struct CachedIconImage: View {
    let fileName: String

    @State private var uiImage: UIImage?

    var body: some View {
        Group {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Color.clear
            }
        }
        .task(id: fileName) {
            guard !fileName.isEmpty else { return }

            if let cached = iconImageCache.object(forKey: fileName as NSString) {
                uiImage = cached
                return
            }

            let url = URL.documentsDirectory.appending(path: fileName)
            guard let data = try? Data(contentsOf: url), let image = UIImage(data: data) else { return }
            iconImageCache.setObject(image, forKey: fileName as NSString)
            uiImage = image
        }
    }
}
