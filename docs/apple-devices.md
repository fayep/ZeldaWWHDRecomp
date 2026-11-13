# Apple TV, iPhone and iPad (experimental)

The macOS release can build the game for your own Apple TV, iPhone or iPad and install it there. Your Mac
builds the app from **your** game, the same way setup builds the Mac's game, signs it with your Apple developer
account and installs it over the network or a cable. Nothing is downloaded for the device: there is no app in any
store, and none can be shared, because the app contains your game.

**The app is for your own devices.** It holds code and files from your game; don't give it to anyone.

## What you need

- A Mac with Apple silicon, and this release of Wind Waker HD set up on it (start it once, so setup prepares the
  game and its shaders).
- **Xcode 26 or newer** from the App Store, with the platform for your device (Xcode > Settings > Components:
  tvOS or iOS, and its Simulator, which is used to draw the app's icon).
- **A paid Apple Developer account**, signed in to Xcode (Xcode > Settings > Accounts). Xcode then makes the
  certificate and the team profiles the app is signed with. Free accounts aren't supported yet.
- The device **paired with the Mac**: Xcode > Window > Devices and Simulators. An Apple TV pairs over the network
  (on the TV: Settings > Remotes and Devices > Remote App and Devices); an iPhone or iPad with a cable, then over
  the network. Turn on Developer Mode on an iPhone or iPad when it asks.
- Devices: Apple TV 4K (2022, A15) or newer; an iPhone or iPad with iOS / iPadOS 17 or newer. On the A15 Apple TV
  the game runs, but only just (lower resolution when it gets warm).

## Building and installing

**In the setup window:** hold Shift while starting Wind Waker HD (or start it with `--setup`), then
**Apple TV, iPhone or iPad...**. The page checks Xcode, signing, this Mac's game and your mods, and says what
to fix if something is missing. Choose Apple TV or iPhone or iPad, **Build the app** (a few minutes), choose the
device and **Install on the device**. Then start Wind Waker HD on the device.

**In Terminal** (`tools/Setup in Terminal.command`, or the release's Python):

```sh
python3 tools/installer/setup.py --apple-status                    # what's ready, as JSON
python3 tools/installer/setup.py --apple-device tv                 # build and install on the Apple TV
python3 tools/installer/setup.py --apple-device iphone --apple-device-id "My iPad"
python3 tools/installer/setup.py --apple-device tv --apple-no-install   # build only
python3 tools/installer/setup.py --apple-device tv --apple-install-only # install the app built last
```

Setup won't install while the game is open on the device: save and quit it there first.

## Mods

The code mods switched on in this Mac's game are built into the app (the device can't build them itself). The
setup page lists which go in. A mod that has never run on this Mac gets its place in memory when the build
briefly starts the Mac's game. Built-in mods (Settings > Mods) work on the device as on the Mac.

Mods that are on the device but not in this Mac's app are switched off when you install. The setup page warns
you before it does that: switch the same mods on in the Mac's game first.

## Saves and updates

Saves and settings stay on the device when you install a new build. A new release of Wind Waker HD means building
and installing the app again (the app and the Mac's game come from the same release).

## Known limits

- The shader library built into the app covers the shaders this Mac's game knows: shaders it hasn't met yet are
  compiled on the device when they first appear (a short stutter). Playing on the Mac fills in more.
- iCloud saves on the iPad need your own iCloud container, which setup doesn't set up yet.
- Profiles from a team's provisioning expire after a year: build and install again then.

How it works, and what's still being checked: [apple-device-installer.md](apple-device-installer.md).
