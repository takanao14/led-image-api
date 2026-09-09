# led-image-api

`led-image-api` is the canonical Protocol Buffers definition for sending images
to the LED display service. It also publishes generated Go bindings.

## API

The API is defined in
[`api/proto/image/v1/image_service.proto`](api/proto/image/v1/image_service.proto).
`ImageService.SendImage` accepts encoded image bytes, their MIME type, a display
duration, and an optional display mode.

Supported image formats are PNG, JPEG, GIF, and PPM/PNM. When `display_mode` is
`DISPLAY_MODE_UNSPECIFIED`, the service infers the mode from `mime_type`: PPM
scrolls and other supported formats display statically.

## Consumers

The two current consumers intentionally use language-appropriate distribution
methods. Both must be updated to the same API release.

### Go: slack-bot

The Go client imports the generated bindings as a versioned Go module:

```go
import imagev1 "github.com/takanao14/led-image-api/gen/go/image/v1"
```

Install or update it with:

```sh
go get github.com/takanao14/led-image-api@vX.Y.Z
go mod tidy
```

### Rust: led-service2

The Rust service pins this repository as the `led-image-api` Git submodule and
generates Rust bindings from the Proto file during its Cargo build:

```sh
git submodule update --init --recursive
git -C led-image-api fetch --tags
git -C led-image-api checkout vX.Y.Z
git add led-image-api
```

This repository does not currently publish generated Rust bindings.

## Development

Requirements:

- Go version declared in `go.mod`
- [Buf CLI](https://buf.build/docs/cli/)

The code-generation plugin versions are pinned in `buf.gen.yaml` and are
downloaded by Buf as needed.

```sh
make format     # Format Proto files
make lint       # Run Buf lint
make generate   # Regenerate Go bindings
make test       # Compile and test Go packages
make breaking   # Compare the API with origin/main
make check      # Run non-mutating local checks
```

Generated files under `gen/go` are committed. Never edit them manually.

## Release process

1. Update the Proto definition without reusing or renumbering existing fields.
2. Run `make format`, `make generate`, and `make check`.
3. Commit the Proto and generated bindings together.
4. Tag the API repository with a SemVer tag such as `v0.2.0` and push it.
5. Update `slack-bot` to the new Go module tag and run its CI checks.
6. Update the `led-service2/led-image-api` submodule to the same tag and run its
   CI checks.

Use a patch release for documentation or compatible implementation-only
changes, a minor release for backward-compatible API additions, and a major
release for breaking API changes. Before the project reaches `v1.0.0`, breaking
changes require an explicit release note and coordinated updates to both
consumers.
