//
//  ContentView.swift
//  ColorDrag
//
//  Created by Joseph Albanese on 11/13/24.
//

import SwiftUI

struct ColorPicker: View {
    @State var hue: CGFloat = 0.40
    @State var saturation: CGFloat = 0.0
    @State var brightness: CGFloat = 1.0
    @State var selectedPoint: CGPoint = .zero
    @State var press: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ColorGrid(
                    hue: $hue,
                    saturation: $saturation,
                    brightness: $brightness,
                    selectedPoint: $selectedPoint,
                    press: $press)
                
                if press {
                    Circle()
                        .fill(Color(hue: hue, saturation: saturation, brightness: brightness))
                        .frame(width: 44, height: 44)
                        .offset(y: -24)
                        .position(selectedPoint)
                        .shadow(color: .black.opacity(0.2), radius: 16, y: 4)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(1.0), lineWidth: 2)
                                .frame(width: 44, height: 44)
                                .position(selectedPoint)
                                .offset(y: -24)
                        )
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    var brightnessSlider: some View {
        Slider(value: $brightness)
            .accentColor(Color(hue: hue, saturation: saturation, brightness: 1.0))
            .padding()
            .background(Color.black.opacity(0.7))
            .cornerRadius(10)
    }
}


struct ColorGrid: View {
    @Binding var hue: CGFloat
    @Binding var saturation: CGFloat
    @Binding var brightness: CGFloat
    @Binding var selectedPoint: CGPoint
    @Binding var press: Bool
    @State private var lastKnownLocation: CGPoint = .zero
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                Canvas { context, size in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let radius = sqrt(pow(size.width / 2, 2) + pow(size.height / 2, 2))
                    
                    for x in 0..<Int(size.width) {
                        for y in 0..<Int(size.height) {
                            let point = CGPoint(x: CGFloat(x), y: CGFloat(y))
                            let vector = CGVector(dx: point.x - center.x, dy: point.y - center.y)
                            
                            let angle = atan2(vector.dy, vector.dx)
                            let distance = sqrt(vector.dx * vector.dx + vector.dy * vector.dy)
                            
                            let hue = (angle + .pi) / (2 * .pi)
                            let saturation = pow(min(distance / radius, 1.0), 0.0)
                            let brightness = 0.8 + 0.2 * (1 - saturation)
                            
                            let color = Color(hue: hue, saturation: saturation, brightness: brightness)
                            context.fill(Path(CGRect(origin: point, size: CGSize(width: 1, height: 1))), with: .color(color))
                        }
                    }
                }
                .blur(radius: 40)
                
                let longPress = LongPressGesture(minimumDuration: 0.01)
                    .onEnded { _ in
                        playHaptic(style: .soft)
                        withAnimation {
                            press = true
                        }
                    }
                
                let drag = DragGesture()
                    .onChanged { value in
                        updateColor(at: value.location, in: geometry.size)
                    }
                    .onEnded { _ in
                        withAnimation {
                            press = false
                        }
                    }

                let combined = longPress.sequenced(before: drag)
                
                Rectangle()
                    .foregroundStyle(.white.opacity(0.001))
                    .opacity(0.3)
                    .preferredColorScheme(.light)
                    .gesture(combined)
            }
            
            // This circle grid will make the simulator and preview lag but should run fine on device
             CircleGridView()
        }
    }
    
    private func updateColor(at point: CGPoint, in size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let vector = CGVector(dx: point.x - center.x, dy: point.y - center.y)
        let angle = atan2(vector.dy, vector.dx)
        let distance = sqrt(vector.dx * vector.dx + vector.dy * vector.dy)
        let radius = sqrt(pow(size.width / 2, 2) + pow(size.height / 2, 2))
        
        hue = (angle + .pi) / (2 * .pi)
        saturation = min(distance / radius, 1.0)
        selectedPoint = point
    }
}

struct CircleGridView: View {
    let fillColor = Color(.white.opacity(0.4))
    
    var body: some View {
        GeometryReader { geometry in
            let circleSize: CGFloat = 2
            let spacing: CGFloat = 6
            
            let columns = Int(geometry.size.width / (circleSize + spacing))
            let rows = Int(geometry.size.height / (circleSize + spacing))
            
            VStack(spacing: spacing) {
                ForEach(0..<rows, id: \.self) { _ in
                    HStack(spacing: spacing) {
                        ForEach(0..<columns, id: \.self) { _ in
                            Circle()
                                .fill(fillColor)
                                .frame(width: circleSize, height: circleSize)
                        }
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .blendMode(.softLight)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ColorPicker()
}
