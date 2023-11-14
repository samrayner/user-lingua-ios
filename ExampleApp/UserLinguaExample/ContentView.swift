//
//  ContentView.swift
//  UserLinguaExample
//
//  Created by Sam Rayner on 06/04/2023.
//

import SwiftUI
import UserLingua

struct ContentView: View {
    var body: some View {
        VStack {
            Text("text_key", tableName: "Localizable", bundle: .main, comment: "comment")
                .userLingua()
            
            Text(verbatim: "verbatim")
                .userLingua()
            
            Text(NSLocalizedString("nslocalized_key", tableName: "Localizable", bundle: .main, comment: "comment"))
                .userLingua()
            
            Text("content")
                .userLingua()
            
            Button("button_key", action: {})
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
