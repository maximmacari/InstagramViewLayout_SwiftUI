//
//  CustomCamera.swift
//  InstagramViewLayout
//
//  Created by Maxim Macari on 8/2/21.
//

import SwiftUI
import AVFoundation

struct CameraView: View {
    
    @StateObject var camera = CameraModel()
    @Binding var offset: CGFloat
    
    var body: some View{
        
        ZStack{
            
            // Going to Be Camera preview...
            CameraPreview(camera: camera)
                .ignoresSafeArea(.all, edges: .all)
            
            VStack{
                
                
                Spacer()
                
                HStack{
                    
                    // if taken showing save and again take button...
                    
                    if camera.isTaken{
                        
                        
                    }
                    else{
                        
                        Button(action: camera.takePic, label: {
                            
                            ZStack{
                                
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 65, height: 65)
                                
                                Circle()
                                    .stroke(Color.white,lineWidth: 2)
                                    .frame(width: 75, height: 75)
                            }
                        })
                    }
                }
                .frame(height: 75)
                .padding(.bottom, edges?.bottom ?? 15)
            }
        }
        .onAppear(perform: {
            
            camera.Check()
        })
        .alert(isPresented: $camera.alert) {
            Alert(title: Text("Please Enable Camera Access"))
        }
        .onChange(of: offset, perform: { value in
            if value == 0 && !camera.session.isRunning {
                camera.session.startRunning()
            }else{
                if camera.session.isRunning && offset >= rect.width{
                    camera.session.stopRunning()
                }
            }
        })
    }
}

class CameraModel: NSObject,ObservableObject,AVCapturePhotoCaptureDelegate{
    
    @Published var isTaken = false
    
    @Published var session = AVCaptureSession()
    
    @Published var alert = false
    
    // since were going to read pic data....
    @Published var output = AVCapturePhotoOutput()
    
    // preview....
    @Published var preview : AVCaptureVideoPreviewLayer!
    
    // Pic Data...
    
    @Published var isSaved = false
    
    @Published var picData = Data(count: 0)
    
    func Check(){
        
        // first checking camerahas got permission...
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setUp()
            return
            // Setting Up Session
        case .notDetermined:
            // retusting for permission....
            AVCaptureDevice.requestAccess(for: .video) { (status) in
                
                if status{
                    self.setUp()
                }
            }
        case .denied:
            self.alert.toggle()
            return
            
        default:
            return
        }
    }
    
    func setUp(){
        
        // setting up camera...
        
        do{
            
            // setting configs...
            self.session.beginConfiguration()
            
            // change for your own...
            
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
            
            let input = try AVCaptureDeviceInput(device: device!)
            
            // checking and adding to session...
            
            if self.session.canAddInput(input){
                self.session.addInput(input)
            }
            
            // same for output....
            
            if self.session.canAddOutput(self.output){
                self.session.addOutput(self.output)
            }
            
            self.session.commitConfiguration()
        }
        catch{
            print(error.localizedDescription)
        }
    }
    
    // take and retake functions...
    
    func takePic(){
        
        self.output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
        
        DispatchQueue.global(qos: .background).async {
            
            self.session.stopRunning()
            
            DispatchQueue.main.async {
                
                withAnimation{self.isTaken.toggle()}
            }
        }
    }
    
    func reTake(){
        
        DispatchQueue.global(qos: .background).async {
            
            self.session.startRunning()
            
            DispatchQueue.main.async {
                withAnimation{self.isTaken.toggle()}
                //clearing ...
                self.isSaved = false
                self.picData = Data(count: 0)
            }
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        if error != nil{
            return
        }
        
        print("pic taken...")
        
        guard let imageData = photo.fileDataRepresentation() else{return}
        
        self.picData = imageData
    }
    
//    func savePic(){
//
//        guard let image = UIImage(data: self.picData) else{return}
//
//        // saving Image...
//        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
//
//        self.isSaved = true
//
//        print("saved Successfully....")
//    }
}

// setting view for preview...

struct CameraPreview: UIViewRepresentable {
    
    @ObservedObject var camera : CameraModel
    
    func makeUIView(context: Context) ->  UIView {
     
        let view = UIView(frame: UIScreen.main.bounds)
        
        camera.preview = AVCaptureVideoPreviewLayer(session: camera.session)
        camera.preview.frame = view.frame
        
        // Your Own Properties...
        camera.preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(camera.preview)
        
        
        //only turning camera on when offset is 0
        
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        
    }
}

   
   
