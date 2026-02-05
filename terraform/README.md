# The Dailies - AWS Infrastructure

This Terraform configuration provisions AWS infrastructure for The Dailies API and Admin Portal, optimized for AWS Free Tier usage.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS Cloud                                │
│                                                                  │
│  ┌──────────────┐     ┌──────────────┐     ┌─────────────────┐ │
│  │   CloudFront │────▶│  S3 Bucket   │     │   EC2 t2.micro  │ │
│  │     (CDN)    │     │ Admin Portal │     │   Backend API   │ │
│  └──────────────┘     └──────────────┘     └────────┬────────┘ │
│         │                                           │          │
│         │ HTTPS                                     │ HTTP     │
│         ▼                                           ▼          │
│    Admin Portal                              MongoDB Atlas     │
│    Static Site                               (External)        │
└─────────────────────────────────────────────────────────────────┘
```

## Free Tier Components

| Component | Service | Free Tier Limit |
|-----------|---------|-----------------|
| Backend API | EC2 t2.micro | 750 hours/month (12 months) |
| Static Hosting | S3 | 5GB storage, 20K GET/month |
| CDN | CloudFront | 1TB transfer, 10M requests/month |
| Elastic IP | EIP | Free when attached to running instance |
| Database | MongoDB Atlas | M0 cluster (always free) |

## Prerequisites

1. **AWS Account** with Free Tier eligibility
2. **Terraform** >= 1.0 installed
3. **AWS CLI** installed and configured
4. **MongoDB Atlas** account (free)

## Setup Instructions

### Step 1: Create AWS IAM User

1. Go to AWS Console → IAM → Users → Create User
2. Name: `the-dailies-terraform`
3. Attach policies:
   - `AdministratorAccess` (for Terraform - can be scoped down later)
4. Create access key (CLI usage)
5. Save the Access Key ID and Secret Access Key

### Step 2: Create MongoDB Atlas Cluster

1. Go to [MongoDB Atlas](https://www.mongodb.com/atlas)
2. Create a free M0 cluster
3. Create a database user with read/write access
4. Whitelist IP `0.0.0.0/0` (or EC2 IP after deploy)
5. Get connection string: `mongodb+srv://user:pass@cluster.mongodb.net/the-dailies`

### Step 3: Generate SSH Key

```bash
# Generate a new SSH key for deployment
ssh-keygen -t ed25519 -f ~/.ssh/the-dailies-deployer -C "the-dailies-deployer"

# Copy the public key content
cat ~/.ssh/the-dailies-deployer.pub
```

### Step 4: Configure Terraform

```bash
cd terraform

# Copy example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

Fill in:
- `ssh_public_key` - Content of `~/.ssh/the-dailies-deployer.pub`
- `mongodb_uri` - Your MongoDB Atlas connection string
- `jwt_secret` - Generate with: `openssl rand -base64 32`

### Step 5: Initialize and Apply Terraform

```bash
# Configure AWS credentials
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"

# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Apply infrastructure
terraform apply
```

### Step 6: Note the Outputs

After apply, note these values for GitHub Actions:

```bash
terraform output
```

You'll need:
- `backend_public_ip` - EC2 instance IP
- `admin_portal_url` - CloudFront URL
- `admin_portal_bucket` - S3 bucket name
- `cloudfront_distribution_id` - For cache invalidation

### Step 7: Configure GitHub Secrets & Variables

Go to your GitHub repo → Settings → Secrets and variables → Actions

**Secrets:**
| Name | Value |
|------|-------|
| `AWS_ACCESS_KEY_ID` | Your AWS access key (or create a deploy-specific IAM user) |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key |
| `EC2_SSH_PRIVATE_KEY` | Content of `~/.ssh/the-dailies-deployer` (private key) |
| `EC2_HOST` | EC2 public IP from terraform output |

**Variables:**
| Name | Value |
|------|-------|
| `AWS_REGION` | `us-east-1` |
| `S3_BUCKET` | `the-dailies-admin-portal` |
| `CLOUDFRONT_DISTRIBUTION_ID` | From terraform output |
| `API_URL` | `http://<EC2-IP>` |
| `ADMIN_URL` | CloudFront URL from terraform output |
| `VITE_API_URL` | `http://<EC2-IP>/api` |

### Step 8: Update CORS

After deployment, update the CORS origins:

```bash
# SSH into EC2
ssh -i ~/.ssh/the-dailies-deployer ec2-user@<EC2-IP>

# Edit environment file
sudo nano /opt/the-dailies/.env

# Add CORS_ORIGINS (CloudFront URL)
CORS_ORIGINS=https://xxxxx.cloudfront.net

# Restart the API
pm2 restart the-dailies-api
```

### Step 9: Initial Deployment

Trigger deployments manually:
1. Go to GitHub Actions
2. Run "Deploy API" workflow
3. Run "Deploy Admin Portal" workflow

Or push to `main` branch.

## Manual EC2 Operations

```bash
# SSH into instance
ssh -i ~/.ssh/the-dailies-deployer ec2-user@<EC2-IP>

# View API logs
pm2 logs the-dailies-api

# Restart API
pm2 restart the-dailies-api

# Check status
pm2 status

# View nginx logs
sudo tail -f /var/log/nginx/error.log
```

## Cost Estimation

With Free Tier (first 12 months):
- **EC2**: $0 (750 hours/month free)
- **EIP**: $0 (free when attached)
- **S3**: $0 (5GB free)
- **CloudFront**: $0 (1TB free)
- **Data Transfer**: $0 (within limits)

After Free Tier expires:
- **EC2 t2.micro**: ~$8.50/month (us-east-1)
- **EIP**: $3.65/month (if instance stopped)
- **S3**: ~$0.02/month
- **CloudFront**: Pay per use

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

## Troubleshooting

### EC2 Instance Not Starting
```bash
# Check user data logs
ssh ec2-user@<IP> "cat /var/log/user-data.log"
```

### API Not Responding
```bash
ssh ec2-user@<IP>
pm2 logs the-dailies-api
sudo systemctl status nginx
```

### CloudFront Returns 403
- Check S3 bucket policy
- Verify Origin Access Control is configured
- Wait for CloudFront distribution to deploy (can take 15+ minutes)

### MongoDB Connection Issues
- Verify IP whitelist in MongoDB Atlas
- Check connection string format
- Ensure database user has correct permissions
