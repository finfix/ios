import SwiftUI

struct GraphView : View {
    var rangeTime: Range<Int>
    var line: Line
    var rangeY: Range<Double>?
    var lineWidth: CGFloat = 1
   
    private var minY: Double {rangeY == nil ? line.points[rangeTime].min()! : rangeY!.lowerBound}
    private var maxY: Double {rangeY == nil ? line.points[rangeTime].max()!: rangeY!.upperBound}
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width: CGFloat = geometry.size.width
                let scale = geometry.size.height / (CGFloat(self.maxY - self.minY) )
                let origin = CGPoint(x: 0, y: geometry.size.height )
                let step = (width - origin.x) / CGFloat(self.rangeTime.distance(from: rangeTime.startIndex, to: rangeTime.endIndex) - 1)
                
               path.addLines(Array(self.rangeTime.lowerBound..<self.rangeTime.upperBound)
                            .map{ CGPoint(x: origin.x + CGFloat($0 - self.rangeTime.lowerBound) * step,
                                         y: origin.y - CGFloat(self.line.points[$0]  - self.minY)  * scale)
                                }
                             )
            }
                .stroke(lineWidth: self.lineWidth)
                .animation(.linear(duration: 0.6))
        }
    }
}


struct GraphView_Previews : PreviewProvider {
    static var previews: some View {
        GraphView ( rangeTime: 0..<(myLine.points.count - 1),
                   line: myLine, lineWidth: 2 )
        .frame( height: 400 )
        .border(.black)
    }
}


