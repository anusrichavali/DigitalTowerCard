//
//  ContentView.swift
//  DigitalTowerCard
//
//  Created by Anusri Chavali on 9/27/24.
//

import SwiftUI
import CoreNFC

//class to generate the NFC card reader
class NFCCardReader: NSObject, NFCNDEFReaderSessionDelegate {
    var session: NFCNDEFReaderSession?

    func beginScanning() {
        guard NFCNDEFReaderSession.readingAvailable else {
            print("NFC not supported on this device.")
            return
        }

        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        session?.alertMessage = "Hold your NFC card near the device."
        session?.begin()
    }

    //used for successful nfc reading
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        for message in messages {
            for record in message.records {
                // Handle NFC data here (this is where you would extract the ID or any info from the card)
                print("NFC message received: \(record.payload)")
            }
        }
    }

    //used for unsuccessful nfc reading (timeout, error)
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        if let nfcError = error as? NFCReaderError {
            switch nfcError.code {
            case .readerSessionInvalidationErrorUserCanceled:
                print("User canceled the session.")
            default:
                print("NFC Error: \(error.localizedDescription)")
            }
        }
    }
}

//modularize the code for buttons to replicate the button style across the app
struct CustomButton: View {
    var buttonText: String
    var action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
        }) {
            Text(buttonText)
                .font(.headline)
                .padding()
                .background(Color.yellow)
                .foregroundColor(.blue)
                .cornerRadius(10)
        }
    }
}

//modularize the code for large titles
struct CustomTitle: View {
    var title: String
    
    var body: some View {
        Text(title)
            .font(.largeTitle)
            .padding()
    }
}

struct CardText: View {
    var text: String
    
    var body: some View {
        Text(text)
            .font(.title2)
            .padding(.bottom, 2)
            .foregroundColor(.white)
    }
}


struct ContentView: View {
    @State private var email: String = ""
    @State private var input: String = ""
    @State private var nextScreen: Bool = false
    @State private var errorMessage: String = ""
    @State private var goToVerification: Bool = false
    @State private var emailSent: Bool = false
    
    //function to connect to the fastapi to send verification code email
    func sendVerificationEmail() {
        emailSent = true
        guard let url = URL(string: "http://localhost:8000/") else {return}
        
        var requestAPI = URLRequest(url: url)
        requestAPI.httpMethod = "POST"
        
        let userEmail = ["email": email]
        requestAPI.httpBody = try? JSONSerialization.data(withJSONObject: userEmail)
        requestAPI.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: requestAPI) {data, response, error in
            DispatchQueue.main.async {
                emailSent = false
                if error != nil {
                    print("Failed to send email")
                    return
                }
                
                if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                    print("Email sent")
                    goToVerification = true
                } else {
                    print("Email failed to send")
                }
            }
        }.resume()
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                CustomTitle(title: "DIGI-TOWER")
                    
                TextField("Enter SJSU Email", text: $input)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray, lineWidth: 2)
                    )
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .padding()
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                CustomButton(buttonText: "Submit") {
                    if !input.isEmpty && input.hasSuffix("@sjsu.edu") {
                        email = input
                        print("email: \(email)")
                        errorMessage = ""
                        goToVerification = true
                    } else {
                        errorMessage = "Please enter a valid SJSU email"
                    }
                }
                
            }
            .padding()
            .navigationDestination(isPresented: $goToVerification) {
                VerificationCode()
            }
        }
    }
}

struct VerificationCode: View {
    @State private var code = Array(repeating: "", count: 4)
    @State private var goToCard = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        VStack {
            CustomTitle(title: "Enter Verification Code")
            
            HStack {
                ForEach(0..<4, id:\.self) {
                    index in
                    TextField("", text: $code[index])
                        .frame(width:30, height:60)
                        .multilineTextAlignment(.center)
                        .padding()
                        .keyboardType(.numberPad)
                        .background(Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
            }
            .padding()
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            CustomButton(buttonText: "Submit"){
                if isCodeComplete() {
                    goToCard = true
                    print("Verification Code Submitted")
                } else {
                    errorMessage = "Please enter a verification code"
                }
            }
            
        }
        .padding()
        .navigationDestination(isPresented: $goToCard) {
            CardView()
        }
        
    }
    func isCodeComplete() -> Bool {
            return code.allSatisfy { !$0.isEmpty }
        }
}

struct CardView: View {
    @State private var name: String = "John Doe"
    @State private var idNumber: String = "12345678"
    let nfcReader = NFCCardReader()
    
    var body: some View {
        VStack {
            CustomTitle(title: "Welcome \(name)!")
            
            VStack {
                CardText(text: "NAME: \(name)")
                
                CardText(text: "ID Number: \(idNumber)")
                
                CardText(text: "STUDENT")
            }
            .frame(width: 300, height: 400)
            .background(Color.blue.opacity(0.4))
            .cornerRadius(5)
            .shadow(color: Color.black.opacity(0.5), radius: 5, x: -5, y: -5)
            .padding(.top, 50)
            
            Spacer()
            
            CustomButton(buttonText: "TAP CARD") {
                nfcReader.beginScanning()
                print("Card tapped")
            }
            .padding(.bottom, 50)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
