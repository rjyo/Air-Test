# AirTest

A tool that will make a lot of iPhone/iPad developers' life easier. It shares your app over-the-air in a WiFi network. Bonjour is used and no configuration is needed. The magic behind is [Apple's Wireless Enterprise](http://developer.apple.com/library/ios/#featuredarticles/FA_Wireless_Enterprise_App_Distribution/Introduction/Introduction.html) Distribution protocol.

If you have any of the following things bugging you

* wanted to test your app but found the USB cable is not with you
* have to plugged in your teammates' devices one by one just to show them some new feature
* worried about your device's battery life because it is charged several times a day just for app test

AirTest solves all these problems in an elegant and extremely simple way. Only 3 steps needed.

1. Compile your app for iOS devices
2. Drag .app or .ipa file(s) in AirTest on Mac. 
3. Open AirTest client on your device and choose the app to install! 

### NOTE
AirTest is only a tool for test-driving your app wirelessly. It is NOT a replacement for Apple’s ad hoc provisioning profile and device number limitations. A valid iOS Developer Program (iDP) account is needed and only devices registered in your iDP can be used.


## AirTest in Action
![screenshot1](https://github.com/rjyo/Air-Test/raw/master/screenshots/desc1.png)

![screenshot2](https://github.com/rjyo/Air-Test/raw/master/screenshots/desc2.png)

## How to Build

AirTest is using [Pull-to-refresh](git@github.com:rjyo/PullToRefresh.git) as a sub-module

    git clone git@github.com:rjyo/Air-Test.git
    git submodule init
    git submodule update
    
It also uses [Tapku Library](https://github.com/devinross/tapkulibrary), and should also use it as a sub-module in the near future.
    
## Precompiled Binary

You can just compile the iPhone app while using our precompiled Mac Client - [AirTest.dmg](http://www.rakutec.com/adhoc/app/AirTest.dmg).

## Todos
* [Tapku Library](https://github.com/devinross/tapkulibrary) is now copied and modified. Should use it as a git sub-module.
* Some other third-party libraries should also be included in some more smarter way.
* Change license information in source code.

## Future Plans
* Support command line interface to make life easier when using a command line based build system like rake
* A web interface for iOS devices so that AirTest will works without the iPhone client

## Copyright
(C)Copyright 2011 Xu Lele (Rakuraku Jyo if you know me in Japan). Feel free to drop me by on Twitter [@xu_lele](http://twitter.com/xu_lele). AirTest is released under [MIT license](http://www.opensource.org/licenses/mit-license.php).


