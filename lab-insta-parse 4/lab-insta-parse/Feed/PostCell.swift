import UIKit
import Alamofire
import AlamofireImage
import CoreLocation
import ParseSwift

class PostCell: UITableViewCell {

    static let identifier = "PostCell"
    private var imageDataRequest: DataRequest?
    private let geocoder = CLGeocoder()

    private lazy var usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var locationLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
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

     private lazy var captionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 0 // Allow multiple lines
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

     private lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10)
        label.textColor = .tertiaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var headerStackView: UIStackView = {
       let sv = UIStackView(arrangedSubviews: [usernameLabel, locationLabel])
        sv.axis = .vertical
        sv.alignment = .leading
        sv.spacing = 2
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

     private lazy var footerStackView: UIStackView = {
       let sv = UIStackView(arrangedSubviews: [captionLabel, dateLabel])
        sv.axis = .vertical
        sv.alignment = .leading
        sv.spacing = 4
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()


    // Initializers
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(headerStackView)
        contentView.addSubview(postImageView)
        contentView.addSubview(footerStackView)

        let padding: CGFloat = 12.0

        NSLayoutConstraint.activate([
            headerStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding),
            headerStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            headerStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            // Post Image
            postImageView.topAnchor.constraint(equalTo: headerStackView.bottomAnchor, constant: padding / 2),
            postImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            postImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
             postImageView.heightAnchor.constraint(equalTo: postImageView.widthAnchor, multiplier: 1.0),

            // Footer (Caption, Date)
             footerStackView.topAnchor.constraint(equalTo: postImageView.bottomAnchor, constant: padding),
            footerStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            footerStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),
            footerStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -padding) // Pin to bottom
        ])
    }


    func configure(with post: Post) {
         resetContent()

         // --- User
        usernameLabel.text = post.user?.username ?? "User" // Provide a default

        // --- Image ---
        if let imageFile = post.imageFile, let imageUrl = imageFile.url {
            imageDataRequest = AF.request(imageUrl).responseImage { [weak self] response in
                guard let self = self else { return }
                switch response.result {
                case .success(let image):
                    
                     if self.usernameLabel.text == post.user?.username {
                         self.postImageView.image = image
                    }
                case .failure(let error):
                    if !(error.isExplicitlyCancelledError || error.isSessionTaskError) {
                         print(" N Image download error: \(error.localizedDescription) for URL: \(imageUrl)")
                        self.postImageView.image = UIImage(systemName: "photo")
                    }
                }
            }
        } else {
            postImageView.image = UIImage(systemName: "photo")
        }

        // --- Caption ---
        captionLabel.text = post.caption

         // --- Date ---
        if let date = post.createdAt {
            dateLabel.text = DateFormatter.postFormatter.string(from: date)
        }

         // --- Location ---
         configureLocation(for: post)

    }

    private func configureLocation(for post: Post) {
        guard let geoPoint = post.location else {
            locationLabel.isHidden = true
            return
        }

        locationLabel.isHidden = false
        locationLabel.text = "Loading location..."

        let location = CLLocation(latitude: geoPoint.latitude, longitude: geoPoint.longitude)

        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
            guard let self = self else { return }

             guard self.usernameLabel.text == post.user?.username else { return }

            DispatchQueue.main.async {
                if let error = error {
                     print(" N Reverse geocode failed: \(error.localizedDescription)")
                    self.locationLabel.text = "Unknown Location"
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
                } else {
                    self.locationLabel.text = "Location details not found"
                }
            }
        }
    }

    // MARK: - Reuse Preparation
    override func prepareForReuse() {
        super.prepareForReuse()
        resetContent()
    }

    private func resetContent() {
        usernameLabel.text = nil
        locationLabel.text = nil
        locationLabel.isHidden = true
        captionLabel.text = nil
        dateLabel.text = nil
        postImageView.image = nil
        postImageView.backgroundColor = .secondarySystemBackground
        imageDataRequest?.cancel()
        imageDataRequest = nil
        geocoder.cancelGeocode()
    }
}
