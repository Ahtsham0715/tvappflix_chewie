import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final VoidCallback preparePreviousEpisode;
  final List episodesList;
  final int currentVideoIndex;
  final int? episode;
  final String videoTitle;
  const VlcPlayerWithControls({
    required this.controller,
    this.showControls = true,
    this.onStopRecording,
    super.key,
    required this.subtitlesList,
    required this.prepareNextEpisode,
    required this.preparePreviousEpisode,
    required this.episodesList,
    required this.currentVideoIndex,
    required this.episode,
    required this.videoTitle,
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
  bool hideControls = false;
  bool timerRunning = false;
  bool resumedPlayback = false;
  static const Duration _seekStepForward = Duration(seconds: 10);
  static const Duration _seekStepBackward = Duration(seconds: -10);
  FocusNode videoPlayerFocusNode = FocusNode();
  Map btnFocusNodes = {};
  String currentFocusedElement = '';
  int currentFocusedLine = 0;
  bool selectedSlider = false;
  @override
  void initState() {
    super.initState();

    _controller = widget.controller;
    initializebtnFocusNodesMap();

    _controller.addListener(listener);
    hideSeekControls();
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

  void initializebtnFocusNodesMap() {
    btnFocusNodes = {
      // 'play_pause_btn_large': {'isFocused': false, 'onTap': () {}},
      'play_pause_btn_small': {
        'isFocused': false,
        'onTap': _togglePlaying(),
        'currentFocusedLine': 0
      },
      'seek_slider_btn': {
        'isFocused': false,
        'onTap': () {},
        'currentFocusedLine': 0
      },
      'subtitle_btn': {
        'isFocused': false,
        'onTap': _getSubtitleTracks(),
        'currentFocusedLine': 1
      },
      'audio_track_btn': {
        'isFocused': false,
        'onTap': _getAudioTracks(),
        'currentFocusedLine': 1
      },
      'speed_btn': {
        'isFocused': false,
        'onTap': _cyclePlaybackSpeed(),
        'currentFocusedLine': 1
      },

      'minus_10_sec_btn': {
        'isFocused': false,
        'onTap': () {
          _onSliderPositionChanged(
              (_controller.value.position - Duration(seconds: 10))
                  .inSeconds
                  .toDouble());
        },
        'currentFocusedLine': 1
      },
      'plus_10_sec_btn': {
        'isFocused': false,
        'onTap': () {
          _onSliderPositionChanged(
              (_controller.value.position + Duration(seconds: 10))
                  .inSeconds
                  .toDouble());
        },
        'currentFocusedLine': 1
      },
      'prev_episode_btn': {
        'isFocused': false,
        'onTap': widget.preparePreviousEpisode,
        'currentFocusedLine': 1
      },
      'next_episode_btn': {
        'isFocused': false,
        'onTap': widget.prepareNextEpisode,
        'currentFocusedLine': 1
      },
      'volume_slider_btn': {
        'isFocused': false,
        'onTap': () {},
        'currentFocusedLine': 1
      },
      // 'prev_episode_btn': {'isFocused': false, 'onTap': () {}},
    };
    setState(() {});
    // btnFocusNodes['play_pause_small']['onTap'] = ;
    // btnFocusNodes['next_episode_btn']['onTap'] = ;
    // btnFocusNodes['prev_episode_btn']['onTap'] = widget.preparePreviousEpisode;
    // btnFocusNodes['subtitle_btn']['onTap'] = ;
    // btnFocusNodes['audio_track_btn']['onTap'] = ;
    // btnFocusNodes['speed_btn']['onTap'] = ;
    // btnFocusNodes['plus_10_sec_btn']['onTap'] = () {

    // };
    // btnFocusNodes['minus_10_sec_btn']['onTap'] = () {

    // };
  }

  // void togglePlayPause() {
  //   if (_controller.value.isPlaying) {
  //     _controller.pause();
  //   } else {
  //     _controller.play();
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

  void hideSeekControls() async {
    await Future.delayed(Duration(seconds: 8), () {
      // if (!timerRunning) {
      setState(() {
        hideControls = true;
        timerRunning = false;
      });
    });
  }

  void changeFocus(bool isForward, {bool isUpArrow = false}) {
    String nextItem = '';
    if (currentFocusedElement.isEmpty) {
      if (isForward) {
        nextItem = btnFocusNodes.entries.first.key;
      } else {
        nextItem = btnFocusNodes.entries.last.key;
      }
    } else {
      btnFocusNodes[currentFocusedElement]['isFocused'] = false;
      List keys = btnFocusNodes.keys.toList();
      if (isForward) {
        // if (currentFocusedLine == 0) {
        //   if (keys.indexOf(currentFocusedElement) == 0) {
        //     nextItem = btnFocusNodes.entries.elementAt(1).key;
        //   } else {
        //     nextItem = btnFocusNodes.entries.first.key;
        //   }
        // } else {
        //   if (keys.indexOf(currentFocusedElement) + 1 < btnFocusNodes.length) {
        //     nextItem = keys[keys.indexOf(currentFocusedElement) + 1];
        //   } else {
        //     nextItem = btnFocusNodes.entries.first.key;
        //   }
        // }
        if (keys.indexOf(currentFocusedElement) + 1 < btnFocusNodes.length) {
          nextItem = keys[keys.indexOf(currentFocusedElement) + 1];
        } else {
          nextItem = btnFocusNodes.entries.first.key;
        }
      } else {
        // if (currentFocusedLine == 0) {
        //   if (keys.indexOf(currentFocusedElement) == 1) {
        //     nextItem = btnFocusNodes.entries.first.key;
        //   } else {
        //     nextItem = btnFocusNodes.entries.elementAt(1).key;
        //   }
        // } else {
        //   if (keys.indexOf(currentFocusedElement) - 1 >= 0) {
        //     nextItem = keys[keys.indexOf(currentFocusedElement) - 1];
        //   } else {
        //     nextItem = btnFocusNodes.entries.last.key;
        //   }
        // }
        if (keys.indexOf(currentFocusedElement) - 1 >= 0) {
          nextItem = keys[keys.indexOf(currentFocusedElement) - 1];
        } else {
          nextItem = btnFocusNodes.entries.last.key;
        }
      }
    }

    setState(() {
      currentFocusedElement = nextItem;
      btnFocusNodes[currentFocusedElement]['isFocused'] = true;
    });
    print('next Item: ${nextItem}');
  }

  void _handleDpadPress(KeyEvent event) async {
    if (event is KeyDownEvent) {
      if (hideControls) {
        setState(() {
          hideControls = false;
        });
        if (!hideControls) {
          timerRunning = true;
          hideSeekControls();
        }
        print('screen tapped');
      }

      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowLeft:
          if (selectedSlider) {
            if (currentFocusedElement == 'seek_slider_btn') {
              _onSliderPositionChanged(
                  (_controller.value.position - Duration(seconds: 10))
                      .inSeconds
                      .toDouble());
            } else if (currentFocusedElement == 'volume_slider_btn') {
              _setSoundVolume((volumeValue - 10));
            }
          } else {
            changeFocus(false);
          }

          break;
        case LogicalKeyboardKey.arrowRight:
          if (selectedSlider) {
            if (currentFocusedElement == 'seek_slider_btn') {
              _onSliderPositionChanged(
                  (_controller.value.position + Duration(seconds: 10))
                      .inSeconds
                      .toDouble());
            } else if (currentFocusedElement == 'volume_slider_btn') {
              _setSoundVolume((volumeValue + 10));
            }
          } else {
            changeFocus(true);
          }

          break;
        case LogicalKeyboardKey.arrowUp:

          // setState(() {
          if (currentFocusedLine == 0) {
            currentFocusedLine = 1;
          } else {
            currentFocusedLine = 0;
          }
          // });

          handleUpAndDownPress();
          break;
        case LogicalKeyboardKey.arrowDown:
          if (currentFocusedLine == 0) {
            currentFocusedLine = 1;
          } else {
            currentFocusedLine = 0;
          }

          handleUpAndDownPress();
          break;
        case (LogicalKeyboardKey.enter || LogicalKeyboardKey.select):
          print('select button pressed: $currentFocusedElement');
          decideOnTap();

          break;

        default:
          break;
      }
    }
  }

  void decideOnTap() async {
    if (currentFocusedElement == 'volume_slider_btn') {
      selectedSlider = !selectedSlider;
    } else if (currentFocusedElement == 'seek_slider_btn') {
      selectedSlider = !selectedSlider;
    } else if (currentFocusedElement == 'play_pause_btn_small') {
      _togglePlaying();
    } else if (currentFocusedElement == 'prev_episode_btn') {
      if (widget.currentVideoIndex > 0) {
        widget.preparePreviousEpisode();
      }
    } else if (currentFocusedElement == 'next_episode_btn') {
      if ((widget.currentVideoIndex < widget.episodesList.length - 1) &&
          widget.episodesList.length > 1 &&
          widget.episode != null) {
        widget.prepareNextEpisode();
      }
    } else if (currentFocusedElement == 'subtitle_btn') {
      _getSubtitleTracks();
    } else if (currentFocusedElement == 'audio_track_btn') {
      _getAudioTracks();
    } else if (currentFocusedElement == 'speed_btn') {
      _cyclePlaybackSpeed();
    } else if (currentFocusedElement == 'plus_10_sec_btn') {
      _onSliderPositionChanged(
          (_controller.value.position + Duration(seconds: 10))
              .inSeconds
              .toDouble());
    } else if (currentFocusedElement == 'minus_10_sec_btn') {
      _onSliderPositionChanged(
          (_controller.value.position - Duration(seconds: 10))
              .inSeconds
              .toDouble());
    }
  }

  void handleUpAndDownPress() async {
    var nextItem;
    btnFocusNodes[currentFocusedElement]['isFocused'] = false;
    List keys = btnFocusNodes.keys.toList();
    if (currentFocusedLine == 0) {
      if (keys.indexOf(currentFocusedElement) == 0) {
        nextItem = btnFocusNodes.entries.elementAt(1).key;
      } else {
        nextItem = btnFocusNodes.entries.elementAt(0).key;
      }
    } else {
      nextItem = btnFocusNodes.entries.elementAt(2).key;
    }
    setState(() {
      currentFocusedElement = nextItem;
      btnFocusNodes[currentFocusedElement]['isFocused'] = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: videoPlayerFocusNode,
      onKeyEvent: (vnt) {
        _handleDpadPress(vnt);
      },
      child: Stack(
        // mainAxisSize: MainAxisSize.max,
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            // aspectRatio: _aspectRatio,
            child: InkWell(
              onTap: timerRunning
                  ? null
                  : () {
                      setState(() {
                        hideControls = !hideControls;
                      });
                      if (!hideControls) {
                        timerRunning = true;
                        hideSeekControls();
                      }
                      print('screen tapped');
                    },
              child: VlcPlayer(
                controller: _controller,
                aspectRatio: _aspectRatio,
                virtualDisplay: true,
                placeholder: const Center(
                    child: CircularProgressIndicator(
                  color: Colors.blue,
                )),
              ),
            ),
          ),
          Visibility(
            visible: !hideControls,
            child: Align(
              alignment: Alignment.center,
              child: ControlsOverlay(controller: _controller),
            ),
          ),
          Visibility(
            visible: !hideControls,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      CustomIconButton(
                          hasFocus: btnFocusNodes['play_pause_btn_small']
                              ['isFocused'],
                          icon: _controller.value.isPlaying
                              ? const Icon(Icons.pause_circle_outline)
                              : const Icon(Icons.play_circle_outline),
                          onTap: _togglePlaying),
                      // Container(
                      //   width: 40,
                      //   height: 40,
                      //   decoration: BoxDecoration(
                      //     shape: BoxShape.circle,
                      //     color: Colors.white.withOpacity(0.4),
                      //   ),
                      //   child: IconButton(
                      //     color: Colors.white,
                      //     icon: _controller.value.isPlaying
                      //         ? const Icon(Icons.pause_circle_outline)
                      //         : const Icon(Icons.play_circle_outline),
                      //     onPressed: ,
                      //     focusNode: ,
                      //     autofocus: true,
                      //   ),
                      // ),

                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              position,
                              style: const TextStyle(color: Colors.white),
                            ),
                            Expanded(
                              child: Container(
                                // width: 20,
                                height: 20,
                                margin: btnFocusNodes['seek_slider_btn']
                                        ['isFocused']
                                    ? EdgeInsets.symmetric(horizontal: 10.0)
                                    : null,
                                decoration: BoxDecoration(
                                  // shape: BoxShape.circle,
                                  borderRadius: BorderRadius.circular(35.0),
                                  color: btnFocusNodes['seek_slider_btn']
                                          ['isFocused']
                                      ? Colors.white.withOpacity(0.3)
                                      : Colors.transparent,
                                ),
                                child: Slider(
                                  // focusNode: btnFocusNodes['seek_slider_btn'],
                                  activeColor: Colors.blue,
                                  inactiveColor: Colors.white70,

                                  value: sliderValue,
                                  max: !validPosition
                                      ? 1.0
                                      : _controller.value.duration.inSeconds
                                          .toDouble(),
                                  onChanged: validPosition
                                      ? _onSliderPositionChanged
                                      : null,
                                ),
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
                  SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        Wrap(
                          children: [
                            Stack(
                              children: [
                                CustomIconButton(
                                    hasFocus: btnFocusNodes['subtitle_btn']![
                                            'isFocused'] ??
                                        false,
                                    icon: const Icon(
                                        CupertinoIcons.captions_bubble_fill),
                                    onTap: _getSubtitleTracks),
                                // IconButton(
                                //   focusNode: btnFocusNodes['subtitle_btn'],
                                //   tooltip: 'Get Subtitle Tracks',
                                //   icon: const Icon(
                                //       CupertinoIcons.captions_bubble_fill),
                                //   color: Colors.white,
                                //   onPressed: _getSubtitleTracks,
                                // ),
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
                                        '${widget.subtitlesList.isEmpty ? numberOfCaptions : widget.subtitlesList.length}',
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
                                CustomIconButton(
                                    hasFocus: btnFocusNodes['audio_track_btn']![
                                            'isFocused'] ??
                                        false,
                                    icon: const Icon(Icons.audiotrack_rounded),
                                    onTap: _getAudioTracks),
                                // IconButton(
                                //   focusNode: btnFocusNodes['audio_track_btn'],
                                //   tooltip: 'Get Audio Tracks',
                                //   icon: const Icon(Icons.audiotrack_rounded),
                                //   color: Colors.white,
                                //   onPressed: _getAudioTracks,
                                // ),
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
                                CustomIconButton(
                                    hasFocus: btnFocusNodes['speed_btn']![
                                            'isFocused'] ??
                                        false,
                                    icon: const Icon(Icons.speed),
                                    onTap: _cyclePlaybackSpeed),
                                // IconButton(
                                //   focusNode: btnFocusNodes['speed_btn'],
                                //   icon: const Icon(Icons.speed),
                                //   color: Colors.white,
                                //   onPressed: _cyclePlaybackSpeed,
                                // ),
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
                            CustomIconButton(
                                hasFocus: btnFocusNodes['minus_10_sec_btn']![
                                        'isFocused'] ??
                                    false,
                                icon: const Icon(Icons.replay_10),
                                onTap: () => _seekRelative(_seekStepBackward)),
                            // IconButton(
                            //   focusNode: btnFocusNodes['minus_10_sec_btn'],
                            //   onPressed: () => _seekRelative(_seekStepBackward),
                            //   color: Colors.white,
                            //   // iconSize: _seekButtonIconSize,
                            //   icon: const Icon(Icons.replay_10),
                            // ),
                            CustomIconButton(
                                hasFocus: btnFocusNodes['plus_10_sec_btn']![
                                        'isFocused'] ??
                                    false,
                                icon: const Icon(Icons.forward_10),
                                onTap: () => _seekRelative(_seekStepForward)),
                            // IconButton(
                            //   focusNode: btnFocusNodes['plus_10_sec_btn'],
                            //   onPressed: () => _seekRelative(_seekStepForward),
                            //   color: Colors.white,
                            //   // iconSize: _seekButtonIconSize,
                            //   icon: const Icon(Icons.forward_10),
                            // ),

                            // if (widget.currentVideoIndex > 0)
                            CustomIconButton(
                              hasFocus: btnFocusNodes['prev_episode_btn']![
                                      'isFocused'] ??
                                  false,
                              icon: const Icon(Icons.skip_previous),
                              onTap: widget.currentVideoIndex > 0
                                  ? widget.preparePreviousEpisode
                                  : null,
                            ),
                            // IconButton(
                            //   focusNode: btnFocusNodes['prev_episode_btn'],
                            //   icon: const Icon(
                            //       Icons.keyboard_double_arrow_left),
                            //   color: Colors.white,
                            //   onPressed: widget.preparePreviousEpisode,
                            // ),
                            // if ((widget.currentVideoIndex <
                            //         widget.episodesList.length - 1) &&
                            //     widget.episodesList.length > 1 &&
                            //     widget.episode != null)
                            CustomIconButton(
                              hasFocus: btnFocusNodes['next_episode_btn']![
                                      'isFocused'] ??
                                  false,
                              icon: const Icon(Icons.skip_next),
                              onTap: (widget.currentVideoIndex <
                                          widget.episodesList.length - 1) &&
                                      widget.episodesList.length > 1 &&
                                      widget.episode != null
                                  ? widget.prepareNextEpisode
                                  : null,
                            ),
                            // IconButton(
                            //   focusNode: btnFocusNodes['next_episode_btn'],
                            //   icon: const Icon(
                            //       Icons.keyboard_double_arrow_right),
                            //   color: Colors.white,
                            //   onPressed: widget.prepareNextEpisode,
                            // ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Text(
                            widget.videoTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                            style: TextStyle(
                              fontSize: 18.0,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Visibility(
                          visible: widget.showControls,
                          child: Container(
                            width: 200,
                            // color: _playerControlsBgColor,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 5.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              // mainAxisSize: MainAxisSize.min,
                              children: [
                                CustomIconButton(
                                  hasFocus: btnFocusNodes['volume_slider_btn']
                                      ['isFocused'],
                                  icon: const Icon(Icons.volume_up_rounded),
                                  onTap: () {},
                                ),
                                // const Icon(
                                //   Icons.volume_up_rounded,
                                //   color: Colors.white,
                                // ),
                                Expanded(
                                  child: Slider(
                                    // focusNode:
                                    //     btnFocusNodes['volume_slider_btn'],
                                    activeColor: Colors.blue,
                                    inactiveColor: Colors.white70,
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(listener);
    super.dispose();
  }

  Future<void> _seekRelative(Duration seekStep) {
    return _controller.seekTo(_controller.value.position + seekStep);
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
    if (widget.subtitlesList.isNotEmpty) {
      await loadSubtitles();
    }
    final subtitleTracks = await _controller.getSpuTracks();
    //

    if (subtitleTracks.isNotEmpty) {
      if (!mounted) return;

      setState(() {
        numberOfCaptions = subtitleTracks.length;
      });
      final selectedSubId = await showDialog<int>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Select Subtitle'),
            content: SizedBox(
              width: 150,
              height: 200,
              child: ListView.builder(
                itemCount: (widget.subtitlesList.isNotEmpty
                        ? widget.subtitlesList.length
                        : subtitleTracks.keys.length) +
                    1,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      index <
                              (widget.subtitlesList.isNotEmpty
                                  ? widget.subtitlesList.length
                                  : subtitleTracks.length)
                          ? widget.subtitlesList.isEmpty
                              ? subtitleTracks.values.elementAt(index)
                              : widget.subtitlesList[index].language
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

class CustomIconButton extends StatelessWidget {
  final bool hasFocus;
  final Icon icon;
  final Function()? onTap;
  const CustomIconButton(
      {super.key,
      required this.hasFocus,
      required this.icon,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: hasFocus ? Colors.white.withOpacity(0.3) : Colors.transparent,
      ),
      child: IconButton(
        color: Colors.white,
        icon: icon,
        onPressed: onTap,
      ),
    );
  }
}
