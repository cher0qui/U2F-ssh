# linux-u2f-via-ssh

> ⚠️ **Note**: This document is for personal reference only. I take no responsibility if you choose to use it.  
> It outlines how to configure SSH with U2F (FIDO2) two-factor authentication on a Linux system using physical security keys, **not** TOTP apps like Google Authenticator.

## 1. Update the system

```bash
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get full-upgrade -y
```

---

## 2. Enable and start the SSH service

```bash
sudo systemctl enable ssh
sudo systemctl start ssh
```

---

## 3. Enable Challenge-Response authentication

Modify the SSH daemon configuration to allow challenge-response-based auth methods:

```bash
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config~
sudo sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/g' /etc/ssh/sshd_config
sudo systemctl restart ssh
```

---

## 4. Install U2F PAM module

```bash
sudo apt-get install libpam-u2f pamu2fcfg -y
for arch-linux you only need:
sudo pacman -S pam-u2f
```

---

## 5. Register your U2F device

Each user must register their U2F key. Plug in your security key and run:

```bash
mkdir -p ~/.config/cher0
pamu2fcfg > ~/.config/cher0/u2f_keys
```

Touch your key when prompted.

---

## 6. Configure PAM to use U2F

Choose **one** of the following options depending on whether you want U2F required **before** or **after** the password.

### Option A: Prompt for U2F **before** password

```bash
sudo cp /etc/pam.d/sshd /etc/pam.d/sshd~
sudo sed -i '/@include common-auth/i \nauth required pam_u2f.so origin=ssh://HOSTNAME appid=ssh://HOSTNAME
' /etc/pam.d/sshd
```

### Option B: Prompt for U2F **after** password

```bash
sudo cp /etc/pam.d/sshd /etc/pam.d/sshd~
sudo sed -i '/@include common-auth/a \nauth required pam_u2f.so origin=ssh://HOSTNAME appid=ssh://HOSTNAME
' /etc/pam.d/sshd
```

> Replace `HOSTNAME` with your actual machine hostname or IP address.

---

## 7. Restart SSH and verify

```bash
sudo systemctl restart ssh
```

**Important**: Open a new SSH session to test before closing your current one. If configuration is incorrect, you may get locked out.

---

## Troubleshooting

- Check `/var/log/auth.log` for login errors.
- Ensure your U2F key is connected when logging in via SSH.
- `pamu2fcfg -n` can be used if you want to avoid touch confirmation when generating key.

---

## Notes

- Each user must generate their own `~/.config/cher0qui/u2f_keys`.
- U2F will only work with clients that support the U2F PAM flow (OpenSSH 8.2+ recommended).
