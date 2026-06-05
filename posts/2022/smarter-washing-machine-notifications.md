---
title: Smarter Washing Machine Notifications
added: 2022-03-03T10:50:03Z
slug: smarter-washing-machine-notifications
description: >-
  In this post, I show you how I use a Z-Wave Plug (Fibaro) to get more monitoring around power consumption and then use this to drive notific...
tags:
  - home-assistant
---
In this post, I show you how I use a Z-Wave Plug (Fibaro) to get more monitoring around power consumption and then use this to drive notifications.

<!--more-->

Where we live now, our washing machine is a "utility room" and we keep the door closed from a noise point of view. With this setup it is possible to miss when the washing is complete and the washing makes no noise to indicate that the washing is compete and this can lead to issues. Have you ever smelled washing that was forgotten? 😖

So how did I do this?

## Ingredients

In my case, I used z-wave as this is what I had, other technology can be used.

1. Z-Wave or other Power Monitoring Capable plug
1. Z-Wave Stick (Z‐Stick Gen5 USB Controller), if you are using a Sonoff device that connects to WiFi, a similar result can be achieved.
1. [Node-RED](https://nodered.org/)
1. [Home Assistant](https://home-assisatnt.io/)
1. Home Assistant companion app
1. Washing Machine use counter (optional)
1. Washing Machine running time (optional)

## Process

I setup the Z-Wave Plug and started to plot the power usage over a few cycles to get a better understanding of how i could monitoring this. The challenge with the current washing machine is that there are “quiet periods” in the usage whether the usage drops really low. I originally tried to use [node-red-contrib-power-monitor](https://flows.nodered.org/node/node-red-contrib-power-monitor) which I have used successfully in the past, however I could find the correct “on” and “off” count value. This emphasizes the importance of **TESTING**. Make no error, I will use [node-red-contrib-power-monitor](https://flows.nodered.org/node/node-red-contrib-power-monitor) for other projects.

## So how did I solve this?

I noticed that there was a distinct power usage of “0.4W” when the cycle was complete so I decided to use 2 [Trigger State](https://zachowj.github.io/node-red-contrib-home-assistant-websocket/node/trigger-state.html#configuration) nodes in [Node-RED](https://nodered.org/).

1. For when the usage goes above 2.1W, based upon my earlier testing this was a guaranteed start point to start the washing cycle.
1. For when the usage drops to 0.4w, this signals that the load is complete and notifications can be fired.

So, we have a way to determine when the wash cycle started and take the appropriate actions. I get the current washing state in home assistant and change it to running.

```json
[
  {
    "id": "c7ac9c26b4b3750d",
    "type": "tab",
    "label": "Flow 5",
    "disabled": false,
    "info": "",
    "env": []
  },
  {
    "id": "fcb212f752a272ef",
    "type": "trigger-state",
    "z": "c7ac9c26b4b3750d",
    "name": "Washing started",
    "server": "770b1d5b.f27204",
    "version": 2,
    "exposeToHomeAssistant": false,
    "haConfig": [
      { "property": "name", "value": "" },
      { "property": "icon", "value": "" }
    ],
    "entityid": "sensor.fibaro_wall_plug_electric_consumption_w",
    "entityidfiltertype": "exact",
    "debugenabled": false,
    "constraints": [
      {
        "targetType": "this_entity",
        "targetValue": "",
        "propertyType": "current_state",
        "propertyValue": "new_state.state",
        "comparatorType": ">=",
        "comparatorValueDatatype": "num",
        "comparatorValue": "2.1"
      }
    ],
    "inputs": 0,
    "outputs": 2,
    "customoutputs": [],
    "outputinitially": false,
    "state_type": "str",
    "enableInput": false,
    "x": 120,
    "y": 260,
    "wires": [["cefc03e9cf83886c"], []]
  },
  {
    "id": "cefc03e9cf83886c",
    "type": "api-current-state",
    "z": "c7ac9c26b4b3750d",
    "name": "Washing machine status dropdown state",
    "server": "770b1d5b.f27204",
    "version": 3,
    "outputs": 2,
    "halt_if": "Completed",
    "halt_if_type": "str",
    "halt_if_compare": "is",
    "entity_id": "input_select.washing_machine_status",
    "state_type": "str",
    "blockInputOverrides": false,
    "outputProperties": [
      {
        "property": "payload",
        "propertyType": "msg",
        "value": "",
        "valueType": "entityState"
      },
      {
        "property": "data",
        "propertyType": "msg",
        "value": "",
        "valueType": "entity"
      }
    ],
    "for": 0,
    "forType": "num",
    "forUnits": "minutes",
    "override_topic": false,
    "state_location": "payload",
    "override_payload": "msg",
    "entity_location": "data",
    "override_data": "msg",
    "x": 420,
    "y": 260,
    "wires": [["681510ab0e10afd0"], []]
  },
  {
    "id": "681510ab0e10afd0",
    "type": "api-call-service",
    "z": "c7ac9c26b4b3750d",
    "name": "Washing input to \"in progress\"",
    "server": "770b1d5b.f27204",
    "version": 5,
    "debugenabled": false,
    "domain": "input_select",
    "service": "select_option",
    "areaId": [],
    "deviceId": [],
    "entityId": ["input_select.washing_machine_status"],
    "data": "{\"option\": \"Running\"}",
    "dataType": "json",
    "mergeContext": "",
    "mustacheAltTags": true,
    "outputProperties": [
      {
        "property": "payload",
        "propertyType": "msg",
        "value": "",
        "valueType": "data"
      }
    ],
    "queue": "none",
    "x": 770,
    "y": 260,
    "wires": [[]]
  },
  {
    "id": "770b1d5b.f27204",
    "type": "server",
    "name": "Home Assistant - Node-red User",
    "version": 2,
    "addon": false,
    "rejectUnauthorizedCerts": true,
    "ha_boolean": "y|yes|true|on|home|open",
    "connectionDelay": true,
    "cacheJson": true,
    "heartbeat": true,
    "heartbeatInterval": "30"
  }
]
```

So, we also have a way to determine when the wash cycle completes and take the appropriate actions. I get the current washing state in home assistant and change it to completed, I increment a washing counter and send notifications.

```json
[
  {
    "id": "c7ac9c26b4b3750d",
    "type": "tab",
    "label": "Flow 5",
    "disabled": false,
    "info": "",
    "env": []
  },
  {
    "id": "5511b05f64f5f5b1",
    "type": "trigger-state",
    "z": "c7ac9c26b4b3750d",
    "name": "Washing Complete",
    "server": "770b1d5b.f27204",
    "version": 2,
    "exposeToHomeAssistant": false,
    "haConfig": [
      { "property": "name", "value": "" },
      { "property": "icon", "value": "" }
    ],
    "entityid": "sensor.fibaro_wall_plug_electric_consumption_w",
    "entityidfiltertype": "exact",
    "debugenabled": false,
    "constraints": [
      {
        "targetType": "this_entity",
        "targetValue": "",
        "propertyType": "current_state",
        "propertyValue": "new_state.state",
        "comparatorType": "<=",
        "comparatorValueDatatype": "num",
        "comparatorValue": "2.0"
      },
      {
        "targetType": "this_entity",
        "targetValue": "",
        "propertyType": "current_state",
        "propertyValue": "new_state.state",
        "comparatorType": ">=",
        "comparatorValueDatatype": "num",
        "comparatorValue": "1.6"
      }
    ],
    "inputs": 0,
    "outputs": 2,
    "customoutputs": [],
    "outputinitially": false,
    "state_type": "str",
    "enableInput": false,
    "x": 110,
    "y": 220,
    "wires": [["f313351b2dce9a05", "125dfa81092d0b75", "d2f6fdb914f820b7"], []]
  },
  {
    "id": "f313351b2dce9a05",
    "type": "api-current-state",
    "z": "c7ac9c26b4b3750d",
    "name": "Washing Machine status dropdown state",
    "server": "770b1d5b.f27204",
    "version": 3,
    "outputs": 2,
    "halt_if": "Running",
    "halt_if_type": "str",
    "halt_if_compare": "is",
    "entity_id": "input_select.washing_machine_status",
    "state_type": "str",
    "blockInputOverrides": false,
    "outputProperties": [
      {
        "property": "payload",
        "propertyType": "msg",
        "value": "",
        "valueType": "entityState"
      },
      {
        "property": "data",
        "propertyType": "msg",
        "value": "",
        "valueType": "entity"
      }
    ],
    "for": 0,
    "forType": "num",
    "forUnits": "minutes",
    "override_topic": false,
    "state_location": "payload",
    "override_payload": "msg",
    "entity_location": "data",
    "override_data": "msg",
    "x": 440,
    "y": 220,
    "wires": [["c68cb6e8d6955af9"], []]
  },
  {
    "id": "125dfa81092d0b75",
    "type": "api-call-service",
    "z": "c7ac9c26b4b3750d",
    "name": "+1 to washing count for the day",
    "server": "770b1d5b.f27204",
    "version": 5,
    "debugenabled": false,
    "domain": "counter",
    "service": "increment",
    "areaId": [],
    "deviceId": [],
    "entityId": ["counter.washing_machine_use_count"],
    "data": "",
    "dataType": "jsonata",
    "mergeContext": "",
    "mustacheAltTags": false,
    "outputProperties": [],
    "queue": "none",
    "x": 410,
    "y": 280,
    "wires": [[]]
  },
  {
    "id": "d2f6fdb914f820b7",
    "type": "link out",
    "z": "c7ac9c26b4b3750d",
    "name": "Notification",
    "mode": "link",
    "links": ["5bef9c598f188374", "fc3b25d4ede64aa2"],
    "x": 350,
    "y": 340,
    "wires": [],
    "icon": "node-red/bridge.svg",
    "l": true
  },
  {
    "id": "c68cb6e8d6955af9",
    "type": "api-call-service",
    "z": "c7ac9c26b4b3750d",
    "name": "Washing input to \"Completed\"",
    "server": "770b1d5b.f27204",
    "version": 5,
    "debugenabled": false,
    "domain": "input_select",
    "service": "select_option",
    "areaId": [],
    "deviceId": [],
    "entityId": ["input_select.washing_machine_status"],
    "data": "{\"option\": \"Completed\"}",
    "dataType": "json",
    "mergeContext": "",
    "mustacheAltTags": true,
    "outputProperties": [
      {
        "property": "payload",
        "propertyType": "msg",
        "value": "",
        "valueType": "data"
      }
    ],
    "queue": "none",
    "x": 790,
    "y": 220,
    "wires": [[]]
  },
  {
    "id": "770b1d5b.f27204",
    "type": "server",
    "name": "Home Assistant - Node-red User",
    "version": 2,
    "addon": false,
    "rejectUnauthorizedCerts": true,
    "ha_boolean": "y|yes|true|on|home|open",
    "connectionDelay": true,
    "cacheJson": true,
    "heartbeat": true,
    "heartbeatInterval": "30"
  }
]
```

I also keep a track of the running time and the washing machine status (Running or Completed) in Home Assistant.

```json
[
  {
    "id": "c7ac9c26b4b3750d",
    "type": "tab",
    "label": "Flow 5",
    "disabled": false,
    "info": "",
    "env": []
  },
  {
    "id": "e0bdee88550c7508",
    "type": "switch",
    "z": "c7ac9c26b4b3750d",
    "name": "Running or completed",
    "property": "payload",
    "propertyType": "msg",
    "rules": [
      { "t": "eq", "v": "Running", "vt": "str" },
      { "t": "eq", "v": "Completed", "vt": "str" }
    ],
    "checkall": "true",
    "repair": false,
    "outputs": 2,
    "x": 500,
    "y": 260,
    "wires": [["47ac4140392aca83"], ["1d8755cc067d138e", "3bfc582ffa71c935"]]
  },
  {
    "id": "8a46dbae7a037860",
    "type": "api-current-state",
    "z": "c7ac9c26b4b3750d",
    "name": "Washing machine stauts dropdown state",
    "server": "770b1d5b.f27204",
    "version": 3,
    "outputs": 1,
    "halt_if": "",
    "halt_if_type": "str",
    "halt_if_compare": "is",
    "entity_id": "input_select.washing_machine_status",
    "state_type": "str",
    "blockInputOverrides": false,
    "outputProperties": [
      {
        "property": "payload",
        "propertyType": "msg",
        "value": "",
        "valueType": "entityState"
      },
      {
        "property": "data",
        "propertyType": "msg",
        "value": "",
        "valueType": "entity"
      }
    ],
    "for": 0,
    "forType": "num",
    "forUnits": "minutes",
    "x": 380,
    "y": 380,
    "wires": [["e0bdee88550c7508"]]
  },
  {
    "id": "14b07d39cf05c174",
    "type": "server-state-changed",
    "z": "c7ac9c26b4b3750d",
    "name": "Washing machine status changed?",
    "server": "770b1d5b.f27204",
    "version": 4,
    "exposeToHomeAssistant": false,
    "haConfig": [
      { "property": "name", "value": "" },
      { "property": "icon", "value": "" }
    ],
    "entityidfilter": "input_select.washing_machine_status",
    "entityidfiltertype": "exact",
    "outputinitially": false,
    "state_type": "str",
    "haltifstate": "",
    "halt_if_type": "str",
    "halt_if_compare": "is",
    "outputs": 1,
    "output_only_on_state_change": true,
    "for": 0,
    "forType": "num",
    "forUnits": "minutes",
    "ignorePrevStateNull": true,
    "ignorePrevStateUnknown": false,
    "ignorePrevStateUnavailable": false,
    "ignoreCurrentStateUnknown": false,
    "ignoreCurrentStateUnavailable": false,
    "outputProperties": [
      {
        "property": "payload",
        "propertyType": "msg",
        "value": "",
        "valueType": "entityState"
      },
      {
        "property": "data",
        "propertyType": "msg",
        "value": "",
        "valueType": "eventData"
      },
      {
        "property": "topic",
        "propertyType": "msg",
        "value": "",
        "valueType": "triggerId"
      }
    ],
    "x": 180,
    "y": 200,
    "wires": [["e0bdee88550c7508"]]
  },
  {
    "id": "5402cfbb2fbac174",
    "type": "poll-state",
    "z": "c7ac9c26b4b3750d",
    "name": "Washing machine status",
    "server": "770b1d5b.f27204",
    "version": 2,
    "exposeToHomeAssistant": false,
    "haConfig": [
      { "property": "name", "value": "" },
      { "property": "icon", "value": "" }
    ],
    "updateinterval": "60",
    "updateIntervalType": "num",
    "updateIntervalUnits": "seconds",
    "outputinitially": false,
    "outputonchanged": false,
    "entity_id": "input_select.washing_machine_status",
    "state_type": "str",
    "halt_if": "",
    "halt_if_type": "str",
    "halt_if_compare": "is",
    "outputs": 1,
    "x": 150,
    "y": 260,
    "wires": [["e0bdee88550c7508"]]
  },
  {
    "id": "47ac4140392aca83",
    "type": "function",
    "z": "c7ac9c26b4b3750d",
    "name": "Milliseconds to Minutes",
    "func": "time = msg.data.timeSinceChangedMs;\nrunningTime = (time / 1000 / 60);\nmsg.runningTime = parseFloat(runningTime).toFixed(1);\nremainingtime = 110 - runningTime;\nmsg.remainingTime = parseFloat(remainingtime).toFixed(1);\nreturn msg;",
    "outputs": 1,
    "noerr": 0,
    "initialize": "",
    "finalize": "",
    "libs": [],
    "x": 770,
    "y": 180,
    "wires": [["7f3b7cbded7ce6be", "c693594518abd80a"]]
  },
  {
    "id": "1d8755cc067d138e",
    "type": "change",
    "z": "c7ac9c26b4b3750d",
    "name": "Not running number",
    "rules": [
      { "t": "set", "p": "runningTime", "pt": "msg", "to": "NaN", "tot": "str" }
    ],
    "action": "",
    "property": "",
    "from": "",
    "to": "",
    "reg": false,
    "x": 760,
    "y": 300,
    "wires": [["7f3b7cbded7ce6be"]]
  },
  {
    "id": "3bfc582ffa71c935",
    "type": "function",
    "z": "c7ac9c26b4b3750d",
    "name": "Milliseconds to Minutes",
    "func": "msg.runningTime = 0;\nreturn msg;",
    "outputs": 1,
    "noerr": 0,
    "initialize": "",
    "finalize": "",
    "libs": [],
    "x": 770,
    "y": 360,
    "wires": [["c693594518abd80a"]]
  },
  {
    "id": "3ecffe436de5790c",
    "type": "inject",
    "z": "c7ac9c26b4b3750d",
    "name": "",
    "props": [{ "p": "payload" }, { "p": "topic", "vt": "str" }],
    "repeat": "",
    "crontab": "",
    "once": false,
    "onceDelay": 0.1,
    "topic": "",
    "payload": "",
    "payloadType": "date",
    "x": 120,
    "y": 380,
    "wires": [["8a46dbae7a037860"]]
  },
  {
    "id": "7f3b7cbded7ce6be",
    "type": "ui_gauge",
    "z": "c7ac9c26b4b3750d",
    "name": "Washing Machine Running Time: ",
    "group": "7e2e840297e6ff32",
    "order": 4,
    "width": "3",
    "height": "4",
    "gtype": "wave",
    "title": "Running Time: ",
    "label": "min",
    "format": "{{msg.runningTime}}",
    "min": 0,
    "max": "80",
    "colors": ["#00b500", "#e6e600", "#ca3838"],
    "seg1": "",
    "seg2": "",
    "className": "",
    "x": 1140,
    "y": 300,
    "wires": []
  },
  {
    "id": "c693594518abd80a",
    "type": "api-call-service",
    "z": "c7ac9c26b4b3750d",
    "name": "Update running time",
    "server": "770b1d5b.f27204",
    "version": 5,
    "debugenabled": false,
    "domain": "input_number",
    "service": "set_value",
    "areaId": [],
    "deviceId": [],
    "entityId": ["input_number.washing_machine_running_time"],
    "data": "{\"value\":\"{{runningTime}}\"}",
    "dataType": "json",
    "mergeContext": "",
    "mustacheAltTags": false,
    "outputProperties": [],
    "queue": "none",
    "x": 1100,
    "y": 240,
    "wires": [[]]
  },
  {
    "id": "b51f0aee106afbd0",
    "type": "comment",
    "z": "c7ac9c26b4b3750d",
    "name": "Multiple triggers",
    "info": "Multiple triggers to ensure as much accuracy as possible.",
    "x": 120,
    "y": 160,
    "wires": []
  },
  {
    "id": "7e26df45e8227dfe",
    "type": "comment",
    "z": "c7ac9c26b4b3750d",
    "name": "Manual trigger",
    "info": "",
    "x": 110,
    "y": 340,
    "wires": []
  },
  {
    "id": "770b1d5b.f27204",
    "type": "server",
    "name": "Home Assistant - Node-red User",
    "version": 2,
    "addon": false,
    "rejectUnauthorizedCerts": true,
    "ha_boolean": "y|yes|true|on|home|open",
    "connectionDelay": true,
    "cacheJson": true,
    "heartbeat": true,
    "heartbeatInterval": "30"
  },
  {
    "id": "7e2e840297e6ff32",
    "type": "ui_group",
    "name": "Utility Room",
    "tab": "e35fd0e6d6776633",
    "order": 1,
    "disp": true,
    "width": "6",
    "collapse": false,
    "className": ""
  },
  {
    "id": "e35fd0e6d6776633",
    "type": "ui_tab",
    "name": "House",
    "icon": "home",
    "order": 34,
    "disabled": false,
    "hidden": false
  }
]
```

For the notifications, I also use [Node-RED](https://nodered.org/) and the “notify service” that is from [Home Assistant](https://home-assisatnt.io/). I have tried to make the flow as modular as possible and I use changes nodes to control the message and which device is notified.

```json
[
  {
    "id": "1a53b6dd316fd626",
    "type": "tab",
    "label": "Flow 8",
    "disabled": false,
    "info": "",
    "env": []
  },
  {
    "id": "b3e4a5624ac9d518",
    "type": "link in",
    "z": "1a53b6dd316fd626",
    "name": "Washing Machine Notifications",
    "links": [
      "ca506a1b0dfe8ba1",
      "e63c199b1210c601",
      "2acc791d40d9f113",
      "b713589b6fc1fa2a",
      "5daafecdbf09105b",
      "d2f6fdb914f820b7"
    ],
    "x": 85,
    "y": 180,
    "wires": [["142cfc8c024d98d0"]]
  },
  {
    "id": "142cfc8c024d98d0",
    "type": "change",
    "z": "1a53b6dd316fd626",
    "name": "Washing Machine Notification",
    "rules": [
      { "t": "set", "p": "domain", "pt": "msg", "to": "notify", "tot": "str" },
      {
        "t": "set",
        "p": "service",
        "pt": "msg",
        "to": "mobile_app_fkapp",
        "tot": "str"
      },
      {
        "t": "set",
        "p": "message",
        "pt": "msg",
        "to": "ACTION - Time to take out washing",
        "tot": "str"
      }
    ],
    "action": "",
    "property": "",
    "from": "",
    "to": "",
    "reg": false,
    "x": 310,
    "y": 240,
    "wires": [["7e2b772ba33565d7"]]
  },
  {
    "id": "7e2b772ba33565d7",
    "type": "api-call-service",
    "z": "1a53b6dd316fd626",
    "name": "Washing out - Action And Text",
    "server": "770b1d5b.f27204",
    "version": 5,
    "debugenabled": false,
    "domain": "{{domain}}",
    "service": "{{service}}",
    "areaId": [],
    "deviceId": [],
    "entityId": [],
    "data": "{\"message\":\"{{message}}\",\"data\":{\"actions\":[{\"action\":\"{{action1Action}}\",\"title\":\"{{action1Title}}\"}]}}",
    "dataType": "json",
    "mergeContext": "",
    "mustacheAltTags": false,
    "outputProperties": [
      {
        "property": "payload",
        "propertyType": "msg",
        "value": "",
        "valueType": "data"
      }
    ],
    "queue": "none",
    "x": 630,
    "y": 240,
    "wires": [[]]
  },
  {
    "id": "770b1d5b.f27204",
    "type": "server",
    "name": "Home Assistant - Node-red User",
    "version": 2,
    "addon": false,
    "rejectUnauthorizedCerts": true,
    "ha_boolean": "y|yes|true|on|home|open",
    "connectionDelay": true,
    "cacheJson": true,
    "heartbeat": true,
    "heartbeatInterval": "30"
  }
]
```

Until next time, have fun automating your home. 🏡

