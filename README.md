
<p align="center">
  <img src=".github/img/header.png" alt="Banner" width="100%">
</p>

<p align="center">
  <!-- Add shields from https://shields.io/ -->
  <a href="https://github.com/sponsors/M4NU5">
    <img alt="GitHub Sponsors" src="https://img.shields.io/github/sponsors/M4NU5">
  </a>
  <img alt="GitHub Workflow Status" src="https://img.shields.io/github/actions/workflow/status/TechSquidTV/UltimateHomeServer/commitlint.yml">
</p>


<p align="center">
  <a href="https://ultimatehomeserver.com/"> UltimateHomeServer.com</a>
</p>

<p align="center">
  Deploy the ultimate home server stack with <a href="https://k3s.io/"> K3s </a> and <a href="https://helm.sh/">Helm</a>.
  Created by [KyleTryon](https://github.com/KyleTryon)
  Perfected by [M4NU5](https://github.com/M4NU5)
</p>


## Getting Started

Here are some useful resources to get you started:
- [TRasSH-Guides](https://trash-guides.info/)
- [ultimatehomeserver](https://www.ultimatehomeserver.com/docs/)

---

## Services
### Dashboard
- 🏠 [`homepage`](https://gethomepage.dev/): A customizable start page for your home server.
### Media
- 🪼 [`jellyfin`](https://jellyfin.org/): The free software media system. (Recommended)
- 📹 [`mediamtx`](https://github.com/bluenviron/mediamtx): Optional RTSP server/proxy for publishing camera streams.
- 📺 [`plex`](https://www.plex.tv/): A personal media server. (Not advised, Plex was not designed to container environments like this)
- 📖 [`kavita`](https://www.kavitareader.com/): A modern reading server for manga, comics, and books.
### Media Management
- ⏺️ [`sonarr`](https://sonarr.tv/): An automated TV show download and management system.
- 🎬 [`radarr`](https://radarr.video/): An automated movie download and management system.
- 🐯 [`prowlarr`](https://github.com/Prowlarr/Prowlarr): Manage indexers for your *arr stack.
- [`bazarr`](https://www.bazarr.media/): Automated subtitles for sonarr & radarr.
- [`unpackerr`](https://unpackerr.zip/): Extract completed Sonarr downloads from archives before import.
- 👁️ [`seerr`](https://seerr.dev/): A request management and media discovery tool for Jellyfin, Plex and Emby.
- 📊 [`tautulli`](https://tautulli.com/): Monitor your Plex Media Server.
- 🐇 [`autobrr`](https://autobrr.com/): Automatically search and download from IRC.
### Download
- ⏬ [`qbittorrent`](https://www.qbittorrent.org/): A lightweight and feature-rich torrent client.
- 📰 [`sabnzbd`](https://sabnzbd.org/): The automated Usenet download tool.
### Network
- 🌐 [`traefik`](https://doc.traefik.io/): A kubernetes native high-performance web server and reverse proxy.
- ☁️ [`cloudflared`](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/): Expose services running on your home network to the internet.
### Messaging
- 💬 [`thelounge`](https://thelounge.chat/): A modern, self-hosted web IRC client.
### Notifications
- 📲 [`gotify`](https://gotify.net/docs/plugin): Self-hosted push notifications.
- 📲 [`apprise`](https://github.com/caronc/apprise-api): Multi-platform push notifications.
### Finance
- 🏦 [`monobank-firefly3-bot`](https://github.com/sashasimkin/monobank-firefly3-bot): Import Monobank transactions into Firefly III through a webhook.

#### Home Assistant USB passthrough

Set `services.homeassistant.usbPassthrough: true` to mount the node's `/dev`
directory into Home Assistant at `/dev`. This exposes all host device nodes,
not only USB devices, and lets udev-created USB nodes and by-id links appear in
the container while Home Assistant is running. With this flag enabled, any
`usbDevices` entry targeting `/dev` is skipped so a per-device mount cannot
mask the live device tree. Other entries such as `/run/dbus` remain mounted.
The flag is opt-in and defaults to false.

```yaml
services:
  homeassistant:
    usbPassthrough: true
    usbDevices:
      dbus: /run/dbus
```

#### Apprise persistence and credentials

Apprise uses `/config` for its persistent API configuration. Deployments can
opt into a PVC with `services.apprise.persistence.use` and
`services.apprise.persistence.claimName`; otherwise the legacy `config`
hostPath is used. An existing deployment-owned Secret can be mounted read-only
with `services.apprise.existingSecret`. The chart neither creates that Secret
nor interprets its contents, so credentials remain outside chart values and
logs. `attachSize` defaults to `0`; a deployment enabling attachments must
provide an appropriate writable attachment volume separately.

#### Unpackerr archive extraction

Unpackerr is an opt-in worker for extracting archived downloads tracked by
Sonarr. Set `services.unpackerr.enabled`, provide the Sonarr URL and an existing
Secret containing its API key, and mount the download filesystem at the same
path Sonarr reports for completed downloads. `downloads.hostPath` is the node
path and `downloads.mountPath` is the path visible inside both applications.
The chart does not create the API Secret or expose a web service. The selected
node must have the configured host path, with write permissions for the
Unpackerr process.

#### Monobank to Firefly III webhook

The `monobankFirefly3Bot` service is opt-in. Its `fireflyApiUrl` defaults to
the in-cluster Firefly Service URL in namespace `home-media`; change it if your
Firefly Service uses a different namespace or port. Set exactly one of
`webhookDomain` (literal hostname) or `webhookDomainSecretRef` (`name` and `key`)
in your deployment values, plus non-secret `config` rules. The referenced
Secret must exist in the application namespace. `podAnnotations` can attach
caller-specific annotations, such as a Secret reloader trigger. Create the
referenced Kubernetes Secret separately with `FIREFLY3_TOKEN`,
`MONOBANK_TOKEN`, and `MONOBANK_WEBHOOK_SECRET`; the chart does not create or
store these credentials. The bot listens on port 8080 and exposes `/health` for
probes. For a Cloudflare Tunnel, add a `services.cloudflared.additionalIngress`
entry routing the webhook hostname to
`http://monobank-firefly3-bot.<namespace>.svc.cluster.local:8080`.

The separate `services.monobankFirefly3Bot.cronSync` option polls the mapped
Monobank accounts using statement APIs, so it can run while the webhook server
is disabled. Its checkpoint is stored on a chart-managed PVC; configure a
storage class if the cluster has no default. `config.import_unmatched_transactions`
can import unmatched new operations under an `Uncategorized` category until
merchant/MCC rules are ready. The poller overlaps its saved cursor to catch
late statements and deduplicates through Firefly transaction external IDs.
Monobank limits statement requests to one per minute, so a run for several
accounts lasts a few minutes even when the schedule is hourly.
On the first run, the job only records the starting cursor for each account;
it leaves prior transactions untouched. Subsequent runs import new operations.

`historicalImport` creates a one-off Job when enabled. It requires a start date,
a unique `runId`, and configured transaction rules; leave it disabled until the
MCC and refund rules have been reviewed. Change `runId` for each intentional
backfill. A history import may take time because it is chunked to comply with
Monobank's statement-window and rate limits.
### Automation
- 🦅 [`huginn`](https://github.com/huginn/huginn): Create agents that monitor and act on your behalf.
- 🔄 [`changedetection.io`](https://changedetection.io): Monitor web pages for changes.
### Development
- 🎭 [`playwright`](https://playwright.dev/): A headless browser automator.

---

## Dedicated persistence

Define opt-in PVCs in `common.storage.persistentVolumes`; enable a service with
`services.<name>.persistence.use: true`. Each PVC can define `migration` with
source paths; the chart creates one copy Job per enabled migration. Existing
services keep using `longhorn-volv-pvc` until switched.

## CLI

View the [`uhs-cli` repository](https://github.com/TechSquidTV/uhs-cli) for more information.

---

## Thanks
<p align="center">
  Made with ❤️, built on the backs of <a href="https://wiki.servarr.com/">*arr stack</a>, <a href="https://www.linuxserver.io/"> linuxserver.io</a>, and more awesome open-source projects.
</p>

### Tuya IPC terminal image

The reproducible multi-architecture image build for the upstream
[`tuya-ipc-terminal`](https://github.com/seydx/tuya-ipc-terminal) binary lives
in [`images/tuya-ipc-terminal`](images/tuya-ipc-terminal) and is published by
`.github/workflows/tuya-ipc-image.yml`. The Docker build pins the upstream source
commit; update that pin and the image tag together when upgrading.
GitHub Container Registry creates newly published user-scoped packages as
private by default. After the first successful workflow run, explicitly change
the `tuya-ipc-terminal` package visibility to public before relying on anonymous
cluster pulls.

#### Tuya IPC camera streams

The `services.mediamtx` service is an opt-in RTSP server for camera streams.
Set `services.mediamtx.enabled: true` and add one entry per stream under
`services.mediamtx.paths`. For example, a path can proxy an RTSP source from a
Tuya IPC bridge running in the same namespace:

```yaml
services:
  mediamtx:
    enabled: true
    paths:
      front-door:
        source: rtsp://tuya-ipc-terminal.home-media.svc.cluster.local:8554/CameraName/hd
        rtspTransport: tcp
```

MediaMTX exposes RTSP on an internal ClusterIP Service; its API, metrics,
WebRTC, HLS, RTMP, and SRT endpoints are disabled. Deploy the Tuya IPC bridge
separately with the public `ghcr.io/sashasimkin/tuya-ipc-terminal` image. The
image is built for `linux/amd64` and `linux/arm64`. Pull requests run a
non-publishing build; pushes to a feature branch publish a `prerelease` alias
and immutable `sha-<commit>` tags to the package owned by that repository.
Push a prerelease tag such as `v0.1.0-rc.1` to build a versioned image before
merging. Main-branch builds publish the pinned upstream version tag.
