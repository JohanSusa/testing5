import UIKit
import ParseSwift




class FeedViewController: UIViewController {

    // MARK: - Data
    private var posts = [Post]() {
        didSet {
            // Reload table view data any time the posts array is updated.
            DispatchQueue.main.async {
                 self.tableView.reloadData()
            }
        }
    }
    private var isLoadingMore = false
    private let limit = 10

    // MARK: - UI Elements
    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.translatesAutoresizingMaskIntoConstraints = false // Essential for programmatic constraints
        tv.delegate = self
        tv.dataSource = self
        tv.allowsSelection = true
        tv.separatorStyle = .none
        tv.register(PostCell.self, forCellReuseIdentifier: PostCell.identifier)
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 450
        return tv
    }()

    // Standard UI element for pull-to-refresh functionality.
    private let refreshControl = UIRefreshControl()

    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        setupRefreshControl()
        // Fetch the first batch of posts.
        queryPosts(refreshing: true)
    }

    // MARK: - UI Setup Methods
    private func setupUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func setupNavigationBar() {
        // Set the title for the navigation bar.
        navigationItem.title = "KindredFind"
        let logoutButton = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogoutTapped))
        logoutButton.tintColor = .systemRed
        navigationItem.leftBarButtonItem = logoutButton

       
        // ---------------------------------
    }

     private func setupRefreshControl() {
        refreshControl.addTarget(self, action: #selector(handleRefresh(_:)), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }

    
    private func queryPosts(refreshing: Bool = false, skip: Int = 0) {
        guard !isLoadingMore || refreshing else {
            print("⚠️ Query blocked: Already loading more.")
            if refreshing {
                 DispatchQueue.main.async { self.refreshControl.endRefreshing() }
            }
            return
        }

        print("➡️ Querying posts (Refreshing: \(refreshing), Skip: \(skip))...")

        if !refreshing {
            isLoadingMore = true
            // Optionally add a visual loading indicator at the table view footer.
        } else {
            DispatchQueue.main.async { self.refreshControl.beginRefreshing() }
        }

        // --- Construct the Parse Query ---
        let query = Post.query()
            .include("user")
            .order([.descending("createdAt")])
            .limit(limit)
            .skip(skip)

        // --- Execute the Query Asynchronously ---
        query.find { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                 print("⬅️ Query finished.")
                self.isLoadingMore = false
                self.refreshControl.endRefreshing()
                 // Remove any footer loading indicator added earlier.

                switch result {
                case .success(let fetchedPosts):
                     print("✅ Successfully fetched \(fetchedPosts.count) posts.")
                    if refreshing {
                        self.posts = fetchedPosts
                         print("🔄 Feed refreshed with new data.")
                    } else {
                        let existingIds = Set(self.posts.compactMap { $0.objectId })
                        let newUniquePosts = fetchedPosts.filter { !existingIds.contains($0.objectId ?? "") }
                        self.posts.append(contentsOf: newUniquePosts)
                         print("➕ Added \(newUniquePosts.count) new unique posts. Total: \(self.posts.count)")
                    }

                     if fetchedPosts.count < self.limit {
                         print("🏁 Reached end of posts (fetched \(fetchedPosts.count) < limit \(self.limit)).")
                    }

                case .failure(let error):
                     print("❌ Error fetching posts: \(error.localizedDescription)")
                    self.showAlert(title: "Error Loading Feed", description: "Could not fetch posts. Please check your connection and try again.")
                }
            }
        }
    }

    //  Action Handlers
    @objc private func handleRefresh(_ sender: UIRefreshControl) {
         print("🔄 Refresh action triggered.")
        // Fetch the latest posts
        queryPosts(refreshing: true, skip: 0)
    }

    @objc private func handleLogoutTapped() {
        showConfirmLogoutAlert()
    }

    

    // MARK: - Alert Controllers
    private func showConfirmLogoutAlert() {
        let alertController = UIAlertController(
            title: "Log Out",
            message: "Are you sure you want to log out?",
            preferredStyle: .alert
        )
        // Destructive action for logging out.
        let logOutAction = UIAlertAction(title: "Log Out", style: .destructive) { _ in
             print("✅ User confirmed logout.")
             // Trigger the logout process via the SceneDelegate.
            (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.handleLogout()
        }
        // Standard cancel action.
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        alertController.addAction(logOutAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }

   
    private func showAlert(title: String = "Error", description: String?) {
        let alertController = UIAlertController(
            title: title,
            message: description ?? "An unknown error occurred.",
            preferredStyle: .alert
        )
        let okAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(okAction)
        DispatchQueue.main.async {
             self.present(alertController, animated: true)
        }
    }
}

// UITableViewDataSource Conformance
extension FeedViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PostCell.identifier, for: indexPath) as? PostCell else {
            print("❌ FATAL ERROR: Unable to dequeue PostCell!")
            return UITableViewCell() // Return a default cell to prevent crash
        }

        // --- Safely Access Post Data ---
        if indexPath.row < posts.count {
            let post = posts[indexPath.row]
            cell.configure(with: post)
        } else {
            print("⚠️ Warning: cellForRowAt requested index \(indexPath.row) outside posts count (\(posts.count)).")
        }
        // -------------------------------

        return cell
    }
}

// UITableViewDelegate Conformance
extension FeedViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // --- Infinite Scrolling Trigger ---
        let triggerIndex = posts.count - 5 
        let safeTriggerIndex = max(0, triggerIndex)

        if indexPath.row >= safeTriggerIndex && indexPath.row == posts.count - 1 && !isLoadingMore {
             print("⚡️ Triggering infinite scroll at row \(indexPath.row).")
            let nextSkip = posts.count
            queryPosts(refreshing: false, skip: nextSkip)
        }
        // ---------------------------------
    }

     func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 450
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        // Safely retrieve the Post object corresponding to the tapped row.
        guard indexPath.row < posts.count else {
            print("⚠️ Warning: Tapped row index \(indexPath.row) is out of bounds (\(posts.count) posts).")
            return // Prevent potential crash
        }
        let selectedPost = posts[indexPath.row]

       
        let detailVC = PostDetailViewController(post: selectedPost)

        
        print("➡️ Navigating to detail view for post: \(selectedPost.objectId ?? "N/A")")
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
