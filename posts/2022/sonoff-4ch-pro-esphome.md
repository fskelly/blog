---
title: Sonoff 4ch Pro R2 with ESPHome
added: 2022-01-17T12:26:36Z
slug: sonoff-4ch-pro-esphome
description: >-
  How to flash ESPHome on a Sonoff 4ch Pro R2
tags:
  - sonoff
  - esphome
  - home-assistant
categories:
  - home-automation
---
In this post, I am going to talk about the process of converting the Sonoff 4CH Pro R2 to [ESPHome](https://esphome.io) and how to now connect it to Home Assistant

<!--more-->

## Tools needed

1. FTDI Converter [![ftdiProgrammer](https://raw.githubusercontent.com/fskelly/fskelly.me/main/static/2022/sonoffProFlashESPHome/ftdiProgrammer.jpg)](https://raw.githubusercontent.com/fskelly/fskelly.me/main/static/2022/sonoffProFlashESPHome/ftdiProgrammer.jpg)
1. Dupont cables [![dupontCables](https://raw.githubusercontent.com/fskelly/fskelly.me/main/static/2022/sonoffProFlashESPHome/dupontCables.jpg)](https://raw.githubusercontent.com/fskelly/fskelly.me/main/static/2022/sonoffProFlashESPHome/dupontCables.jpg)
1. USB Cable [![dupontCables](https://raw.githubusercontent.com/fskelly/fskelly.me/main/static/2022/sonoffProFlashESPHome/usbCable.jpg)](https://raw.githubusercontent.com/fskelly/fskelly.me/main/static/2022/sonoffProFlashESPHome/usbCable.jpg)
1. Sonoff 4ch Pro R2 [![dupontCables](https://raw.githubusercontent.com/fskelly/fskelly.me/main/static/2022/sonoffProFlashESPHome/sonoff4chOpen.jpg)](https://raw.githubusercontent.com/fskelly/fskelly.me/main/static/2022/sonoffProFlashESPHome/sonoff4chOpen.jpg)
1. [ESPHome YAML code](/content/posts/2022/sonoff-4ch-pro-esphome/sonoff-pro-4ch-test.yaml)
1. [ESPHome Flasher](https://github.com/esphome/esphome-flasher)
1. [Home Assistant](https://home-assistant.io)

### FTDI Converter

Needed to transfer the compiled .bin to the Sonoff 4Ch Pro, only needed with initial flash from factory firmware to 3rd party firmware.

### Dupoint cables

Creates the connection from the FTDI converter to the actual device.

### USB Cable

Connects the FTDI converter to the computer

#### Cable connections

Computer → USB Cable → FTDI Converter → Dupont cables → Sonoff 4ch Pro R2
[![sonoffHeaderPlug](https://raw.githubusercontent.com/fskelly/fskelly.me/main/static/2022/sonoffProFlashESPHome//sonoffHeaderPlug.jpg)](https://raw.githubusercontent.com/fskelly/fskelly.me/main/static/2022/sonoffProFlashESPHome//sonoffHeaderPlug.jpg)

### Sonoff 4Ch Pro R2

This is the device we are going to convert to ESPHome firmware

### ESPHome Yaml

**Remember to use secrets (! secret)**  
You can find the file [here](https://github.com/fskelly/fskelly.me/blob/main/content/posts/2022/sonoff-4ch-pro-esphome/sonoff-pro-4ch-test.yaml)

```yml
# Basic Config
esphome:
  name: sonoff_4chpror2
  platform: ESP8266
  board: esp01_1m

wifi:
  ssid: !secret wifi_ssid
  password: !secret wifi_password

api:

# Example configuration entry
web_server:
  port: 80

logger:

ota:

binary_sensor:
  - platform: gpio
    on_press:
      then:
        - switch.toggle: button_1
    pin:
      number: GPIO0
      mode: INPUT_PULLUP
      inverted: True
    name: "Sonoff 4CH Button 1"
  - platform: gpio
    on_press:
      then:
        - switch.toggle: button_2
    pin:
      number: GPIO9
      mode: INPUT_PULLUP
      inverted: True
    name: "Sonoff 4CH Button 2"
  - platform: gpio
    on_press:
      then:
        - switch.toggle: button_3
    pin:
      number: GPIO10
      mode: INPUT_PULLUP
      inverted: True
    name: "Sonoff 4CH Button 3"
  - platform: gpio
    on_press:
      then:
        - switch.toggle: button_4
    pin:
      number: GPIO14
      mode: INPUT_PULLUP
      inverted: True
    name: "Sonoff 4CH Button 4"
  - platform: status
    name: "Sonoff 4CH Status"

switch:
  - platform: gpio
    id: button_1
    name: "Sonoff 4CH Relay 1"
    pin: GPIO12
  - platform: gpio
    id: button_2
    name: "Sonoff 4CH Relay 2"
    pin: GPIO5
  - platform: gpio
    id: button_3
    name: "Sonoff 4CH Relay 3"
    pin: GPIO4
  - platform: gpio
    id: button_4
    name: "Sonoff 4CH Relay 4"
    pin: GPIO15

output:
  - platform: esp8266_pwm
    id: blue_led
    pin: GPIO13
    inverted: True

light:
  - platform: monochromatic
    id: status_led
    name: "Sonoff 4CH Blue LED"
    output: blue_led
```

### ESPHome Flasher

Currently found [here](https://github.com/esphome/ESPHome-Flasher)

### Home Asisstant

Great guide [here](https://esphome.io/guides/getting_started_hassio.html) to install the integration.

Added the flashed ESPHome device to Home Assistant using the ESPHome integration

