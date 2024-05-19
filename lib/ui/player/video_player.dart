// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_tv/model/channel.dart';
import 'package:flutter_app_tv/model/poster.dart';
import 'package:flutter_app_tv/model/season.dart';
import 'package:flutter_app_tv/model/source.dart';
import 'package:flutter_app_tv/model/subtitle.dart' as model;
import 'package:flutter_app_tv/ui/dialogs/sources_dialog.dart' as ui;
import 'package:flutter_app_tv/ui/dialogs/subscribe_dialog.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  AnimationController? _animated_controller;
  ItemScrollController _sourcesScrollController = ItemScrollController();

  bool _visibile_controllers = true;

  bool visibileSourcesDialog = false;

  Timer? _visibile_controllers_future;

  FocusNode video_player_focus_node = FocusNode();

  int _video_controller_settings_position = 2;
  bool visible_subscribe_dialog = false;

  List<model.Subtitle> _subtitlesList = [];

  int post_x = 0;
  int post_y = 0;

  bool isPlaying = true;

  SharedPreferences? prefs;

  bool? logged = false;
  String? subscribed = "FALSE";

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      widget.next = (widget.episode != null) ? true : false;
      widget.live = (widget.channel != null) ? true : false;
      FocusScope.of(context).requestFocus(video_player_focus_node);
      _prepareNext();
      _checkLogged();
    });

    initSettings();
    super.initState();
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
    final videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.sourcesList![index].url));
    await Future.wait(
        [videoPlayerController.initialize().then((value) => setState(() {}))]);
    chewieController = ChewieController(
      videoPlayerController: videoPlayerController,
      autoPlay: true,
      looping: true,
      autoInitialize: true,
      zoomAndPan: true,
      subtitle: Subtitles(_subtitlesList
          .map((e) => Subtitle(
              index: index,
              start: Duration.zero,
              end: const Duration(seconds: 10),
              text: e.url))
          .toList()),
      subtitleBuilder: (context, subtitle) => Container(
        padding: const EdgeInsets.all(10.0),
        child: Text(
          subtitle,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _visibile_controllers_future!.cancel();
    chewieController!.dispose();
    _animated_controller!.dispose();
    video_player_focus_node.dispose();
    chewieController!.pause();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        Center(
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: chewieController != null &&
                    chewieController!.videoPlayerController.value.isInitialized
                ? Chewie(
                    controller: chewieController!,
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
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
