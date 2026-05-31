# Step 0: Create Ubuntu VM in VMware Workstation

## Prerequisites
- VMware Workstation Pro (free for personal use) installed on Windows 11
- Ubuntu Server 24.04 LTS ISO downloaded from https://ubuntu.com/download/server

---

## Part 1: Configure VMware Virtual Networks

Before creating the VM, set up VMware's virtual networks.

1. Open VMware Workstation
2. Click **Edit → Virtual Network Editor**
3. Click **Change Settings** (requires admin)
4. Configure two networks:

| Network | Type | Subnet IP | Subnet Mask |
|---------|------|-----------|-------------|
| VMnet8 | NAT | 192.168.131.0 | 255.255.255.0 |
| VMnet1 | Host-only | 192.168.56.0 | 255.255.255.0 |

> **Why two networks?**
> - VMnet8 (NAT) = `ens33` → your SSH/management network
> - VMnet1 (Host-only) = `ens37` → OpenStack provider/floating IP network
> - **CRITICAL**: Keep these separate — OVS will take over ens37 for OpenStack networking

5. Click **Apply → OK**

---

## Part 2: Create the Virtual Machine

### 2.1 New VM Wizard
1. Click **File → New Virtual Machine**
2. Select **Custom (advanced)** → Next
3. Hardware compatibility: **Workstation 17.x** → Next
4. Select **Installer disc image file (ISO)** → Browse to Ubuntu 24.04 ISO → Next
5. Guest OS: **Linux** / **Ubuntu 64-bit** → Next
6. VM Name: `openstack-node` → Location: `C:\VMs\openstack-node` → Next

### 2.2 Processor Settings
- Number of processors: **2**
- Number of cores per processor: **3** (= 6 total vCPUs)
- ✅ Check **"Virtualize Intel VT-x/EPT or AMD-V/RVI"** ← IMPORTANT for KVM
- Next

### 2.3 Memory
- Memory: **20480 MB** (20 GB) → Next

### 2.4 Network
- Select **Use network address translation (NAT)** → Next
- *(We'll add the second adapter after)*

### 2.5 Storage
- SCSI Controller: **LSI Logic** → Next
- Disk type: **SCSI** → Next
- Create a new virtual disk → Next
- Disk size: **150 GB** → Store as single file → Next
- Disk filename: keep default → Next

### 2.6 Finish
- Click **Customize Hardware** before clicking Finish

### 2.7 Customize Hardware
In the hardware dialog:

**Add second network adapter:**
1. Click **Add** → Select **Network Adapter** → Finish
2. Set new adapter to **Custom: VMnet1** (Host-only)
3. First adapter should be **NAT**

**Remove unnecessary hardware (optional):**
- Remove USB Controller
- Remove Sound Card
- Remove Printer

Click **Close → Finish**

---

## Part 3: Install Ubuntu Server 24.04

### 3.1 Boot and Language
1. Power on the VM
2. Select **Try or Install Ubuntu Server**
3. Language: **English** → Continue

### 3.2 Network Configuration
Ubuntu will detect both interfaces:
- `ens33` (NAT) — will get DHCP IP from VMware
- `ens37` (Host-only) — no IP yet (configured later)

Leave as-is for now → Done

### 3.3 Storage
- Use entire disk → No LVM → Done
- Confirm destructive action → Continue

### 3.4 Profile Setup
| Field | Value |
|-------|-------|
| Your name | sage |
| Server name | openstack-node |
| Username | sage |
| Password | (your choice) |
| Confirm password | same |

### 3.5 SSH Setup
- ✅ **Install OpenSSH server** ← IMPORTANT
- No SSH keys needed (we'll set up key auth later)
- Continue

### 3.6 Featured Snaps
- Don't select anything
- Continue

### 3.7 Installation
Wait for installation to complete (~5-10 minutes) then click **Reboot Now**

---

## Part 4: First Boot Configuration

### 4.1 Login via VMware console
Log in as `sage` with your password

### 4.2 Get the management IP
```bash
ip addr show ens33
```
Note the IP (e.g., `192.168.131.128`) — this is your SSH address

### 4.3 SSH from Windows
Open PowerShell on Windows:
```powershell
ssh sage@192.168.131.128
```

### 4.4 Verify both interfaces are up
```bash
ip addr show
```
You should see:
- `ens33` with an IP like `192.168.131.x`
- `ens37` with no IPv4 (that's correct)

---

## Part 5: Ready to Install OpenStack

You now have a VM ready for OpenStack installation.

**Copy the install scripts to your VM:**

Option A — via SCP from Windows:
```powershell
scp -r C:\path\to\openstack-install sage@192.168.131.128:~/
```

Option B — via Git (if scripts are in a repo):
```bash
git clone https://github.com/yourrepo/openstack-install.git
```

Option C — Create the scripts directory manually and paste content.

**Then run in order:**
```bash
cd ~/openstack-install

# FIRST: Edit the IP addresses to match your setup
nano 01-prepare.sh
# Update MGMT_IP to match your ens33 IP (from ip addr show)

# Then run each script
chmod +x *.sh
./01-prepare.sh
./02-install-kolla.sh
./03-configure.sh
./04-patches.sh
./05-build-images.sh   # Takes 15 min
./06-deploy.sh         # Takes 30-40 min
./07-post-deploy.sh
./08-setup-network.sh
```

---

## VMware Settings Summary

| Setting | Value |
|---------|-------|
| vCPUs | 6 (2 processors × 3 cores) |
| RAM | 20 GB |
| Disk | 150 GB |
| Network 1 | NAT (VMnet8) → ens33 |
| Network 2 | Host-only (VMnet1) → ens37 |
| VT-x/EPT | Enabled |
| OS | Ubuntu Server 24.04 LTS |

---

## Troubleshooting VM Creation

**VT-x not supported error in VMware:**
- Disable Hyper-V in Windows: `bcdedit /set hypervisorlaunchtype off` → reboot
- Enable VT-x in BIOS (F2 on Dell, F10 on HP)
- Disable Memory Integrity: Windows Security → Core Isolation → off

**Can't SSH after install:**
- Find VM IP via VMware console: `ip addr show ens33`
- Make sure OpenSSH was installed during setup
- Try: `sudo systemctl start ssh`

**ens37 shows no IP:**
- That's correct! ens37 has no IP — OpenStack will manage it via OVS
- Never assign a static IP to ens37 manually
