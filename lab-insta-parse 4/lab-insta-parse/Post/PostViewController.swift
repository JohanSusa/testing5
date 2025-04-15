import UIKit
import ParseSwift
import PhotosUI
import CoreLocation

class PostViewController: UIViewController {

    // MARK: - Properties
    private var pickedImage: UIImage? {
        didSet {
            previewImageView.image = pickedImage
            navigationItem.rightBarButtonItem?.isEnabled = pickedImage != nil
        }
    }
     private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?

    // MARK: - UI Elements
    private lazy var previewImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .secondarySystemBackground
        iv.translatesAutoresizingMaskIntoConstraints = false
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleImageTap))
        iv.addGestureRecognizer(tapGesture)
        iv.isUserInteractionEnabled = true
        iv.image = UIImage(systemName: "photo.on.rectangle.angled")
        iv.tintColor = .secondaryLabel
        return iv
    }()

    private lazy var captionTextView: UITextView = {
        let tv = UITextView()
        tv.font = .systemFont(ofSize: 16)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.layer.borderWidth = 1.0
        tv.layer.borderColor = UIColor.systemGray4.cgColor
        tv.layer.cornerRadius = 5
        
        tv.text = "Write a caption..."
        tv.textColor = .placeholderText
        tv.delegate = self // Needed for placeholder logic
        return tv
    }()

     private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.color = .white
        return indicator
    }()

    private lazy var loadingOverlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        return view
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        setupLocationServices()
        setupDismissKeyboardGesture()
    }

    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(previewImageView)
        view.addSubview(captionTextView)
        view.addSubview(loadingOverlayView)

        let padding: CGFloat = 15.0

        NSLayoutConstraint.activate([
            // Preview Image
            previewImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: padding),
            previewImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            previewImageView.widthAnchor.constraint(equalToConstant: 100),
            previewImageView.heightAnchor.constraint(equalTo: previewImageView.widthAnchor),

            // Caption Text View
            captionTextView.topAnchor.constraint(equalTo: previewImageView.topAnchor),
            captionTextView.leadingAnchor.constraint(equalTo: previewImageView.trailingAnchor, constant: padding),
            captionTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
             captionTextView.heightAnchor.constraint(equalTo: previewImageView.heightAnchor),

            // Loading Overlay
            loadingOverlayView.topAnchor.constraint(equalTo: view.topAnchor),
            loadingOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingOverlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

     private func setupNavigationBar() {
        navigationItem.title = "New Post"
        // Cancel Button
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(handleCancel))
        // Share Button
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Share", style: .done, target: self, action: #selector(handleShare))
        navigationItem.rightBarButtonItem?.isEnabled = false // Disabled initially
    }

    // MARK: - Location Services (Keep Original Logic, Ensure Delegate methods have @objc)
    private func setupLocationServices() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters // Balance accuracy and power
        requestLocationPermission()
    }

    private func requestLocationPermission() {
         DispatchQueue.global().async {
            let status = self.locationManager.authorizationStatus

            DispatchQueue.main.async {
                switch status {
                case .notDetermined:
                     print(" N Requesting location permission...")
                    self.locationManager.requestWhenInUseAuthorization()
                case .authorizedWhenInUse, .authorizedAlways:
                     print(" N Location permission granted. Requesting location update.")
                     self.locationManager.requestLocation()
                case .denied, .restricted:
                    print(" N Location permission denied or restricted.")
                @unknown default:
                    fatalError("Unhandled CLLocationAuthorizationStatus")
                }
            }
        }
    }


    // MARK: - Actions
    @objc private func handleImageTap() {
         print(" N Image view tapped, presenting picker.")
        presentImagePicker()
    }

    @objc private func handleCancel() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func handleShare() {
        dismissKeyboard()
        print(" N Share button tapped.")

        guard let image = pickedImage else {
            showAlert(title: "Missing Image", description: "Please select an image to share.")
            return
        }

        // Validate caption (optional: remove placeholder if it's still there)
         let captionText = (captionTextView.text == "Write a caption..." || captionTextView.text.isEmpty) ? nil : captionTextView.text

        setLoading(true)

        // Prepare Image Data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
             print("❌ Could not get JPEG data from image.")
            showAlert(description: "Could not process image.")
            setLoading(false)
            return
        }

         print(" N Image data prepared (\(imageData.count) bytes).")

        //  Create ParseFile
        let fileName = "post_\(UUID().uuidString).jpg"
        let imageFile = ParseFile(name: fileName, data: imageData)

         print(" N ParseFile created: \(fileName)")


        //  Create Post Object
        var post = Post()
        post.caption = captionText
        post.user = User.current
        post.imageFile = imageFile

        // Add Location
        if let location = self.currentLocation {
            do {
                post.location = try ParseGeoPoint(location: location)
                 print("✅ Attaching location to post: \(post.location!)")
            } catch {
                 print(" N Could not create ParseGeoPoint: \(error)")
            }
        } else {
             print(" N No location data available or permission denied.")
        }

        // 5. Save the Post
        post.save { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                 print(" N Post save attempt finished.")
                 self.setLoading(false)

                switch result {
                case .success(let savedPost):
                     print("✅ Post saved successfully! ObjectId: \(savedPost.objectId ?? "N/A")")
                     self.dismiss(animated: true, completion: nil)
                   
                case .failure(let error):
                    print("❌ Failed to save post: \(error)")
                    self.showAlert(title: "Upload Failed", description: "Could not save post. \(error.localizedDescription)")
                }
            }
        }
    }


    // MARK: - Image Picking (PHPicker)
    private func presentImagePicker() {
        var config = PHPickerConfiguration(photoLibrary: .shared()) // Use shared library
        config.filter = .images
        config.selectionLimit = 1
        config.preferredAssetRepresentationMode = .current // Get best representation

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

     // MARK: - Helpers
     private func setupDismissKeyboardGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
         tapGesture.cancelsTouchesInView = false // Allow tapping controls within the view
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func setLoading(_ isLoading: Bool) {
        captionTextView.isEditable = !isLoading // Prevent editing while loading
        navigationItem.leftBarButtonItem?.isEnabled = !isLoading // Cancel button
        navigationItem.rightBarButtonItem?.isEnabled = !isLoading && (pickedImage != nil) // Share button

         loadingOverlayView.isHidden = !isLoading
        if isLoading {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }

    private func showAlert(title: String = "Error", description: String?) {
        let alertController = UIAlertController(title: title, message: description ?? "An unknown error occurred.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(okAction)
        present(alertController, animated: true)
    }
}

// MARK: - PHPickerViewControllerDelegate
extension PostViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let provider = results.first?.itemProvider else { return }

        if provider.canLoadObject(ofClass: UIImage.self) {
            provider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    if let error = error {
                         print("❌ Error loading image from picker: \(error)")
                        self.showAlert(description: "Could not load selected image.")
                        return
                    }
                    guard let image = image as? UIImage else {
                        print("❌ Could not cast loaded object to UIImage.")
                        self.showAlert(description: "Selected item was not a valid image.")
                        return
                    }
                     print(" N Image successfully loaded from picker.")
                    self.pickedImage = image // Update the image view and enable share button
                }
            }
        } else {
             print(" N Selected item provider cannot load UIImage.")
             showAlert(description: "Cannot load this type of item as an image.")
        }
    }
}


