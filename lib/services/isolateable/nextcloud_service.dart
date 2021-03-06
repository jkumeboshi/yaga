import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';
import 'package:nextcloud/nextcloud.dart';
import 'package:yaga/model/nc_file.dart';
import 'package:yaga/model/nc_login_data.dart';
import 'package:yaga/model/nc_origin.dart';
import 'package:yaga/services/file_provider_service.dart';
import 'package:yaga/services/service.dart';
import 'package:yaga/utils/forground_worker/isolateable.dart';
import 'package:yaga/utils/forground_worker/messages/init_msg.dart';
import 'package:yaga/utils/logger.dart';
import 'package:yaga/utils/nextcloud_client_factory.dart';
import 'package:yaga/utils/uri_utils.dart';

class NextCloudService
    with Service<NextCloudService>, Isolateable<NextCloudService>
    implements FileProviderService<NextCloudService> {
  final Logger _logger = getLogger(NextCloudService);

  //todo: it will probably be best to replace nc with https since it does not bring any actual advantage
  // --> however this is a breaking change
  final String scheme = "nc";
  NcOrigin _origin;
  NextCloudClient _client;
  NextCloudClientFactory nextCloudClientFactory;

  NextCloudService(this.nextCloudClientFactory);

  Future<NextCloudService> initIsolated(
    InitMsg init,
    SendPort isolateToMain,
  ) async {
    if (init.lastLoginData.server != null) {
      await this.login(init.lastLoginData);
    }
    return this;
  }

  Future<NcOrigin> login(NextCloudLoginData loginData) async {
    //todo: can we get rid of the client factory?
    this._client = this.nextCloudClientFactory.createNextCloudClient(
          loginData.server,
          loginData.user,
          loginData.password,
        );

    UserData userData;

    if (loginData.id == "" || loginData.displayName == "") {
      userData = await this._client.user.getUser();
    }

    this._origin = NcOrigin(
      UriUtils.fromUri(uri: loginData.server, scheme: this.scheme),
      userData?.id ?? loginData.id,
      userData?.displayName ?? loginData.displayName,
      loginData.user,
    );

    return this._origin;
  }

  void logout() {
    this._client = null;
  }

  bool isLoggedIn() => _client == null ? false : true;

  @override
  Stream<NcFile> list(Uri dir) {
    String basePath = "files/${origin.username}";
    return this
        ._client
        .webDav
        .ls(basePath + dir.path)
        .asStream()
        .flatMap((value) => Stream.fromIterable(value))
        .where(
            (event) => event.isDirectory || event.mimeType.startsWith("image"))
        .map((webDavFile) {
      //todo: removing _host.path is just a quick fix for a much bigger problem:
      // we cannot assume that the origin is depictable by url.host
      // furthermore for identifing the upstream of a file we actually need an origin-url + username
      // since, when adding multi user support in future, in theory you can have multiple users on the same cloud
      // to properly be able to identify the origin of a NcFile we need to split the information currently stored in the uri property in three:
      // file.origin: Uri
      // file.username: String
      // file.path: String/Uri (not sure yet)
      // file.origin + file.username can identify the NextCloudClient
      // file.path represents only the relative path of that file
      // --> however, we can not simply substitute the [NcFile.uri] field as long as the [MppingManager] has not been reworked
      // --> the [MappingManager] needs now to be able to map [NcLocations(NcOrigin+Path)] to each other and not simply Urls
      // --> this however requires a rather big refactoring of the [MappingManager] including persistance
      var path = webDavFile.path.replaceFirst(
        "${_origin.uri.path}/$basePath",
        "",
      );
      Uri uri = UriUtils.fromUri(uri: origin.userEncodedDomainRoot, path: path);

      NcFile file = NcFile(uri);
      file.isDirectory = webDavFile.isDirectory;
      file.lastModified = webDavFile.lastModified;
      file.name = webDavFile.name;
      return file;
    }).doOnError(
      (error, stacktrace) => _logger.e(
        "Unexpected error while loading list",
        error,
        stacktrace,
      ),
    ); //.toList --> should this return a Future<List> since the data is actually allready downloaded?
  }

  Future<Uint8List> getAvatar() => this
      ._client
      .avatar
      .getAvatar(origin.username, 100)
      .then((value) => base64.decode(value));

  Future<Uint8List> getPreview(Uri file) {
    String path = Uri.decodeComponent(file.path);
    _logger.d("Fetching preview $path");
    //todo: think about image sizes vs in code scaling
    return this._client.preview.getPreviewByPath(path, 128, 128);
    //todo: implement proper error handling
    // .catchError((err) {
    //   print("Could not load preview for $path");
    //   return err;
    // });
  }

  Future<Uint8List> downloadImage(Uri file) {
    String basePath =
        "files/${origin.username}"; //todo: add proper logging and check if download gets called on real device multiple times
    return this._client.webDav.download(basePath + file.path);
  }

  NcOrigin get origin => _origin;

  //todo: should we consider adding an [isLocal] property to NcOrigin?
  bool isUriOfService(Uri uri) => uri.scheme == this.scheme;

  Future<NcFile> deleteFile(NcFile file) {
    return this
        ._client
        .webDav
        .delete("files/${origin.username}" + file.uri.path)
        .then((_) => file);
  }
}
