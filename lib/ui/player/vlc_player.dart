import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_app_tv/api/api_rest.dart';
import 'package:flutter_app_tv/constants.dart';
import 'package:flutter_app_tv/model/channel.dart';
import 'package:flutter_app_tv/model/poster.dart';
import 'package:flutter_app_tv/model/season.dart';
import 'package:flutter_app_tv/model/source.dart';
import 'package:flutter_app_tv/model/subtitle.dart' as model;
import 'package:flutter_app_tv/ui/player/video_state_saver.dart';
import 'package:flutter_app_tv/ui/player/vlc_player_with_controls.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VlcPlayerPage extends StatefulWidget {
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
  AnimationController? _animated_controller;
  VlcPlayerPage({
    Key? key,
    this.sourcesList,
    this.selected_source,
    required this.focused_source,
    this.poster,
    this.episode,
    this.seasons,
    this.season,
    this.channel,
  }) : super(key: key);

  @override
  _VlcPlayerPageState createState() => _VlcPlayerPageState();
}

class _VlcPlayerPageState extends State<VlcPlayerPage>
    with SingleTickerProviderStateMixin {
  VlcPlayerController? _videoPlayerController;
  static const _networkCachingMs = 5000;
  // static const _subtitlesFontSize = 25;
  // static const _height = 400.0;
  List<model.Subtitle> _subtitlesList = [];
  // List<Subtitle> subtitlesData = [];
  List<String> subtitleUrls = [];
  bool? logged = false;
  String? subscribed = "FALSE";
  SharedPreferences? prefs;
  bool visible_subscribe_dialog = false;
  bool visibileSourcesDialog = false;
  AnimationController? _animated_controller;
  // Timer? _visibile_controllers_future;
  bool _visibile_controllers = true;
  final _key = GlobalKey<VlcPlayerWithControlsState>();
  int post_x = 0;
  int post_y = 0;
  int _video_controller_settings_position = 2;
  //subtitl prfs
  int? subtitleTextColorPref;
  int? subtitleBackgroundColorPref;
  int? subtitleSizePref;
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      widget.next = (widget.episode != null) ? true : false;
      widget.live = (widget.channel != null) ? true : false;
      // FocusScope.of(context).requestFocus(video_player_focus_node);
      loadSubtitlePrefs();
      _prepareNext();
      _getSubtitlesList();
      _checkLogged();
      initSettings();
    });
  }

  void loadSubtitlePrefs() async {
    subtitleTextColorPref = await getSubtitleValue("subtitle_color");
    subtitleBackgroundColorPref = await getSubtitleValue("subtitle_background");
    subtitleSizePref = await getSubtitleValue('subtitle_size');
    setState(() {});
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

  void _checkLogged() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    this.logged = prefs.getBool("LOGGED_USER");
    this.subscribed = prefs.getString("NEW_SUBSCRIBE_ENABLED");
  }

  void _setupDataSource(int index) async {
    int? savedPosition = await VideoStateSaver.getVideoState(
        key: widget.sourcesList![index].url);
    // print(
    //     'savedPosition: $savedPosition url: ${widget.sourcesList![index].url}');
    _videoPlayerController = VlcPlayerController.network(
      widget.sourcesList![index].url,
      hwAcc: HwAcc.auto,
      startAt: Duration(milliseconds: savedPosition ?? 0),
      options: VlcPlayerOptions(
          advanced: VlcAdvancedOptions([
            VlcAdvancedOptions.networkCaching(_networkCachingMs),
          ]),
          subtitle: VlcSubtitleOptions([
            VlcSubtitleOptions.boldStyle(true),
            VlcSubtitleOptions.fontSize(subtitleSizePref ?? 30),
            VlcSubtitleOptions.font('TTF'),
            VlcSubtitleOptions.backgroundOpacity(150),
            VlcSubtitleOptions.backgroundColor(subtitleBackgroundColorPref ==
                    null
                ? VlcSubtitleColor.black
                : VlcSubtitleColor.rgb(
                    red: subtitleBackgroundColors[subtitleBackgroundColorPref!]
                        .red,
                    green:
                        subtitleBackgroundColors[subtitleBackgroundColorPref!]
                            .green,
                    blue: subtitleBackgroundColors[subtitleBackgroundColorPref!]
                        .blue,
                  )),
            VlcSubtitleOptions.color(subtitleTextColorPref == null
                ? VlcSubtitleColor.white
                : VlcSubtitleColor.rgb(
                    red: subtitleTextColors[subtitleTextColorPref!].red,
                    green: subtitleTextColors[subtitleTextColorPref!].green,
                    blue: subtitleTextColors[subtitleTextColorPref!].blue,
                  )),
          ]),
          http: VlcHttpOptions([
            VlcHttpOptions.httpReconnect(true),
          ]),
          rtp: VlcRtpOptions([
            VlcRtpOptions.rtpOverRtsp(true),
          ]),
          sout: VlcStreamOutputOptions(
              [VlcStreamOutputOptions.soutMuxCaching(3500)]),
          video: VlcVideoOptions([
            VlcVideoOptions.dropLateFrames(false),
            VlcVideoOptions.skipFrames(false),
          ])),
      autoPlay: true,
      autoInitialize: true,
      allowBackgroundPlayback: false,
    );
    // await Future.wait([
    //   _videoPlayerController!.initialize().then((value) => setState(() {}))
    // ]);

    _videoPlayerController!.addOnInitListener(() async {
      await _videoPlayerController!.startRendererScanning();
    });
    // _videoPlayerController!.addListener(() {

    // });
    _videoPlayerController!.addOnRendererEventListener((type, id, name) {
      debugPrint('OnRendererEventListener $type $id $name');
    });
  }

  void _getSubtitlesList() async {
    if (widget.channel != null) return;
    _subtitlesList.clear();
    setState(() {});
    // model.Subtitle? subtitle =
    //     new model.Subtitle(id: -1, type: "", language: "", url: "", image: "");
    // _subtitlesList.add(subtitle);
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
            // print(subtitle["url"]);
            // subtitleUrls.add(subtitle["url"]);
            print(
                'url length: ' + subtitle["url"].toString().length.toString());
            if (subtitle["language"].toString().isNotEmpty) {
              model.Subtitle _subtitle = model.Subtitle(
                  id: subtitle["id"],
                  type: subtitle["type"],
                  url: subtitle["url"],
                  image: language["image"],
                  language:
                      language["language"] + " (" + (count).toString() + ")");

              _subtitlesList.add(_subtitle);
            }

            count++;
          }
          // subtitleController = SubtitleController(
          //   subtitleUrl: subtitleUrls.first,
          //   subtitleType: SubtitleType.webvtt,
          //   showSubtitles: showSubtitles,
          // );
          // subtitlesData = await fetchSubtitles(subtitleUrls);
          // print(subtitlesData);
        }

        print('subtitles list1: ${_subtitlesList.first.toJson()}');
        print('subtitles list2: ${_subtitlesList.last.toJson()}');
      }
    }
    setState(() {});
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

  @override
  void dispose() async {
    super.dispose();
    await _videoPlayerController!.stopRendererScanning();
    await _videoPlayerController!.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        body: _videoPlayerController == null ||
                _videoPlayerController!.value.isBuffering
            ? Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : VlcPlayerWithControls(
                key: _key,
                prepareNextEpisode: _prepareNext,
                subtitlesList: _subtitlesList,
                showControls: true,
                controller: _videoPlayerController!,
                onStopRecording: (recordPath) {
                  // setState(() {
                  //   listVideos.add(
                  //     VideoData(
                  //       name: 'Recorded Video',
                  //       path: recordPath,
                  //       type: VideoType.recorded,
                  //     ),
                  //   );
                  // });
                  // ScaffoldMessenger.of(context).showSnackBar(
                  //   const SnackBar(
                  //     content: Text(
                  //       'The recorded video file has been added to the end of list.',
                  //     ),
                  //   ),
                  // );
                },
              ));
  }
}
