# Setting Up ModSecurity WAF for Apache & NGINX on Linux

##  Overview
ModSecurity is an open-source Web Application Firewall (WAF) that helps protect **Apache** and **NGINX** from threats like SQL injection, cross-site scripting (XSS), and other web-based attacks.

---

## 1. Install ModSecurity for Apache & NGINX
### **For Apache**
1. **Update system packages:**
   ```bash
   sudo apt update && sudo apt upgrade -y  # Ubuntu/Debian
   sudo yum update -y                      # RHEL/CentOS
   ```
2. **Install ModSecurity for Apache:**
   ```bash
   sudo apt install libapache2-mod-security2 -y  # Ubuntu/Debian
   sudo yum install mod_security -y              # RHEL/CentOS
   ```
3. **Enable ModSecurity in Apache:**
   ```bash
   sudo a2enmod security2
   sudo systemctl restart apache2  # Restart Apache
   ```

### **For NGINX**
1. **Install required dependencies:**
   ```bash
   sudo apt install libmodsecurity-dev -y  # Ubuntu/Debian
   sudo yum install mod_security -y        # RHEL/CentOS
   ```
2. **Clone and compile ModSecurity for NGINX:**
   ```bash
   git clone --depth 1 https://github.com/SpiderLabs/ModSecurity.git
   cd ModSecurity
   git submodule init && git submodule update
   ./build.sh && ./configure && make && sudo make install
   ```
3. **Integrate ModSecurity with NGINX:**
   - Download and compile **nginx-modsecurity module**:
     ```bash
     git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git
     cd ModSecurity-nginx
     ```
   - Add the module when compiling NGINX:
     ```bash
     ./configure --add-module=/path/to/ModSecurity-nginx && make && sudo make install
     ```

---

## 2. Configure ModSecurity Rules
### **Edit the Main Configuration File**
For **Apache**:
```bash
sudo nano /etc/modsecurity/modsecurity.conf
```
For **NGINX**:
```bash
sudo nano /etc/nginx/modsecurity.conf
```
Enable key settings:
```ini
SecRuleEngine On
SecRequestBodyAccess On
SecResponseBodyAccess On
```

### **Use OWASP Core Rule Set (CRS)**
1. **Download OWASP CRS:**
   ```bash
   git clone https://github.com/coreruleset/coreruleset.git /etc/modsecurity/crs
   ```
2. **Enable CRS in ModSecurity:**
   ```ini
   Include "/etc/modsecurity/crs/crs-setup.conf"
   Include "/etc/modsecurity/crs/rules/*.conf"
   ```

---

## 3. Enable Logging
Enable logging for attack monitoring:
```ini
SecAuditEngine RelevantOnly
SecAuditLog /var/log/modsecurity_audit.log
SecDebugLogLevel 3
```
Restart Apache or NGINX:
```bash
sudo systemctl restart apache2   # For Apache
sudo systemctl restart nginx     # For NGINX
```

---

## 4. Test ModSecurity
To verify ModSecurity, try accessing:
```bash
curl -A "bad-bot" http://yourserver.com
curl "http://yourserver.com/?param=<script>alert('XSS')</script>"
```
Check logs:
```bash
sudo tail -f /var/log/modsecurity_audit.log
```

---

## 5. Fine-Tune ModSecurity Rules
If false positives occur, disable specific rules by adding:
```ini
SecRuleRemoveById 949110
```
Restart Apache or NGINX:
```bash
sudo systemctl restart apache2   # For Apache
sudo systemctl restart nginx     # For NGINX
```
