import 'package:flutter/material.dart';
import '../../../domain/entities/novel_entity.dart';
import '../../../domain/entities/episode_entity.dart';
import '../../../app/theme/app_theme.dart';

enum ReaderColorTheme {
  cream,
  parchment,
  dark,
  white;

  Color get backgroundColor {
    switch (this) {
      case ReaderColorTheme.cream:
        return AppColors.readerCreamBg;
      case ReaderColorTheme.parchment:
        return AppColors.readerParchmentBg;
      case ReaderColorTheme.dark:
        return AppColors.readerDarkBg;
      case ReaderColorTheme.white:
        return AppColors.readerWhiteBg;
    }
  }

  Color get textColor {
    switch (this) {
      case ReaderColorTheme.cream:
        return AppColors.readerCreamText;
      case ReaderColorTheme.parchment:
        return AppColors.readerParchmentText;
      case ReaderColorTheme.dark:
        return AppColors.readerDarkText;
      case ReaderColorTheme.white:
        return AppColors.readerWhiteText;
    }
  }

  String get label {
    switch (this) {
      case ReaderColorTheme.cream:
        return 'Cream';
      case ReaderColorTheme.parchment:
        return 'Parchment';
      case ReaderColorTheme.dark:
        return 'Dark';
      case ReaderColorTheme.white:
        return 'White';
    }
  }
}

enum ReaderFontFamily {
  serif,
  sans;

  String get label {
    switch (this) {
      case ReaderFontFamily.serif:
        return 'Merriweather (Serif)';
      case ReaderFontFamily.sans:
        return 'Plus Jakarta (Sans)';
    }
  }
}

sealed class EpisodeReaderState {
  const EpisodeReaderState();
}

class EpisodeReaderLoading extends EpisodeReaderState {
  const EpisodeReaderLoading();
}

class EpisodeReaderFailure extends EpisodeReaderState {
  final String message;
  const EpisodeReaderFailure(this.message);
}

class EpisodeReaderReady extends EpisodeReaderState {
  final NovelEntity novel;
  final EpisodeEntity currentEpisode;
  final List<EpisodeEntity> allEpisodes;
  final EpisodeEntity? previousEpisode;
  final EpisodeEntity? nextEpisode;
  final double progressPercent;

  const EpisodeReaderReady({
    required this.novel,
    required this.currentEpisode,
    required this.allEpisodes,
    this.previousEpisode,
    this.nextEpisode,
    this.progressPercent = 0.0,
  });

  EpisodeReaderReady copyWith({
    NovelEntity? novel,
    EpisodeEntity? currentEpisode,
    List<EpisodeEntity>? allEpisodes,
    EpisodeEntity? previousEpisode,
    EpisodeEntity? nextEpisode,
    double? progressPercent,
  }) {
    return EpisodeReaderReady(
      novel: novel ?? this.novel,
      currentEpisode: currentEpisode ?? this.currentEpisode,
      allEpisodes: allEpisodes ?? this.allEpisodes,
      previousEpisode: previousEpisode ?? this.previousEpisode,
      nextEpisode: nextEpisode ?? this.nextEpisode,
      progressPercent: progressPercent ?? this.progressPercent,
    );
  }
}
