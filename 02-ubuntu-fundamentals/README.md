# Project 2: Linux Fundamentals — Users, Groups, and Permissions on Ubuntu Server

## Objective
Practice core Linux system administration skills (user/group management, file 
permissions, ownership) as a foundation for cybersecurity work, using a 
second VM in the home lab.

## Environment
- Host: MacBook Air M2, macOS
- Hypervisor: UTM (QEMU-based, ARM64)
- Guest OS: Ubuntu Server 26.04 LTS (ARM64)
- Allocated resources: 2GB RAM, 20GB disk

## Steps

### 1. VM Setup
Installed Ubuntu Server via UTM, using a Serial console device from the 
start (based on a fix discovered in Project 1) to avoid the graphical 
display bug encountered previously. Also hit and resolved a package mirror 
clock-sync error during install (see Problems Encountered).

### 2. User and Group Management
- Created a new user: `sudo adduser testuser`
- Created a new group: `sudo groupadd labgroup`
- Added the user to the group: `sudo usermod -aG labgroup testuser`
- Verified membership: `groups testuser` → confirmed output 
  `testuser : testuser users labgroup`

### 3. File Permissions
- Created a test file and inspected default permissions with `ls -l`
- Modified permissions using `chmod 640` (owner: read/write, group: read 
  only, others: no access)
- Practiced interpreting symbolic (`rw-r-----`) vs numeric (`640`) 
  permission notation

### 4. Ownership and Real-World Permission Testing
Attempted to grant `testuser` read access to a file inside my home 
directory via group membership and `chmod`. This failed even with correct 
file permissions.

**Root cause:** the home directory itself (`/home/akshay2010`) had 
permissions `drwxr-x---` (750) with the group set to my own personal 
group, not `labgroup`. Since directory traversal permission is required to 
access anything inside it, `testuser` was blocked at the directory level 
before even reaching the file.

**Fix:** created a dedicated shared directory instead of using a home 
directory:
sudo mkdir /srv/labshare
sudo chown akshay2010:labgroup /srv/labshare
sudo chmod 750 /srv/labshare

Moved the test file into it and set its group ownership to `labgroup` with 
`chown` (note: moving a file does not automatically change its group 
ownership, so this had to be set explicitly after the move).

### 5. Verification
Switched to `testuser` (`sudo su - testuser`) and confirmed:
- **Read access succeeded** — `cat /srv/labshare/labfile.txt` returned no 
  error, confirming group read permission worked
- **Write access failed** — `echo "test" >> /srv/labshare/labfile.txt` 
  returned `Permission denied`, confirming the group only had read, not 
  write, permission

## Problems Encountered

**1. Ubuntu installer failed with a mirror clock-sync error**
The installer's mirror check failed with: `Release file ... is not valid 
yet (invalid for another 12h 20min 25s)`. This indicated the VM's virtual 
clock was significantly out of sync with real time.

**Fix:** performed a full VM restart (not just retry) — this re-synced the 
virtual clock from the host Mac at boot, and the mirror check passed 
normally on the next install attempt.

**2. File moved with `mv` appeared to vanish**
After running `mv labfile.txt /srv/labshare/` using a relative path, the 
destination folder was empty and the file couldn't be found there.

**Fix:** used `find / -name "labfile.txt"` to locate the file (still in 
the original home directory — the move had not actually executed as 
intended) and re-ran the move using full absolute paths for both source 
and destination, which resolved the issue.

**3. testuser access denied despite correct file permissions**
Covered in detail above (Step 4) — directory-level permissions blocked 
access even though file-level permissions were correctly configured.

## What I Learned
- The difference between numeric (`chmod 640`) and symbolic permission 
  notation, and how to calculate numeric values (read=4, write=2, 
  execute=1)
- File permissions alone aren't sufficient — directory traversal 
  permissions (read/execute on the containing directory) are required 
  before file-level permissions even come into play
- `mv` does not preserve or reassign group ownership automatically after a 
  move between differently-owned locations
- The practical difference between a user's personal group vs a shared 
  group, and why dedicated shared directories (e.g. `/srv/`) are the 
  correct pattern for group-based file sharing rather than using home 
  directories
- How to verify permission behavior empirically by switching users 
  (`sudo su - <user>`) rather than assuming configuration is correct

## Screenshots
See `/screenshots` folder:
- `groups-testuser.png` — group membership confirmation
- `file-permissions.png` — final file permissions and ownership
- `write-denied.png` — proof write access was correctly blocked
- `home-dir-permissions.png` — the directory permissions that caused the 
  initial failure
