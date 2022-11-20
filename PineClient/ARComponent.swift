//
//  ARComponent.swift
//  PineClient
//
//  Created by Анастасия Ступникова on 17.11.2022.
//

import UIKit
import ARKit

struct ImageData {
    let transform: Data
    let image: UIImage
}

protocol ARComponentDelegate: AnyObject {
    func userDidPlaceImage(imageData: ImageData)
    func userDidCreateWorldMap(data: Data)
    func sessionFailed()
}

protocol ARComponent: AnyObject {
    var view: UIView { get }
    var delegate: ARComponentDelegate? { get set }
    var isWorldInitialized: Bool { get }
    
    func run()
    func pause()
}

struct ARComponentConfiguration {
    let showAddImageButton: Bool
    let showGetWorldMapButton: Bool
    let trackingText: String
    let normalTrackingText: String?
    let worldData: Data?
    let imagesList: [ImageData]
}

final class ARComponentImpl: NSObject {
    
    weak var delegate: ARComponentDelegate?
    
    private let mainView = ARComponentView()
    private let trackingConfiguration = ARWorldTrackingConfiguration()
    private let imagePicker: UIImagePickerController = {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        return picker
    }()
    
    private let initialConfiguration: ARComponentConfiguration
    private var isInitialImagesAdded = false
    
    private var isObjectsAdded = false
    private var anchorImageMap: [ARAnchor: UIImage] = [:]
    
    init(configuration: ARComponentConfiguration) {
        initialConfiguration = configuration
        super.init()
        imagePicker.delegate = self
        mainView.delegate = self
        mainView.setSceneViewDelegate(delegate: self)
        mainView.hideButtons()
        
        guard
            let worldData = initialConfiguration.worldData,
            let worldMap = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: worldData)
        else {
            return
        }
        
        trackingConfiguration.initialWorldMap = worldMap
    }
    
    private func addImageToCameraFront(image: UIImage) {
        let translation = matrix_float4x4(SCNMatrix4MakeTranslation(0, 0, -1))
        let transform = mainView.session.currentFrame!.camera.transform
        let rotation = matrix_float4x4(SCNMatrix4MakeRotation(Float.pi/2, 0, 0, 1))
        
        let anchorTransform = matrix_multiply(transform, matrix_multiply(translation, rotation))

        let anchor = ARAnchor(transform: anchorTransform)
        anchorImageMap[anchor] = image
        mainView.session.add(anchor: anchor)
        
        delegate?.userDidPlaceImage(
            imageData: ImageData(transform: matrixToData(matrix: anchorTransform), image: image)
        )
    }
    
    private func matrixToData(matrix: simd_float4x4) -> Data {
        var data = Data()
        data.append(vectorToData(vector: matrix.columns.0))
        data.append(vectorToData(vector: matrix.columns.1))
        data.append(vectorToData(vector: matrix.columns.2))
        data.append(vectorToData(vector: matrix.columns.3))
        return data
    }
    
    private func vectorToData(vector: simd_float4) -> Data {
        var data = Data()
        data.append(floatToData(number: vector.w))
        data.append(floatToData(number: vector.x))
        data.append(floatToData(number: vector.y))
        data.append(floatToData(number: vector.z))
        return data
    }
    
    private func floatToData(number: Float) -> Data {
        var number = number
        return Data(bytes: &number, count: MemoryLayout.size(ofValue: number))
    }
    
    private func decodeFloat(data: inout Data) -> Float? {
        let size = MemoryLayout<Float>.size
        guard data.count >= size else { return nil }
        let result = Data(data.prefix(size)).withUnsafeBytes { $0.load(as: Float.self) }
        data = data.dropFirst(size)
        return result
    }
    
    private func decodeVector(data: inout Data) -> simd_float4? {
        guard let w = decodeFloat(data: &data) else { return nil }
        guard let x = decodeFloat(data: &data) else { return nil }
        guard let y = decodeFloat(data: &data) else { return nil }
        guard let z = decodeFloat(data: &data) else { return nil }
        return simd_float4(x: x, y: y, z: z, w: w)
    }
    
    private func dataToMatrix(data: Data) -> simd_float4x4? {
        var data = data
        guard let c0 = decodeVector(data: &data) else { return nil }
        guard let c1 = decodeVector(data: &data) else { return nil }
        guard let c2 = decodeVector(data: &data) else { return nil }
        guard let c3 = decodeVector(data: &data) else { return nil }
        return simd_float4x4(columns: (c0, c1, c2, c3))
    }
    
    private func addImagesIfNeeded() {
        guard !isInitialImagesAdded else { return }
        isInitialImagesAdded = true
        initialConfiguration.imagesList.forEach { placeImage(imageData: $0) }
    }
    
    private func placeImage(imageData: ImageData) {
        guard let transform = dataToMatrix(data: imageData.transform) else { return }
        let anchor = ARAnchor(transform: transform)
        anchorImageMap[anchor] = imageData.image
        mainView.session.add(anchor: anchor)
    }
}

