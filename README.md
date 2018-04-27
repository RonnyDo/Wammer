# Wammer

Wammer lets you kick out all clients in your WiFi network, so you can enjoy its full bandwidth. Best part of the story: everything works fully automatically!

Wammer uses the aircrack-ng suite and requires a compatible WiFi device to work. See below for more information.

![Wammer Screenshot](https://raw.github.com/ronnydo/wammer/master/data/screenshot_active.png)

## Disclaimer
Jamming WiFi networks might violate certain laws or regulations in your country. You are using this software on your own risk.

## Installation & Requirements
To run Wammer you'll need to...

   * install the Wammer app 
   * install aircrack-ng
   * get a WiFi device which supports monitor mode

### install Wammer
On elementaryOS simply install Wammer from AppCenter:
<p align="center">
  <a href="https://appcenter.elementary.io/com.github.ronnydo.wammer">
    <img src="https://appcenter.elementary.io/badge.svg" alt="Get it on AppCenter">
  </a>
</p>

Otherwise you can download and install the [latest .deb file](https://www.github.com/ronnydo/wammer/releases/latest).

### Install aircrack-ng
The aircrack-ng suite is a bunch of WiFi (hacking) tools. You can simply install it from the Ubuntu Softare repository:
    ```sudo apt install aircrack-ng```

### WiFi device
Furthermore you‘ll need a WiFi card which aircrack-ng is able to put into monitor-mode. See [the aircrack-ng page](https://www.aircrack-ng.org/doku.php?id=compatibility_drivers) for supported devices or simply try it out.
This software was tested with a [TP-Link TL-WN722N](https://www.amazon.de/TP-Link-TL-WN722N-High-Gain-Antenne-WLAN-Empfang-unterst%C3%BCtzt/dp/B002SZEOLG/ref=sr_1_5?ie=UTF8&qid=1524723875&sr=8-5&keywords=tp+link+wifi+adapter) adapter. 

## Technical background 
WiFi jamming isn‘t magic! It basically relies on a fault in the WPA/WPA2 handshake design. 

Thereby it's possible to send „[de-auth](https://en.wikipedia.org/wiki/Wi-Fi_deauthentication_attack)“ packages to the multicast address of a WiFi network. In result all connected clients get disconnected from it. Aircrack-ng implements it in a way that all clients, except the sending one, get kicked out.

De-auth packages always get send unencrypted. That means it would be technically possible to disconnect clients of a WPA/WPA2 encrypted WiFi network even if you‘re not connected to it. However Wammer is implement in a way that makes it necessary to be connected to the attacked WiFi network.

## Dependencies
You'll need the following dependencies to build:
* granite
* libgtk-3-dev
* meson
* valac
* aircrack-ng

## Build, Install and Run
Tbd.
