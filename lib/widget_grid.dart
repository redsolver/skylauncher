import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:skylauncher/app.dart';
import 'package:skylauncher/model/widget_definition.dart';
import 'package:skylauncher/widget/action_button.dart';
/* import 'package:skylauncher/widget/calendar.dart';
import 'package:unicons/unicons.dart'; */

import 'widget/android_widget.dart';
// import 'widget/live_button.dart';

class WidgetGrid extends StatefulWidget {
  @override
  _WidgetGridState createState() => _WidgetGridState();
}

class _WidgetGridState extends State<WidgetGrid> {
  bool editMode = false;

  final widgetList = <List<WidgetDefinition>>[
    <WidgetDefinition>[
      WidgetDefinition(WidgetType.test),
    ],
  ];
  Widget _buildWidget(WidgetDefinition definition) {
    if (definition.type == WidgetType.test) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Test Widget',
            style: TextStyle(
              fontSize: 24,
            ),
          ),
        ),
      );
    } else if (definition.type == WidgetType.calendar) {
      // TODO return CalendarWidget();
    } else if (definition.type == WidgetType.android) {
      return SizedBox(
        height: definition.height ?? 100,
        child: AndroidWidget(definition.appWidgetId),
      );
    }
    return Center(
      child: Text('ERROR'),
    );
  }

  @override
  void initState() {
    if (dataBox.containsKey('widgets')) {
      widgetList.clear();
      final list = json.decode(dataBox.get('widgets'));

      for (final List row in list) {
        widgetList.add(row
            .map<WidgetDefinition>((m) => WidgetDefinition.fromJson(m))
            .toList());
      }
    }
    _removeUnusedWidgetIds();
    super.initState();
  }

  void _removeUnusedWidgetIds() async {
    final usedWidgetIds = <int>{};
    for (final row in widgetList) {
      for (final def in row) {
        if (def.type == WidgetType.android) {
          usedWidgetIds.add(def.appWidgetId);
        }
      }
    }
    final List<int> appWidgetIds = await methodChannel.invokeMethod(
      'appWidgetIds',
    );
    print('appWidgetIds $appWidgetIds');
    for (final appWidgetId in appWidgetIds) {
      if (usedWidgetIds.contains(appWidgetId)) continue;
      await methodChannel.invokeMethod(
        'deleteAppWidgetId',
        appWidgetId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final row in widgetList)
          (row.length == 0 && !editMode)
              ? SizedBox()
              : /*  row.length == 1
                  ? _buildWidget(row.first)
                  : */
              Row(
                  children: [
                    if (editMode && row.isEmpty && widgetList.length > 1)
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.red,
                            ),
                          ),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                widgetList.remove(row);
                              });
                            },
                            child: SizedBox(
                              height: 84,
                              child: Center(
                                child: ListTile(
                                  leading: Icon(
                                    Icons.remove_circle,
                                    color: Colors.red,
                                  ),
                                  title: Text(
                                    'Remove row',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    for (final definition in row)
                      Expanded(
                        flex: definition.flex ?? 1,
                        child: Stack(
                          children: [
                            if (definition.showHint != true)
                              _buildWidget(definition),
                            if (definition.showHint == true)
                              InkWell(
                                onTap: () async {
                                  print('reload');
                                  /*   setState(() {
                                          definition.loadWidget = false;
                                        });
                                        await Future.delayed(
                                            Duration(milliseconds: 200)); */
                                  setState(() {
                                    //definition.loadWidget = true;
                                    definition.showHint = false;
                                  });
                                },
                                child: Container(
                                  color: Colors.black,
                                  alignment: Alignment.center,
                                  height: 100,
                                  child: Text(
                                    'LOAD WIDGET',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            if (editMode)
                              Wrap(
                                children: [
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        row.remove(definition);
                                      });
                                    },
                                    child: Material(
                                      color: Colors.red,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Icon(
                                          Icons.close,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () async {
                                      final ctrl = TextEditingController(
                                          text: (definition.flex ?? 1)
                                              .toString());

                                      final res = await showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title:
                                              Text('Set flex (higher = wider)'),
                                          content: TextField(
                                            decoration: InputDecoration(
                                              border: OutlineInputBorder(),
                                            ),
                                            controller: ctrl,
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  Navigator.of(context).pop,
                                              child: Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context).pop(
                                                int.tryParse(
                                                  ctrl.text.trim(),
                                                ),
                                              ),
                                              child: Text('Set'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (res != null) {
                                        setState(() {
                                          definition.flex = res;
                                        });
                                      }
                                    },
                                    child: Material(
                                      color: Colors.yellow.shade700,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Icon(
                                          Icons.compare_arrows,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () async {
                                      final ctrl = TextEditingController(
                                          text: (definition.height ?? 100)
                                              .toString());

                                      final res = await showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text('Set height'),
                                          content: TextField(
                                            decoration: InputDecoration(
                                              border: OutlineInputBorder(),
                                            ),
                                            controller: ctrl,
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  Navigator.of(context).pop,
                                              child: Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context).pop(
                                                double.tryParse(
                                                  ctrl.text.trim(),
                                                ),
                                              ),
                                              child: Text('Set'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (res != null) {
                                        setState(() {
                                          definition.height = res;
                                        });
                                      }
                                    },
                                    child: Material(
                                      color: Colors.yellow.shade700,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Icon(
                                          Icons.height,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    if (editMode)
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white,
                            ),
                          ),
                          child: InkWell(
                            onTap: () async {
                              final int appWidgetId =
                                  await methodChannel.invokeMethod(
                                'appWidget',
                              );

                              setState(() {
                                row.add(
                                  WidgetDefinition(
                                    WidgetType.android,
                                    appWidgetId: appWidgetId,
                                  )..showHint = true,
                                );
                              });
                            },
                            child: SizedBox(
                              height: 84,
                              child: Icon(Icons.add),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        if (editMode && widgetList.last.isNotEmpty)
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white,
              ),
            ),
            child: InkWell(
              onTap: () {
                setState(() {
                  widgetList.add(
                    <WidgetDefinition>[],
                  );
                });
              },
              child: SizedBox(
                height: 84,
                child: Center(
                  child: ListTile(
                    leading: Icon(Icons.add),
                    title: Text('Add new row'),
                  ),
                ),
              ),
            ),
          ),
        Row(
          children: [
            // TODO Insert Home Assistant Widgets
            ActionButton(
              label: 'Edit',
              icon: Icons.edit,
              action: () async {
                if (editMode) {
                  final widgetConfig = json.encode(widgetList);
                  dataBox.put('widgets', widgetConfig);
                  _removeUnusedWidgetIds();

                  setState(() {
                    editMode = false;
                  });
                } else {
                  setState(() {
                    editMode = true;
                  });
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

/* class EditableWidget extends StatefulWidget {
  @override
  _EditableWidgetState createState() => _EditableWidgetState();
}

class _EditableWidgetState extends State<EditableWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(
        color: Colors.red,
      )),
    );
  }
}
 */
