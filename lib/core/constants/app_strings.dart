class AppStrings {
  AppStrings._();

  // Navigation
  static const String navHome = 'Discover';
  static const String navLibrary = 'Library';
  static const String navWriter = 'Studio';
  static const String navAdmin = 'Admin';
  static const String navProfile = 'Profile';

  // Reader Home
  static const String greetingMorning = 'Good morning, reader';
  static const String greetingAfternoon = 'Good afternoon, reader';
  static const String greetingEvening = 'Good evening, reader';
  static const String searchNovelsPlaceholder = 'Search title, writer, or tag...';
  static const String sectionContinueReading = 'Continue Reading';
  static const String sectionFeatured = 'Featured Stories';
  static const String sectionTrending = 'Trending Now';
  static const String sectionExploreGenres = 'Explore by Genre';
  static const String seeAll = 'See all';
  static const String noProgressYet = 'No reading history yet. Start a story today!';

  // Novel Details
  static const String readNow = 'Read Now';
  static const String continueReading = 'Continue Reading';
  static const String startReading = 'Start Chapter 1';
  static const String chapters = 'Chapters';
  static const String synopsis = 'Synopsis';
  static const String aboutTheAuthor = 'About the Author';
  static const String totalViews = 'reads';
  static const String totalLikes = 'likes';
  static const String totalDownloads = 'downloads';
  static const String downloadFullNovel = 'Download Full Novel (EPUB/PDF)';
  static const String fullNovelDownloaded = 'Novel downloaded for offline reading';
  static const String reportNovel = 'Report Story';

  // Reader Screen
  static const String previousChapter = 'Previous';
  static const String nextChapter = 'Next';
  static const String tableOfContents = 'Table of Contents';
  static const String readingSettings = 'Reading Settings';
  static const String fontSans = 'Modern Sans';
  static const String fontSerif = 'Editorial Serif';
  static const String themeCream = 'Cream';
  static const String themeParchment = 'Parchment';
  static const String themeDark = 'Charcoal';
  static const String themeWhite = 'Classic';

  // Library
  static const String librarySaved = 'Saved';
  static const String libraryHistory = 'History';
  static const String libraryDownloads = 'Offline Shelf';
  static const String emptySaved = 'No saved stories in your library';
  static const String emptyHistory = 'You haven\'t started reading any novels yet';
  static const String emptyDownloads = 'No offline stories downloaded';

  // Writer Dashboard
  static const String writerDashboardTitle = 'Author Studio';
  static const String writerWelcome = 'Welcome back to your workspace';
  static const String newNovel = 'New Novel';
  static const String newEpisode = 'New Episode';
  static const String myNovels = 'My Novels';
  static const String publishedEpisodes = 'Published Episodes';
  static const String totalReads = 'Total Reads';
  static const String writerEngagement = 'Reader Engagement Overview';
  static const String novelStatusDraft = 'Draft';
  static const String novelStatusOngoing = 'Ongoing';
  static const String novelStatusCompleted = 'Completed';
  static const String novelStatusPaused = 'Paused';
  static const String novelStatusArchived = 'Archived';

  // Editors
  static const String createNovelTitle = 'Create Novel Draft';
  static const String editNovelTitle = 'Edit Novel';
  static const String titleLabel = 'Novel Title';
  static const String titlePlaceholder = 'e.g., The Whispering Pines';
  static const String synopsisLabel = 'Synopsis / Description';
  static const String synopsisPlaceholder = 'A compelling summary of your novel...';
  static const String genresLabel = 'Genres';
  static const String tagsLabel = 'Tags (comma separated)';
  static const String tagsPlaceholder = 'mystery, magic, slow-burn';
  static const String coverImageLabel = 'Cover Image';
  static const String uploadCover = 'Select Cover Art';
  static const String saveDraft = 'Save Draft';
  static const String publishNovel = 'Publish Novel';
  static const String saveChanges = 'Save Changes';

  // Episode Editor
  static const String episodeEditorTitle = 'Episode Editor';
  static const String episodeNumberLabel = 'Episode / Chapter Number';
  static const String episodeTitleLabel = 'Episode Title';
  static const String episodeTitlePlaceholder = 'e.g. Chapter 1: The First Spark';
  static const String episodeSummaryLabel = 'Episode Teaser / Summary (Optional)';
  static const String episodeContentLabel = 'Episode Content';
  static const String episodeContentPlaceholder = 'Write your story here...';
  static const String wordCount = 'Words';
  static const String publishEpisode = 'Publish Episode';
  static const String publishSuccess = 'Episode published successfully';
  static const String draftSaved = 'Draft saved successfully';
  static const String unsavedChangesTitle = 'Unsaved Changes';
  static const String unsavedChangesMsg = 'You have unsaved changes. Are you sure you want to discard them?';

  // Admin Dashboard
  static const String adminDashboardTitle = 'Command Center';
  static const String totalUsersMetric = 'Total Users';
  static const String totalNovelsMetric = 'Total Novels';
  static const String pendingModerationMetric = 'Pending Moderation';
  static const String activeReportsMetric = 'Open Reports';
  static const String moderationQueue = 'Content Moderation Queue';
  static const String reportsQueue = 'User Reports';
  static const String approve = 'Approve';
  static const String reject = 'Reject';
  static const String hideContent = 'Hide';
  static const String takeDown = 'Take Down';
  static const String resolveReport = 'Resolve';
  static const String dismissReport = 'Dismiss';

  // Auth & Profile
  static const String signIn = 'Sign In';
  static const String signUp = 'Create Account';
  static const String signOut = 'Sign Out';
  static const String emailLabel = 'Email Address';
  static const String passwordLabel = 'Password';
  static const String displayNameLabel = 'Full Name / Author Pen Name';
  static const String switchRole = 'Switch User Role (Demo Mode)';
  static const String currentRole = 'Active Role';
  static const String roleReader = 'Reader';
  static const String roleWriter = 'Writer';
  static const String roleAdmin = 'Administrator';
  static const String demoSwitchSubtitle = 'Quickly switch roles to test reader, writer, and admin features';

  // Errors & States
  static const String loadingMessage = 'Loading stories and inspirations...';
  static const String defaultErrorMessage = 'An unexpected error occurred. Please try again.';
  static const String retry = 'Retry';
  static const String confirm = 'Confirm';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String discard = 'Discard';
}
