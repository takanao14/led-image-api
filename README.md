# led-image-api

`led-image-api` is the canonical Protocol Buffers definition for sending images
to the LED display service. It also publishes generated Go bindings.

## API

The API is defined in
[`api/proto/image/v1/image_service.proto`](api/proto/image/v1/image_service.proto).
`ImageService.SendImage` accepts encoded image bytes, their MIME type, a display
duration, and an optional display mode. Clients can alternatively request a
minimum number of horizontal scroll cycles and a minimum main display time.

Supported image formats are PNG, JPEG, GIF, and PPM/PNM. When `display_mode` is
`DISPLAY_MODE_UNSPECIFIED`, the service infers the mode from `mime_type`: PPM
scrolls and other supported formats display statically.

When `scroll_cycles` is positive, a supporting server ignores
`duration_seconds` and scrolls until both `scroll_cycles` and
`min_display_seconds` are satisfied. Worker deadlines and shutdown may still
interrupt playback. Clients may send a positive `duration_seconds` alongside
cycle options as a fallback for older servers, which ignore the new fields and
therefore cannot guarantee the cycle count or minimum display time.

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
3. Commit the Proto and generated bindings together and open a PR targeting
   `main`. The required `check` job also checks compatibility against the PR's
   base commit. Merge only after it passes; no approval is required.
4. After the PR is merged, tag the merged commit on `main` with a SemVer tag
   such as `v0.2.0` and push the tag.
5. Update `slack-bot` to the new Go module tag and run its CI checks.
6. Update the `led-service2/led-image-api` submodule to the same tag and run its
   CI checks.

Use a patch release for documentation or compatible implementation-only
changes, a minor release for backward-compatible API additions, and a major
release for breaking API changes. Before the project reaches `v1.0.0`, breaking
changes require an explicit release note and coordinated updates to both
consumers.

The release version does not exempt a change from compatibility checks. For an
intentional incompatible API design, add a new Proto package (for example,
`image.v2`) and its generated bindings while retaining `image.v1`. Document the
migration in the release notes and coordinate both consumers before retiring
the old API. Removing or changing the existing API in place remains blocked by
the `FILE` compatibility check, even for a pre-1.0 or major release; do not add
routine skips or relax `buf.yaml`. A Go module release at v2 or above also
requires the `/v2` (or later major) module/import paths; a Proto package version
and a Go module major version are separate decisions.

`main` requires PRs and the GitHub Actions `check` result, with the branch up to
date before merging. Deletion and force pushes are blocked, with no owner or
Bot bypass. Use the same PR process for automation and maintenance changes.
