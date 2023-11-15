//
//  ContentView.swift
//  UserLinguaExample
//
//  Created by Sam Rayner on 06/04/2023.
//

import SwiftUI
import UserLingua

struct ContentView: View, UserLinguaOptIn {
    var body: some View {
        VStack {
            Text("text_key", tableName: "Localizable", bundle: .main, comment: "comment")
            
            Text("text_key_\("lol")", tableName: "Localizable", bundle: .main, comment: "comment")
            
            Text(verbatim: "verbatim")
                .bold()
            
            Text(NSLocalizedString("nslocalized_key", tableName: "Localizable", bundle: .main, comment: "comment"))
                .bold()
            
            Text("content")
            
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
