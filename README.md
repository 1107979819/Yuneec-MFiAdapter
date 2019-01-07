# Yuneec-MFiAdapter

This repo contains all the pieces needed to talk to the ST10C Remote Controller.

An example usage of these frameworks can be found in [YUNEEC/MFiExample](https://github.com/YUNEEC/MFiExample/).

## Frameworks

In an iOS app, the frameworks below need to be added to the "Embedded Binaries":

   - `BaseFramework`
   - `CocoaAsyncSocket`
   - `FFMpegDecoder`
   - `FFMpegDemuxer`
   - `FFMpegLowDelayDecoder`
   - `FFMpegLowDelayDemuxer`
   - `MediaBase`
   - `MFiAdapter`
   - `YuneecDataTransferManager`
   - `YuneecMFiDataTransfer`
   - `YuneecRemoteControllerSDK`
   - `YuneecWifiDataTransfer`

### Use Carthage to get the framework

To use the MFiAdapter in your iOS application, you can pull in this framework using [Carthage](https://github.com/Carthage/Carthage).

To install carthage, it's easiest to use [Homebrew](https://brew.sh/):

```
brew install carthage
```

Then to add the framework, create the file `Cartfile` in your app's repository with below's content:

```
# Require the iOS framework of Yuneec-MFiAdapter
github "YUNEEC/Yuneec-MFiAdapter" "master"
```

Then, to pull in the library and build it, run Carthage in your app's repository:

```
carthage update
```

This command also needs to be re-run if you want to udpate the framework.  

Or create the file `Cartfile.resolved` in your app's repository with below content:

```
# Require the iOS framework of Yuneec-MFiAdapter
github "YUNEEC/Yuneec-MFiAdapter" "c555d9fdc73d364a29653cd7dd9701d639403064"
```

Then, to pull in the library and build it, run Carthage in your app's repository:

```
carthage bootstrap --platform ios --use-ssh
```
