# Trying the Apple TV, iPhone and iPad build (team testing)

This is experimental and not part of any release. Setup can build the game for your own Apple TV, iPhone or iPad
from your game and install it there. To try it, build a test release folder from this branch, then run setup from
that folder. The app is made on your Mac from your game, so it is for your own devices only: don't share it.

## What you need

- A Mac with Apple silicon, with your game dump.
- **Xcode 26 or newer**, with the tvOS and iOS platforms (Xcode > Settings > Components; also the Simulator for
  your device, which draws the app's icon), CMake, Ninja and Python 3.
- **A paid Apple Developer account** signed in to Xcode (Xcode > Settings > Accounts). Free accounts aren't
  supported yet.
- The device **paired with the Mac** (Xcode > Window > Devices and Simulators). An Apple TV pairs over the network
  (Settings > Remotes and Devices > Remote App and Devices on the TV). An iPhone or iPad pairs with a cable and
  needs Developer Mode.
- Apple TV 4K (2022, A15) or newer, or an iPhone or iPad on iOS / iPadOS 17 or newer. The A15 Apple TV runs the
  game, but only just.

## 1. Build the test release folder

```sh
tvos/build_test_package.sh            # into build/apple-test; or pass another folder
```

This builds the Mac runtime and the tvOS and iOS runtimes against placeholder guest code (no game is needed for
this step), then packages them into a release folder. It prints the folder's path at the end.

## 2. Set up the Mac game from that folder

In the release folder, start `Wind Waker HD` and point setup at your game, as for any release. Start the game
once, play for a bit, and switch on the code mods you want on the device. The device's shader library is made from
the shaders this Mac's game has already seen, so a game that has been played gives a much smoother start.

## 3. Build and install on the device

**In the setup window:** hold Shift while starting Wind Waker HD (or start it with `--setup`), then choose
**Apple TV, iPhone or iPad...**. The page checks Xcode, signing, the game and your mods. Choose the kind of
device, **Build the app** (a few minutes), choose the device, then **Install on the device**.

**In Terminal**, from the release folder:

```sh
python3 tools/installer/setup.py --apple-status                    # what's ready, as JSON
python3 tools/installer/setup.py --apple-device tv                 # build and install on the Apple TV
python3 tools/installer/setup.py --apple-device iphone --apple-device-id "My iPad"
python3 tools/installer/setup.py --apple-device tv --apple-no-install   # build only
python3 tools/installer/setup.py --apple-device tv --apple-install-only # install the app built last
```

Setup won't install while the game is open on the device: save and quit it there first. Saves and settings on the
device are kept when you install a new build.

## Mods

The code mods switched on in the Mac's game are built into the app. A mod that has never run on the Mac gets its
place in memory when the build briefly starts the Mac's game. Mods on the device that aren't in the new app are
switched off when you install, and the setup page warns you first.

## Known limits

- Shaders the Mac's game hasn't met are compiled on the device when they first appear (a stutter).
- iCloud saves on the iPad need your own iCloud container, which setup doesn't set up yet.
- Provisioning profiles expire after a year: build and install again then.

Please report what you find, with the device, the setup log and what you did. How it works and what's still open:
[apple-device-installer.md](apple-device-installer.md).
