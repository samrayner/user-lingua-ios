//
//  ContentView.swift
//  UserLinguaExample
//
//  Created by Sam Rayner on 06/04/2023.
//

import SwiftUI
import UserLingua

let key = "text_key"

struct ContentView: View {
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                Text("text_key", tableName: "Localizable", userLingua: true)
                
                VStack(alignment: .leading) {
                    Text("text_key_\("lol")", tableName: "Localizable", bundle: .main, comment: "comment", userLingua: true)
                    
                    Text(verbatim: "verbatim".userLingua())
                        .bold()
                    
                    Text(NSLocalizedString("nslocalized_key", tableName: "Localizable", bundle: .main, comment: "comment").userLingua())
                        .bold()
                    
                    Text("text_key", userLingua: true)
                    
                    Text(key.userLingua())
                }
            }
            
            Button("button_key", action: {})
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewLayout(.sizeThatFits)
    }
}
