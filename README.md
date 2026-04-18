# Setup
#### Look inside `Repo Setup - DELETEME`
Run `setup_repository.sh`. (You may need to do `chmod +x`)  
You can also use the JSON ruleset file there for GitHub.

# __PACKAGENAME__
A template for Swift packages.  
Made with 💜 by [__USERNAME__](__PERSONALWEBSITE__).

![A GIF showing off the demonstration app](__PERSONALWEBSITE__)

## Installation
__PACKAGENAME__ is on the [Swift Package Index](https://swiftpackageindex.com/__GITHUBUSERNAME__/__PACKAGENAME__). Install it using the [Swift Package Manager](https://docs.swift.org/swiftpm/documentation/packagemanagerdocs/).

In Xcode, go to File → Add Package Dependencies…  
Then, enter the following URL and select “Add Package.”
```
https://github.com/__GITHUBUSERNAME__/__PACKAGENAME__
```

## Usage
After importing __PACKAGENAME__, you can do lots of cool stuff with it:
1. Use case one
2. Use case two

### Use case one
```swift
// some code
```

### Use case two
```swift
// some more code
```

### Example
```swift
// a more fully-fledged example
```

## Contributing
All contributions are welcome. Please open a pull request and give a clear description of your changes.

### Building
In order to keep the `.xcodeproj` of the demo app clean, please run the `devsetup.sh` script before building the app, as it configures local signing settings required for the demo app to build. It will create a file called `DeveloperSettings.xcconfig` which will not be committed to GitHub.

You may need to run `chmod +x devsetup.sh` to make the script executable.
