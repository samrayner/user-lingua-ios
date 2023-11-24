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
            HStack(alignment: .top, spacing: 30) {
                Text("text_key", tableName: "Localizable")
                
                VStack(alignment: .leading) {
                    Text("text_key_\("lol")", tableName: "Localizable", bundle: .main, comment: "comment")
                    
                    Text(verbatim: userLingua("verbatim"))
                        .bold()
                    
                    Text(userLingua(NSLocalizedString("nslocalized_key", tableName: "Localizable", bundle: .main, comment: "comment")))
                        .bold()
                    
                    Text(localizedStringResource: LocalizedStringResource("text_key"))
                    
                    Text(userLingua(key))
                }
            }
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
