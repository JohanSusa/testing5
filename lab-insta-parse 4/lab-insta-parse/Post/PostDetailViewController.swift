import UIKit
import ParseSwift
import Alamofire
import AlamofireImage
import CoreLocation
import MapKit

class PostDetailViewController: UIViewController {

    // MARK: - Properties
    let post: Post
    private var imageDataRequest: DataRequest?
    private let geocoder = CLGeocoder()


    private lazy var usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var locationLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var postImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .secondarySystemBackground
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    // --- Add Map View
    private lazy var mapView: MKMapView = {
        let map = MKMapView()
        map.translatesAutoresizingMaskIntoConstraints = false
        map.mapType = .standard
        map.isZoomEnabled = true
        map.isScrollEnabled = true
        map.layer.cornerRadius = 8
        map.clipsToBounds = true
        map.isHidden = true
        return map
    }()
    // --------------------

     private lazy var captionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

     private lazy var timestampLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .tertiaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()


    // --- Layout Containers
    private lazy var headerStackView: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [usernameLabel, locationLabel])
        sv.axis = .vertical
        sv.alignment = .leading
        sv.spacing = 4
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    // --- Modify contentStackView to include mapView ---
    private lazy var contentStackView: UIStackView = {
        // Add mapView after postImageView
        let sv = UIStackView(arrangedSubviews: [headerStackView, postImageView, mapView, captionLabel, timestampLabel])
        sv.axis = .vertical
        sv.spacing = 12
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.setCustomSpacing(15, after: mapView)
        captionLabel.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        timestampLabel.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        return sv
    }()
    // -----------------------------------------------

    // MARK: - Initialization
    init(post: Post) {
        self.post = post
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented - use init(post:)")
    }

    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureView()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        imageDataRequest?.cancel()
        geocoder.cancelGeocode()
        
        mapView.removeAnnotations(mapView.annotations)
    }

    // MARK: - UI Setup Method
    private func setupUI() {
        view.backgroundColor = .systemBackground
        navigationItem.title = "Post Details"

        view.addSubview(contentStackView)

        let padding: CGFloat = 16.0
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: padding / 2),
            contentStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            contentStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            contentStackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -padding),

            // --- Image View Constraints ---
            postImageView.widthAnchor.constraint(equalTo: contentStackView.widthAnchor),
            postImageView.heightAnchor.constraint(equalTo: postImageView.widthAnchor, multiplier: 1.0),

            // --- Map View Constraints ---
            mapView.widthAnchor.constraint(equalTo: contentStackView.widthAnchor),
            mapView.heightAnchor.constraint(equalToConstant: 180)
            // ----------------------------
        ])
    }

    // MARK: - Data Configuration Methods
    private func configureView() {
        usernameLabel.text = post.user?.username ?? "Unknown User"
        captionLabel.text = post.caption
        captionLabel.isHidden = (post.caption ?? "").isEmpty

        if let date = post.createdAt {
            timestampLabel.text = DateFormatter.postFormatter.string(from: date)
            timestampLabel.isHidden = false
        } else {
            timestampLabel.isHidden = true
        }

        // --- Check for location data before configuring map and location label ---
        if post.location != nil {
            mapView.isHidden = false
            configureLocation()
        } else {
            mapView.isHidden = true
            locationLabel.isHidden = true
            print("ℹ️ Detail View: No location data available for post \(post.objectId ?? "N/A"). Map and Location Label hidden.")
        }
        // -----------------------------------------------------------------------

        configureImage() // Load image
    }

    private func configureImage() {
        postImageView.image = nil
        postImageView.backgroundColor = .secondarySystemBackground

        guard let imageFile = post.imageFile, let imageUrl = imageFile.url else {
            print("⚠️ Detail View: No image file/URL for post \(post.objectId ?? "N/A").")
            postImageView.image = UIImage(systemName: "photo.fill")
            postImageView.tintColor = .systemGray
            postImageView.contentMode = .scaleAspectFit
            postImageView.backgroundColor = .clear
            return
        }

        print("➡️ Detail View: Loading image from URL: \(imageUrl)")
        imageDataRequest?.cancel()
        imageDataRequest = AF.request(imageUrl).responseImage { [weak self] response in
            guard let self = self else { return }
            self.postImageView.backgroundColor = .clear

            switch response.result {
            case .success(let image):
                print("✅ Detail View: Image loaded successfully.")
                self.postImageView.image = image
                self.postImageView.contentMode = .scaleAspectFill
            case .failure(let error):
                if !error.isExplicitlyCancelledError {
                    print("❌ Detail View: Image download error: \(error.localizedDescription)")
                    self.postImageView.image = UIImage(systemName: "exclamationmark.triangle.fill")
                    self.postImageView.tintColor = .systemOrange
                    self.postImageView.contentMode = .scaleAspectFit
                } else {
                    print("ℹ️ Detail View: Image request cancelled.")
                }
            }
        }
    }


 
    private func configureLocation() {
        guard let geoPoint = post.location else {
            // This check is redundant because configureView already checks,
            print("❌ Error: configureLocation called but post.location is nil.")
            locationLabel.isHidden = true
            mapView.isHidden = true
            return
        }

        // Make sure they are visible if called
        locationLabel.isHidden = false
        mapView.isHidden = false

        // --- Configure Map View ---
        let coordinate = CLLocationCoordinate2D(latitude: geoPoint.latitude, longitude: geoPoint.longitude)

        // Remove existing annotations before adding a new one
        mapView.removeAnnotations(mapView.annotations)

        // Create a pin annotation for the post's location
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = post.user?.username ?? "Post Location"
        mapView.addAnnotation(annotation)

        // Center the map on the coordinate and set the zoom
        let regionRadius: CLLocationDistance = 1000
        let coordinateRegion = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: regionRadius,
            longitudinalMeters: regionRadius
        )
        mapView.setRegion(coordinateRegion, animated: true)

        print("🗺️ Map configured for coordinate: \(coordinate.latitude), \(coordinate.longitude)")


        // --- Configure Location Label
        locationLabel.text = "Fetching location..."
        locationLabel.textColor = .tertiaryLabel

        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geocoder.cancelGeocode()
        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
            guard let self = self else { return }
             DispatchQueue.main.async {
                if let error = error {
                     print("❌ Detail View: Reverse geocode failed: \(error.localizedDescription)")
                    self.locationLabel.text = "Location Unavailable"
                    self.locationLabel.textColor = .systemRed
                    return
                }

                if let placemark = placemarks?.first {
                    var locationString = ""
                    if let city = placemark.locality { locationString += city }
                    if let state = placemark.administrativeArea {
                        if !locationString.isEmpty { locationString += ", " }
                        locationString += state
                    }
                    if locationString.isEmpty, let name = placemark.name {
                         locationString = name
                    } else if locationString.isEmpty {
                        locationString = "Location Available"
                    }
                    self.locationLabel.text = locationString
                    self.locationLabel.textColor = .secondaryLabel
                    print("📍 Location Label updated: \(locationString)")
                } else {
                     print("ℹ️ Detail View: No placemark found for location.")
                    self.locationLabel.text = "Location details not found"
                    self.locationLabel.textColor = .secondaryLabel
                }
            }
        }
    }
}
