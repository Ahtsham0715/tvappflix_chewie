import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_tv/ui/player/controls_overlay.dart';
import 'package:flutter_app_tv/ui/player/video_state_saver.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:flutter_app_tv/model/subtitle.dart' as model;

typedef OnStopRecordingCallback = void Function(String);

class VlcPlayerWithControls extends StatefulWidget {
  final VlcPlayerController controller;
  final bool showControls;
  final OnStopRecordingCallback? onStopRecording;
  final List<model.Subtitle> subtitlesList;
  final VoidCallback prepareNextEpisode;
  const VlcPlayerWithControls({
    required this.controller,
    this.showControls = true,
    this.onStopRecording,
    super.key,
    required this.subtitlesList,
    required this.prepareNextEpisode,
  });

  @override
  VlcPlayerWithControlsState createState() => VlcPlayerWithControlsState();
}

class VlcPlayerWithControlsState extends State<VlcPlayerWithControls> {
  static const _numberPositionOffset = 8.0;
  static const _positionedBottomSpace = 7.0;
  static const _positionedRightSpace = 3.0;
  static const _overlayWidth = 100.0;
  // static const _elevation = 4.0;
  static const _aspectRatio = 16 / 9;

  final double initSnapshotRightPosition = 10;
  final double initSnapshotBottomPosition = 10;

  // ignore: avoid-late-keyword
  late VlcPlayerController _controller;

  //
  // OverlayEntry? _overlayEntry;

  //
  double sliderValue = 0.0;
  double volumeValue = 50;
  String position = '';
  String duration = '';
  int numberOfCaptions = 0;
  int numberOfAudioTracks = 0;
  bool validPosition = false;

  double recordingTextOpacity = 0;
  DateTime lastRecordingShowTime = DateTime.now();
  bool isRecording = false;

