import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class EmbedPlayer extends StatefulWidget {
  final String url;
  const EmbedPlayer({super.key, required this.url});

  @override
  State<EmbedPlayer> createState() => _EmbedPlayerState();
}

class _EmbedPlayerState extends State<EmbedPlayer> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    // #docregion webview_controller
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          // onHttpError: (HttpResponseError error) {},

          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            if (request.url != widget.url) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
            // return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));

    // #enddocregion webview_controller
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: Platform.isIOS ? AppBar(
        backgroundColor: Colors.black,
        leading: InkWell(onTap: (){
        Navigator.pop(context);
      },child: Icon(
        Icons.arrow_back_ios, color: Colors.white,size: 25.0,
      ),),) : null,
      body: WebViewWidget(
        controller: _controller,
      ),
    );
  }
}
