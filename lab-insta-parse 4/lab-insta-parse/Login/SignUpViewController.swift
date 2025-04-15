import UIKit
import ParseSwift

class SignUpViewController: UIViewController {

    // MARK: - UI Elements
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Create Account"
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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

     private lazy var emailField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Email"
        textField.borderStyle = .roundedRect
        textField.keyboardType = .emailAddress
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

    private lazy var signUpButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign Up", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.backgroundColor = .systemGreen // Different color for sign up
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 5
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handleSignUpTapped), for: .touchUpInside)
        return button
    }()

     private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDismissKeyboardGesture()
    }

    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        navigationItem.title = "Sign Up" // Set navigation bar title if pushed

        // Add subviews
        view.addSubview(titleLabel)
        view.addSubview(usernameField)
        view.addSubview(emailField)
        view.addSubview(passwordField)
        view.addSubview(signUpButton)
        view.addSubview(activityIndicator)

        // Constraints
        let padding: CGFloat = 20.0
        let fieldHeight: CGFloat = 44.0
        let buttonHeight: CGFloat = 50.0
        let interItemSpacing: CGFloat = 15.0

         NSLayoutConstraint.activate([
            // Title Label (Adjust positioning as needed)
            titleLabel.bottomAnchor.constraint(equalTo: usernameField.topAnchor, constant: -padding * 1.5),
            titleLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: padding),
            titleLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -padding),

            // Username Field
            usernameField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: padding),
            usernameField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -padding),
            usernameField.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -(fieldHeight * 1.5 + interItemSpacing)), // Adjust vertical position
            usernameField.heightAnchor.constraint(equalToConstant: fieldHeight),

             // Email Field
            emailField.topAnchor.constraint(equalTo: usernameField.bottomAnchor, constant: interItemSpacing),
            emailField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: padding),
            emailField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -padding),
            emailField.heightAnchor.constraint(equalToConstant: fieldHeight),

            // Password Field
            passwordField.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: interItemSpacing),
            passwordField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: padding),
            passwordField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -padding),
            passwordField.heightAnchor.constraint(equalToConstant: fieldHeight),

            // Sign Up Button
            signUpButton.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: interItemSpacing * 1.5), // More space before button
            signUpButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: padding),
            signUpButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -padding),
            signUpButton.heightAnchor.constraint(equalToConstant: buttonHeight),

            // Activity Indicator
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    // MARK: - Actions
    @objc private func handleSignUpTapped() {
        dismissKeyboard()
        guard let username = usernameField.text, !username.isEmpty,
              let email = emailField.text, !email.isEmpty, // Validate email format if needed
              let password = passwordField.text, !password.isEmpty else {
            showAlert(title: "Missing Information", message: "Please fill out all fields.")
            return
        }

        setLoading(true)

        var newUser = User()
        newUser.username = username
        newUser.email = email
        newUser.password = password

        newUser.signup { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                 self.setLoading(false)

                switch result {
                case .success(let user):
                    print("✅ Successfully signed up user: \(user.username ?? "N/A")")
                    // Post notification to trigger UI transition in SceneDelegate
                    NotificationCenter.default.post(name: .userDidLogin, object: nil)

                    // Optional: Clear fields after successful signup if staying on screen
                    // self.usernameField.text = ""
                    // self.emailField.text = ""
                    // self.passwordField.text = ""

                case .failure(let error):
                     print("❌ Sign up error: \(error)")
                     self.showAlert(title: "Sign Up Failed", message: error.localizedDescription)
                }
            }
        }
    }

     // MARK: - Helpers
     private func setLoading(_ isLoading: Bool) {
        usernameField.isEnabled = !isLoading
        emailField.isEnabled = !isLoading
        passwordField.isEnabled = !isLoading
        signUpButton.isEnabled = !isLoading

        if isLoading {
            activityIndicator.startAnimating()
            signUpButton.alpha = 0.5
        } else {
            activityIndicator.stopAnimating()
             signUpButton.alpha = 1.0
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
