//
//  ContentView.swift
//  DigitalTowerCard
//
//  Created by Anusri Chavali on 9/27/24.
//

import SwiftUI
import CoreNFC
import CoreImage.CIFilterBuiltins

//class to generate the NFC card reader
class NFCCardReader: NSObject, NFCNDEFReaderSessionDelegate {
    var session: NFCNDEFReaderSession?

    //scanning function when tap card is clicked
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

//modularize the code for text on the digital tower card
struct CardText: View {
    var text: String
    
    var body: some View {
        Text(text)
            .font(.title2)
            .padding(.bottom, 2)
            .foregroundColor(.white)
    }
}

//structure containing the SJSU logo which is displayed on the app
struct Logo: View {
    var body: some View {
        //loads image from the assets file
        Image("San_Jose_State_Spartans_logo")
            .resizable()
            .frame(width: 50, height: 50)
            .background(Color.white.opacity(0.7))
            .cornerRadius(5)
            .padding([.top, .trailing], 10)
    }
}

//view for the landing page -- sending email
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
        //connect to fastAPI
        guard let url = URL(string: "http://localhost:8000/") else {return}
        
        var requestAPI = URLRequest(url: url)
        requestAPI.httpMethod = "POST"
        
        //sends the user email to the api request
        let userEmail = ["email": email]
        requestAPI.httpBody = try? JSONSerialization.data(withJSONObject: userEmail)
        requestAPI.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        //handle successful and unsuccessful requests to the email sending api
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
    
    //view containing the stack for title, slogan, email entry, and submit
    var body: some View {
        NavigationStack {
            Logo()
            VStack {
                //title
                CustomTitle(title: "Digi-Tower")
                
                //slogan
                Text("Your Tower Card - Anytime, Anywhere")
                    .font(.title3)
                    
                //text field entry for email
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
                
                //Submit button -- if successful, goes to verification screen
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

//view to control the verification code entry screen
struct VerificationCode: View {
    @State private var code = Array(repeating: "", count: 4)
    @State private var goToCard = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        Logo()
        VStack {
            //titles with instructions for finding and entering verification code
            CustomTitle(title: "Enter Verification")
            Text("Check Your SJSU Email for a Code")
                .font(.title3)
                
            //stack containing textfields that take in the digits for the code
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
            
            //display error message if verification is submitted without four digits
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            //Submit button -- if successful, retrieve the card
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
    //function to check if the code is complete
    func isCodeComplete() -> Bool {
            return code.allSatisfy { !$0.isEmpty }
        }
}

//view of the screen containing the front and back of the digital card
struct CardView: View {
    @State private var name: String = "John Doe"
    @State private var idNumber: String = "12345678"
    @State private var barcodeNum: String = "234859102"
    @State private var role: String = "STUDENT"
    let nfcReader = NFCCardReader()
    
    //variables to set state for the barcode generator
    let context = CIContext()
    let filter = CIFilter.code128BarcodeGenerator()
    
    var body: some View {
        VStack {
            //title customized to the student's name
            CustomTitle(title: "Welcome \(name)!")
            
            //front of the card: with name, id number, and role
            VStack {
                CardText(text: "NAME: \(name)")
                
                CardText(text: "ID Number: \(idNumber)")
                
                CardText(text: "ROLE: \(role)")
            }
            .frame(width: 300, height: 200)
            .background(Color.blue.opacity(0.4))
            .cornerRadius(5)
            .shadow(color: Color.black.opacity(0.5), radius: 5, x: -5, y: -5)
            .padding(.top, 25)
            
            //back of the card: generates barcode based on the barcode number retrieved from the database
            VStack {
                if let barcodeImage = generateBarcode(from: barcodeNum) {
                    Image(uiImage: barcodeImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 100)
                        .background(Color.white)
                        .cornerRadius(5)
                        .padding()
                } else {
                    Text("Invalid Barcode")
                        .foregroundColor(.red)
                }
                CardText(text: barcodeNum)
            }
            .padding()
            .frame(width: 300, height: 200)
            .background(Color.blue.opacity(0.4))
            .cornerRadius(5)
            .shadow(color: Color.black.opacity(0.5), radius: 5, x: -5, y: -5)
            .padding(.top, 25)
            Spacer()
            
            //button to trigger NFC scanning capability
            CustomButton(buttonText: "TAP CARD") {
                nfcReader.beginScanning()
                print("Card tapped")
            }
            .padding(.bottom, 50)
        }
        .padding()
    }
    
    //creating a function that will generate a barcode based on the
    func generateBarcode(from barcodeNumber: String) -> UIImage? {
        let data = Data(barcodeNumber.utf8)
        filter.setValue(data, forKey: "inputMessage")
        
        // Convert the generated barcode to a UIImage
        if let outputImage = filter.outputImage {
            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        return nil
    }
}

#Preview {
    ContentView()
}
