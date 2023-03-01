import 'package:cake_wallet/src/screens/settings/widgets/settings_cell_with_arrow.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/nodes/widgets/node_list_row.dart';
import 'package:cake_wallet/src/widgets/standard_list.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/view_model/node_list/node_list_view_model.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class ConnectionSyncPage extends BasePage {
  ConnectionSyncPage(this.nodeListViewModelMainnet, this.nodeListViewModelTestnet, this.dashboardViewModel);

  @override
  String get title => S.current.connection_sync;

  final NodeListViewModelMainnet nodeListViewModelMainnet;
  final NodeListViewModelTestnet nodeListViewModelTestnet;
  final DashboardViewModel dashboardViewModel;

  @override
  Widget body(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SettingsCellWithArrow(
            title: S.current.reconnect,
            handler: (context) => _presentReconnectAlert(context),
          ),
          StandardListSeparator(padding: EdgeInsets.symmetric(horizontal: 24)),
          if (dashboardViewModel.hasRescan)
            SettingsCellWithArrow(
              title: S.current.rescan,
              handler: (context) => Navigator.of(context).pushNamed(Routes.rescan),
            ),
          StandardListSeparator(padding: EdgeInsets.symmetric(horizontal: 24)),
          SettingsCellWithArrow(
              title: S.current.network,
              handler: (context) async => await showDialog<void>(
                context: context,
                builder: (BuildContext context) {
                  return SimpleDialog(
                    title: Row (
                        children: [
                          Icon(Icons.code, color:Colors.blue),
                          SizedBox(width:5, height:5),
                          Text(S.of(context).choose_network),
                        ]
                    ),
                    titleTextStyle: TextStyle(
                      color: Theme.of(context).textTheme.headline3?.color,
                    ),
                    children: <Widget>[
                      SimpleDialogOption(
                        onPressed: () async {
                          dashboardViewModel.useMainnet();
                          Navigator.of(context).pop();
                          },
                        child: Text(S.of(context).mainnet),
                      ),
                      SimpleDialogOption(
                        onPressed: () async {
                          dashboardViewModel.useTestnet();
                          Navigator.of(context).pop();
                        },
                        child: Text(S.of(context).testnet),
                      ),
                    ],
                  );
                },
              )
          ),
          StandardListSeparator(padding: EdgeInsets.symmetric(horizontal: 24)),
          NodeHeaderListRow(
            title: S.of(context).add_new_node,
            onTap: (_) async => await Navigator.of(context).pushNamed(Routes.newNode),
          ),
          StandardListSeparator(padding: EdgeInsets.symmetric(horizontal: 24)),
          SizedBox(height: 100),
          Observer(
            builder: (BuildContext context) {
              return Flexible(
                child: SectionStandardList(
                  sectionCount: 1,
                  context: context,
                  dividerPadding: EdgeInsets.symmetric(horizontal: 24),
                  itemCounter: (int sectionIndex) {
                    return (dashboardViewModel.currentNetwork()==NetworkKind.mainnet?
                      nodeListViewModelMainnet.nodesMainnet:nodeListViewModelTestnet.nodesTestnet).length;
                  },
                  itemBuilder: (_, sectionIndex, index) {
                    final node = (dashboardViewModel.currentNetwork()==NetworkKind.mainnet?
                    nodeListViewModelMainnet.nodesMainnet:nodeListViewModelTestnet.nodesTestnet)[index];
                    final isSelected = node.keyIndex == (dashboardViewModel.currentNetwork()==NetworkKind.mainnet?
                    nodeListViewModelMainnet.currentNode:nodeListViewModelTestnet.currentNode).keyIndex;
                    final nodeListRow = NodeListRow(
                      title: "${node.uriRaw}"+(isSelected?" (${S.of(context).selected})":""),
                      isSelected: isSelected,
                      isAlive: node.requestNode(),
                      onTap: (_) async {
                        if (isSelected) {
                          return;
                        }

                        await showPopUp<void>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertWithTwoActions(
                                alertTitle: S.of(context).change_current_node_title,
                                alertContent: (dashboardViewModel.currentNetwork()==NetworkKind.mainnet?
                                nodeListViewModelMainnet.getAlertContent(node.uriRaw):
                                nodeListViewModelTestnet.getAlertContent(node.uriRaw)),
                                leftButtonText: S.of(context).cancel,
                                rightButtonText: S.of(context).change,
                                actionLeftButton: () => Navigator.of(context).pop(),
                                actionRightButton: () async {
                                  if(dashboardViewModel.currentNetwork()==NetworkKind.mainnet)
                                    await nodeListViewModelMainnet.setAsCurrent(node);
                                  else
                                    await nodeListViewModelTestnet.setAsCurrent(node);
                                  Navigator.of(context).pop();
                                },
                              );
                            });
                      },
                    );

                    final dismissibleRow = Slidable(
                      key: Key('${node.keyIndex}'),
                      startActionPane: _actionPane(context, node),
                      endActionPane: _actionPane(context, node),
                      child: nodeListRow,
                    );

                    return isSelected ? nodeListRow : dismissibleRow;
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _presentReconnectAlert(BuildContext context) async {
    await showPopUp<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertWithTwoActions(
            alertTitle: S.of(context).reconnection,
            alertContent: S.of(context).reconnect_alert_text,
            rightButtonText: S.of(context).ok,
            leftButtonText: S.of(context).cancel,
            actionRightButton: () async {
              Navigator.of(context).pop();
              await dashboardViewModel.reconnect();
            },
            actionLeftButton: () => Navigator.of(context).pop());
      },
    );
  }

  ActionPane _actionPane(BuildContext context, Node node) => ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.3,
        children: [
          SlidableAction(
            onPressed: (context) async {
              final confirmed = await showPopUp<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertWithTwoActions(
                            alertTitle: S.of(context).remove_node,
                            alertContent: S.of(context).remove_node_message,
                            rightButtonText: S.of(context).remove,
                            leftButtonText: S.of(context).cancel,
                            actionRightButton: () => Navigator.pop(context, true),
                            actionLeftButton: () => Navigator.pop(context, false));
                      }) ??
                  false;

              if (confirmed) {
                if(dashboardViewModel.currentNetwork()==NetworkKind.mainnet)
                  await nodeListViewModelMainnet.delete(node);
                else
                  await nodeListViewModelTestnet.delete(node);
              }
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: CupertinoIcons.delete,
            label: S.of(context).delete,
          ),
        ],
      );
}
