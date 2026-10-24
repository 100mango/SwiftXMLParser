#!/usr/bin/env bash
set -euo pipefail
repo_root=$(cd "$(dirname "$0")/.." && pwd)
consumer_dir=$(mktemp -d "${TMPDIR:-/tmp}/SwiftXMLParserConsumer.XXXXXX")
trap 'rm -rf "$consumer_dir"' EXIT
version=${PACKAGE_VERSION:-}
python3 - "$repo_root" "$consumer_dir" "$version" <<'PY'
import json, pathlib, re, sys
root, destination, version = sys.argv[1:]
if version and not re.fullmatch(r"\d+\.\d+\.\d+", version):
    raise SystemExit("Expected a semantic version tag")
dependency = '.package(url: "https://github.com/100mango/SwiftXMLParser.git", .exact("' + version + '"))' if version else '.package(path: ' + json.dumps(root, ensure_ascii=False) + ')'
p = pathlib.Path(destination)
(p / 'Sources/Consumer').mkdir(parents=True)
(p / 'Package.swift').write_text('''// swift-tools-version:5.3
import PackageDescription
let package = Package(
    name: "Consumer",
    products: [.executable(name: "Consumer", targets: ["Consumer"])],
    dependencies: [''' + dependency + '''],
    targets: [.target(name: "Consumer", dependencies: [.product(name: "SwiftXMLParser", package: "SwiftXMLParser")])]
)
''')
PY
cat > "$consumer_dir/Sources/Consumer/main.swift" <<'SWIFT'
import Foundation
import SwiftXMLParser

let original: [String: Any] = ["root": ["_XMLAttributes": ["id": "consumer"], "item": ["one", "  two & <three>  ", "你好 😀"]]]
let xml = SwiftXMLParser.makeXML(dic: original)
guard let result = SwiftXMLParser.makeDic(string: xml) else { fatalError("Serialized XML did not parse") }
precondition(NSDictionary(dictionary: result) == NSDictionary(dictionary: original))
let parser = SwiftXMLParser()
parser.attributesAsStandaloneDic = false
let flat = parser.makeDic(data: Data("<item id=\"1\">value</item>".utf8))
let item = flat?["item"] as? [String: Any]
precondition(item?["id"] as? String == "1")
precondition(item?[parser.TextKey] as? String == "value")
precondition(SwiftXMLParser.makeDic(string: "<root><item></root>") == nil)
precondition(SwiftXMLParser.makeDic(string: " \n\t") == nil)
print("External consumer passed: imports, parsing, attributes, CDATA round-trip, and invalid input")
SWIFT
swift package --package-path "$consumer_dir" resolve
if [[ -n "$version" ]]; then
    python3 - "$consumer_dir/Package.resolved" "$version" "${EXPECTED_REVISION:-}" <<'PY'
import json, sys
path, version, expected = sys.argv[1:]
data = json.load(open(path))
pins = data.get('pins', data.get('object', {}).get('pins', []))
pin = next(p for p in pins if p.get('identity', p.get('package', '')).lower() == 'swiftxmlparser')
assert pin['state']['version'] == version, pin
if expected:
    assert pin['state']['revision'] == expected, pin
print('Verified remote version and revision:', pin['state'])
PY
fi
swift run --package-path "$consumer_dir" --configuration release --jobs 2 Consumer
