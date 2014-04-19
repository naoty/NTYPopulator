# NTYPopulator

[![Version](http://cocoapod-badges.herokuapp.com/v/NTYPopulator/badge.png)](http://cocoadocs.org/docsets/NTYPopulator)
[![Platform](http://cocoapod-badges.herokuapp.com/p/NTYPopulator/badge.png)](http://cocoadocs.org/docsets/NTYPopulator)

## Installation

NTYPopulator is available through [CocoaPods](http://cocoapods.org), to install it simply add the following line to your Podfile:

```ruby
platform :ios
pod "NTYPopulator"
```

## Usage

```objective-c
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[NTYPopulator new] run];
    return YES;
}
```

`-init` method initializes an instance with the URL of `Model.momd` and `$(CFBundleName).sqlite`. You can also specify these URLs by `-initWithModelURL:sqliteURL:`.

`-run` method populates seed data at `seeds/*.csv` at the application resource bundle. The filename is used to look up an entity name. For example, seed data at `seeds/user.csv` is populated into `User` entity. You can also specify the URL of seed data by `-runWithSeedFileURL:`.
