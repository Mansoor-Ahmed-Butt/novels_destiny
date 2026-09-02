import 'dart:async';
import '../models/user_model.dart';
import '../models/novel_model.dart';
import '../models/episode_model.dart';
import '../models/reading_progress_model.dart';
import '../models/report_model.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/novel_entity.dart';
import '../../domain/entities/episode_entity.dart';
import '../../domain/entities/report_entity.dart';
import '../../domain/entities/analytics_entity.dart';

class AppDataSource {
  static final AppDataSource _instance = AppDataSource._internal();
  factory AppDataSource() => _instance;

  AppDataSource._internal() {
    _seedData();
  }

  // In-memory collections mimicking Cloud Firestore
  final Map<String, UserModel> _users = {};
  final Map<String, NovelModel> _novels = {};
  final Map<String, List<EpisodeModel>> _episodes = {}; // key: novelId
  final Map<String, Set<String>> _novelLikes = {}; // key: novelId -> Set<userId>
  final Map<String, Set<String>> _userLibrary = {}; // key: userId -> Set<novelId>
  final Map<String, Map<String, ReadingProgressModel>> _userReadingProgress = {}; // userId -> {novelId -> progress}
  final Map<String, Set<String>> _userDownloads = {}; // key: userId -> Set<novelId>
  final Map<String, ReportModel> _reports = {};

  // Auth state
  UserModel? _currentUser;
  final StreamController<UserModel?> _authStateController = StreamController<UserModel?>.broadcast();

  Stream<UserModel?> get authStateStream => _authStateController.stream;
  UserModel? get currentUser => _currentUser;

  void setCurrentUser(UserModel? user) {
    _currentUser = user;
    _authStateController.add(_currentUser);
  }

