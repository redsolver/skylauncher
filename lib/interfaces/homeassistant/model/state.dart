class HomeAssistantState {
  HomeAssistantState({
    this.entityId,
    this.state,
    this.attributes,
    this.lastChanged,
    this.lastUpdated,
    this.context,
  });

  String entityId;
  String state;
  Map<String, dynamic> attributes;
  DateTime lastChanged;
  DateTime lastUpdated;
  Map<String, dynamic> context;

  factory HomeAssistantState.fromJson(Map<String, dynamic> json) =>
      HomeAssistantState(
        entityId: json["entity_id"],
        state: json["state"],
        attributes: json["attributes"],
        lastChanged: DateTime.parse(json["last_changed"]),
        lastUpdated: DateTime.parse(json["last_updated"]),
        context: json["context"],
      );

  Map<String, dynamic> toJson() => {
        "entity_id": entityId,
        "state": state,
        "attributes": attributes,
        "last_changed": lastChanged.toIso8601String(),
        "last_updated": lastUpdated.toIso8601String(),
        "context": context,
      };
}
