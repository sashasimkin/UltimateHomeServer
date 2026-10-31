
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

The shared Longhorn PVC accepts optional metadata labels through
`common.storage.longhorn.labels`. For recurring backup enrollment, set
`recurring-job.longhorn.io/source: enabled` and a
`recurring-job.longhorn.io/<job-name>: enabled` label for an existing Longhorn
RecurringJob. The labels do not change the claim's storage class or access mode.

Home Assistant supports optional `services.homeassistant.dnsPolicy`,
`dnsConfig`, and `hostAliases` pod settings. Defaults preserve Kubernetes DNS
behavior. If using `dnsPolicy: None`, supply at least one DNS server in
`dnsConfig.nameservers`. Static aliases can keep a critical service resolvable
when the cluster DNS service is unavailable; keep their addresses synchronized
with the corresponding service configuration.

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

Set `services.monobankFirefly3Bot.enabled`, account/routing `config`, and either
`webhookDomain` or `webhookDomainSecretRef` (`name`/`key`). `existingSecret` must
contain `FIREFLY3_TOKEN` and `MONOBANK_TOKEN`. Set `fireflyApiUrl` for your Firefly
Service. The server uses one replica, port 8080, and `/health` probes.

Helm generates the webhook key in immutable Secret `<namePrefix>-<version>`
from `managedWebhookSecret`. `lookup` reuses its key during connected upgrades.
Change `version` to rotate and restart the server for URL registration. Retain
the previous Secret for rollback; delete obsolete versions explicitly.

Offline rendering produces a new candidate. Argo CD Applications need both
settings below to preserve stored data during comparison and sync:

```yaml
spec:
  ignoreDifferences:
    - group: ""
      kind: Secret
      jqPathExpressions:
        - 'select(.metadata.labels["app.kubernetes.io/component"] == "monobank-webhook-key") | .data'
  syncPolicy:
    syncOptions:
      - RespectIgnoreDifferences=true
```

Do not publish rendered Secret manifests. Retention annotations preserve Secrets
through Helm removal and Argo pruning/deletion.

For Cloudflare Tunnel, route the webhook hostname through
`services.cloudflared.additionalIngress` to
`http://monobank-firefly3-bot.<namespace>.svc.cluster.local:8080`.

`cronSync.enabled` runs statement polling independently of the webhook, with
PVC-backed cursors and an overlap window for deduplication. Its first run records
starting cursors without importing history. Monobank limits statement requests
to one per minute; polling several accounts takes a few minutes.

For backfills, enable `historicalImport` with `from`, configured transaction
rules, and a new `runId` per run. It leaves incremental polling cursors unchanged.

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

The reproducible multi-architecture image build for the
[`tuya-ipc-terminal` fork](https://github.com/sashasimkin/tuya-ipc-terminal) lives
in [`images/tuya-ipc-terminal`](images/tuya-ipc-terminal) and is published by
`.github/workflows/tuya-ipc-image.yml`. The Docker build pins the upstream source
commit `585cbcbea0bed19aab6ec46e9165c9090c11fc27`: the complete
[upstream PR #5](https://github.com/seydx/tuya-ipc-terminal/pull/5) plus redacted
diagnostics and capability-based discovery. Owned and shared devices are checked
for WebRTC video support without a category allowlist. Incomplete discovery
preserves that account's registry and returns failure. Update the source pin
and deployment image reference together when upgrading; consume the immutable
SHA tag and verified digest, not a mutable branch alias.
GitHub Container Registry creates newly published user-scoped packages as
private by default. After the first successful workflow run, explicitly change
the `tuya-ipc-terminal` package visibility to public before relying on anonymous
cluster pulls.

#### Tuya IPC camera streams

The `services.mediamtx` service is an opt-in RTSP server for camera streams.
Set `services.mediamtx.enabled: true` and add one entry per stream under
`services.mediamtx.paths`. MoQ is disabled by default. Set
`services.mediamtx.moq.enabled: true` to turn on its HTTP/2 listener on port
8892, HTTP/3 listener on port 8894, and native QUIC listener on port 8893.
Those ports are then added to the internal ClusterIP Service. For example, a
path can proxy an RTSP source from a Tuya IPC bridge running in the same
namespace:

```yaml
services:
  tuyaIpc:
    enabled: true
  mediamtx:
    enabled: true
    moq:
      enabled: true
    paths:
      front-door:
        source: rtsp://tuya-ipc-terminal.home-media.svc.cluster.local:8554/CameraName/hd
        rtspTransport: tcp
```

MediaMTX paths are passed through to its configuration, so they can also use
MediaMTX hooks such as `runOnInit` to publish an FFmpeg-processed stream. Set
`services.mediamtx.ffmpeg.enabled: true` to use the official `-ffmpeg` image
variant for the configured MediaMTX version. For example, a video-only restream
can discard source audio without re-encoding the video:

```yaml
services:
  mediamtx:
    enabled: true
    ffmpeg:
      enabled: true
    paths:
      baby-monitor:
        runOnInit: >-
          ffmpeg -hide_banner -loglevel warning -rtsp_transport tcp
          -i rtsp://tuya-ipc-terminal.home-media.svc.cluster.local:8554/Baby_Monitor
          -map 0:v:0 -c:v copy -an -f rtsp -rtsp_transport tcp
          rtsp://127.0.0.1:$RTSP_PORT/$MTX_PATH
        runOnInitRestart: yes
```

The `-ffmpeg` image adds FFmpeg to the MediaMTX container; MediaMTX itself
does not transcode tracks. `-c:v copy -an` preserves source video and drops
audio. To transcode audio instead, map an audio track and set `-c:a aac`.

MediaMTX WebRTC is independently opt-in with
`services.mediamtx.webrtc.enabled: true`. The chart opens the WebRTC HTTP
listener and ICE UDP listener on the ClusterIP Service. To publish the HTTP
reader, also set `webrtc.ingress.enabled`, its TLS host and certificate, and a
non-empty `sourceRanges` allowlist. The chart creates an HTTPS IngressRoute and
an `IngressRouteUDP` for the configured ICE entry point; the cluster's Traefik
HelmChartConfig must expose that UDP entry point, and
`webrtc.additionalHosts` must contain an address clients can reach on the ICE
port. Keep the HTTP reader restricted to trusted networks because MediaMTX's
default read permissions are anonymous. Browser support for H.265 WebRTC varies
by browser and device.

MediaMTX exposes its enabled listeners on an internal ClusterIP Service. Its
API, metrics, HLS, RTMP, and SRT endpoints are disabled by default. When MoQ is
enabled, its generated certificate is stored in a writable pod volume. Mount
the ConfigMap as a directory; changes to it trigger a Deployment rollout.

Enable `services.tuyaIpc` to deploy the bridge with persistent pairing state.
Use `bin/tuya-ipc` to pair cameras and list RTSP endpoints. Configure paths in
`services.mediamtx.paths`.
