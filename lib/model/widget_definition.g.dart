// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'widget_definition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WidgetDefinition _$WidgetDefinitionFromJson(Map<String, dynamic> json) {
  return WidgetDefinition(
    _$enumDecodeNullable(_$WidgetTypeEnumMap, json['type']),
    data: json['data'] as Map<String, dynamic>,
    appWidgetId: json['appWidgetId'] as int,
    flex: json['flex'] as int,
    height: (json['height'] as num)?.toDouble(),
  );
}

Map<String, dynamic> _$WidgetDefinitionToJson(WidgetDefinition instance) =>
    <String, dynamic>{
      'type': _$WidgetTypeEnumMap[instance.type],
      'data': instance.data,
      'flex': instance.flex,
      'height': instance.height,
      'appWidgetId': instance.appWidgetId,
    };

T _$enumDecode<T>(
  Map<T, dynamic> enumValues,
  dynamic source, {
  T unknownValue,
}) {
  if (source == null) {
    throw ArgumentError('A value must be provided. Supported values: '
        '${enumValues.values.join(', ')}');
  }

  final value = enumValues.entries
      .singleWhere((e) => e.value == source, orElse: () => null)
      ?.key;

  if (value == null && unknownValue == null) {
    throw ArgumentError('`$source` is not one of the supported values: '
        '${enumValues.values.join(', ')}');
  }
  return value ?? unknownValue;
}

T _$enumDecodeNullable<T>(
  Map<T, dynamic> enumValues,
  dynamic source, {
  T unknownValue,
}) {
  if (source == null) {
    return null;
  }
  return _$enumDecode<T>(enumValues, source, unknownValue: unknownValue);
}

const _$WidgetTypeEnumMap = {
  WidgetType.calendar: 'calendar',
  WidgetType.action: 'action',
  WidgetType.android: 'android',
  WidgetType.test: 'test',
};
