# SerphunterRecon - Subdomain Enumeration Tool

![Version](https://img.shields.io/badge/version-1.0-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Bash](https://img.shields.io/badge/bash-5.0+-green.svg)

An advanced, comprehensive subdomain enumeration and reconnaissance tool designed for penetration testers and security researchers. SerphunterRecon leverages multiple passive sources and APIs to efficiently discover subdomains while providing detailed metrics and reporting.

## Features

✨ **Core Features**
- 🔍 Multi-source passive subdomain enumeration
- ⚡ Parallel execution for faster results
- 🌐 HTTP/HTTPS probing for live server detection
- 📊 Comprehensive metrics and reporting
- 🔑 API key support for extended capabilities
- 📁 Organized output with per-source results
- 🎯 Deduplication of results across all sources
- 📈 Execution statistics and recommendations

## Enumeration Sources

SerphunterRecon integrates with the following sources for comprehensive subdomain discovery:

| Source | Type | Coverage |
|--------|------|----------|
| **CRT.SH** | Certificate Transparency | High |
| **Alienvault OTX** | Passive DNS | High |
| **Certspotter** | Certificate API | High |
| **JLDC Anubis** | Subdomain API | Medium |
| **Subdomain.center** | Aggregator API | Medium |
| **VirusTotal** | Enterprise API | High (API Key Required) |
| **Shodan** | Search Engine API | High (API Key Required) |

## Installation

### Prerequisites
- Bash 4.0 or higher
- curl
- Common Unix utilities (grep, sort, uniq)

### Quick Start
```bash
git clone https://github.com/yourusername/serphunter-recon.git
cd serphunter-recon
chmod +x serphunter.sh
```

## Usage

### Basic Enumeration
```bash
./serphunter.sh -d example.com
```

### Advanced Options
```bash
# Run enumeration in parallel mode (faster)
./serphunter.sh -d example.com --parallel

# Enable HTTP probing to find live servers
./serphunter.sh -d example.com --http-probe

# Combine options
./serphunter.sh -d example.com -p -hp
```

### Command-line Options
```
Usage: serphunter.sh -d <domain> [OPTIONS]

Options:
  -d, --domain      Target domain for enumeration (required)
  -p, --parallel    Run enumeration sources in parallel
  -hp, --http-probe Probe for live HTTP/HTTPS servers
  -h, --help        Show this help message
  -v, --version     Show version information
```

## Configuration

Edit `config.txt` to add API keys for enhanced functionality:

```bash
# VirusTotal API Key
VIRUSTOTAL_API_KEY="your_api_key_here"

# Shodan API Key
SHODAN_API_KEY="your_api_key_here"

# Censys API Credentials
CENSYS_API_ID="your_id_here"
CENSYS_API_SECRET="your_secret_here"

# HTTP Probe Settings
HTTP_PROBE_TIMEOUT=10
MAX_PARALLEL_JOBS=5
```

## Output

SerphunterRecon generates the following outputs in the `results/` directory:

- **{domain}_combined_{timestamp}.txt** - All unique subdomains
- **{domain}_crtsh_{timestamp}.txt** - CRT.SH results
- **{domain}_otx_{timestamp}.txt** - Alienvault OTX results
- **{domain}_certspotter_{timestamp}.txt** - Certspotter results
- **{domain}_anubis_{timestamp}.txt** - JLDC Anubis results
- **{domain}_subdomaincenter_{timestamp}.txt** - Subdomain.center results
- **{domain}_virustotal_{timestamp}.txt** - VirusTotal results (if API key configured)
- **{domain}_shodan_{timestamp}.txt** - Shodan results (if API key configured)
- **{domain}_http_probe_{timestamp}.txt** - Live servers found (if probing enabled)
- **{domain}_metrics_{timestamp}.txt** - Detailed execution report

## Metrics & Reporting

After enumeration, SerphunterRecon provides:

- **Execution Statistics**
  - Total execution time
  - Results per enumeration source
  - Total unique subdomains discovered

- **Source Breakdown**
  - Number of subdomains from each source
  - Statistical analysis
  - Performance metrics

- **Live Server Discovery**
  - HTTP status codes
  - Responsive protocols (HTTP/HTTPS)
  - Server statistics

- **Recommendations**
  - Guidance based on discovery count
  - Next steps for reconnaissance
  - Best practices

## Examples

### Example 1: Quick reconnaissance
```bash
$ ./serphunter.sh -d google.com
╔════════════════════════════════════╗
║  SerphunterRecon - Enumeration    ║
╚════════════════════════════════════╝

Target: google.com
Mode: Sequential

[*] Querying crt.sh for google.com
[+] Found subdomains: 245

[*] Querying Alienvault OTX for google.com
[+] Found subdomains: 128

... (other sources)

[+] Final results saved to: results/google.com_combined_20251210_153022.txt
[+] Total unique subdomains: 487
```

### Example 2: Fast parallel enumeration with live detection
```bash
$ ./serphunter.sh -d target.com --parallel --http-probe
[...enumeration output with metrics...]
[+] Live servers found: 23
```

## Performance

**Execution Times** (varies based on domain popularity):
- Sequential mode: 30-60 seconds
- Parallel mode: 10-20 seconds
- With HTTP probing: +30-120 seconds (depends on subdomain count)

## Workflow

```
1. Parse arguments and load configuration
2. Initialize output directories
3. Run enumeration from multiple sources
4. Combine and deduplicate results
5. (Optional) Probe for live servers
6. Generate comprehensive metrics report
7. Save all results to organized file structure
```

## Security Considerations

- ✅ Passive reconnaissance only - no active scanning
- ✅ Respects rate limits of target services
- ✅ No exploitation or malicious activity
- ⚠️ Always obtain proper authorization before using on any system
- ⚠️ Review your local laws and regulations regarding security testing

## Version History

- **v1.0** (Dec 2025) - Production release with full feature set
- **v0.6** (Dec 2025) - Added comprehensive metrics and reporting
- **v0.5** (Nov 2025) - Added HTTP/HTTPS probing
- **v0.4** (Oct 2025) - Implemented parallel execution
- **v0.3** (Sep 2025) - Added API key support
- **v0.2** (Aug 2025) - Added multiple enumeration sources
- **v0.1** (Jul 2025) - Initial release

## Contributing

Contributions, bug reports, and feature requests are welcome! 

## License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

## Disclaimer

This tool is designed for authorized security testing and educational purposes only. Unauthorized access to computer systems is illegal. Always obtain proper written permission before conducting security assessments.

## Author

Security Researcher | Final Year Engineering Student

## Acknowledgments

- Inspired by similar reconnaissance tools in the cybersecurity community
- Built on principles of passive information gathering
- Aggregates data from publicly available certificate transparency logs and APIs

---

**Happy Hunting! 🎯**

