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
                Text("text_key")
                
                Text(key)
                
//                VStack(alignment: .leading) {
//                    Text("text_key_\("lol")", tableName: "Localizable", bundle: .main, comment: "comment")
//                    
//                    Text(verbatim: UL("verbatim"))
//                        .bold()
//                    
//                    Text(NSLocalizedString("nslocalized_key", tableName: "Localizable", bundle: .main, comment: "comment"))
//                        .bold()
//                    
//                    Text(localizedStringResource: LocalizedStringResource("text_key"))
//                    
//                    Text(key)
//                    
//                    Button("button_key") { print("HI") }
//                }
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
