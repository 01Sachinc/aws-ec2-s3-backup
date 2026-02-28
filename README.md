# AWS Secure EC2 to S3 Backup & Restore Automation

![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white) ![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black) ![Bash Shell](https://img.shields.io/badge/bash_script-%23121011.svg?style=for-the-badge&logo=gnu-bash&logoColor=white)

## 📌 Project Overview
A production-ready cloud automation project to securely backup data from an Amazon EC2 instance to an S3 bucket and perform restores. This solution removes the need for hardcoded AWS credentials by utilizing IAM Roles, implements least privilege security, enables bucket versioning for accidental deletion protection, and uses cron jobs for automated daily backups.

## 🏗️ Architecture Diagram
<div align="center">
  <img src="architecture/architecture-diagram.png" alt="Architecture Diagram" width="800"/>
</div>

### Architecture Components
1. **Amazon EC2 (Amazon Linux 2/2023)**: Hosts the application/data and runs the backup shell scripts. 
2. **Amazon S3**: Object storage container for backups. Configured with Block Public Access and Bucket Versioning.
3. **IAM Role**: Attached to the EC2 instance to grant programmatic access to S3 and CloudWatch (No Access Keys required).
4. **CloudWatch Logs**: Centralized logging for tracking backup success/failures.
5. **EventBridge / Cron**: Triggers the backup script locally on a scheduled daily basis.

---

## 🚀 Step-by-Step Setup Guide

### 1. S3 Bucket Creation
1. Navigate to the AWS S3 Console.
2. Click **Create bucket**.
3. Name your bucket (e.g., `your-secure-backup-bucket-name`).
4. **Enable Bucket Versioning** (Crucial for rollback capabilities).
5. Ensure **Block all public access** is **checked**.
6. Enable **Default Encryption** (SSE-S3 or SSE-KMS).
7. Create the bucket.

### 2. IAM Role Configuration
1. Navigate to the AWS IAM Console > **Roles** > **Create role**.
2. Select **AWS service** -> **EC2**.
3. Create a custom inline policy using the provided JSON in this project (`policies/iam-policy.json`).
4. Name the role (e.g., `EC2-Backup-Restore-Role`) and save.
5. Attach this role to your target EC2 instance. (EC2 Console > Select Instance > Actions > Security > Modify IAM Role).

### 3. Deploy Scripts to EC2
SSH into your EC2 instance and clone this repository or copy the scripts:
```bash
sudo yum install -y git jq
git clone https://github.com/yourusername/aws-ec2-s3-backup.git
cd aws-ec2-s3-backup/scripts
chmod +x backup.sh restore.sh
```

### 4. Configure Automation (Cron Job)
Set up a daily automated backup at 2:00 AM.
```bash
crontab -e
```
Add the following line:
```cron
0 2 * * * /path/to/aws-ec2-s3-backup/scripts/backup.sh /var/www/html >> /var/log/cron_backup.log 2>&1
```

---

## 📜 CLI Commands Reference

### Manual Backup
```bash
./scripts/backup.sh /var/www/html
```

### Manual Restore
```bash
./scripts/restore.sh s3://your-secure-backup-bucket-name/backups/YYYY-MM-DD/backup_timestamp.tar.gz /var/www/html_restored
```

---

## 🔒 Security Best Practices Implemented
- **No Hardcoded Credentials**: Relying exclusively on EC2 Instance Profiles (IAM roles), significantly reducing the risk of exposed `AWS_ACCESS_KEY_ID`.
- **Least Privilege Principle**: The IAM policy is highly restricted to only allow `PutObject` and `GetObject` on specific bucket paths.
- **S3 Versioning**: Protects against accidental overwrites or malicious data manipulation (Ransomware protection).
- **Encryption in Transit & Rest**: AWS CLI utilizes HTTPS automatically, and files are uploaded with SSE parameter enabled.
- **Timestamped & Organized Paths**: Eliminates naming collisions and organizes daily iterations linearly.

---

## 📸 Screenshots
*(Include screenshots of your AWS setup showing S3 buckets, IAM roles, and CLI outputs in the `screenshots/` directory)*
- [ ] S3 Bucket View
- [ ] IAM Role Attachment
- [ ] CloudWatch Log Streams

---

## 🔮 Future Improvements
1. **Lifecycle Policies**: Add an S3 lifecycle rule to automatically transition backups older than 30 days to S3 Glacier Flexible Retrieval to save costs.
2. **SNS Notifications**: Integrate Amazon SNS into the bash script to send an email or Slack alert on backup failure.
3. **CloudWatch Agent**: Send local script logs (`/var/log/s3_backup.log`) directly to CloudWatch Logs using the CloudWatch Agent.

---
**Author**: Sachin (DevOps & Cloud Engineer)