extension ARComponentImpl: ARComponent {

    var view: UIView { mainView }
    var isWorldInitialized: Bool { trackingConfiguration.initialWorldMap != nil }
    
    func run() {
        mainView.session.run(trackingConfiguration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func pause() {
        mainView.session.pause()
    }
}

extension ARComponentImpl: ARSCNViewDelegate {

    func session(_ session: ARSession, didFailWithError error: Error) {
        delegate?.sessionFailed()
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        let trackingState = camera.trackingState
        
        switch trackingState {
        case .normal:
            
            if let text = initialConfiguration.normalTrackingText {
                mainView.configure(with: .init(text: text, color: .systemBlue))
                mainView.showHint()
            } else {
                mainView.hideHint()
            }
            
            if initialConfiguration.showAddImageButton {
                mainView.showAddImageButton()
            }
            
            if initialConfiguration.showGetWorldMapButton {
                mainView.showSaveButton()
            }
            
            addImagesIfNeeded()
        default:
            mainView.hideButtons()
            mainView.configure(with: .init(
                text: initialConfiguration.trackingText,
                color: .darkGray
            ))
            mainView.showHint()
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let image = anchorImageMap[anchor] else { return nil }
        
        let S: CGFloat = 0.5
        let worldWidth = image.size.width > image.size.height ? S : image.size.width / image.size.height * S
        let worldHeight = image.size.width < image.size.height ? S : image.size.height / image.size.width * S
        
        let plane = SCNPlane(width: worldWidth, height: worldHeight)
        plane.cornerRadius = 0.1
        plane.firstMaterial?.diffuse.contents = image
        
        if worldHeight > worldWidth && image.imageOrientation == .right {
            let rotation = SCNMatrix4MakeRotation(-Float.pi / 2, 0, 0, 1)
            let translation = SCNMatrix4MakeTranslation(0, 1, 0)
            plane.firstMaterial?.diffuse.contentsTransform = SCNMatrix4Mult(rotation, translation)
        }

        return SCNNode(geometry: plane)
    }
}

extension ARComponentImpl: ARComponentViewDelegate {
    func saveButtonTapped() {
        mainView.session.getCurrentWorldMap { (worldMap, error) in
            guard let worldMap = worldMap else { return }
            guard let data = try? NSKeyedArchiver.archivedData(
                withRootObject: worldMap, requiringSecureCoding: true
            ) else { return }
            
            DispatchQueue.main.async { self.delegate?.userDidCreateWorldMap(data: data) }
        }
    }
    
    func addImageButtonTapped() {
        UIViewController.current?.present(imagePicker, animated: true)
    }
}

extension ARComponentImpl: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        guard let image = info[.originalImage] as? UIImage else { return }
        picker.dismiss(animated: true)
        addImageToCameraFront(image: image)
    }
}

private extension UIViewController {
    static var current: UIViewController? {
        guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else {
            return nil
        }
        
        var topController = rootViewController
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        
        return topController
    }
}
