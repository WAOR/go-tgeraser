# go-tgeraser

Go implementation of [TgEraser](https://github.com/en9inerd/tgeraser) - a tool that deletes all your messages from a chat, channel, or conversation on Telegram without requiring admin privileges.

## Installation

### Homebrew (macOS / Linux)

```
brew install WAOR/tap/tgeraser
```

### Install script (Linux / macOS)

```
curl -fsSL https://raw.githubusercontent.com/WAOR/go-tgeraser/master/scripts/install.sh | sh
```

Detects OS/arch, verifies SHA256, installs to `/usr/local/bin`. Override with env vars:

```
curl -fsSL https://raw.githubusercontent.com/WAOR/go-tgeraser/master/scripts/install.sh | VERSION=1.2.3 INSTALL_DIR=$HOME/.local/bin sh
```

### Pre-built binaries

Download from the [Releases](https://github.com/WAOR/go-tgeraser/releases) page.

### From source

```
go install github.com/WAOR/go-tgeraser/cmd/tgeraser@latest
```

## Configuration

You'll need `api_id` and `api_hash`, which you can obtain from [my.telegram.org](https://my.telegram.org/auth?to=apps).

There are three ways to provide credentials:
1. **Environment variables**: `TG_API_ID` and `TG_API_HASH`
2. **Credentials file**: `~/.tgeraser/credentials.json`
3. **Interactive prompt**: The tool will prompt you on first run and optionally save to the credentials file

Credentials file format:
```json
{
    "api_id": 111111,
    "api_hash": "abcdef1234567890abcdef1234567890"
}
```

## Usage

```
tgeraser [flags]

Flags:
    -d, --directory PATH        Session storage directory (default: ~/.tgeraser/)
    --session NAME              Session name
    --entity-type TYPE          Entity type: any, chat, channel, user (default: chat)
    -p, --peers PEER_ID         Comma-separated peer IDs or usernames
    -l, --limit NUM             Number of recent chats to show
    -w, --wipe-everything       Delete messages from all entities of the specified type
    --delete-conversation       Delete entire conversation (user peers only)
    -o, --older-than STRING     Delete messages older than duration (e.g., "3*days", "5*hours")
    -m, --media-type TYPES      Comma-separated media types: photo, video, audio, voice,
                                video_note, gif, document, media
    --proxy HOST:PORT:SECRET    MTProto proxy (e.g. 1.2.3.4:443:deadbeef)
    -v, --verbose               Enable verbose logging
    --version                   Show version
```

Running the tool without `--peers` or `--wipe-everything` will show an interactive list of your chats to choose from.

### Examples

Delete all your messages from a specific chat by username:
```
tgeraser --session myaccount -p @chatname
```

Delete messages older than 7 days from all chats:
```
tgeraser --session myaccount -w -o "7*days"
```

Delete only photos and videos from a specific peer:
```
tgeraser --session myaccount -p @chatname -m "photo,video"
```

Delete entire conversation with a user:
```
tgeraser --session myaccount -p @username --entity-type user --delete-conversation
```

Connect via an MTProto proxy:
```
tgeraser --session myaccount --proxy 1.2.3.4:443:ee367f1d2b4c7e9a0f5d8b3c6a2e1f4d
```

## Contributing

If you have any issues or suggestions, please feel free to open an issue or submit a pull request.

## License

MIT
