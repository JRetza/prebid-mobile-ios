[![Build Status](https://api.travis-ci.org/prebid/prebid-mobile-ios.svg?branch=master)](https://travis-ci.org/prebid/prebid-mobile-ios)

# Prebid Mobile Adsolutions iOS SDK

Get started with Prebid Mobile by contacting Adsolutions [here](https://www.adsolutions.com)

## Use Cocoapods?

Easily include the Prebid Mobile SDK for your primary ad server in your Podfile/

```
platform :ios, '8.0'

target 'MyAmazingApp' do 
    pod 'PrebidMobileAdsolutions', '~> 0.5.7'
end
```

## Build framework from source

Build Prebid Mobile from source code. After cloning the repo, from the root directory run

```
./scripts/buildPrebidMobile.sh
```

to output the Prebid Mobile framework.


## Test Prebid Mobile

Run the test script to run unit tests and integration tests.

```
./scripts/testPrebidMobile.sh
```
