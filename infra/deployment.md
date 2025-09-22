# CI/CD Pipeline Health Dashboard - Cloud Deployment Guide

**Assignment 3: Infrastructure as Code (IaC) + Cloud Deployment**

This guide demonstrates deploying the CI/CD Pipeline Health Dashboard (from Assignment 2) to AWS using Terraform (Infrastructure as Code).

## 🎯 Overview

- **Infrastructure**: AWS EC2, VPC, Security Groups
- **Application**: Containerized Node.js backend + React frontend
- **IaC Tool**: Terraform
- **Cloud Provider**: AWS
- **AI Tools Used**: Cursor AI for code generation and debugging

## 📋 Prerequisites

### 1. Install Required Tools

```bash
# Install Terraform
# macOS
brew install terraform

# Windows (using Chocolatey)
choco install terraform

# Linux
sudo apt-get update && sudo apt-get install terraform
```

```bash
# Install AWS CLI
# macOS
brew install awscli

# Windows
# Download from: https://aws.amazon.com/cli/
# Linux
sudo apt-get install awscli
```

### 2. AWS Setup

#### Configure AWS Credentials
```bash
aws configure
# Enter your:
# - AWS Access Key ID
# - AWS Secret Access Key  
# - Default region (e.g., us-east-1)
# - Default output format (json)
```

#### Verify AWS Access
```bash
aws sts get-caller-identity
```

### 3. Generate SSH Key Pair

```bash
# Generate a new SSH key pair for EC2 access
ssh-keygen -t rsa -b 2048 -f cicd-dashboard-key

# This creates:
# - cicd-dashboard-key (private key - keep secure!)
# - cicd-dashboard-key.pub (public key - for Terraform)
```

## 🚀 Deployment Steps

### Step 1: Clone and Navigate to Infrastructure

```bash
cd /Users/sanketp/Downloads/AI-Native/Assignment_3_Sanket_Patharkar/infra
```

### Step 2: Configure Terraform Variables

```bash
# Copy the example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
nano terraform.tfvars
```

**Required Configuration:**
```hcl
# terraform.tfvars
aws_region = "us-east-1"
project_name = "cicd-dashboard"
environment = "dev"
instance_type = "t3.micro"

# IMPORTANT: Add your public key content here
public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ... your-public-key-content"

# Optional: Your GitHub repo URL
github_repo_url = "https://github.com/your-username/ci-cd-health-dashboard.git"
```

**To get your public key content:**
```bash
cat cicd-dashboard-key.pub
# Copy the entire output and paste into terraform.tfvars
```

### Step 3: Initialize Terraform

```bash
terraform init
```

This downloads the AWS provider and prepares the working directory.

### Step 4: Plan the Infrastructure

```bash
terraform plan
```

Review the planned resources:
- VPC with public subnet
- Internet Gateway and Route Table
- Security Group (ports 22, 80, 4000, 8080)
- EC2 instance with application deployment
- SSH Key Pair

### Step 5: Apply the Infrastructure

```bash
terraform apply
```

Type `yes` when prompted. This process takes 5-10 minutes to:
1. Create AWS infrastructure
2. Launch EC2 instance
3. Install Docker and dependencies
4. Deploy the containerized application

### Step 6: Get Deployment Information

```bash
# View outputs
terraform output

# Example output:
# dashboard_frontend_url = "http://ec2-xx-xx-xx-xx.compute-1.amazonaws.com:8080"
# dashboard_api_url = "http://ec2-xx-xx-xx-xx.compute-1.amazonaws.com:4000"
# instance_public_ip = "xx.xx.xx.xx"
# ssh_connection_command = "ssh -i cicd-dashboard-key.pem ec2-user@ec2-xx-xx-xx-xx.compute-1.amazonaws.com"
```

## 🔍 Verification & Testing

### 1. Test Application Access

```bash
# Get the public IP
PUBLIC_IP=$(terraform output -raw instance_public_ip)

# Test API health endpoint
curl http://$PUBLIC_IP:4000/api/health

# Test frontend (open in browser)
echo "Frontend URL: http://$PUBLIC_IP:8080"
echo "API URL: http://$PUBLIC_IP:4000"
```

### 2. SSH into Instance (Optional)

```bash
# SSH into the instance
ssh -i cicd-dashboard-key ec2-user@$(terraform output -raw instance_public_ip)

# Check application status
sudo docker ps
sudo docker logs cicd-dashboard_backend_1
sudo docker logs cicd-dashboard_frontend_1
```

### 3. Monitor Application Logs

```bash
# View deployment logs
ssh -i cicd-dashboard-key ec2-user@$(terraform output -raw instance_public_ip)
sudo tail -f /var/log/user-data.log
```

## 🧪 Application Features

Once deployed, the dashboard provides:

### Frontend (Port 8080)
- **Real-time Metrics**: Success rate, total runs, average build time
- **Recent Builds Table**: Latest 20 pipeline executions
- **Auto-refresh**: Updates every 30 seconds
- **Demo Mode**: Automatically generates sample data

### API Endpoints (Port 4000)
```bash
# Health check
GET /api/health

# Pipeline metrics summary
GET /api/metrics/summary

# Latest builds
GET /api/builds/latest?limit=20

# Real-time events (SSE)
GET /api/events/stream

# Webhook endpoints for CI/CD integration
POST /api/webhook/gha     # GitHub Actions
POST /api/webhook/jenkins # Jenkins
```

