# Setup for running on iOS

Love2d's site contains various instructions for doing local installs to mobile devices.

To install from a mac to an iPad or iPhone you'll need xcode, and the love2d xcode source project.

- Instructions: https://love2d.org/wiki/Game_Distribution
- iOS source (linked on Love2D homepage): https://github.com/love2d/love/releases/download/11.5/love-11.5-ios-source.zip

Did this stuff:

- (you need xcode installed)
- unzip ios xcode project source
- symlink xcode proj
- open xcode
- Project Navigator (leftbar) -> Targets: love-ios (midleftbar) -> General (tab bar)
  - Miniumum Deployments: iOS: 17.1
  - Identity: (trying to mess with this section may drag you into a subscreen to sign into Apple, and give an error that the love2d identifier is already taken... first chance you get, change the Bundle Indentifier to something unique)
    - Display Name: Air Hockey
    - Bundle Identifier: org.crozware.airhockey
    - Version 11.5
- -> Build Phases -> Copy Bundle Resources -> + -> Add other... -> navigate upward to find airhockey.love
  - Copy Bundle 