  void _seedData() {
    // 1. Seed Users
    final readerUser = UserModel(
      id: 'reader_1',
      displayName: 'Aria Thorne',
      email: 'aria.reader@destiny.com',
      photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      role: UserRole.reader,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
      updatedAt: DateTime.now(),
      bio: 'Avid fantasy and historical fiction reader. Always looking for hidden gems.',
    );

    final writerUser = UserModel(
      id: 'writer_1',
      displayName: 'Julian Vance',
      email: 'julian.author@destiny.com',
      photoUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      role: UserRole.writer,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
      updatedAt: DateTime.now(),
      bio: 'Author of dark atmospheric fantasy and speculative fiction.',
    );

    final adminUser = UserModel(
      id: 'admin_1',
      displayName: 'Elena Rostova',
      email: 'admin@novelsdestiny.com',
      photoUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150',
      role: UserRole.admin,
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 200)),
      updatedAt: DateTime.now(),
      bio: 'Platform Administrator & Chief Editor.',
    );

    _users[readerUser.id] = readerUser;
    _users[writerUser.id] = writerUser;
    _users[adminUser.id] = adminUser;
    _currentUser = readerUser; // default active user is Reader

    // 2. Seed Novels
    final novel1 = NovelModel(
      id: 'novel_1',
      writerId: writerUser.id,
      writerName: writerUser.displayName,
      writerAvatarUrl: writerUser.photoUrl,
      title: 'The Clockwork Alchemist',
      titleLowercase: 'the clockwork alchemist',
      description:
          'In the subterranean brass city of Oakhaven, an exiled alchemist discovers an ancient automaton that bleeds liquid starlight. When the Guild of Gears seeks its destruction, he must unravel a forgotten century-old conspiracy before the city itself is transmuted into ash.',
      coverUrl:
          'https://images.unsplash.com/photo-1532012164546-f432f2e3edd7?w=600&auto=format&fit=crop&q=80',
      genreIds: ['Fantasy', 'Steampunk', 'Mystery'],
      tags: ['alchemy', 'automaton', 'magic', 'steampunk', 'intrigue'],
      language: 'en',
      status: NovelStatus.ongoing,
      moderationStatus: ModerationStatus.approved,
      isDownloadEnabled: true,
      publishedEpisodeCount: 4,
      totalViews: 48200,
      totalLikes: 3410,
      totalDownloads: 890,
      rating: 4.9,
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      publishedAt: DateTime.now().subtract(const Duration(days: 44)),
    );

    final novel2 = NovelModel(
      id: 'novel_2',
      writerId: writerUser.id,
      writerName: writerUser.displayName,
      writerAvatarUrl: writerUser.photoUrl,
      title: 'Whispers Across the Moors',
      titleLowercase: 'whispers across the moors',
      description:
          'A gothic romance set amidst misty 19th-century Yorkshire estates. When Evelyn inherits a desolate manor, the phantom melodies from the locked attic draw her into an enigmatic romance with a recluse lord whose family harbors an ancestral curse.',
      coverUrl:
          'https://images.unsplash.com/photo-1512820790803-83ca734da794?w=600&auto=format&fit=crop&q=80',
      genreIds: ['Romance', 'Gothic', 'Historical'],
      tags: ['gothic', 'slow-burn', 'manor', 'mystery', 'victorian'],
      language: 'en',
      status: NovelStatus.completed,
      moderationStatus: ModerationStatus.approved,
      isDownloadEnabled: true,
      publishedEpisodeCount: 5,
      totalViews: 62400,
      totalLikes: 5120,
      totalDownloads: 1420,
      rating: 4.95,
      createdAt: DateTime.now().subtract(const Duration(days: 80)),
      updatedAt: DateTime.now().subtract(const Duration(days: 10)),
      publishedAt: DateTime.now().subtract(const Duration(days: 78)),
      completedAt: DateTime.now().subtract(const Duration(days: 10)),
    );

    final novel3 = NovelModel(
      id: 'novel_3',
      writerId: 'writer_2',
      writerName: 'Seraphina Vale',
      writerAvatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
      title: 'Echoes of the Starlit Citadel',
      titleLowercase: 'echoes of the starlit citadel',
      description:
          'On the edge of deep celestial space, humanity lives inside orbiting biosphere spires. When communications with the core spire go silent, junior astronavigator Kai is tasked with piloting through an uncharted nebula where time dilates with every breath.',
      coverUrl:
          'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600&auto=format&fit=crop&q=80',
      genreIds: ['Sci-Fi', 'Space Opera', 'Adventure'],
      tags: ['space', 'cosmic', 'nebula', 'survival', 'future'],
      language: 'en',
      status: NovelStatus.ongoing,
      moderationStatus: ModerationStatus.approved,
      isDownloadEnabled: false,
      publishedEpisodeCount: 3,
      totalViews: 29500,
      totalLikes: 1980,
      totalDownloads: 340,
      rating: 4.75,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      publishedAt: DateTime.now().subtract(const Duration(days: 28)),
    );

    final novel4 = NovelModel(
      id: 'novel_4',
      writerId: writerUser.id,
      writerName: writerUser.displayName,
      writerAvatarUrl: writerUser.photoUrl,
      title: 'The Silent Cartographer',
      titleLowercase: 'the silent cartographer',
      description:
          'A quiet cartographer is commissioned to map a phantom archipelago that appears on ocean charts only during total solar eclipses.',
      coverUrl:
          'https://images.unsplash.com/photo-1524995997946-a1c2e315a42f?w=600&auto=format&fit=crop&q=80',
      genreIds: ['Mystery', 'Adventure'],
      tags: ['maps', 'voyage', 'uncharted', 'expedition'],
      language: 'en',
      status: NovelStatus.draft,
      moderationStatus: ModerationStatus.pending,
      isDownloadEnabled: false,
      publishedEpisodeCount: 1,
      totalViews: 120,
      totalLikes: 15,
      totalDownloads: 0,
      rating: 4.5,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    );

    _novels[novel1.id] = novel1;
    _novels[novel2.id] = novel2;
    _novels[novel3.id] = novel3;
    _novels[novel4.id] = novel4;

    // 3. Seed Episodes for Novel 1 (The Clockwork Alchemist)
    _episodes[novel1.id] = [
      EpisodeModel(
        id: 'ep_1_1',
        novelId: novel1.id,
        writerId: writerUser.id,
        episodeNumber: 1,
        title: 'Chapter 1: The Glass Furnace',
        titleLowercase: 'chapter 1: the glass furnace',
        summary: 'Kael inspects a rusted relic recovered from the sunken lowest quarter.',
        content: '''The copper bells of the Low Foundry tolled six in the morning, their metallic resonance vibrating through the iron rafters of Kael’s basement laboratory. Outside, the sulfur fumes of Oakhaven were already settling like a yellow shroud over the cobblestones.

Kael adjusted his twin-lens magnification spectacles. On the slate table lay a mechanism no larger than an eagle’s egg, crusted in verdigris and calcified lime. It had taken three weeks of discreet bartering with the dredge-workers of Sluice Seven to acquire it.

"Steady now," he murmured to himself, lifting a silver pipette filled with distilled vitriol.

A single drop fell upon the central brass seam. The calcified crust hissed, dissolving into a pale violet vapor that smelled faintly of ozone and lavender—an impossibility in a city reeking of coal and grease.

Beneath the corrosive froth, the metal did not reveal gears or sprockets. Instead, the interior shimmered with tiny interlocking filaments of celestial crystal, beating in a rhythmic, organic pulse. It wasn't a clockwork heart.

It was alive.

A sharp rap on the reinforced oak door shattered his concentration. Kael swept a heavy velvet cloth over the artifact before reaching for the pneumatic piston lock.

"Who calls at sunrise?"

"The Guild of Gears, Alchemist Vance," came a voice dry as parchment. "Open, in the name of the Grand Mechanist."''',
        wordCount: 245,
        status: EpisodeStatus.published,
        publishedAt: DateTime.now().subtract(const Duration(days: 44)),
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
        updatedAt: DateTime.now().subtract(const Duration(days: 44)),
        totalViews: 18400,
      ),
      EpisodeModel(
        id: 'ep_1_2',
        novelId: novel1.id,
        writerId: writerUser.id,
        episodeNumber: 2,
        title: 'Chapter 2: The Scent of Ozone',
        titleLowercase: 'chapter 2: the scent of ozone',
        summary: 'Enforcers of the Guild arrive to demand submission of unregistered relics.',
        content: '''The heavy oak door unlatched with a pressurized hiss. Standing in the yellow morning mist were two Wardens of the Iron Spire, clad in articulated brass cuirasses and high-collared leather coats. Their goggles reflected Kael’s disheveled workshop in distorted amber circles.

"Inquisitor Thorne," Kael said, keeping one hand casually tucked inside his work apron, fingers curled around a glass sphere of flash-powder. "I didn't expect the Spire to inspect humble scrap collectors before noon."

"We are not here for scrap, Kael Vance," Thorne stepped past him without waiting for an invitation, his heavy boots clicking over the flagstones. "The resonance sensors in the Upper Ward recorded a spike of pure aetheric frequency at dawn. Originating precisely at these coordinates."

Thorne’s gaze swept across the worktables—the rows of bubbling alembics, the racks of titanium tweezers, the scribbled chalk diagrams covering the soot-blackened chimney breast.

"You know the edict," Thorne continued, tapping his brass-tipped baton against the iron vise. "Unlicensed transmutation carries a penalty of exile to the Cinder Barrens."

Beneath the velvet cloth on the central table, a faint, rhythmic humming began to build. Kael’s pulse leaped into his throat.

"I was merely clarifying whale oil for the street lamps," Kael lied smoothly, moving to block the table. "You know how stubborn the impurities can be."

Thorne stopped. His head tilted toward the velvet cloth. "And does whale oil sing, alchemist?"''',
        wordCount: 240,
        status: EpisodeStatus.published,
        publishedAt: DateTime.now().subtract(const Duration(days: 35)),
        createdAt: DateTime.now().subtract(const Duration(days: 36)),
        updatedAt: DateTime.now().subtract(const Duration(days: 35)),
        totalViews: 14200,
      ),
      EpisodeModel(
        id: 'ep_1_3',
        novelId: novel1.id,
        writerId: writerUser.id,
        episodeNumber: 3,
        title: 'Chapter 3: The Subterranean Vaults',
        titleLowercase: 'chapter 3: the subterranean vaults',
        summary: 'A narrow escape into the subterranean forgotten channels of Old Oakhaven.',
        content: '''Before Inquisitor Thorne could reach for the cloth, Kael hurled the flash-powder sphere against the slate floor.

A blinding flare of white magnesium light engulfed the workshop, followed by a concussive burst that knocked both wardens backward. Kael didn't hesitate. He grabbed the velvet-wrapped artifact, stuffed it into his canvas haversack, and kicked open the iron hatch set into the floorboards.

He dropped twelve feet into the damp, echoing darkness of the abandoned aqueducts below.

Water splashed up to his knees—chilled runoff from the mountain springs that supplied the grand boilers of the High Promenade. Above him, shouts and the clatter of steam-powered carbines rattled down the shaft.

Kael ignited a chemical phosphor-stick. Its green luminescence revealed arches of mossy stonework dating back three centuries, before the Great Enclosure had sealed the city under iron domes.

"Where now?" he breathed to himself.

As if answering, the haversack against his ribs grew warm. A soft, pulse of violet light shone through the thick canvas weave, illuminating a low tunnel heading northwest toward the Sunken Quarter. The artifact wasn't just reacting. It was guiding him.''',
        wordCount: 200,
        status: EpisodeStatus.published,
        publishedAt: DateTime.now().subtract(const Duration(days: 20)),
        createdAt: DateTime.now().subtract(const Duration(days: 21)),
        updatedAt: DateTime.now().subtract(const Duration(days: 20)),
        totalViews: 9800,
      ),
      EpisodeModel(
        id: 'ep_1_4',
        novelId: novel1.id,
        writerId: writerUser.id,
        episodeNumber: 4,
        title: 'Chapter 4: The Starlight Automaton',
        titleLowercase: 'chapter 4: the starlight automaton',
        summary: 'Deep within the sunken temple, Kael discovers the resting cradle of the automaton.',
        content: '''The tunnel widened into a subterranean amphitheater carved entirely from dark basalt. In the center stood a circular dais, cradled by four towering pylons of polished obsidian.

Resting upon the dais was a figure carved in the likeness of a winged guardian, its porcelain face serene and unbroken by time. Its chest bore an empty oval aperture of identical dimensions to the relic in Kael's haversack.

Kael walked forward, each step echoing through the chamber. With trembling hands, he unwrapped the celestial core and held it near the open cavity.

The core floated gently from his grasp, sliding into place with a chime like crystal bells.

Silver lines of light surged across the automaton's porcelain skin, its eyes opening to reveal twin pools of liquid starlight.

"Awakened," the guardian spoke, a melody that resonated in Kael's very bones. "The time of the Great Conjunction has arrived."''',
        wordCount: 160,
        status: EpisodeStatus.published,
        publishedAt: DateTime.now().subtract(const Duration(days: 1)),
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        totalViews: 5800,
      ),
    ];

    // Seed Episodes for Novel 2 (Whispers Across the Moors)
    _episodes[novel2.id] = [
      EpisodeModel(
        id: 'ep_2_1',
        novelId: novel2.id,
        writerId: writerUser.id,
        episodeNumber: 1,
        title: 'Chapter 1: The Inherited Keys',
        titleLowercase: 'chapter 1: the inherited keys',
        summary: 'Evelyn arrives at Blackwood Manor in the pouring rain.',
        content: '''The carriage wheels sank deep into the black peat mud of the North Yorkshire moors. Rain lashed against the glass in relentless torrents, blurring the jagged silhouette of Blackwood Manor perched like a roosting raven atop the crag.

Evelyn held the iron key ring tightly in her lap. Seven keys of brass and blackened silver, left to her by an uncle she had never met.

"We can go no further, Miss Hawthorne," the coachman called out, hauling back on the reins. "The horses will not cross the bridge after dusk."

Evelyn stepped down into the gale, gathering her wool cloak around her shoulders. Ahead, the great oak doors of Blackwood stood slightly ajar, and from within came the faint, melancholic strain of a violin.''',
        wordCount: 135,
        status: EpisodeStatus.published,
        publishedAt: DateTime.now().subtract(const Duration(days: 78)),
        createdAt: DateTime.now().subtract(const Duration(days: 80)),
        updatedAt: DateTime.now().subtract(const Duration(days: 78)),
        totalViews: 22000,
      ),
      EpisodeModel(
        id: 'ep_2_2',
        novelId: novel2.id,
        writerId: writerUser.id,
        episodeNumber: 2,
        title: 'Chapter 2: The Locked East Wing',
        titleLowercase: 'chapter 2: the locked east wing',
        summary: 'A midnight encounter with Lord Julian.',
        content: '''The halls of Blackwood were cold and cavernous. Dust sheets covered portraits of forgotten ancestors whose painted eyes seemed to follow Evelyn as she climbed the grand marble staircase.

At the end of the east corridor stood a heavy iron door, bolted with three padlocks.

As she reached out to touch the tarnished bronze lock, a shadow detached itself from the gloom.

"I would advise against disturbing what sleeps behind that threshold, Miss Hawthorne," a deep, quiet voice spoke.

Evelyn spun around. Standing near the gothic arched window was a man in dark velvet attire, his features sharp and aristocratic, illuminated by the silver moonlight.''',
        wordCount: 110,
        status: EpisodeStatus.published,
        publishedAt: DateTime.now().subtract(const Duration(days: 60)),
        createdAt: DateTime.now().subtract(const Duration(days: 62)),
        updatedAt: DateTime.now().subtract(const Duration(days: 60)),
        totalViews: 18000,
      ),
    ];

    // Seed Episodes for Novel 3
    _episodes[novel3.id] = [
      EpisodeModel(
        id: 'ep_3_1',
        novelId: novel3.id,
        writerId: 'writer_2',
        episodeNumber: 1,
        title: 'Chapter 1: The Nebula Crossing',
        titleLowercase: 'chapter 1: the nebula crossing',
        summary: 'Navigating through the veil of cosmic dust.',
        content: '''The sub-light thrusters hummed with a quiet vibration that thrummed through the soles of Kai\'s boots. Outside the polarized cockpit viewport, the Veil of Orion shimmered like a ribbon of violet silk spun across the void.

"Sensors reading anomalous gravitational spikes in Sector 9," the ship\'s AI intoned.

Kai adjusted the manual helm. "Prepare the jump stabilizers. We\'re going in."''',
        wordCount: 75,
        status: EpisodeStatus.published,
        publishedAt: DateTime.now().subtract(const Duration(days: 28)),
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 28)),
        totalViews: 12000,
      ),
    ];

    // 4. Seed user library & progress
    _userLibrary[readerUser.id] = {novel1.id, novel2.id};
    _novelLikes[novel1.id] = {readerUser.id};
    _userDownloads[readerUser.id] = {novel2.id};

    _userReadingProgress[readerUser.id] = {
      novel1.id: ReadingProgressModel(
        novelId: novel1.id,
        episodeId: 'ep_1_2',
        episodeNumber: 2,
        scrollOffset: 120.0,
        progressPercent: 0.50,
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      novel2.id: ReadingProgressModel(
        novelId: novel2.id,
        episodeId: 'ep_2_2',
        episodeNumber: 2,
        scrollOffset: 450.0,
        progressPercent: 1.0,
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    };

    // 5. Seed Reports
    final report1 = ReportModel(
      id: 'rep_1',
      reporterId: readerUser.id,
      reporterName: readerUser.displayName,
      targetType: 'novel',
      targetId: novel4.id,
      targetTitle: novel4.title,
      reason: 'Draft preview seems to contain placeholder text requiring review.',
      status: ReportStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    );
    _reports[report1.id] = report1;
  }

  // --- Novel methods ---
  Future<List<NovelModel>> getFeaturedNovels() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _novels.values.where((n) => n.isPubliclyVisible).toList();
  }

  Future<List<NovelModel>> getTrendingNovels() async {
    await Future.delayed(const Duration(milliseconds: 100));
    final list = _novels.values.where((n) => n.isPubliclyVisible).toList();
    list.sort((a, b) => b.totalViews.compareTo(a.totalViews));
    return list;
  }

  Future<List<NovelModel>> getNovelsByGenre(String genre) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _novels.values
        .where((n) => n.isPubliclyVisible && n.genreIds.any((g) => g.toLowerCase() == genre.toLowerCase()))
        .toList();
  }

  Future<List<NovelModel>> searchNovels(String query, {String? genre, String? status}) async {
    await Future.delayed(const Duration(milliseconds: 120));
    final q = query.trim().toLowerCase();
    return _novels.values.where((n) {
      if (!n.isPubliclyVisible && n.writerId != _currentUser?.id && _currentUser?.role != UserRole.admin) {
        return false;
      }
      final matchesQuery = q.isEmpty ||
          n.titleLowercase.contains(q) ||
          n.writerName.toLowerCase().contains(q) ||
          n.tags.any((t) => t.toLowerCase().contains(q)) ||
          n.genreIds.any((g) => g.toLowerCase().contains(q));
      final matchesGenre = genre == null || genre.isEmpty || n.genreIds.contains(genre);
      final matchesStatus = status == null || status.isEmpty || n.status.name == status;
      return matchesQuery && matchesGenre && matchesStatus;
    }).toList();
  }

  Future<NovelModel?> getNovelById(String id) async {
    await Future.delayed(const Duration(milliseconds: 80));
    return _novels[id];
  }

  Future<List<NovelModel>> getNovelsByWriter(String writerId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _novels.values.where((n) => n.writerId == writerId).toList();
  }

  Future<NovelModel> saveNovel(NovelModel novel) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _novels[novel.id] = novel;
    return novel;
  }

  Future<void> deleteNovel(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _novels.remove(id);
    _episodes.remove(id);
  }

  // --- Episode methods ---
  Future<List<EpisodeModel>> getEpisodesForNovel(String novelId, {bool publishedOnly = true}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final list = _episodes[novelId] ?? [];
    if (publishedOnly) {
      return list.where((e) => e.isPublished).toList();
    }
    return List.from(list);
  }

  Future<EpisodeModel?> getEpisodeById(String novelId, String episodeId) async {
    await Future.delayed(const Duration(milliseconds: 80));
    final list = _episodes[novelId] ?? [];
    try {
      return list.firstWhere((e) => e.id == episodeId);
    } catch (_) {
      return null;
    }
  }

  Future<EpisodeModel> saveEpisode(EpisodeModel episode) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final list = _episodes[episode.novelId] ?? [];
    final idx = list.indexWhere((e) => e.id == episode.id);
    if (idx >= 0) {
      list[idx] = episode;
    } else {
      list.add(episode);
    }
    _episodes[episode.novelId] = list;

    // Update novel published count
    final novel = _novels[episode.novelId];
    if (novel != null) {
      final publishedCount = list.where((e) => e.isPublished).length;
      _novels[episode.novelId] = NovelModel.fromEntity(novel.copyWith(
        publishedEpisodeCount: publishedCount,
        updatedAt: DateTime.now(),
      ));
    }
    return episode;
  }

  Future<void> deleteEpisode(String novelId, String episodeId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final list = _episodes[novelId] ?? [];
    list.removeWhere((e) => e.id == episodeId);
    _episodes[novelId] = list;
  }

  // --- Interactions ---
  bool isNovelLiked(String novelId, String userId) {
    return _novelLikes[novelId]?.contains(userId) ?? false;
  }

  void toggleLikeNovel(String novelId, String userId) {
    final set = _novelLikes[novelId] ?? <String>{};
    if (set.contains(userId)) {
      set.remove(userId);
      final n = _novels[novelId];
      if (n != null && n.totalLikes > 0) {
        _novels[novelId] = NovelModel.fromEntity(n.copyWith(totalLikes: n.totalLikes - 1));
      }
    } else {
      set.add(userId);
      final n = _novels[novelId];
      if (n != null) {
        _novels[novelId] = NovelModel.fromEntity(n.copyWith(totalLikes: n.totalLikes + 1));
      }
    }
    _novelLikes[novelId] = set;
  }

  bool isNovelSaved(String novelId, String userId) {
    return _userLibrary[userId]?.contains(novelId) ?? false;
  }

  void toggleSaveNovel(String novelId, String userId) {
    final set = _userLibrary[userId] ?? <String>{};
    if (set.contains(userId)) {
      set.remove(userId);
    } else {
      set.add(novelId);
    }
    _userLibrary[userId] = set;
  }

  List<NovelModel> getSavedNovels(String userId) {
    final ids = _userLibrary[userId] ?? {};
    return ids.map((id) => _novels[id]).whereType<NovelModel>().toList();
  }

  void saveReadingProgress(String userId, ReadingProgressModel progress) {
    final userMap = _userReadingProgress[userId] ?? {};
    userMap[progress.novelId] = progress;
    _userReadingProgress[userId] = userMap;
  }

  ReadingProgressModel? getReadingProgress(String userId, String novelId) {
    return _userReadingProgress[userId]?[novelId];
  }

  List<ReadingProgressModel> getReadingHistory(String userId) {
    final map = _userReadingProgress[userId] ?? {};
    final list = map.values.toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  void recordDownload(String userId, String novelId) {
    final set = _userDownloads[userId] ?? <String>{};
    set.add(novelId);
    _userDownloads[userId] = set;

    final n = _novels[novelId];
    if (n != null) {
      _novels[novelId] = NovelModel.fromEntity(n.copyWith(totalDownloads: n.totalDownloads + 1));
    }
  }

  List<NovelModel> getDownloadedNovels(String userId) {
    final ids = _userDownloads[userId] ?? {};
    return ids.map((id) => _novels[id]).whereType<NovelModel>().toList();
  }

  // --- Users ---
  List<UserModel> getAllUsers() => _users.values.toList();

  UserModel? getUserById(String id) => _users[id];

  void updateUser(UserModel user) {
    _users[user.id] = user;
    if (_currentUser?.id == user.id) {
      setCurrentUser(user);
    }
  }

  // --- Moderation & Reports ---
  List<NovelModel> getPendingNovels() {
    return _novels.values.where((n) => n.moderationStatus == ModerationStatus.pending).toList();
  }

  void updateNovelModerationStatus(String novelId, ModerationStatus status) {
    final n = _novels[novelId];
    if (n != null) {
      _novels[novelId] = NovelModel.fromEntity(n.copyWith(moderationStatus: status, updatedAt: DateTime.now()));
    }
  }

  List<ReportModel> getReports({ReportStatus? status}) {
    if (status != null) {
      return _reports.values.where((r) => r.status == status).toList();
    }
    return _reports.values.toList();
  }

  void saveReport(ReportModel report) {
    _reports[report.id] = report;
  }

  // --- Analytics ---
  PlatformAnalyticsEntity getPlatformAnalytics() {
    final totalUsers = _users.length;
    final totalReaders = _users.values.where((u) => u.isReader).length;
    final totalWriters = _users.values.where((u) => u.isWriter).length;
    final totalNovels = _novels.length;
    final totalPublishedEpisodes = _episodes.values.fold<int>(0, (sum, list) => sum + list.where((e) => e.isPublished).length);
    final totalReads = _novels.values.fold<int>(0, (sum, n) => sum + n.totalViews);
    final totalLikes = _novels.values.fold<int>(0, (sum, n) => sum + n.totalLikes);
    final totalDownloads = _novels.values.fold<int>(0, (sum, n) => sum + n.totalDownloads);
    final pendingMods = _novels.values.where((n) => n.moderationStatus == ModerationStatus.pending).length;
    final openReps = _reports.values.where((r) => r.status == ReportStatus.pending).length;

    return PlatformAnalyticsEntity(
      totalUsers: totalUsers,
      totalReaders: totalReaders,
      totalWriters: totalWriters,
      totalNovels: totalNovels,
      totalPublishedEpisodes: totalPublishedEpisodes,
      totalReads: totalReads,
      totalLikes: totalLikes,
      totalDownloads: totalDownloads,
      pendingModerations: pendingMods,
      openReports: openReps,
      dailyReadsTrend: const [
        DailyMetricPoint(dateLabel: 'Mon', value: 12400),
        DailyMetricPoint(dateLabel: 'Tue', value: 15800),
        DailyMetricPoint(dateLabel: 'Wed', value: 14200),
        DailyMetricPoint(dateLabel: 'Thu', value: 18900),
        DailyMetricPoint(dateLabel: 'Fri', value: 24500),
        DailyMetricPoint(dateLabel: 'Sat', value: 31200),
        DailyMetricPoint(dateLabel: 'Sun', value: 28400),
      ],
      dailyUsersTrend: const [
        DailyMetricPoint(dateLabel: 'Mon', value: 450),
        DailyMetricPoint(dateLabel: 'Tue', value: 520),
        DailyMetricPoint(dateLabel: 'Wed', value: 490),
        DailyMetricPoint(dateLabel: 'Thu', value: 680),
        DailyMetricPoint(dateLabel: 'Fri', value: 890),
        DailyMetricPoint(dateLabel: 'Sat', value: 1100),
        DailyMetricPoint(dateLabel: 'Sun', value: 980),
      ],
    );
  }

  WriterAnalyticsEntity getWriterAnalytics(String writerId) {
    final writerNovels = _novels.values.where((n) => n.writerId == writerId).toList();
    final totalNovels = writerNovels.length;
    final publishedEpisodes = writerNovels.fold<int>(0, (sum, n) => sum + n.publishedEpisodeCount);
    final totalReads = writerNovels.fold<int>(0, (sum, n) => sum + n.totalViews);
    final totalLikes = writerNovels.fold<int>(0, (sum, n) => sum + n.totalLikes);
    final totalDownloads = writerNovels.fold<int>(0, (sum, n) => sum + n.totalDownloads);

    return WriterAnalyticsEntity(
      writerId: writerId,
      totalNovels: totalNovels,
      publishedEpisodes: publishedEpisodes,
      totalReads: totalReads,
      totalLikes: totalLikes,
      totalDownloads: totalDownloads,
      dailyReadsTrend: const [
        DailyMetricPoint(dateLabel: 'Mon', value: 3400),
        DailyMetricPoint(dateLabel: 'Tue', value: 4200),
        DailyMetricPoint(dateLabel: 'Wed', value: 3900),
        DailyMetricPoint(dateLabel: 'Thu', value: 5100),
        DailyMetricPoint(dateLabel: 'Fri', value: 6800),
        DailyMetricPoint(dateLabel: 'Sat', value: 8900),
        DailyMetricPoint(dateLabel: 'Sun', value: 7600),
      ],
    );
  }
}
