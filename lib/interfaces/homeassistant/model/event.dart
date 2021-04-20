class HomeAssistantEvent {
  HomeAssistantEvent({
    this.event,
    this.listenerCount,
  });

  String event;
  int listenerCount;

  factory HomeAssistantEvent.fromJson(Map<String, dynamic> json) =>
      HomeAssistantEvent(
        event: json["event"],
        listenerCount: json["listener_count"],
      );

  Map<String, dynamic> toJson() => {
        "event": event,
        "listener_count": listenerCount,
      };
}
