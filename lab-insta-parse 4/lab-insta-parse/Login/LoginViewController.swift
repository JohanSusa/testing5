import UIKit
import ParseSwift

class LoginViewController: UIViewController {

    // MARK: - UI Elements (Programmatic)
    private lazy var logoImageView: UIImageView = {
        let imageView = UIImageView()
        // Replace "AppLogo" with your actual logo image name if you have one
        imageView.image = UIImage(systemName: "camera.fill")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .label
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var usernameField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Username"
        textField.borderStyle = .roundedRect
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    private lazy var passwordField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Password"
        textField.borderStyle = .roundedRect
        textField.isSecureTextEntry = true
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    private lazy var loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Log In", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 5
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handleLoginTapped), for: .touchUpInside)
        return button
    }()

     private lazy var goToSignUpButton: UIButton = {
        let button = UIButton(type: .system)
        let attributedTitle = NSMutableAttributedString(
            string: "Don't have an account? ",
            attributes: [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.secondaryLabel]
        )
        attributedTitle.append(NSAttributedString(
            string: "Sign Up",
            attributes: [.font: UIFont.boldSystemFont(ofSize: 14), .foregroundColor: UIColor.systemBlue]
        ))
        button.setAttributedTitle(attributedTitle, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handleGoToSignUpTapped), for: .touchUpInside)
        return button
    }()

     private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()


    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDismissKeyboardGesture()
    }

    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground

        
        view.addSubview(logoImageView)
        view.addSubview(usernameField)
        view.addSubview(passwordField)
        view.addSubview(loginButton)
        view.addSubview(goToSignUpButton)
        view.addSubview(activityIndicator)


        // --- Auto Layout
        let padding: CGFloat = 20.0
        let fieldHeight: CGFloat = 44.0
        let buttonHeight: CGFloat = 50.0
        let interItemSpacing: CGFloat = 15.0

        NSLayoutConstraint.activate([
            // Logo
            logoImageView.bottomAnchor.constraint(equalTo: usernameField.topAnchor, constant: -padding * 2),
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 120),
            logoImageView.heightAnchor.constraint(equalToConstant: 120),

            // Username Field
            usernameField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: padding),
            usernameField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -padding),
            usernameField.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -fieldHeight), // Adjust vertical position
            usernameField.heightAnchor.constraint(equalToConstant: fieldHeight),

            // Password Field
            passwordField.topAnchor.constraint(equalTo: usernameField.bottomAnchor, constant: interItemSpacing),
            passwordField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: padding),
            passwordField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -padding),
            passwordField.heightAnchor.constraint(equalToConstant: fieldHeight),

            // Login Button
            loginButton.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: interItemSpacing),
            loginButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: padding),
            loginButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -padding),
            loginButton.heightAnchor.constraint(equalToConstant: buttonHeight),

             // Go To Sign Up Button
            goToSignUpButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: padding),
            goToSignUpButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    // MARK: - Actions
    @objc private func handleLoginTapped() {
        dismissKeyboard()
        guard let username = usernameField.text, !username.isEmpty,
              let password = passwordField.text, !password.isEmpty else {
            showAlert(title: "Missing Information", message: "Please enter both username and password.")
            return
        }

        setLoading(true)

        User.login(username: username, password: password) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.setLoading(false)

                switch result {
                case .success(let user):
                    print("✅ Successfully logged in as user: \(user.username ?? "N/A")")
                    NotificationCenter.default.post(name: .userDidLogin, object: nil)
                case .failure(let error):
                    print("❌ Login error: \(error)")
                    self.showAlert(title: "Login Failed", message: error.localizedDescription)
                }
            }
        }
    }

    @objc private func handleGoToSignUpTapped() {
       print("Navigating to Sign Up")
       let signUpVC = SignUpViewController()
       navigationController?.pushViewController(signUpVC, animated: true) // Assumes embedded in UINavigationController
    }

    // MARK: - Helpers
    private func setLoading(_ isLoading: Bool) {
        usernameField.isEnabled = !isLoading
        passwordField.isEnabled = !isLoading
        loginButton.isEnabled = !isLoading
        goToSignUpButton.isEnabled = !isLoading // Disable navigation while loading

        if isLoading {
            activityIndicator.startAnimating()
            loginButton.alpha = 0.5 // Visual cue
        } else {
            activityIndicator.stopAnimating()
             loginButton.alpha = 1.0
        }
    }

     private func setupDismissKeyboardGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(okAction)
        present(alertController, animated: true)
    }
}
