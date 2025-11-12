//
//  Bars.swift
//  Shazam
//
//  Created by Aniseh Khajuei on 12/11/25.
//

import SwiftUI

struct Bars: View {
        
        let barsMaxHeight: CGFloat = 50
        let barsMinHeight: CGFloat = 20
        let barsWidth: CGFloat = 10
        let barsSpacing: CGFloat = 2
        let barsCount: Int = 3
        let barsColor: Color = Color.white
        let cycleDuration: Double = 1.0
        let barsFrequency: Double = 3          // how fast bars oscillate

        
        
        var body: some View {
            
                
                ZStack {
                    LinearGradient(gradient: Gradient(colors: [Color.blue, Color.white]), startPoint: .top, endPoint: .bottom)
                        .ignoresSafeArea(edges: .all)
                    
                    
                    // TimelineView for time-driven animation
                    
                    TimelineView(.animation) { ctx in
                        let t = ctx.date.timeIntervalSinceReferenceDate
                        let barsPhaseOffset = t * barsFrequency
                        
                        
                        HStack {
                            
                            ForEach(0..<3) { i in
                                
                                let phaseOffset = (Double(i) + 1)
                                let sine = (sin(barsPhaseOffset + phaseOffset) * 0.5 + 0.5)   // 0..1
                                // final height mixes sine (0..1) with growth factor
                                let h = barsMinHeight + CGFloat(sine) * (barsMaxHeight - barsMinHeight)
                     
                                
                                Capsule()
                                    .frame(width: barsWidth, height: h)
                                    .foregroundColor(barsColor)
                                    
                            }
                        }
                        
                        
                        
                        
                        
                        
                    }
                    
                    
                }//END ZSTACK
                
                
            
            
            
            
            
        }//END TIMELINEVIEW
        
        
    
        
        
        
        
        
        
        
    }

#Preview {
    Bars()
}
