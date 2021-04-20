import 'package:json_annotation/json_annotation.dart';

part 'widget_definition.g.dart';

@JsonSerializable()
class WidgetDefinition {
  final WidgetType type;
  Map<String, dynamic> data;
  int flex;
  double height;

  final int appWidgetId;

  @JsonKey(ignore: true)
  bool showHint;

  WidgetDefinition(this.type,
      {this.data, this.appWidgetId, this.flex = 1, this.height});
  factory WidgetDefinition.fromJson(Map<String, dynamic> json) =>
      _$WidgetDefinitionFromJson(json);
  Map<String, dynamic> toJson() => _$WidgetDefinitionToJson(this);
}

enum WidgetType {
  calendar,
  action,
  android,
  test,
}
