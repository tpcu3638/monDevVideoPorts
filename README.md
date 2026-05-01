# mondevvideoports

Polls `/dev/video*` ports on a schedule and pushes an [ntfy](https://ntfy.sh) notification when one disappears.

## Quick install (binary release)

On the target machine:

```bash
git clone https://github.com/tpcu3638/monDevVideoPorts.git
cd monDevVideoPorts
sudo ./install.sh
```

The installer prompts for ntfy slug, endpoint, ports, service user, and release tag, then:

1. Downloads the matching `linux-x64` / `linux-arm64` binary from the latest GitHub Release
2. Installs it to `/opt/mondevvideoports/dist/build`
3. Writes `/etc/systemd/system/mondevvideoports.service`
4. Runs `systemctl daemon-reload` and `enable` (and optionally `start`)

## Reconfigure later

```bash
sudo ./adjust.sh
```

Reads the current values from the installed unit file, prompts for new ones (Enter keeps the existing value), rewrites the unit, `daemon-reload`s, and offers to restart.

## Non-interactive download

`download.sh` is the lower-level script the installer wraps. Use it directly in automation:

```bash
sudo NTFY_SLUG=abc123 PORTS=video0,video1 START_SERVICE=1 ./download.sh
```

### Environment variables

| Var               | Default                          | Notes                                                        |
| ----------------- | -------------------------------- | ------------------------------------------------------------ |
| `NTFY_SLUG`       | —                                | Required for a real install; otherwise placeholder is used   |
| `PORTS`           | —                                | Comma-separated, e.g. `video0,video1`                        |
| `NTFY_ENDPOINT`   | `https://ntfy.sh`                | Custom ntfy server                                           |
| `SERVICE_USER`    | `root`                           | Must be in the `video` group if not root                     |
| `TAG`             | `latest`                         | Release tag to download                                      |
| `INSTALL_DIR`     | `/opt/mondevvideoports/dist`     | Where the binary lands                                       |
| `WORK_DIR`        | parent of `INSTALL_DIR`          | systemd `WorkingDirectory`                                   |
| `INSTALL_SERVICE` | `1`                              | Set to `0` to skip systemd unit installation                 |
| `START_SERVICE`   | `0`                              | Set to `1` to `systemctl start` after install                |
| `EXEC_ARGS`       | derived from above               | Override the full args passed to the binary                  |
| `GITHUB_TOKEN`    | —                                | Used for private repos or to avoid API rate limits           |

## Building from source

```bash
bun install
bun run index.ts -s YOUR_SLUG -p video0,video1
```

CLI flags:

- `-s, --slug` — ntfy slug (required)
- `-p, --ports` — comma-separated `/dev/video*` names without the `/dev/` prefix (required)
- `-u, --notifyEndpoint` — ntfy endpoint (default `https://ntfy.sh`)

## Releases

`.github/workflows/build.yml` builds `bun-linux-x64` and `bun-linux-arm64` standalone binaries via `bun build --compile`.

- **Tag push** (`git tag v0.1.0 && git push origin v0.1.0`) — builds and publishes a GitHub Release with both binaries attached.
- **Manual dispatch** — Actions UI → "Build and Release" → Run workflow. Provide a `tag` input to also publish a release; leave it empty to just build artifacts.

## Files

- `index.ts` — the monitor itself
- `install.sh` — interactive installer (wraps `download.sh`)
- `adjust.sh` — interactive reconfigurator for the systemd unit
- `download.sh` — non-interactive binary fetcher + systemd unit writer
- `mondevvideoports.service` — reference unit file (the real one is generated at install time)
- `.github/workflows/build.yml` — CI build & release pipeline
