// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:convert';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_tv/api/api_rest.dart';
import 'package:flutter_app_tv/constants.dart';
import 'package:flutter_app_tv/model/channel.dart';
import 'package:flutter_app_tv/model/poster.dart';
import 'package:flutter_app_tv/model/season.dart';
import 'package:flutter_app_tv/model/source.dart';
import 'package:flutter_app_tv/model/subtitle.dart' as model;
import 'package:flutter_app_tv/ui/dialogs/sources_dialog.dart' as ui;
import 'package:flutter_app_tv/ui/dialogs/subscribe_dialog.dart';
import 'package:flutter_app_tv/ui/player/video_state_saver.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:subtitle_wrapper_package/subtitle_wrapper_package.dart';
import 'package:video_player/video_player.dart';

/// An example of using the plugin, controlling lifecycle and playback of the
/// video.

class VideoPlayer extends StatefulWidget {
  List<Source>? sourcesList = [];
  List<Source>? sourcesListDialog = [];
  Poster? poster;
  Channel? channel;
  int? episode;
  int? season;

  int? next_episode;
  int? next_season;
  String? next_title = "";

  List<Season>? seasons = [];
  int? selected_source = 0;
  int focused_source = 0;
  bool? next = false;
  bool? live = false;
  bool? _play_next_episode = false;

  VideoPlayer(
      {this.sourcesList,
      this.selected_source,
      required this.focused_source,
      this.poster,
      this.episode,
      this.seasons,
      this.season,
      this.channel});

