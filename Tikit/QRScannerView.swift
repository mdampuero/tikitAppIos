import SwiftUI
import AVFoundation

struct QRScannerView: UIViewControllerRepresentable {
    let completion: (String) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.onCodeScanned = completion
        controller.onCancel = onCancel
        return controller
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
}

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var onCodeScanned: ((String) -> Void)?
    var onCancel: (() -> Void)?
    private var isPresentingAlert = false
    private var isTorchOn = false
    private var torchButton: UIButton?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        captureSession = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            presentScanErrorAlert(message: "No se pudo acceder a la cámara para leer el código QR.")
            return
        }
        guard let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else {
            presentScanErrorAlert(message: "No se pudo preparar la cámara para leer el código QR.")
            return
        }
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            presentScanErrorAlert(message: "No se pudo iniciar la cámara para leer el código QR.")
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            presentScanErrorAlert(message: "No se pudo configurar el lector de códigos QR.")
            return
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        // Ejecutar el startRunning en un hilo de fondo para evitar bloquear la UI
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }

        // Agregar botón de cancelar estándar (X en la esquina) - DESPUÉS de la previewLayer
        let cancelButton = UIButton(type: .system)
        cancelButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        cancelButton.tintColor = .white
        cancelButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        cancelButton.layer.cornerRadius = 22
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.addTarget(self, action: #selector(cancelScanning), for: .touchUpInside)
        view.addSubview(cancelButton)
        
        // Posicionar en la esquina superior derecha
        NSLayoutConstraint.activate([
            cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            cancelButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            cancelButton.widthAnchor.constraint(equalToConstant: 44),
            cancelButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        // Agregar botón de linterna si está disponible
        if let device = AVCaptureDevice.default(for: .video), device.hasTorch {
            torchButton = UIButton(type: .system)
            torchButton?.setImage(UIImage(systemName: "flashlight.off.fill"), for: .normal)
            torchButton?.tintColor = .white
            torchButton?.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            torchButton?.layer.cornerRadius = 22
            torchButton?.translatesAutoresizingMaskIntoConstraints = false
            torchButton?.addTarget(self, action: #selector(toggleTorch), for: .touchUpInside)
            view.addSubview(torchButton!)
            
            // Posicionar en la esquina inferior izquierda
            NSLayoutConstraint.activate([
                torchButton!.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
                torchButton!.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
                torchButton!.widthAnchor.constraint(equalToConstant: 44),
                torchButton!.heightAnchor.constraint(equalToConstant: 44)
            ])
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession?.isRunning == true {
            captureSession.stopRunning()
        }
    }

    @objc private func cancelScanning() {
        captureSession?.stopRunning()
        onCancel?()
    }

    @objc private func toggleTorch() {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        
        do {
            try device.lockForConfiguration()
            isTorchOn.toggle()
            
            if isTorchOn {
                device.torchMode = .on
                torchButton?.setImage(UIImage(systemName: "flashlight.on.fill"), for: .normal)
                torchButton?.tintColor = .yellow
            } else {
                device.torchMode = .off
                torchButton?.setImage(UIImage(systemName: "flashlight.off.fill"), for: .normal)
                torchButton?.tintColor = .white
            }
            
            device.unlockForConfiguration()
        } catch {
            // print("Error al controlar la linterna: \(error.localizedDescription)")
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject else { return }
        guard let stringValue = object.stringValue else {
            presentScanErrorAlert(message: "No se pudo leer correctamente el código QR.")
            return
        }
        captureSession?.stopRunning()
        onCodeScanned?(stringValue)
    }

    private func presentScanErrorAlert(message: String) {
        guard !isPresentingAlert else { return }
        isPresentingAlert = true
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Aceptar", style: .default) { [weak self] _ in
                self?.isPresentingAlert = false
                self?.captureSession?.stopRunning()
                self?.onCancel?()
            })
            self.present(alert, animated: true)
        }
    }
}

