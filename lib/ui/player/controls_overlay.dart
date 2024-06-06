import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

class ControlsOverlay extends StatelessWidget {
  // static const double _playButtonIconSize = 5;
  // static const double _replayButtonIconSize = 5;
  // static const double _seekButtonIconSize = 5;

  // static const Duration _seekStepForward = Duration(seconds: 10);
  // static const Duration _seekStepBackward = Duration(seconds: -10);

  static const Color _iconColor = Colors.white;

  final VlcPlayerController controller;
  const ControlsOverlay({
    required this.controller,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (ctx) {
        if (controller.value.isEnded || controller.value.hasError) {
          return Center(
            child: FittedBox(
              child: IconButton(
                onPressed: _replay,
                color: _iconColor,
                // iconSize: _replayButtonIconSize,
                icon: const Icon(Icons.replay),
              ),
            ),
          );
        }

        switch (controller.value.playingState) {
          case PlayingState.initialized:
          case PlayingState.stopped:
          case PlayingState.paused:
            return Container(
              padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _play,
                color: Colors.white,
                iconSize: 35,
                icon: const Icon(Icons.play_arrow),
              ),
            );

          case PlayingState.buffering:
          case PlayingState.playing:
            return Container(
              padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _pause,
                color: Colors.white,
                iconSize: 35,
                icon: const Icon(Icons.pause),
              ),
            );

          case PlayingState.ended:
          case PlayingState.error:
            return Center(
              child: FittedBox(
                child: IconButton(
                  onPressed: _replay,
                  color: _iconColor,
                  // iconSize: _replayButtonIconSize,
                  icon: const Icon(Icons.replay),
                ),
              ),
            );

          default:
            return const SizedBox.shrink();
        }
      },
    );
  }

  Future<void> _play() {
    return controller.play();
  }

  Future<void> _replay() async {
    await controller.stop();
    await controller.play();
  }

  Future<void> _pause() async {
    if (controller.value.isPlaying) {
      await controller.pause();
    }
  }

  /// Returns a callback which seeks the video relative to current playing time.
  Future<void> _seekRelative(Duration seekStep) {
    return controller.seekTo(controller.value.position + seekStep);
  }
}
