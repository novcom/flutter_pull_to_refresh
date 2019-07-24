/*
    Author: Jpeng
    Email: peng8350@gmail.com
    createTime: 2019-07-20 22:15
 */

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:flutter/material.dart';
import 'dataSource.dart';
import 'test_indicator.dart';

void main() {
  testWidgets("test child attribute ", (tester) async {
    final RefreshController _refreshController = RefreshController();
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: SmartRefresher(
        header: TestHeader(),
        footer: TestFooter(),
        enablePullUp: true,
        enablePullDown: true,
        child: null,
        controller: _refreshController,
      ),
    ));
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: SmartRefresher(
        header: TestHeader(),
        footer: TestFooter(),
        enablePullUp: true,
        enablePullDown: true,
        child: ListView.builder(
          itemBuilder: (c, i) => Card(),
          itemExtent: 100.0,
          itemCount: 20,
        ),
        controller: _refreshController,
      ),
    ));
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: SmartRefresher(
        header: TestHeader(),
        footer: TestFooter(),
        enablePullUp: true,
        enablePullDown: true,
        child: CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Text("asd"),
            ),
            SliverToBoxAdapter(
              child: Text("asd"),
            ),
            SliverToBoxAdapter(
              child: Text("asd"),
            ),
            SliverToBoxAdapter(
              child: Text("asd"),
            )
          ],
        ),
        controller: _refreshController,
      ),
    ));

    //test scrollController
    final List<String> log = [];
    final ScrollController scrollController = ScrollController()
      ..addListener(() {
        log.add("");
      });
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: SmartRefresher(
        header: TestHeader(),
        footer: TestFooter(),
        enablePullUp: true,
        enablePullDown: true,
        child: ListView.builder(
          itemBuilder: (c, i) => Card(),
          itemExtent: 100.0,
          itemCount: 20,
          controller: scrollController,
        ),
        controller: _refreshController,
      ),
    ));
    await tester.drag(find.byType(Scrollable), const Offset(0.0, -100.0));
    await tester.pumpAndSettle();
    expect(log.length, greaterThanOrEqualTo(1));
  });

  testWidgets("param check ", (tester) async {
    final RefreshController _refreshController = RefreshController();
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: SmartRefresher(
        header: TestHeader(),
        footer: TestFooter(),
        enablePullUp: true,
        enablePullDown: true,
        child: ListView.builder(
          itemBuilder: (c, i) => Center(
            child: Text(data[i]),
          ),
          itemCount: 20,
          itemExtent: 100,
        ),
        controller: _refreshController,
      ),
    ));
    RenderViewport viewport = tester.renderObject(find.byType(Viewport));
    expect(viewport.childCount, 3);

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: SmartRefresher(
        header: TestHeader(),
        footer: TestFooter(),
        enablePullUp: true,
        enablePullDown: false,
        child: ListView.builder(
          itemBuilder: (c, i) => Center(
            child: Text(data[i]),
          ),
          itemCount: 20,
          itemExtent: 100,
        ),
        controller: _refreshController,
      ),
    ));
    viewport = tester.renderObject(find.byType(Viewport));
    expect(viewport.childCount, 2);
    expect(viewport.firstChild.runtimeType, RenderSliverFixedExtentList);
    final List<dynamic> logs = [];
    // check enablePullDown,enablePullUp
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: SmartRefresher(
        header: TestHeader(),
        footer: TestFooter(),
        enablePullDown: true,
        enablePullUp: true,
        child: ListView.builder(
          itemBuilder: (c, i) => Center(
            child: Text(data[i]),
          ),
          itemCount: 20,
          itemExtent: 100,
        ),
        onRefresh: () {
          logs.add("refresh");
        },
        onLoading: () {
          logs.add("loading");
        },
        controller: _refreshController,
      ),
    ));

    // check onRefresh,onLoading
    await tester.drag(find.byType(Scrollable), Offset(0, 100.0),
        touchSlopY: 0.0);
    await tester.pump(Duration(milliseconds: 20));
    await tester.pump(Duration(milliseconds: 20));
    expect(logs.length, 1);
    expect(logs[0], "refresh");
    logs.clear();
    _refreshController.refreshCompleted();
    await tester.pumpAndSettle(Duration(milliseconds: 600));

    await tester.drag(find.byType(Scrollable), Offset(0, -4000.0),
        touchSlopY: 0.0);
    await tester.pump(Duration(milliseconds: 20)); //canRefresh
    await tester.pump(Duration(milliseconds: 20)); //refreshing
    expect(logs.length, 1);
    expect(logs[0], "loading");
    logs.clear();
    _refreshController.loadComplete();

    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: SmartRefresher(
        header: TestHeader(),
        footer: TestFooter(),
        enablePullDown: true,
        enablePullUp: true,
        child: ListView.builder(
          itemBuilder: (c, i) => Center(
            child: Text(data[i]),
          ),
          itemCount: 20,
          itemExtent: 100,
        ),
        onOffsetChange: (up, offset) {
          logs.add(offset);
        },
        controller: _refreshController,
      ),
    ));

    // check onOffsetChange(top)
    _refreshController.position.jumpTo(0.0);
    double count = 1;
    while (count < 11) {
      await tester.drag(find.byType(Scrollable), Offset(0, 20),
          touchSlopY: 0.0);
      count++;
      await tester.pump(Duration(milliseconds: 20));
    }
    for (double i in logs) {
      expect(i, greaterThanOrEqualTo(0));
    }
    logs.clear();
    // check onOffsetChange
    _refreshController.position
        .jumpTo(_refreshController.position.maxScrollExtent);
    count = 1;
    while (count < 11) {
      await tester.drag(find.byType(Scrollable), Offset(0, -20),
          touchSlopY: 0.0);
      count++;
      await tester.pump(Duration(milliseconds: 20));
    }
    expect(logs.length, greaterThan(0));
    for (double i in logs) {
      expect(i, greaterThanOrEqualTo(0));
    }
    logs.clear();
    await tester.pump(Duration(milliseconds: 20));
  });


  testWidgets(" verity smartRefresher and NestedScrollView", (tester) async {
    final RefreshController _refreshController = RefreshController();
    int time = 0;
    await tester.pumpWidget(MaterialApp(
      home: SmartRefresher(
        header: TestHeader(),
        footer: TestFooter(),
        enablePullDown: true,
        enablePullUp: true,
        child: ListView.builder(
          itemBuilder: (c, i) => Center(
            child: Text(data[i]),
          ),
          itemCount: 20,
          itemExtent: 100,
        ),
        onRefresh: ()  async{
          time++;
        },
        onLoading: () async{
          time++;
        },
        controller: _refreshController,
      ),
    ));

    // test pull down
    await tester.drag(find.byType(Viewport), const Offset(0,120));
    await tester.pump();
    expect(_refreshController.headerStatus,RefreshStatus.canRefresh);
    await tester.pumpAndSettle();
    expect(_refreshController.headerStatus,RefreshStatus.refreshing);
    _refreshController.refreshCompleted();
    await tester.pumpAndSettle(Duration(milliseconds: 800));


    // test flip up
    await tester.fling(find.byType(Viewport), const Offset(0,-1000),3000);
    await tester.pumpAndSettle();
    expect(_refreshController.footerStatus,LoadStatus.loading);
    _refreshController.footerMode.value = LoadStatus.idle;
    await tester.pumpAndSettle();
    // test drag up
    _refreshController.position.jumpTo(_refreshController.position.maxScrollExtent);
    await tester.drag(find.byType(Viewport), const Offset(0,-100));
    await tester.pumpAndSettle();
    expect( _refreshController.position.extentAfter, 0.0);
    _refreshController.loadComplete();
    expect(time,3);
  });

  testWidgets("fronStyle can hittest content when springback", (tester) async {
    final RefreshController _refreshController = RefreshController();
    int time = 0;
    await tester.pumpWidget(MaterialApp(
      home: SmartRefresher(
        header: CustomHeader(
          builder: (c,m) => Container(),
          height: 60.0,
        ),
        footer: TestFooter(),
        enablePullDown: true,
        enablePullUp: true,
        child: GestureDetector(
          child: Container(
            height: 60.0,
            width: 60.0,
            color: Colors.transparent,
          ),
          onTap: (){
            time++;
          },
        )
        ,
        onRefresh: ()  async{
          time++;
        },
        onLoading: () async{
          time++;
        },
        controller: _refreshController,
      ),
    ));

    // test pull down
    await tester.drag(find.byType(Viewport), const Offset(0,120));
    await tester.pump();
    expect(_refreshController.headerStatus,RefreshStatus.canRefresh);
    await tester.pump(Duration(milliseconds: 2));
    expect(_refreshController.headerStatus,RefreshStatus.refreshing);
    expect(_refreshController.position.pixels,lessThan(0.0));
    await tester.tapAt(Offset(30,30));
    expect(time,1);
  });
}