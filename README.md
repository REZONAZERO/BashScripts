# 🔐 BashScripts — Security Research Toolbox

> ⚠️ **Disclaimer**: These scripts are experimental and provided for educational and research purposes only. Use them only in environments you own or have explicit permission to test. The author assumes no responsibility for misuse.

---

## 🛠️ Tools

### `SilverWolfs_Revenge.sh`
**Type:** Banner loader / utility script

Deploys banners from the `banners/` directory. Simple and straightforward — likely used to brand your tools or set up visual feedback during pentesting sessions.

### `zombie-process-hunt.sh`
**Type:** Process investigation / forensics

Scans for zombie processes and other suspicious activity on the system. Useful for quick system checks and identifying potential persistence mechanisms.

---

## 📂 `banners/`

Contains ASCII banners for various tools:

- `silver_wolfs_revenge.txt`
- `ssh_honeypot.txt`
- `wifi_pouncer.txt`

---

## 📂 `ssh_honeypot/`

Lightweight SSH honeypot implementation:

- `ssh-honeypot.sh` — Main honeypot script  
- `fake_ssh.sh` — SSH simulation script to log connection attempts

Useful for:
- Logging unauthorized access attempts
- Analyzing attack patterns
- Understanding common SSH brute-force tactics

---

## 🧪 Research Notes

These scripts are a mix of:
- **Forensic tools** (process hunting)
- **Deception tools** (honeypots)
- **Quick utilities** (banner management)

They were written during live experiments and may contain raw, unpolished code — treat them as learning material and adapt them to your own workflow.

---

## 🚀 Getting Started

```bash
git clone https://github.com/REZONAZERO/BashScripts.git
cd BashScripts
chmod +x *.sh
