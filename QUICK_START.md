# SerphunterRecon - Quick Reference Guide

## Installation

```bash
git clone https://github.com/yourusername/serphunter-recon.git
cd serphunter-recon
chmod +x install.sh
./install.sh
```

## Quick Start

```bash
# Show help
./serphunter.sh -h

# Show version
./serphunter.sh -v

# Basic enumeration
./serphunter.sh -d example.com

# Fast parallel mode
./serphunter.sh -d example.com --parallel

# With live server detection
./serphunter.sh -d example.com --http-probe

# All features
./serphunter.sh -d example.com -p -hp
```

## Features at a Glance

| Feature | v1.0 | Example |
|---------|------|---------|
| CRT.SH Enumeration | ✓ | Automatic |
| OTX Integration | ✓ | Automatic |
| Certspotter API | ✓ | Automatic |
| Anubis Integration | ✓ | Automatic |
| Subdomain.center | ✓ | Automatic |
| VirusTotal API | ✓ | w/ API key |
| Shodan API | ✓ | w/ API key |
| Parallel Execution | ✓ | -p flag |
| HTTP Probing | ✓ | -hp flag |
| Metrics Report | ✓ | Automatic |
| Source Statistics | ✓ | In report |
| Live Server Count | ✓ | In report |

## Output Files

After running enumeration, check the `results/` directory:

```
results/
├── example.com_combined_20251215_153022.txt        # All unique subdomains
├── example.com_crtsh_20251215_153022.txt           # CRT.SH results
├── example.com_otx_20251215_153022.txt             # OTX results
├── example.com_certspotter_20251215_153022.txt     # Certspotter results
├── example.com_anubis_20251215_153022.txt          # Anubis results
├── example.com_subdomaincenter_20251215_153022.txt # Subdomain.center results
├── example.com_virustotal_20251215_153022.txt      # VirusTotal results
├── example.com_shodan_20251215_153022.txt          # Shodan results
├── example.com_http_probe_20251215_153022.txt      # Live servers (if -hp enabled)
└── example.com_metrics_20251215_153022.txt         # Detailed metrics report
```

## Configuration

Edit `config.txt` to add API keys:

```bash
VIRUSTOTAL_API_KEY="your_key_here"
SHODAN_API_KEY="your_key_here"
CENSYS_API_ID="your_id_here"
CENSYS_API_SECRET="your_secret_here"
HTTP_PROBE_TIMEOUT=10
MAX_PARALLEL_JOBS=5
```

## Typical Workflow

### Step 1: Initial Reconnaissance
```bash
./serphunter.sh -d target.com
```
📊 **Result**: List of discovered subdomains saved to file

### Step 2: Find Live Servers
```bash
./serphunter.sh -d target.com --http-probe
```
🌐 **Result**: Identifies which servers are responding

### Step 3: Further Analysis
- Use combined result file for additional tools
- Import into OSINT frameworks
- Further manual investigation

## Performance Tips

### 1. Use Parallel Mode (2-3x faster)
```bash
./serphunter.sh -d target.com --parallel
```

### 2. Configure API Keys for Maximum Coverage
```bash
# Edit config.txt with your keys
# Adds VirusTotal and Shodan data sources
```

### 3. Run HTTP Probing in Separate Step
```bash
# First: Get all subdomains
./serphunter.sh -d target.com -p

# Second: Probe for live servers
./serphunter.sh -d target.com -p -hp
```

### 4. Redirect Output
```bash
./serphunter.sh -d target.com 2>&1 | tee enumeration.log
```

## Understanding Metrics Report

The metrics report includes:

```
Total Unique Subdomains: 487
│
├─ Per-source breakdown
├─ Execution timing
├─ Performance analysis
└─ Recommendations
    ├─ Low count (< 10): Get more sources
    ├─ Medium count (10-50): Consider HTTP probing
    └─ High count (> 50): Run probing to find live services
```

## Troubleshooting

### Issue: "curl: command not found"
```bash
# Solution: Install curl
sudo apt-get install curl  # Ubuntu/Debian
brew install curl          # macOS
```

### Issue: No results from any source
```bash
# Check your internet connection
curl -s https://crt.sh > /dev/null && echo "Connected" || echo "No connection"

# Check if target domain exists
dig target.com
```

### Issue: HTTP probing is slow
```bash
# Edit config.txt to reduce timeout
HTTP_PROBE_TIMEOUT=5
```

### Issue: "Permission denied"
```bash
# Make scripts executable
chmod +x serphunter.sh install.sh
```

## Integration with Other Tools

### Save for Nmap Scanning
```bash
cat results/example.com_combined_*.txt | while read subdomain; do
    nmap -p 80,443 "$subdomain"
done
```

### Import into Burp Suite
1. Copy subdomains from `combined` file
2. Use as target scope
3. Start crawling

### Run SSL Certificate Check
```bash
cat results/example.com_combined_*.txt | while read subdomain; do
    timeout 5 openssl s_client -connect "$subdomain:443" 2>/dev/null | \
    grep -E "CN=|subject="
done
```

## Resume Keywords

Include these when describing the project:

- **Bash Scripting**: Advanced process management, function design
- **Cybersecurity**: Passive reconnaissance, OSINT, certificate transparency
- **API Integration**: Multi-source data aggregation, JSON parsing
- **Performance**: Parallel execution, job queuing, optimization
- **Software Development**: Modular architecture, documentation, version control
- **Problem Solving**: Data deduplication, error handling, edge cases
- **Professional Tools**: Git, configuration management, production release

## Project Statistics

| Metric | Value |
|--------|-------|
| Total Lines of Code | 523 |
| Main Script Size | 523 lines |
| Documentation | 816 lines |
| Total Project Size | 492 KB |
| Git Commits | 8 |
| Development Time | 6 months |
| Enumeration Sources | 7+ |

## Version Timeline

```
🎯 July 2025 ......... v0.1 - Initial setup
  ↓
🎯 August 2025 ....... v0.2 - Multi-source enumeration
  ↓
🎯 September 2025 .... v0.3 - API key support
  ↓
🎯 October 2025 ...... v0.4 - Parallel execution
  ↓
🎯 November 2025 ..... v0.5 - HTTP probing
  ↓
🎯 December 2025 ..... v0.6 - Metrics & reporting
  ↓
🎯 December 2025 ..... v1.0 - PRODUCTION RELEASE ✓
```

## Next Steps

1. **Test the tool**: `./serphunter.sh -d example.com`
2. **Configure API keys**: Edit `config.txt` with your API keys
3. **Run on real targets**: Use in your security assessments
4. **Contribute improvements**: See CONTRIBUTING.md
5. **Share your feedback**: Report issues and feature requests

## Support

- 📖 Read [README.md](README.md) for detailed documentation
- 📝 Check [CHANGELOG.md](CHANGELOG.md) for version history
- 🤝 Review [CONTRIBUTING.md](CONTRIBUTING.md) for contributions
- 💡 See [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) for architecture details

## Legal Notice

This tool is designed for **authorized security testing only**:
- ✅ Always get written permission
- ✅ Respect laws and regulations
- ✅ Use only on systems you own or have explicit authorization for
- ⚠️ Unauthorized access is illegal

---

**Happy Hunting! 🎯**

For more info, visit the [README.md](README.md)
