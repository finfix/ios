//
//  SnapCarousel.swift
//  Coin
//
//  Created by Илья on 18.10.2022.
//

import SwiftUI

struct SnapCarousel: View {
    
    @State var posts: [Post] = []
    @State var currentIndex: Int = 0

    var body: some View {
        
        
        VStack(spacing: 15) {
            VStack(alignment: .leading, spacing: 12) {
                Button {
                    
                } label: {
                    Label {
                        Text("Back")
                            .fontWeight(.semibold)
                    } icon: {
                        Image(systemName: "chevron.left")
                            .font(.title2.bold())
                    }
                    .foregroundColor(.primary)
                }
                Text("My Wishes")
                    .font(.title)
                    .fontWeight(.black)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            
            SnapCarouselView(spacing: 15, index: $currentIndex, items: posts) { post in
                GeometryReader { proxy in
                    
                    let size = proxy.size
                    
                    Image(post.postImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size.width)
                        .cornerRadius(12)
                }
            }
            
            HStack(spacing: 10) {
                ForEach(posts.indices, id: \.self) { index in
                    Circle()
                        .fill(Color.black.opacity(currentIndex == index ? 1 : 0.1))
                        .frame(width: 5)
                        .scaleEffect(currentIndex == index ? 1.4 : 1)
                        .animation(.spring(), value: currentIndex == index )
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .onAppear {
            for index in 1...3 {
                posts.append(Post(postImage: "post\(index)"))
            }
        }
    }
}

struct SnapCarousel_Previews: PreviewProvider {
    static var previews: some View {
        SnapCarousel()
    }
}

struct SnapCarouselView<Content: View, T: Identifiable>: View {
    var content: (T) -> Content
    var list: [T]
    
    var spacing: CGFloat
    var trailingSpace: CGFloat
    @Binding var index: Int
    
    init(spacing: CGFloat = 15, trailingSpace: CGFloat = 100, index: Binding<Int>, items: [T], @ViewBuilder content: @escaping (T) -> Content) {
        
        self.list = items
        self.spacing = spacing
        self.trailingSpace = trailingSpace
        self._index = index
        self.content = content
    }
    
    @GestureState var offset: CGFloat = 0
    @State var currentIndex: Int = 0
    
    var body: some View {
        
        GeometryReader { proxy in
            
            let width = proxy.size.width - (trailingSpace - spacing)
            let adjustMentWidth = (trailingSpace / 2) - spacing
            
            HStack(spacing: spacing) {
                
                ForEach(list) { item in
                    
                    content(item)
                        .frame(width: proxy.size.width - trailingSpace)
                }
            }
            .padding(.horizontal, spacing)
            .offset(x: (CGFloat(currentIndex) * -width) + (adjustMentWidth) + offset)
            .gesture(
            DragGesture()
                .updating($offset, body: { value, out, _ in
                    out = value.translation.width
                })
                .onEnded({ value in
                     
                    let offsetX = value.translation.width
                    
                    let progress = -offsetX / width
                    
                    let roundIndex = progress.rounded()
                    
                    currentIndex = max(min(currentIndex + Int(roundIndex), list.count - 1), 0)
                    
                    currentIndex = index
                })
                .onChanged({ value in
                    let offsetX = value.translation.width
                    
                    let progress = -offsetX / width
                    
                    let roundIndex = progress.rounded()
                    
                    index = max(min(currentIndex + Int(roundIndex), list.count - 1), 0)
                })
            )
        }
        .animation(.easeInOut, value: offset == 0)
    }
}

struct Post: Identifiable {
    var id = UUID().uuidString
    var postImage: String
}




















