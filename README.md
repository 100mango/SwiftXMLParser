# SwiftXMLParser

A Foundation-based XML-to-dictionary and dictionary-to-XML utility written in
Swift. Supports Swift Package Manager and retains its CocoaPods and Xcode
project layouts.

## Installation

### Swift Package Manager

Requires Swift 5.3 or later. In Xcode, choose **File > Add Package Dependencies**,
enter `https://github.com/100mango/SwiftXMLParser.git`, and add the
`SwiftXMLParser` product to your target. Select version `0.2.0` or later.

For a `Package.swift` dependency:

```swift
.package(url: "https://github.com/100mango/SwiftXMLParser.git", from: "0.2.0")
```

Then add `.product(name: "SwiftXMLParser", package: "SwiftXMLParser")` to your
target's `dependencies` and use `import SwiftXMLParser`.

The package has no third-party dependencies or bundled resources. Its Apple
platform declarations preserve the existing podspec's deployment minimums:
iOS 8.0, macOS 10.9, tvOS 9.0, and watchOS 2.0. The selected Swift/Xcode SDK may
impose newer minimums. Linux uses FoundationXML for XML parsing.

### CocoaPods

The existing `SwiftXMLParser.podspec` and `Sources/` layout are retained. To use
the repository directly from a Podfile:

```ruby
pod 'SwiftXMLParser', :git => 'https://github.com/100mango/SwiftXMLParser.git', :tag => '0.2.0'
```

## Usage

```swift
import SwiftXMLParser

let result = SwiftXMLParser.makeDic(
    string: "<root><item>one</item><item>two</item></root>"
)
// ["root": ["item": ["one", "two"]]]

let xml = SwiftXMLParser.makeXML(dic: ["root": ["item": "value"]])
// <root><item><![CDATA[value]]></item></root>
```

Repeated elements become arrays. By default, attributes are stored under
`_XMLAttributes`; set an instance's `attributesAsStandaloneDic` to `false` to
place attributes alongside its child keys. Text on an element that also has
attributes or children uses the instance's `TextKey`. Invalid XML returns `nil`. CDATA contents are read as text, including their
whitespace.

## Model limitations

This is a dictionary convenience model for element-only XML, not a lossless
implementation of the full XML document model. Mixed content such as
`<root>before<child>inside</child>after</root>` is unsupported: the legacy parser
can combine the leading text with the child value, and dictionary keys cannot
preserve the original ordering of text and child elements. Avoid mixed content
when parsing or round-tripping documents. Empty elements without attributes are
omitted. The serializer expects valid XML element/attribute names and does not
escape a `]]>` sequence inside a value.

## Testing

Run the full package suite on macOS or Linux:

```sh
swift package describe
swift test
swift test -c release
bash scripts/test-consumer.sh
```

The `SwiftPM` workflow runs Debug and Release tests and an independent
consuming package on standard Linux and macOS runners. On a GitHub release,
the consumer resolves the exact published tag and verifies its commit revision. It does not sign code or upload build artifacts. Tests cover
repeated and nested elements, attribute modes, malformed input, parser reuse,
serialization, CDATA, Unicode/BOM input, invalid document variants, and
element-only round trips, alongside the original tests.

## License

MIT. See [LICENSE](LICENSE).
