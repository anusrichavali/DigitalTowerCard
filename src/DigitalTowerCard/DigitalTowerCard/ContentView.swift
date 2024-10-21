//
//  ContentView.swift
//  DigitalTowerCard
//
//  Created by Anusri Chavali on 9/27/24.
//

import SwiftUI

struct VerificationCode: View {
    @State private var code = Array(repeating: "", count: 4)
    
    var body: some View {
        VStack {
            Text("Enter Verification")
                .font(.largeTitle)
                .padding()
            
            HStack {
                ForEach(0..<4, id:\.self) {
                    index in
                    TextField("", text: $code[index])
                        .frame(width:40, height:60)
                        .multilineTextAlignment(.center)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                }
            }
            .padding()
            
            Button(action: {
                print("Verification Code Submitted")
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

struct ContentView: View {
    @State private var email: String = ""
    @State private var input: String = ""
    @State private var nextScreen: Bool = false
    @State private var errorMessage: String = ""
    @State private var goToVerification: Bool = false
    
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Tower Card")
                    .font(.largeTitle)
                    .padding()
                
                TextField("Enter SJSU Email", text: $input)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .padding()
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Button(action: {
                    if !input.isEmpty && input.hasSuffix("@sjsu.edu") {
                        email = input
                        print("email: \(email)")
                        nextScreen = true
                        errorMessage = ""
                        goToVerification = true
                    } else {
                        errorMessage = "Please enter a valid SJSU email"
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
            .navigationDestination(isPresented: $goToVerification) {
                VerificationCode()
            }
            
        }
    }
}


#Preview {
    ContentView()
}