// MARK: - CLLocationManagerDelegate
extension PostViewController: CLLocationManagerDelegate {

     // Handle authorization changes
     @objc func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print(" N Location authorization status changed to: \(status.rawValue)")
        if status == .authorizedWhenInUse || status == .authorizedAlways {
             print(" N Permission granted. Requesting location.")
             manager.requestLocation() // Request a one-time update
        } else if status == .denied || status == .restricted {
             print(" N User denied or restricted location access. Clearing current location.")
            self.currentLocation = nil
        }
    }

     // Handle successful location updates
    @objc func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            print(" N Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            self.currentLocation = location
           
        } else {
             print(" N Location update received but no locations array.")
        }
    }

    // Handle location errors
    @objc func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
         print(" N Location manager failed with error: \(error)")
        
        if let clError = error as? CLError {
            if clError.code == .denied {
                print(" N Location access specifically denied by user.")
            } else if clError.code == .locationUnknown {
                 print(" N Could not determine location currently.")
            } else {
                 print(" N Unhandled CL Location Error: \(clError.code)")
            }
        } else {
            print(" N Non-CL Location Error: \(error.localizedDescription)")
        }

        self.currentLocation = nil
    }
}

// MARK: - UITextViewDelegate (for Placeholder)
extension PostViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .placeholderText {
            textView.text = nil
            textView.textColor = .label
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Write a caption..."
            textView.textColor = .placeholderText
        }
    }

    
}