  //
  List<double> playbackSpeeds = [0.5, 1.0, 2.0];
  int playbackSpeedIndex = 1;
  bool hideSeekControls = true;
  bool resumedPlayback = false;
  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    // _controller.addOnInitListener(() {
    // if (_controller.value.isPlaying) {
    // resumePlayback();
    // }
    // });
    _controller.addListener(listener);
  }

  // void resumePlayback() async {
  //   int? savedPosition =
  //       await VideoStateSaver.getVideoState(key: _controller.dataSource);
  //   print('savedPosition: $savedPosition');
  //   if (savedPosition != null) {
  //     try {
  //       // await Future.delayed(Duration(milliseconds: 500));
  //       _controller.setTime(savedPosition);
  //       print(
  //           'rsum playback at ${savedPosition} position: ${_controller.value.position.inSeconds}');
  //     } catch (e) {
  //       print('seeking error: $e');
  //     }
  //   }
  // }

  void listener() async {
    if (!mounted) return;
    //
    if (_controller.value.isInitialized) {
      // if (resumedPlayback) {
      //   oPosition = _controller.value.position;
      // } else {
      // resumedPlayback = true;
      // int? savedPosition =
      //     await VideoStateSaver.getVideoState(key: _controller.dataSource);

      // oPosition = Duration(milliseconds: savedPosition ?? 0);
      // _controller.seekTo(Duration(milliseconds: savedPosition ?? 0));
      // print(
      //     'rsum playback at ${savedPosition} position: ${oPosition.inSeconds}');
      // }
      final oPosition = _controller.value.position;
      final oDuration = _controller.value.duration;

      if (oDuration.inHours == 0) {
        final strPosition = oPosition.toString().split('.').first;
        final strDuration = oDuration.toString().split('.').first;
        setState(() {
          position =
              "${strPosition.split(':')[1]}:${strPosition.split(':')[2]}";
          duration =
              "${strDuration.split(':')[1]}:${strDuration.split(':')[2]}";
        });
      } else {
        setState(() {
          position = oPosition.toString().split('.').first;
          duration = oDuration.toString().split('.').first;
        });
      }
      setState(() {
        validPosition = oDuration.compareTo(oPosition) >= 0;

        sliderValue = validPosition ? oPosition.inSeconds.toDouble() : 0;
      });
      setState(() {
        // numberOfCaptions = _controller.value.spuTracksCount;
        numberOfAudioTracks = _controller.value.audioTracksCount;
      });
      // if (_controller.value.isPlaying &&
      //     _controller.value.position.inSeconds > 0 &&
      //     !resumedPlayback) {
      //   resumedPlayback = true;
      //   int? savedPosition =
      //       await VideoStateSaver.getVideoState(key: _controller.dataSource);

      //   _controller.seekTo(_controller.value.position +
      //       Duration(milliseconds: savedPosition ?? 0));
      //   print(
      //       'rsum playback at ${savedPosition} position: ${oPosition.inSeconds}');
      // }
      if (_controller.value.isPlaying) {
        VideoStateSaver.saveVideoState(
            _controller.value.position.inMilliseconds, _controller.dataSource);
        print('savdValu: ${_controller.value.position.inMilliseconds}');
      }
      // print('datasource: ${_controller.dataSource}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: ColoredBox(
            color: Colors.black,
            child: Stack(
              fit: StackFit.expand,
              alignment: Alignment.bottomCenter,
              children: <Widget>[
                VlcPlayer(
                  controller: _controller,
                  aspectRatio: _aspectRatio,
                  // virtualDisplay: false,
                  placeholder: const Center(child: CircularProgressIndicator()),
                ),
                ControlsOverlay(controller: _controller),
              ],
            ),
          ),
        ),
        Visibility(
          visible: widget.showControls,
          child: Container(
            child: Row(
              children: [
                IconButton(
                  color: Colors.white,
                  icon: _controller.value.isPlaying
                      ? const Icon(Icons.pause_circle_outline)
                      : const Icon(Icons.play_circle_outline),
                  onPressed: _togglePlaying,
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        position,
                        style: const TextStyle(color: Colors.white),
                      ),
                      Expanded(
                        child: Slider(
                          activeColor: Colors.redAccent,
                          inactiveColor: Colors.white70,
                          value: sliderValue,
                          max: !validPosition
                              ? 1.0
                              : _controller.value.duration.inSeconds.toDouble(),
                          onChanged:
                              validPosition ? _onSliderPositionChanged : null,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: Text(
                          duration,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Visibility(
          visible: widget.showControls,
          child: SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              children: [
                Wrap(
                  children: [
                    Stack(
                      children: [
                        IconButton(
                          tooltip: 'Get Subtitle Tracks',
                          icon: const Icon(Icons.closed_caption),
                          color: Colors.white,
                          onPressed: _getSubtitleTracks,
                        ),
                        Positioned(
                          top: _numberPositionOffset,
                          right: _numberPositionOffset,
                          child: IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(1),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 1,
                                horizontal: 2,
                              ),
                              child: Text(
                                '${widget.subtitlesList.length}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Stack(
                      children: [
                        IconButton(
                          tooltip: 'Get Audio Tracks',
                          icon: const Icon(CupertinoIcons.captions_bubble_fill),
                          color: Colors.white,
                          onPressed: _getAudioTracks,
                        ),
                        Positioned(
                          top: _numberPositionOffset,
                          right: _numberPositionOffset,
                          child: IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(1),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 1,
                                horizontal: 2,
                              ),
                              child: Text(
                                '$numberOfAudioTracks',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.speed),
                          color: Colors.white,
                          onPressed: _cyclePlaybackSpeed,
                        ),
                        Positioned(
                          bottom: _positionedBottomSpace,
                          right: _positionedRightSpace,
                          child: IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(1),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 1,
                                horizontal: 2,
                              ),
                              child: Text(
                                '${playbackSpeeds.elementAt(playbackSpeedIndex)}x',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // IconButton(
                    //   icon: const Icon(Icons.keyboard_double_arrow_right),
                    //   color: Colors.white,
                    //   onPressed: widget.prepareNextEpisode,
                    // ),
                  ],
                ),
                Visibility(
                  visible: widget.showControls,
                  child: Container(
                    width: 200,
                    // color: _playerControlsBgColor,
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      // mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.volume_up_rounded,
                          color: Colors.white,
                        ),
                        Expanded(
                          child: Slider(
                            max: _overlayWidth,
                            value: volumeValue,
                            onChanged: _setSoundVolume,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.removeListener(listener);
    super.dispose();
  }

  Future<void> _cyclePlaybackSpeed() async {
    playbackSpeedIndex++;
    if (playbackSpeedIndex >= playbackSpeeds.length) {
      playbackSpeedIndex = 0;
    }

    return _controller
        .setPlaybackSpeed(playbackSpeeds.elementAt(playbackSpeedIndex));
  }

  void _setSoundVolume(double value) {
    setState(() {
      volumeValue = value;
    });

    _controller.setVolume(volumeValue.toInt());
  }

  Future<void> _togglePlaying() async {
    _controller.value.isPlaying
        ? await _controller.pause()
        : await _controller.play();
  }

  void _onSliderPositionChanged(double progress) {
    setState(() {
      sliderValue = progress.floor().toDouble();
    });
    //convert to Milliseconds since VLC requires MS to set time
    _controller.setTime(sliderValue.toInt() * Duration.millisecondsPerSecond);
  }

  Future loadSubtitles() async {
    for (model.Subtitle sub in widget.subtitlesList) {
      _controller.addSubtitleFromNetwork(
        sub.url,
      );
    }
  }

  Future<void> _getSubtitleTracks() async {
    // if (!_controller.value.isPlaying) return;
    await loadSubtitles();
    final subtitleTracks = await _controller.getSpuTracks();
    //

    if (widget.subtitlesList.isNotEmpty) {
      if (!mounted) return;

      final selectedSubId = await showDialog<int>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Select Subtitle'),
            content: SizedBox(
              width: 150,
              height: 200,
              child: ListView.builder(
                itemCount: widget.subtitlesList.length + 1,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      index < widget.subtitlesList.length
                          ? widget.subtitlesList[index].language
                          : 'Disable',
                    ),
                    onTap: () {
                      print(
                          'selectedValue: ${index < widget.subtitlesList.length ? widget.subtitlesList[index].language : 'Disable'}');
                      Navigator.pop(
                        context,
                        index < subtitleTracks.keys.length
                            ? subtitleTracks.keys.elementAt(index)
                            : -1,
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      );

      if (selectedSubId != null) {
        await _controller.setSpuTrack(selectedSubId);
      }
    }
  }

  Future<void> _getAudioTracks() async {
    // if (!_controller.value.isPlaying) return; //TODO

    final audioTracks = await _controller.getAudioTracks();
    //
    if (audioTracks.isNotEmpty) {
      if (!mounted) return;
      final selectedAudioTrackId = await showDialog<int>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Select Audio'),
            content: SizedBox(
              width: 150,
              height: 200,
              child: ListView.builder(
                itemCount: audioTracks.keys.length + 1,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      index < audioTracks.keys.length
                          ? audioTracks.values.elementAt(index)
                          : 'Disable',
                    ),
                    onTap: () {
                      Navigator.pop(
                        context,
                        index < audioTracks.keys.length
                            ? audioTracks.keys.elementAt(index)
                            : -1,
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      );

      if (selectedAudioTrackId != null) {
        await _controller.setAudioTrack(selectedAudioTrackId);
      }
    }
  }
}
