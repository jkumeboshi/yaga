import 'package:flutter/material.dart';
import 'package:share/share.dart';
import 'package:yaga/managers/widget_local/file_list_local_manager.dart';
import 'package:yaga/views/widgets/yaga_popup_menu_button.dart';
import 'package:yaga/views/widgets/list_menu_entry.dart';

enum SelectionViewMenu { share, delete }

class SelectionPopupMenuButton extends StatelessWidget {
  final FileListLocalManager fileListLocalManager;

  SelectionPopupMenuButton({@required this.fileListLocalManager});

  @override
  Widget build(BuildContext context) {
    return YagaPopupMenuButton<SelectionViewMenu>(
      _buildSelectionPopupMenu,
      _popupMenuHandler,
    );
  }

  List<PopupMenuEntry<SelectionViewMenu>> _buildSelectionPopupMenu(
      BuildContext context) {
    return [
      PopupMenuItem(
        child: ListMenuEntry(Icons.share, "Share"),
        value: SelectionViewMenu.share,
      ),
      PopupMenuItem(
        child: ListMenuEntry(Icons.delete, "Delete"),
        value: SelectionViewMenu.delete,
      ),
    ];
  }

  void _popupMenuHandler(BuildContext context, SelectionViewMenu result) {
    if (result == SelectionViewMenu.share) {
      if (fileListLocalManager.selected
              .where((element) => !element.localFile.existsSync())
              .toList()
              .length >
          0) {
        Scaffold.of(context).showSnackBar(SnackBar(
          content:
              Text("Currently sharing supports only already downloaded files."),
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }

      Share.shareFiles(
          fileListLocalManager.selected.map((e) => e.localFile.path).toList());
      return;
    }

    if (result == SelectionViewMenu.delete) {
      showDialog(
        context: context,
        useRootNavigator: false,
        builder: (contextDialog) => this.fileListLocalManager.isRemoteUri
            ? _buildRemoteDialog(contextDialog, context)
            : _buildLocalDialog(contextDialog, context),
      );
    }
  }

  AlertDialog _buildRemoteDialog(
      BuildContext contextDialog, BuildContext parentContex) {
    return AlertDialog(
      title: const Text("Delete location"),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Text(
                "If you delete your images locally, they will be deleted from your phone only."),
            Text(
                "If you delete them remotely they will be deleted from your phone and server."),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text('Keep'),
          onPressed: () {
            Navigator.pop(contextDialog);
          },
        ),
        TextButton(
          child: Text('Delete locally'),
          onPressed: () {
            Navigator.pop(contextDialog);
            this._openDeletingDialog(parentContex);
          },
        ),
        TextButton(
          child: Text('Delete remotely'),
          style: TextButton.styleFrom(primary: Colors.red),
          onPressed: () {
            Navigator.pop(parentContex);
            this._openDeletingDialog(parentContex, local: false);
          },
        ),
      ],
    );
  }

  AlertDialog _buildLocalDialog(
      BuildContext contextDialog, BuildContext parentContex) {
    return AlertDialog(
      title: const Text("Deleting"),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Text(
                "This images seem to be local to your phone. Do you really want to delete them?"),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text('Keep'),
          onPressed: () {
            Navigator.pop(contextDialog);
          },
        ),
        TextButton(
          child: Text('Delete'),
          style: TextButton.styleFrom(primary: Colors.red),
          onPressed: () {
            Navigator.pop(contextDialog);
            this._openDeletingDialog(parentContex);
          },
        ),
      ],
    );
  }

  void _openDeletingDialog(BuildContext context, {bool local = true}) {
    bool dialogOpen = true;

    showDialog(
      context: context,
      useRootNavigator: false,
      builder: (context) => AlertDialog(
        title: const Text("Deleting..."),
        content: SingleChildScrollView(
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => this.fileListLocalManager.cancelDelete(),
          ),
        ],
      ),
    ).whenComplete(() => dialogOpen = false);

    this.fileListLocalManager.deleteSelected(local).whenComplete(() {
      if (dialogOpen) {
        Navigator.pop(context);
      }
    });
  }
}