### Example API Usage
```bash
# Test API endpoints
curl http://$PUBLIC_IP:4000/api/health
curl http://$PUBLIC_IP:4000/api/metrics/summary
curl http://$PUBLIC_IP:4000/api/builds/latest?limit=5
```

## 🔧 Troubleshooting

### Common Issues

#### 1. Application Not Accessible
```bash
# Check security group rules
aws ec2 describe-security-groups --group-ids $(terraform output -raw security_group_id)

# Check instance status
aws ec2 describe-instances --instance-ids $(terraform output -raw instance_id)
```

#### 2. SSH Connection Issues
```bash
# Ensure correct key permissions
chmod 600 cicd-dashboard-key

# Verify key pair name
aws ec2 describe-key-pairs --key-names cicd-dashboard-key
```

#### 3. Application Startup Issues
```bash
# SSH into instance and check logs
ssh -i cicd-dashboard-key ec2-user@$(terraform output -raw instance_public_ip)
sudo tail -f /var/log/user-data.log
sudo docker ps -a
sudo docker logs cicd-dashboard_backend_1
```

#### 4. Terraform State Issues
```bash
# If state gets corrupted
terraform refresh

# Force unlock if needed
terraform force-unlock LOCK_ID
```

## 🧹 Cleanup

### Destroy Infrastructure
```bash
# Remove all AWS resources
terraform destroy

# Confirm by typing 'yes'
```

### Local Cleanup
```bash
# Remove SSH keys (optional)
rm cicd-dashboard-key cicd-dashboard-key.pub

# Remove Terraform state files (optional)
rm terraform.tfstate terraform.tfstate.backup
```

## 💰 Cost Estimation

**Estimated AWS Costs (us-east-1):**
- **t3.micro EC2**: ~$8.50/month (Free tier: 750 hours/month)
- **EBS Volume**: ~$0.80/month for 8GB
- **Data Transfer**: ~$0.90/month for 1GB outbound
- **Total**: ~$10.20/month (or FREE with AWS Free Tier)

## 🤖 AI-Native Workflow

### AI Tools Used:

1. **Cursor AI**:
   - Generated complete Terraform configurations
   - Created user data script for automated deployment
   - Generated React frontend components
   - Assisted with troubleshooting and optimization

2. **Example AI Prompts Used**:
   ```
   "Generate Terraform configuration for AWS EC2 deployment with VPC, security groups, and automated Docker installation"
   
   "Create a user data script that installs Docker, clones a repository, and starts a containerized application"
   
   "Generate a React dashboard component that displays CI/CD metrics with real-time updates"
   ```

3. **AI-Assisted Debugging**:
   - Identified missing dependencies in Dockerfiles
   - Optimized security group rules
   - Fixed environment variable configurations

### Benefits of AI-Native Approach:
- **Rapid Prototyping**: Generated complete infrastructure in minutes
- **Best Practices**: AI suggested security and performance optimizations
- **Error Prevention**: Caught common configuration mistakes early
- **Documentation**: Auto-generated comprehensive documentation

## 📚 Infrastructure Components

### Created AWS Resources:
1. **VPC** (`10.0.0.0/16`) - Isolated network environment
2. **Public Subnet** (`10.0.1.0/24`) - For internet-accessible resources
3. **Internet Gateway** - Enables internet access
4. **Route Table** - Routes traffic to internet gateway
5. **Security Group** - Firewall rules for ports 22, 80, 4000, 8080
6. **Key Pair** - SSH access to EC2 instance
7. **EC2 Instance** - t3.micro running Amazon Linux 2

### Application Architecture:
```
Internet → ALB/CloudFront (optional) → EC2 Instance
                                        ├── Docker: Frontend (React)
                                        └── Docker: Backend (Node.js)
```

## 🔗 Next Steps

1. **Domain & SSL**: Add custom domain with SSL certificate
2. **Load Balancer**: Add ALB for high availability
3. **Auto Scaling**: Implement auto-scaling groups
4. **Database**: Replace in-memory storage with RDS
5. **Monitoring**: Add CloudWatch dashboards and alerts
6. **CI/CD**: Automate deployment with GitHub Actions

## 📝 Assignment Deliverables Checklist

- ✅ **Terraform Scripts**: Complete IaC in `/infra` folder
- ✅ **Live Dashboard**: Accessible via public URL
- ✅ **Deployment Guide**: This comprehensive guide
- ✅ **AI-Native Workflow**: Documented AI tool usage
- ✅ **Infrastructure Provisioning**: No manual AWS console clicks
- ✅ **Application Deployment**: Fully automated via Terraform

## 🎉 Success Criteria Met

1. **Cloud Deployment**: ✅ App running on AWS EC2
2. **Infrastructure as Code**: ✅ 100% Terraform-managed
3. **Public Accessibility**: ✅ Available via public IP/DNS
4. **AI-Native Development**: ✅ Generated with Cursor AI
5. **Documentation**: ✅ Complete deployment guide
6. **Reproducible**: ✅ One-command deployment

---

**Assignment 3 Complete!** 🚀

Your CI/CD Pipeline Health Dashboard is now running in the cloud with infrastructure fully managed by Terraform code.
