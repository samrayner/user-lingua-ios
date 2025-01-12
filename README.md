# UserLingua for iOS (alpha)

UserLingua is an SDK for iOS that allows anyone to preview and suggest changes to your app copy and translations without touching your View code.

https://github.com/user-attachments/assets/7c5b560b-cfd7-4860-8bd6-ae4678c03a37

> [!WARNING]
UserLingua is a work in progress and should not be used in Production

## Features

- Automatic detection of localized string keys
- As-you-type preview of alternative strings
- Language switching with live preview
- String suggestion diffing
- Dark mode and Dynamic Type preview
- [Coming soon] On-device machine translation suggestions
- [Coming soon] Submission of strings for review
- [Coming soon] Comment threads on strings

## Instegration

Package.swift
```swift
dependencies: [
  .package(url: "https://github.com/samrayner/user-lingua-ios", branch: "main")
]
```

Initialization
```swift
import UserLingua

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UserLinguaClient.shared.configure(
            UserLinguaConfiguration(
                automaticallyOptInTextViews: true,
                appSupportsDynamicType: true,
                appSupportsDarkMode: true,
                baseLocale: Locale.current
            )
        )
        UserLinguaClient.shared.enable()
        return true
    }
}
```


SwiftUI View opt-in (no code required for UIViews)
```swift
import UserLingua

@CopyEditable
struct ContentView: View {
  Text("my_localized_string_key")
}
```

## Modules

| Module           | Description                           |
|------------------|---------------------------------------|
| UserLingua       | Umbrella module for all modules       |
| UserLinguaCore   | Everything except Extensions          |
| UserLinguaAuto   | Extensions to SwiftUI and UIKit types |
| UserLinguaMacros | The ContentEditable macro for SwiftUI |

## Support

iOS 16+ minimum target. Supports UIKit views with no code and SwiftUI views by applying a macro.

## Contributing

> git clone https://github.com/samrayner/user-lingua-ios
> cd user-lingua-ios
> ./post-clone

## Generate XCFrameworks

> ./build
