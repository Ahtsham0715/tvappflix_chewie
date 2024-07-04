import 'package:flutter/material.dart';
import 'package:flutter_app_tv/constants.dart';
import 'package:flutter_app_tv/model/genre.dart';
import 'package:flutter_app_tv/model/poster.dart';
import 'package:flutter_app_tv/ui/movie/movie.dart';
import 'package:flutter_app_tv/ui/serie/serie.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class MovieShortDetailMiniWidget extends StatefulWidget {
  Poster? movie;
  String genres = "";

  MovieShortDetailMiniWidget({this.movie}) {
    for (Genre g in movie!.genres) {
      genres = genres + " • " + g.title;
    }
  }

  @override
  State<MovieShortDetailMiniWidget> createState() =>
      _MovieShortDetailMiniWidgetState();
}

class _MovieShortDetailMiniWidgetState
    extends State<MovieShortDetailMiniWidget> {
  bool isMobile = true;
  @override
  void initState() {
    super.initState();
    context.isMobile.then((value) => isMobile = value);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      margin: EdgeInsets.only(
          left: context.isPortrait ? 15 : 50,
          right: context.isPortrait ? 0 : 50),
      child: Stack(
        children: [
          Container(
            height: isMobile && context.isLandscape ? 130 : 170,
            margin:
                EdgeInsets.only(right: MediaQuery.of(context).size.width / 5),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.movie!.title,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: isMobile && context.isLandscape ? 5 : 15),
                  Row(
                    children: [
                      Text(
                        widget.movie!.rating.toString() + " / 5",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800),
                      ),
                      RatingBar.builder(
                        initialRating: 3.5,
                        minRating: 1,
                        direction: Axis.horizontal,
                        allowHalfRating: true,
                        itemCount: 5,
                        itemSize: 15.0,
                        ignoreGestures: true,
                        unratedColor: Colors.amber.withOpacity(0.4),
                        itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                        itemBuilder: (context, _) => Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        onRatingUpdate: (rating) {
                          print(rating);
                        },
                      ),
                      SizedBox(width: 10),
                      Text(
                        "  •   " + widget.movie!.imdb.toString() + " / 10",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800),
                      ),
                      SizedBox(width: 5),
                      Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                        decoration: BoxDecoration(
                            color: Colors.orangeAccent,
                            borderRadius: BorderRadius.circular(5)),
                        child: Text(
                          "IMDb",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800),
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: isMobile && context.isLandscape ? 5 : 10),
                  Text(
                    "${widget.movie!.year} • ${widget.movie!.classification} • ${widget.movie!.duration} ${widget.genres}",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: isMobile && context.isLandscape ? 5 : 10),
                  Text(
                    widget.movie!.description,
                    style: TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                        height: 1.5,
                        fontWeight: FontWeight.normal),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () {
                if (widget.movie != null) {
                  Future.delayed(Duration(milliseconds: 50), () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation1, animation2) =>
                            (widget.movie!.type == "serie")
                                ? Serie(serie: widget.movie)
                                : Movie(movie: widget.movie),
                        transitionDuration: Duration(seconds: 0),
                      ),
                    );
                  });
                }
              },
              child: context.isPortrait
                  ? Container(
                      height: 50,
                      width: 50,
                      child: Center(
                          child: Icon(Icons.info_outline,
                              size: 20, color: Colors.white)),
                      decoration: BoxDecoration(
                          border: Border(
                              right:
                                  BorderSide(width: 1, color: Colors.black12))),
                    )
                  : Container(
                      child: Row(
                        children: [
                          Container(
                            height: 35,
                            width: 35,
                            child: Center(
                                child: Icon(Icons.info_outline,
                                    size: 20, color: Colors.white)),
                            decoration: BoxDecoration(
                                border: Border(
                                    right: BorderSide(
                                        width: 1, color: Colors.black12))),
                          ),
                          Expanded(
                              child: Center(
                                  child: Text(
                            "More details",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500),
                          )))
                        ],
                      ),
                      height: 35,
                      width: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: Colors.white30,
                      ),
                    ),
            ),
          )
        ],
      ),
    );
  }
}
