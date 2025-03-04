# SSH Authentication with Certificates
## 1. Generate Your Key Pair on Linux

Run the following command in your terminal to generate a new RSA key pair:

```bash
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

- **Options Explained:**
  - `-t rsa`: Specifies the RSA algorithm. Alternatively, you can use `ed25519` for a modern option.
  - `-b 4096`: Creates a 4096-bit key for strong encryption.
  - `-C "your_email@example.com"`: Adds a comment (often your email) to help identify the key.

You'll be prompted to choose a file location (default is `~/.ssh/id_rsa`) and to enter an optional passphrase for additional security.

## 2. Copy the Public Key to the Target Host

To allow the remote server to recognize your key, you need to add your public key to the `~/.ssh/authorized_keys` file on the server.

### Option A: Using `ssh-copy-id` (Recommended)

```bash
ssh-copy-id user@remote_host
```

This command will append your public key to the remote user's `authorized_keys` file and ensure the correct permissions are set.

### Option B: Manually Copying the Key

```bash
cat ~/.ssh/id_rsa.pub | ssh user@remote_host "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

After copying the key, ensure the correct permissions on the remote host:

- Set the `.ssh` directory to `700`:
  ```bash
  chmod 700 ~/.ssh
  ```
- Set the `authorized_keys` file to `600`:
  ```bash
  chmod 600 ~/.ssh/authorized_keys
  ```

## 3. Configure the SSH Daemon on the Target Host

Edit the SSH daemon configuration file, typically located at `/etc/ssh/sshd_config`, to ensure that public key authentication is enabled.

### Key Settings to Check or Add:

```text
PubkeyAuthentication yes
AuthorizedKeysFile     %h/.ssh/authorized_keys
```

For additional security, you can disable password authentication:

```text
PasswordAuthentication no
```

After updating the configuration, restart the SSH service:

```bash
sudo systemctl restart sshd
```

*(Note: On some systems, the service might be named `ssh` instead of `sshd`.)*

## 4. Test the Connection

Attempt to connect to the remote host using:

```bash
ssh user@remote_host
```

