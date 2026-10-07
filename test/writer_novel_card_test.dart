import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novels_destiny/domain/entities/novel_entity.dart';
import 'package:novels_destiny/features/writer_dashboard/widgets/writer_novel_card.dart';

void main() {
  testWidgets('WriterNovelCard renders cleanly without overflow on small screens', (tester) async {
    // Set small screen size typical of mobile phones
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final novel = NovelEntity(
      id: 'novel-1',
      writerId: 'writer-1',
      writerName: 'Test Author',
      title: 'رسول اللہ ﷺ نے فرمایا - The Path of Light',
      titleLowercase: 'the path of light',
      description: 'A deeply inspiring spiritual manuscript.',
      coverUrl: '',
      genreIds: ['spiritual'],
      tags: ['faith'],
      language: 'Urdu',
      status: NovelStatus.ongoing,
      moderationStatus: ModerationStatus.approved,
      isDownloadEnabled: true,
      publishedEpisodeCount: 1,
      totalViews: 0,
      totalLikes: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    bool addEpisodeCalled = false;
    bool editCalled = false;
    bool viewCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: WriterNovelCard(
              novel: novel,
              onAddEpisode: () => addEpisodeCalled = true,
              onEdit: () => editCalled = true,
              onView: () => viewCalled = true,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify novel title is visible (in placeholder cover and title header)
    expect(find.text('رسول اللہ ﷺ نے فرمایا - The Path of Light'), findsNWidgets(2));

    // Verify stats are visible
    expect(find.text('1 Episode'), findsOneWidget);
    expect(find.text('0 Reads'), findsOneWidget);
    expect(find.text('0 Likes'), findsOneWidget);

    // Verify buttons are rendered
    expect(find.text('Add Episode'), findsOneWidget);

    // Tap Add Episode
    await tester.tap(find.text('Add Episode'));
    expect(addEpisodeCalled, isTrue);

    // Tap Edit icon
    await tester.tap(find.byTooltip('Edit Story Details'));
    expect(editCalled, isTrue);

    // Tap View icon
    await tester.tap(find.byTooltip('View as Reader'));
    expect(viewCalled, isTrue);

    // Ensure no flutter exceptions (like RenderFlex overflow) occurred
    expect(tester.takeException(), isNull);
  });
}
