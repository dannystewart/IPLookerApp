# IPLooker

A native macOS and iOS app for IP address geolocation and network intelligence. Enter any IPv4 or IPv6 address and instantly see location, network, and security details aggregated from multiple sources.

## Features

- **Multi-source lookups** — Queries up to 7 independent APIs in parallel and aggregates results for accuracy
- **Aggregated results** — Uses consensus across sources to surface the most reliable data
- **Per-source breakdown** — Expandable view showing each source's individual response
- **Your public IP** — One tap to detect and look up your current public IP address
- **Clipboard detection** — On macOS, automatically detects IP addresses on the clipboard and pre-fills the search field
- **Security flags** — Identifies VPNs, proxies, Tor exit nodes, datacenters, and anonymous IPs
- **Network details** — ISP, organization, ASN, and IP range information where available
- **Bring your own keys** — Add your own API keys in Settings for higher rate limits

## Installation

### Homebrew

```bash
brew install dannystewart/apps/iplooker
```

### Direct download

Download the latest `.dmg` from the [Releases](https://github.com/dannystewart/IPLookerApp/releases) page.

## Requirements

- **macOS**: Tahoe (macOS 26) or later
- **iOS**: iOS 26 or later

## Data Sources

IPLooker queries the following services:

| Source | Free tier | API key required |
| --- | --- | --- |
| [ipapi.co](https://ipapi.co) | Yes | No |
| [ipapi.is](https://ipapi.is) | Yes | Optional |
| [ipdata.co](https://ipdata.co) | Yes | Optional |
| [ipgeolocation.io](https://ipgeolocation.io) | Yes | Optional |
| [ipinfo.io](https://ipinfo.io) | Yes | Optional |
| [iplocate.io](https://iplocate.io) | Yes | Optional |
| [ipregistry.co](https://ipregistry.co) | No | Yes |

The app ships with embedded API keys so it works out of the box. You can provide your own keys in **Settings** to increase rate limits.

## Building from Source

Clone and open `IPLooker.xcodeproj` in Xcode.

API keys are loaded from a `Secrets.xcconfig` file (not included in the repository). Create one at the project root with the following keys if you want all sources to be active:

```text
IPAPI_IS_KEY = your_key_here
IPDATA_KEY = your_key_here
IPGEOLOCATION_KEY = your_key_here
IPINFO_KEY = your_key_here
IPLOCATE_KEY = your_key_here
```

Sources without a key will be skipped; lookups still work using the sources that don't require one.

## Related

- [iplooker](https://github.com/dannystewart/iplooker) — The original Python CLI tool this app is based on
