
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

#### Home Assistant host devices

`services.homeassistant.usbDevices` accepts a host path string for existing
configurations, or an object with `path` and optional Kubernetes
`hostPath.type` fields. Use `type: CharDevice` for serial radios so Kubernetes
checks that the host path resolves to a character device instead of mounting a
directory if the device path is missing. A by-id path keeps the configuration
stable across changes to `/dev/ttyUSB*` enumeration.

```yaml
services:
  homeassistant:
    usbDevices:
      skyconnect:
        path: /dev/serial/by-id/usb-device-id
        type: CharDevice
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
Firefly Service uses a different namespace or port. Set `webhookDomain` and
non-secret `config` rules in your deployment values. Create
the referenced Kubernetes Secret separately with `FIREFLY3_TOKEN`,
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
