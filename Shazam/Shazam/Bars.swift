//
//  Bars.swift
//  Shazam
//
//  Created by Aniseh Khajuei on 12/11/25.
//

import SwiftUI

struct Bars: View {
        
        let barsMaxHeight: CGFloat = 30
        let barsMinHeight: CGFloat = 12
        let barsWidth: CGFloat = 8
        let barsSpacing: CGFloat = 2
        let barsCount: Int = 3
        let barsColor: Color = Color.white
        let cycleDuration: Double = 1.0
        let barsFrequency: Double = 3          // how fast bars oscillate

        
        
        var body: some View {
            
                
            
                ZStack {
                    // background gradient
                    /*LinearGradient(gradient: Gradient(colors: [.blue, .white]),
                                   startPoint: .top, endPoint: .bottom)
                        .ignoresSafeArea()
                     */

                    
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
