import 'package:flutter/material.dart';
import 'package:yaga/managers/nextcloud_manager.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/route_args/directory_navigation_screen_arguments.dart';
import 'package:yaga/model/route_args/image_screen_arguments.dart';
import 'package:yaga/services/isolateable/nextcloud_service.dart';
import 'package:yaga/services/isolateable/system_location_service.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/views/screens/directory_navigation_screen.dart';
import 'package:yaga/views/screens/image_screen.dart';
import 'package:yaga/views/widgets/avatar_widget.dart';

class BrowseTab extends StatelessWidget {

  Widget bottomNavBar;
  Widget drawer;

  BrowseTab({@required this.bottomNavBar, @required this.drawer});

  void _navigateToBrowseView(BuildContext context, Uri origin) {
    Navigator.pushNamed(
      context, 
      DirectoryNavigationScreen.route, 
      arguments: DirectoryNavigationScreenArguments(
        title: "Browse",
        uri: origin,
        onFileTap: (List<NcFile> files, int index) => Navigator.pushNamed(
          context, 
          ImageScreen.route, 
          arguments: ImageScreenArguments(files, index)
        ),
        bottomBarBuilder: (context, uri) => bottomNavBar
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text("Nextcloud Yaga"),
      ),
      drawer: drawer,
      body: StreamBuilder(
        stream: getIt.get<NextCloudManager>().updateLoginStateCommand,
        builder: (context, snapshot) {
          List<ListTile> children = [];

          children.add(
            ListTile(
              leading: Icon(Icons.phone_android,),
              title: Text("Internal Memory"),
              onTap: () => _navigateToBrowseView(context, getIt.get<SystemLocationService>().getOrigin()),
            )
          );
          
          if(getIt.get<NextCloudService>().isLoggedIn()) {
            Uri origin = getIt.get<NextCloudService>().getOrigin();
            children.add(
              ListTile(
                leading: AvatarWidget.command(getIt.get<NextCloudManager>().updateAvatarCommand, radius: 12,),
                title: Text(origin.authority),
                onTap: () => _navigateToBrowseView(context, origin),
              )
            );
          }

          return ListView(children: children,);
        }
      ),
      bottomNavigationBar: bottomNavBar,
    );
  }

}