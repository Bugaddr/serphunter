# SerphunterRecon

Intermediate subdomain enumeration tool.

## Features
- Sources: crt.sh, OTX, Certspotter, VirusTotal, Shodan
- Config file support for API keys

## Configuration
Edit `config.txt` to add your API keys:
```bash
VIRUSTOTAL_API_KEY="your_key"
SHODAN_API_KEY="your_key"
```

## Changelog
- v0.3: Added API key support (VT, Shodan)
- v0.2: Added OTX, Certspotter
- v0.1: Initial release
