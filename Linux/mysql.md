# MySQL Hardening and Defense Guide
## 1. Keep System and MySQL Updated

Ensure your Linux system and MySQL server are always up-to-date with the latest security patches.

```sh
sudo apt update && sudo apt upgrade -y   # Debian/Ubuntu
sudo yum update -y                       # RHEL/CentOS
```

Update MySQL:
```sh
sudo systemctl stop mysql
sudo apt install --only-upgrade mysql-server  # Debian/Ubuntu
sudo yum update mysql-server                  # RHEL/CentOS
sudo systemctl start mysql
```

## 2. Secure MySQL Installation

Run the security script to remove insecure defaults:

```sh
sudo mysql_secure_installation
```

Options to configure:
- Set a **strong root password**.
- Remove **anonymous users**.
- Disallow **remote root login**.
- Remove the **test database**.
- Reload **privilege tables**.

## 3. Restrict Remote Access
Limit access to MySQL only from necessary IPs:

Edit MySQL configuration file:
```sh
sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf  # Debian/Ubuntu
sudo nano /etc/my.cnf                          # RHEL/CentOS
```

Find the `bind-address` directive and change it:
```ini
bind-address = 127.0.0.1
```

Restart MySQL:
```sh
sudo systemctl restart mysql
```

## 4. Configure Strong User Authentication

Access MySQL command mode:
```sh
sudo mysql -u root -p
```

Ensure users have **strong passwords** and use **authentication plugins**:

```sql
ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY 'Str0ngP@ssw0rd!';
```

Verify password policy (MySQL 8+):
```sql
SHOW VARIABLES LIKE 'validate_password%';
```

Enable strict policy (adjust parameters as needed):
```sql
SET GLOBAL validate_password.policy = 2;  -- STRONG
SET GLOBAL validate_password.length = 12;
```

## 5. Implement Least Privilege Principle

Access MySQL command mode:
```sh
sudo mysql -u root -p
```

Create users with **minimal** privileges:

```sql
CREATE USER 'appuser'@'localhost' IDENTIFIED BY 'SecurePass123!';
GRANT SELECT, INSERT, UPDATE, DELETE ON mydb.* TO 'appuser'@'localhost';
FLUSH PRIVILEGES;
```

Avoid using the `root` user for applications.

## 6. Enable Firewall and Allow Only Required Ports

Use **UFW** (Ubuntu/Debian):
```sh
sudo ufw allow 3306/tcp  # Allow MySQL (if needed)
sudo ufw enable
sudo ufw status
```

For **firewalld** (RHEL/CentOS):
```sh
sudo firewall-cmd --add-service=mysql --permanent
sudo firewall-cmd --reload
```

If remote access isn’t needed, **disable MySQL port 3306**.

```sh
sudo ufw deny 3306/tcp
```

## 7. Enable MySQL Logging and Monitoring

Access MySQL command mode:
```sh
sudo mysql -u root -p
```

Enable logging for security auditing:

```sql
SET GLOBAL general_log = 'ON';
SET GLOBAL general_log_file = '/var/log/mysql_general.log';
```

For error logs:
```sh
sudo tail -f /var/log/mysql/error.log
```

Install **Fail2Ban** to prevent brute-force attacks:
```sh
sudo apt install fail2ban -y  # Debian/Ubuntu
sudo yum install fail2ban -y  # RHEL/CentOS
```

Configure MySQL-specific **Fail2Ban** rules (`/etc/fail2ban/jail.local`):
```ini
[mysqld-auth]
enabled  = true
filter   = mysqld-auth
logpath  = /var/log/mysql/error.log
bantime  = 3600
maxretry = 5
```

Restart Fail2Ban:
```sh
sudo systemctl restart fail2ban
```

## 8. Encrypt Data in Transit

Enable **TLS encryption** for MySQL:

Generate SSL certificates:
```sh
sudo openssl req -newkey rsa:2048 -days 365 -nodes -x509 \
  -keyout /etc/mysql/server-key.pem -out /etc/mysql/server-cert.pem
```

Edit MySQL configuration (`mysqld.cnf` or `my.cnf`):
```ini
[mysqld]
ssl-ca=/etc/mysql/ca.pem
ssl-cert=/etc/mysql/server-cert.pem
ssl-key=/etc/mysql/server-key.pem
require_secure_transport = ON
```

Restart MySQL:
```sh
sudo systemctl restart mysql
```

Verify SSL is enabled:
Access MySQL command mode:
```sh
sudo mysql -u root -p
```

```sql
SHOW VARIABLES LIKE 'have_ssl';
```

## 9. Enable Backups and Disaster Recovery Plan

Use **mysqldump** for backups:
```sh
mysqldump -u root -p --all-databases > /backup/mysql_backup.sql
```

Schedule automated backups:
```sh
crontab -e
```
Add a backup job (daily at 2 AM):
```sh
0 2 * * * mysqldump -u root -p'MyPassword' --all-databases > /backup/mysql_backup_$(date +\%F).sql
```

Use **Percona XtraBackup** for **hot backups** (without downtime):
```sh
sudo apt install percona-xtrabackup -y  # Debian/Ubuntu
```

## 10. Remove Unnecessary Features and Secure Files

Disable **MySQL LOAD DATA LOCAL INFILE** to prevent file-based attacks:
```ini
[mysqld]
local-infile=0
```
Restart MySQL:
```sh
sudo systemctl restart mysql
```

Ensure MySQL directories have proper permissions:
```sh
sudo chown -R mysql:mysql /var/lib/mysql
sudo chmod -R 700 /var/lib/mysql
```

Disable **performance_schema** if not used (to reduce attack surface):
```ini
[mysqld]
performance_schema=0
```

Restart MySQL:
```sh
sudo systemctl restart mysql
```
