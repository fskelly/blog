---
title: Enhancing Node-Red with GUIDs
added: 2025-06-30T13:47:26+01:00
slug: enhancing-node-red
description: >-
    A simple way to add traceability to your Node-Red flows
tags:
    - node-red  
    - improvement
categories:
    - home-automation
---

Do you have a lot of automation in your house using [Node-RED](https://nodered.org/) and are you looking for a way to increase the possibility of finding a faulty flow? If yes, follow me as I come up with a solution that might work for you as well.

<!--more-->


This is a use case for me. Your mileage may vary.
This will take some time. 

> Anything worth doing is worth doing well.

## Background


So let me explain the problem and see if this sounds familiar. I use [Node-RED](https://nodered.org/) **A LOT** along with [Home Assistant](https://www.home-assistant.io). I made the decision a long time ago that the automations built into Home Assistant and the YAML engine was not for me. Please note that was quite a while, probably 5 or 6 years ago - the automation interface in  [Home Assistant](https://www.home-assistant.io) is so much better now, *however* I am heavily invested in [Node-RED](https://nodered.org/) and will not be going back anytime soon.

## So what is the problem?

I have a lot of flows and nodes in my environment. I make heavy use of links and try to centralize as much as possible and use links (link in and link out) to ensure that the actions I perform are consistent. When you get to the size of my installation (over a 100 flows), troubleshooting and figuring out erratic or intermittent issues can be challenge. With all the wiring and multiple nodes and linking and multiple condition checking - it can become overwhelming to figure out where the problem starts and ends.

## How did I fix this?


I have spent time and this will be an on-going process to add GUIDs (yes, those long 32 digit things that are now everywhere) and simple use of a [subflow](https://nodered.org/docs/user-guide/editor/workspace/subflows). The [subflow](https://nodered.org/docs/user-guide/editor/workspace/subflows) I created is simply used right at the beginning of my flow and its **G**lobally **U**nique **ID**entifier now allows me to at least back-track to the start of the problematic flow and if the debug nodes returns more than 1 **GUID** that is also helpful.

So a simple enough change, but time-consuming to implement.


[![My GUID Subflow](https://raw.githubusercontent.com/fskelly/fskelly.me/main/static/2025/enhancing-node-red-guids/subflow.png)](https://raw.githubusercontent.com/fskelly/fskelly.me/main/static/2025/enhancing-node-red-guids/subflow.png)

_Click image to view full size._

Here is the export of my subflow - feel free to use it.

```json
[{"id":"f44cf6f9b8f814e3","type":"subflow","name":"Flow Trace Tagger (1)","info":"Adds msg.flow_origin and msg.flow_trace for debugging and traceability.\nSet the environment variable TAG_NAME when using this subflow.","category":"","in":[{"x":60,"y":80,"wires":[{"id":"6c2c2c6e8e2f886c"}]}],"out":[{"x":440,"y":80,"wires":[{"id":"6c2c2c6e8e2f886c","port":0}]}],"env":[{"name":"TAG_NAME","type":"str","value":""}],"color":"#FFD580","status":{"x":340,"y":380,"wires":[{"id":"0df253ebbfe15d99","port":0}]}},{"id":"6c2c2c6e8e2f886c","type":"change","z":"f44cf6f9b8f814e3","name":"Set flow trace tags","rules":[{"t":"set","p":"flow_origin","pt":"msg","to":"$env('TAG_NAME') != '' ? $env('TAG_NAME') : 'Unlabeled Flow'","tot":"jsonata"},{"t":"set","p":"flow_trace","pt":"msg","to":"$now() & ' - ' & ($env('TAG_NAME') != '' ? $env('TAG_NAME') : 'Unlabeled Flow')","tot":"jsonata"}],"x":250,"y":80,"wires":[["363a78cde4fa6638"]]},{"id":"0df253ebbfe15d99","type":"status","z":"f44cf6f9b8f814e3","name":"","scope":null,"x":180,"y":380,"wires":[[]]},{"id":"363a78cde4fa6638","type":"function","z":"f44cf6f9b8f814e3","name":"status","func":"//var date = new Date();\n//var dateTime = date.toLocaleString(); // Format the date and time\n\n// In our `msg.payload` the `title` attribute contains the name of the game.\nvar statusText = msg.flow_trace;\n\n// `node.status` will display the actual status below your function node using\n// the data you provide here.\nnode.status({ fill: \"blue\", shape: \"ring\", text: statusText });\nreturn msg;\n","outputs":1,"timeout":0,"noerr":0,"initialize":"","finalize":"","libs":[],"x":490,"y":200,"wires":[[]]}]
```

Example flow, this is just a simple example to show how everything stitches together.

[![Simple flow example using the GUID subflow](https://raw.githubusercontent.com/fskelly/fskelly.me/main/static/2025/enhancing-node-red-guids/flow.png)](https://raw.githubusercontent.com/fskelly/fskelly.me/main/static/2025/enhancing-node-red-guids/flow.png)

_Click image to view full size._

Configuration of sub-flow

[![Subflow](https://raw.githubusercontent.com/fskelly/fskelly.me/main/static/2025/enhancing-node-red-guids/flow-config.png)](https://raw.githubusercontent.com/fskelly/fskelly.me/main/static/2025/enhancing-node-red-guids/flow-config.png)

_Click image to view full size._

Debug node

[![Debug information with GUID](https://raw.githubusercontent.com/fskelly/fskelly.me/main/static/2025/enhancing-node-red-guids/flow-debug.png)](https://raw.githubusercontent.com/fskelly/fskelly.me/main/static/2025/enhancing-node-red-guids/flow-debug.png)

_Click image to view full size._


## Is it worth it?

Well, that depends on you and how much and effort you want to spend making your automation system resilient, robust and easy to troubleshoot.

For me, absolutely **YES**