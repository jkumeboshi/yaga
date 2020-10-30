import 'package:yaga/model/category_view_config.dart';
import 'package:yaga/services/isolateable/system_location_service.dart';
import 'package:yaga/utils/service_locator.dart';
import 'package:yaga/views/screens/yaga_home_screen.dart';
import 'package:yaga/views/screens/category_view_screen.dart';

class HomeView extends CategoryViewScreen {
  static final String pref = "category";

  HomeView()
      : super(CategoryViewConfig(
            defaultPath: getIt.get<SystemLocationService>().externalAppDirUri,
            pref: pref,
            pathEnabled: true,
            hasDrawer: true,
            selectedTab: YagaHomeTab.grid,
            title: "Nextcloud Yaga"));
}
