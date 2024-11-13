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
                
                // Selection indicator
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
                            
                            // Increase saturation and brightness slightly to reduce whiteness in the center
                            let saturation = pow(min(distance / radius, 1.0), 0.0)
                            let brightness = 0.8 + 0.2 * (1 - saturation) // Ensure brightness is reduced near the center
                            
                            let color = Color(hue: hue, saturation: saturation, brightness: brightness)
                            context.fill(Path(CGRect(origin: point, size: CGSize(width: 1, height: 1))), with: .color(color))
                        }
                    }
                }
                .blur(radius: 40)
                .onChange(of: selectedPoint) { newValue in
                    let hue = calculateHue(for: newValue, in: geometry.size)
                    let saturation = calculateSaturation(for: newValue, in: geometry.size)
                    let brightness = calculateBrightness(for: newValue, in: geometry.size)
                    
                    let (r, g, b) = hsbToRgb(h: hue, s: saturation, b: brightness)
                }
                
                let longPress = LongPressGesture(minimumDuration: 0.01)
                    .onEnded { _ in
                        playHaptic(style: .soft)
                    }
                
                let drag = DragGesture()
                    .onChanged { value in
                        updateColor(at: value.location, in: geometry.size)
                        withAnimation {
                            print("pressed")
                            press = true
                        }
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
            CircleGridView()
        }
    }
    
    func calculateHue(for point: CGPoint, in size: CGSize) -> Double {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let angle = atan2(point.y - center.y, point.x - center.x)
        return (angle + .pi) / (2 * Double.pi)
    }

    func calculateSaturation(for point: CGPoint, in size: CGSize) -> Double {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = sqrt(pow(size.width / 2, 2) + pow(size.height / 2, 2))
        let distance = sqrt(pow(point.x - center.x, 2) + pow(point.y - center.y, 2))
        return pow(min(distance / radius, 1.0), 0.0)
    }

    func calculateBrightness(for point: CGPoint, in size: CGSize) -> Double {
        let saturation = calculateSaturation(for: point, in: size)
        return 0.8 + 0.2 * (1 - saturation)
    }

    func hsbToRgb(h: Double, s: Double, b: Double) -> (red: Double, green: Double, blue: Double) {
        let c = b * s
        let x = c * (1 - abs((h * 6).truncatingRemainder(dividingBy: 2) - 1))
        let m = b - c
        
        var r, g, b: Double
        
        switch h * 6 {
        case 0..<1: (r, g, b) = (c, x, 0)
        case 1..<2: (r, g, b) = (x, c, 0)
        case 2..<3: (r, g, b) = (0, c, x)
        case 3..<4: (r, g, b) = (0, x, c)
        case 4..<5: (r, g, b) = (x, 0, c)
        case 5..<6: (r, g, b) = (c, 0, x)
        default: (r, g, b) = (0, 0, 0)
        }
        
        return (r + m, g + m, b + m)
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
    
    private func updateCodeRGBValues() {
        let rgbValues = hsbToRGB(hue: hue, saturation: saturation, brightness: brightness)
    }
    
    private func hsbToRGB(hue: CGFloat, saturation: CGFloat, brightness: CGFloat) -> (red: CGFloat, green: CGFloat, blue: CGFloat) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        
        let i = floor(hue * 6)
        let f = hue * 6 - i
        let p = brightness * (1 - saturation)
        let q = brightness * (1 - f * saturation)
        let t = brightness * (1 - (1 - f) * saturation)
        
        switch Int(i) % 6 {
        case 0: r = brightness; g = t; b = p
        case 1: r = q; g = brightness; b = p
        case 2: r = p; g = brightness; b = t
        case 3: r = p; g = q; b = brightness
        case 4: r = t; g = p; b = brightness
        case 5: r = brightness; g = p; b = q
        default: break
        }
        
        return (red: r, green: g, blue: b)
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
