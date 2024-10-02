//
//  ContentView.swift
//  DigitalTowerCard
//
//  Created by Anusri Chavali on 9/27/24.
//

import SwiftUI

struct ContentView: View {
    @State private var email: String = ""
    @State private var input: String = ""
    @State private var nextScreen: Bool = false
    var body: some View {
            VStack {
                Text("Tower Card")
                    .font(.largeTitle)
                    .padding()
                
                TextField("Enter SJSU Email", text: $input)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .padding()
                
                Button(action: {
                    if !input.isEmpty {
                        email = input
                        print("email: \(email)")
                        nextScreen = true
                    }
                }) {
                    Text("Submit")
                        .font(.headline)
                        .padding()
                        .background(Color.yellow)
                        .foregroundColor(.blue)
                        .cornerRadius(10)
                }
                
                
            }
            
            .padding()
        }
}

#Preview {
    ContentView()
}
