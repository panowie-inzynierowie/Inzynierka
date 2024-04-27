#include <ArduinoJson.h>

JsonDocument doc;
int devicePins[] = {7, 10, 12};
bool deviceStates[] = {false, false, true};

void sendStatus() {
  doc.clear();
  JsonArray devices = doc.to<JsonArray>();
  for (int i = 0; i < 3; i++) {
    JsonObject device = devices.createNestedObject();
    device["id"] = i;
    device["status"] = deviceStates[i] ? "on" : "off";
  }
  serializeJson(doc, Serial);
}

void toggleDevice(int id) {
  if (id >= 0 && id < 3) {
    deviceStates[id] = !deviceStates[id];
    digitalWrite(devicePins[id], deviceStates[id] ? HIGH : LOW);
  }
}

void setup() {
  Serial.begin(9600);
  for (int i = 0; i < sizeof(devicePins)/sizeof(*devicePins); i++) {
    pinMode(devicePins[i], OUTPUT);
    digitalWrite(devicePins[i], deviceStates[i] ? HIGH : LOW);
  }
}

void clearSerialBuffer() {
  while (Serial.available() > 0) {
    Serial.read();
  }
}

void loop() {
  if (Serial.available() > 0) {
    String command = Serial.readStringUntil('\n');
    clearSerialBuffer();
    if (command == "get_status") {
      sendStatus();
    } else if (command.startsWith("toggle_")) {
      int id = command.charAt(7) - '0';
      toggleDevice(id);
      sendStatus();
    }
  }
}