  @override
  _VideoPlayerState createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer>
    with SingleTickerProviderStateMixin {
  List<Color> _list_text_bg = [
    Colors.transparent,
    Colors.black,
    Colors.white,
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.orange,
    Colors.brown,
    Colors.purple,
    Colors.pink,
    Colors.teal
  ];
  List<Color> _list_text_color = [
    Colors.black,
    Colors.white,
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.orange,
    Colors.brown,
    Colors.purple,
    Colors.pink,
    Colors.teal
  ];
  ChewieController? chewieController;
  SubtitleController? subtitleController;
  AnimationController? _animated_controller;
  ItemScrollController _sourcesScrollController = ItemScrollController();

  bool _visibile_controllers = true;

  bool visibileSourcesDialog = false;

  Timer? _visibile_controllers_future;

  FocusNode video_player_focus_node = FocusNode();

  int _video_controller_settings_position = 2;
  bool visible_subscribe_dialog = false;

  List<model.Subtitle> _subtitlesList = [];
  // List<Subtitle> subtitlesData = [];
  List<String> subtitleUrls = [];
  int post_x = 0;
  int post_y = 0;
  bool showSubtitles = true;
  bool isPlaying = true;
  int? subtitleTextColorPref;
  int? subtitleBackgroundColorPref;
  int? subtitleSizePref;
  SharedPreferences? prefs;

  bool? logged = false;
  String? subscribed = "FALSE";

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      widget.next = (widget.episode != null) ? true : false;
      widget.live = (widget.channel != null) ? true : false;
      FocusScope.of(context).requestFocus(video_player_focus_node);
      loadSubtitlePrefs();
      _prepareNext();
      _getSubtitlesList();
      _checkLogged();
    });

    initSettings();
    super.initState();
  }

  void loadSubtitlePrefs() async {
    subtitleTextColorPref = await getSubtitleValue("subtitle_color");
    subtitleBackgroundColorPref = await getSubtitleValue("subtitle_background");
    subtitleSizePref = await getSubtitleValue('subtitle_size');
    setState(() {});
  }

  // Future<List<Subtitle>> fetchSubtitles(List<String> urls) async {
  //   List<Subtitle> subtitles = [];
  //   for (String url in urls) {
  //     final response = await http.get(Uri.parse(url));
  //     print(response.statusCode);
  //     print(response.body);
  //     if (response.statusCode == 200) {
  //       String vttContent = response.body;
  //       subtitles.addAll(parseVtt(vttContent));
  //     }
  //   }
  //   return subtitles;
  // }

  // List<Subtitle> parseVtt(String vttContent) {
  //   final subtitles = <Subtitle>[];
  //   final lines = vttContent.split('\n\n');

  //   for (final line in lines) {
  //     final cueLines = line.split('\n');

  //     // Parse cue identifier (if present)
  //     final cueId = cueLines.firstOrNull;

  //     // Parse timestamps
  //     final timestamps = cueLines[1];
  //     final startTimestamp = timestamps.split(' --> ')[0];
  //     final endTimestamp = timestamps.split(' --> ')[1];

  //     // Parse subtitle text
  //     final textContent = cueLines.skip(2).join('\n');

  //     // Parse styles (not implemented in this simplified parser)
  //     // ...

  //     // Create subtitle object
  //     final subtitle = Subtitle(
  //       index: 0,
  //       start: convertTimestampToDuration(startTimestamp),
  //       end: convertTimestampToDuration(endTimestamp),
  //       text: textContent,
  //     );

  //     // Add subtitle to list
  //     subtitles.add(subtitle);
  //   }

  //   return subtitles;
  // }

  // Duration convertTimestampToDuration(String timestamp) {
  //   final parts = timestamp.split(':');
  //   final hours = int.parse(parts[0]);
  //   final minutes = int.parse(parts[1]);
  //   final seconds = int.parse(parts[2]);
  //   final milliseconds = int.parse(parts[3]);

  //   return Duration(
  //       hours: hours,
  //       minutes: minutes,
  //       seconds: seconds,
  //       milliseconds: milliseconds);
  // }

  void _getSubtitlesList() async {
    if (widget.channel != null) return;
    _subtitlesList.clear();
    setState(() {});
    model.Subtitle? subtitle =
        new model.Subtitle(id: -1, type: "", language: "", url: "", image: "");
    _subtitlesList.add(subtitle);
    var response;

    if ((widget.episode == null))
      response = await apiRest.getSubtitlesByMovie(widget.poster!.id);
    else
      response = await apiRest.getSubtitlesByEpisode(
          widget.seasons![widget.season!].episodes[widget.episode!].id);

    if (response != null) {
      print('languageb: ${response.body}');
      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        for (Map language in jsonData) {
          // print('language: $language');
          int count = 1;
          for (Map subtitle in language["subtitles"]) {
            print(subtitle["url"]);
            subtitleUrls.add(subtitle["url"]);
            model.Subtitle _subtitle = model.Subtitle(
                id: subtitle["id"],
                type: subtitle["type"],
                url: subtitle["url"],
                image: language["image"],
                language:
                    language["language"] + " (" + (count).toString() + ")");
            _subtitlesList.add(_subtitle);
            count++;
          }
          subtitleController = SubtitleController(
            subtitleUrl: subtitleUrls.first,
            subtitleType: SubtitleType.webvtt,
            showSubtitles: showSubtitles,
          );
          // subtitlesData = await fetchSubtitles(subtitleUrls);
          // print(subtitlesData);
        }
      }
    }
    setState(() {});
  }

  void _checkLogged() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    this.logged = prefs.getBool("LOGGED_USER");
    this.subscribed = prefs.getString("NEW_SUBSCRIBE_ENABLED");
  }

  void _prepareNext() {
    if (widget.episode != null) {
      if ((widget.episode! + 1) <
          widget.seasons![widget.season!].episodes.length) {
        widget.next_episode = widget.episode! + 1;
        widget.next_season = widget.season!;
        widget.next = true;
        widget.next_title = widget.seasons![widget.next_season!].title +
            " : " +
            widget.seasons![widget.next_season!].episodes[widget.next_episode!]
                .title;
      } else {
        if ((widget.season! + 1) < widget.seasons!.length) {
          if (widget.seasons![widget.season! + 1].episodes.length > 0) {
            widget.next_episode = 0;
            widget.next_season = widget.season! + 1;
            widget.next = true;
            widget.next_title = widget.seasons![widget.next_season!].title +
                " : " +
                widget.seasons![widget.next_season!]
                    .episodes[widget.next_episode!].title;
          } else {
            widget.next = false;
          }
        } else {
          widget.next = false;
        }
      }
      setState(() {});
    }
  }

  void _setupDataSource(int index) async {
    print('movie url: ${widget.sourcesList![index].url}');
    final videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.sourcesList![index].url),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
          allowBackgroundPlayback: false,
        ));
    int? savedPosition = await VideoStateSaver.getVideoState(
        key: widget.sourcesList![index].url);
    await Future.wait(
        [videoPlayerController.initialize().then((value) => setState(() {}))]);
    chewieController = ChewieController(
      videoPlayerController: videoPlayerController,
      autoPlay: true,

      looping: true,
      autoInitialize: true,
      zoomAndPan: true,
      errorBuilder: (context, errorMessage) {
        return Icon(Icons.close);
      },
      // subtitle: Subtitles(_subtitlesList
      //     .map((e) => Subtitle(
      //         index: index,
      //         start: Duration.zero,
      //         end: const Duration(seconds: 10),
      //         text: e.url))
      //     .toList()),
      // subtitle: Subtitles(subtitlesData),
      // subtitleBuilder: (context, subtitle) => Container(
      //   padding: const EdgeInsets.all(10.0),
      //   child: Text(
      //     subtitle,
      //     style: const TextStyle(color: Colors.white),
      //   ),
      // ),
      allowMuting: true,
      draggableProgressBar: true,
      showControls: true,
      showOptions: true,
      showControlsOnInitialize: true,
      allowPlaybackSpeedChanging: true,

      additionalOptions: (context) {
        return subtitleController == null
            ? []
            : [
                OptionItem(
                    onTap: () {
                      subtitleController!.isShowSubtitles =
                          !subtitleController!.showSubtitles;
                      setState(() {});
                      Navigator.pop(context);
                    },
                    iconData: Icons.subtitles,
                    title: 'Subtitles',
                    subtitle: !subtitleController!.isShowSubtitles
                        ? 'Turn On'
                        : 'Turn Off'),
              ];
      },
      // subtitleBuilder: (context, subtitle) {
      //   print('subtitle: $subtitle');
      //   return Container(
      //     padding: const EdgeInsets.all(10.0),
      //     child: Text(
      //       subtitle,
      //       style: const TextStyle(color: Colors.black),
      //     ),
      //   );
      // },
    );
    if (savedPosition != null) {
      chewieController!.seekTo(Duration(milliseconds: savedPosition));
    }
    chewieController!.videoPlayerController.addListener(() {
      // print('listning');
      // print(chewieController!
      //     .videoPlayerController.value.position.inMilliseconds);
      VideoStateSaver.saveVideoState(
          chewieController!.videoPlayerController.value.position.inMilliseconds,
          widget.sourcesList![index].url);
    });
  }

  // @override
  // void dispose() {
  //   super.dispose();
  //   _visibile_controllers_future!.cancel();
  //   chewieController!.videoPlayerController.removeListener(() {});
  //   chewieController!.videoPlayerController.dispose();
  //   chewieController!.dispose();
  //   _animated_controller!.dispose();
  //   video_player_focus_node.dispose();
  //   chewieController!.pause();
  // }

  void _handleDpadPress(KeyEvent event) async {
    if (event is KeyDownEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowLeft:
          // Handle left press (e.g., rewind)
          chewieController!.seekTo(
              chewieController!.videoPlayerController.value.position -
                  Duration(seconds: 5));
          break;
        case LogicalKeyboardKey.arrowRight:
          // Handle right press (e.g., fast-forward)
          chewieController!.seekTo(
              chewieController!.videoPlayerController.value.position +
                  Duration(seconds: 5));
          break;
        case LogicalKeyboardKey.arrowUp:
          chewieController!.videoPlayerController.value.volume;
          chewieController!.setVolume(
              chewieController!.videoPlayerController.value.volume +
                  0.1); // Adjust increment as needed
          break;
        case LogicalKeyboardKey.arrowDown:
          // Handle down press (e.g., volume down)

          chewieController!.setVolume(
              chewieController!.videoPlayerController.value.volume -
                  0.1); // Adjust decrement as needed
          break;
        case LogicalKeyboardKey.select:
          // Handle select/enter press (e.g., play/pause)
          if (chewieController!.videoPlayerController.value.isBuffering) {}
          if (chewieController!.isPlaying) {
            chewieController!.pause();
          } else {
            chewieController!.play();
          }
          break;
        case LogicalKeyboardKey.subtitle:
          subtitleController!.isShowSubtitles =
              !subtitleController!.showSubtitles;
          setState(() {});
          break;
        // Add other D-pad key handling as needed
        default:
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        print('pop invoked: $didPop');

        await chewieController!.pause();

        await chewieController!.videoPlayerController.pause();
        _visibile_controllers_future!.cancel();
        chewieController!.videoPlayerController.removeListener(() {});

        await chewieController!.videoPlayerController.dispose();
        chewieController!.dispose();
        _animated_controller!.dispose();
        video_player_focus_node.dispose();
        Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: KeyboardListener(
          focusNode: video_player_focus_node,
          onKeyEvent: (vnt) {
            _handleDpadPress(vnt);
          },
          // autofocus: true,
          child: Stack(children: [
            Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: chewieController != null &&
                        chewieController!
                            .videoPlayerController.value.isInitialized
                    ? subtitleController == null
                        ? Chewie(
                            controller: chewieController!,
                          )
                        : SubtitleWrapper(
                            videoPlayerController:
                                chewieController!.videoPlayerController,
                            subtitleController: subtitleController!,
                            backgroundColor: subtitleBackgroundColorPref == null
                                ? Colors.transparent
                                : subtitleBackgroundColors[
                                    subtitleBackgroundColorPref!],
                            subtitleStyle: SubtitleStyle(
                              textColor: subtitleTextColorPref == null
                                  ? Colors.white
                                  : subtitleTextColors[subtitleTextColorPref!],
                              fontSize: subtitleSizePref == null
                                  ? 22
                                  : subtitleSizePref!.toDouble(),
                              hasBorder: true,
                            ),
                            videoChild: Chewie(
                              controller: chewieController!,
                            ),
                          )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children:
                            // (chewieController == null &&
                            //         chewieController!
                            //             .videoPlayerController.value.hasError)
                            //     ? [
                            //         InkWell(
                            //             onTap: () {
                            //               if (mounted) {
                            //                 Navigator.of(context).pop();
                            //               }
                            //             },
                            //             child: Icon(
                            //               Icons.close,
                            //               color: Colors.white,
                            //               size: 30,
                            //             )),
                            //         Text("Error Occured")
                            //       ]
                            //     :
                            [
                          CircularProgressIndicator.adaptive(),
                          Text("Loading, please wait...")
                        ],
                      ),
              ),
            ),
            ui.SourcesDialog(
                sourcesList: widget.sourcesListDialog!,
                selected_source: widget.selected_source!,
                focused_source: widget.focused_source,
                sourcesScrollController: _sourcesScrollController,
                visibileSourcesDialog: visibileSourcesDialog,
                close: closeSourceDialog,
                select: selectSource),
            SubscribeDialog(
                visible: visible_subscribe_dialog,
                close: () {
                  setState(() {
                    visible_subscribe_dialog = false;
                  });
                }),
          ]),
        ),
      ),
    );
  }

  void selectSource(int selected_source_pick) {
    setState(() {
      widget.focused_source = selected_source_pick;
      _applySource();
    });
  }

  void closeSourceDialog() {
    setState(() {
      visibileSourcesDialog = false;
    });
  }

  void SourcesButton() {
    setState(() {
      post_y = _video_controller_settings_position;
      post_x = 1;
    });
    Future.delayed(Duration(milliseconds: 200), () {
      _showSourcesDialog();
    });
  }

  void _showSourcesDialog() {
    if (post_y == _video_controller_settings_position && post_x == 1) {
      widget.sourcesListDialog = widget.sourcesList;
      setState(() {
        visibileSourcesDialog = true;
      });
    }
  }

  void _hideSourcesDialog() {
    setState(() {
      visibileSourcesDialog = false;
    });
  }

  void _hideControllersDialog() {
    setState(() {
      _visibile_controllers = false;
    });
  }

  void _applySource() {
    if (widget._play_next_episode! == true) {
    } else {
      visibileSourcesDialog = false;
      _visibile_controllers = false;
      widget.selected_source = widget.focused_source;

      if (widget.sourcesListDialog![widget.selected_source!].premium == "2" ||
          widget.sourcesListDialog![widget.selected_source!].premium == "3") {
        if (subscribed == "TRUE") {
          _setupDataSource(widget.selected_source!);
        } else {
          setState(() {
            visible_subscribe_dialog = true;
          });
        }
      } else {
        _setupDataSource(widget.selected_source!);
      }
    }
  }

  void initSettings() async {
    _animated_controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 450));
    _animated_controller!.forward();

    prefs = await SharedPreferences.getInstance();

    _setupDataSource(widget.selected_source!);
  }
}
