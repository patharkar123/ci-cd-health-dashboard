# AI-Native Assignment 3: Infrastructure as Code + Cloud Deployment

**CI/CD Pipeline Health Dashboard - Cloud Deployment**

This project demonstrates deploying the CI/CD Pipeline Health Dashboard (from Assignment 2) to AWS cloud using Infrastructure as Code (Terraform) with AI-native development workflow.

## 🎯 Project Overview

- **Base Application**: CI/CD Pipeline Health Dashboard (Assignment 2)
- **Cloud Provider**: AWS (EC2, VPC, Security Groups)
- **IaC Tool**: Terraform
- **Deployment**: Fully automated with Docker containers
- **AI Tools**: Cursor AI, Claude Sonnet 4, GitHub Copilot

## 📁 Project Structure

```
Assignment_3_Sanket_Patharkar/
├── infra/                          # Terraform Infrastructure Code
│   ├── main.tf                     # Main infrastructure configuration
│   ├── variables.tf                # Input variables
│   ├── outputs.tf                  # Output values
│   ├── user_data.sh               # EC2 startup script
│   └── terraform.tfvars.example   # Example configuration
├── deployment.md                   # Complete deployment guide
├── prompts.md                     # AI prompt logs
└── README.md                      # This file
```

## 🚀 Quick Start

### Prerequisites
- AWS Account with CLI configured
- Terraform installed
- SSH key pair generated

### Deploy in 3 Commands
```bash
# 1. Navigate to infrastructure directory
cd infra/

# 2. Configure variables (copy terraform.tfvars.example to terraform.tfvars and edit)
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your SSH public key

# 3. Deploy infrastructure and application
terraform init
terraform apply
```

### Access Your Dashboard
```bash
# Get the public URL
terraform output dashboard_frontend_url
terraform output dashboard_api_url
```

## 🏗️ Infrastructure Components

### AWS Resources Created:
- **VPC** with public subnet (10.0.0.0/16)
- **Internet Gateway** for public access
- **Security Group** with minimal required ports
- **EC2 Instance** (t3.micro) running Amazon Linux 2
- **SSH Key Pair** for instance access

### Application Stack:
- **Backend**: Node.js Express API (Port 4000)
- **Frontend**: React Dashboard (Port 8080)
- **Database**: In-memory storage (no external DB needed)
- **Containers**: Docker with docker-compose orchestration

## 🔧 Features

### Dashboard Capabilities:
- Real-time CI/CD pipeline metrics
- Success/failure rate tracking
- Average build time monitoring
- Recent builds table (last 20 executions)
- Live updates via Server-Sent Events (SSE)
- Demo mode with synthetic data generation

### API Endpoints:
- `GET /api/health` - Health check
- `GET /api/metrics/summary` - Pipeline metrics
- `GET /api/builds/latest` - Recent builds
- `GET /api/events/stream` - Real-time events
- `POST /api/webhook/gha` - GitHub Actions webhook
- `POST /api/webhook/jenkins` - Jenkins webhook

## 🤖 AI-Native Development

### AI Tools Used:
1. **Cursor AI**: Primary development assistant for code generation
2. **Claude Sonnet 4**: Architecture design and complex problem solving
3. **GitHub Copilot**: Code completion and optimization suggestions

### AI-Generated Components:
- Complete Terraform infrastructure (main.tf, variables.tf, outputs.tf)
- EC2 user data script with full application deployment
- React frontend with dashboard components
- Node.js backend with all API endpoints
- Comprehensive documentation and guides

### Productivity Gains:
- **Development Time**: 4 hours vs 15-20 hours manual
- **Code Quality**: Industry best practices automatically applied
- **Documentation**: Comprehensive guides auto-generated
- **Error Prevention**: Common pitfalls avoided through AI suggestions

## 💰 Cost Estimation

**AWS Free Tier Eligible:**
- t3.micro EC2 instance: 750 hours/month free
- 8GB EBS storage: Included
- Data transfer: 1GB outbound free

**Post Free Tier (~$10/month):**
- EC2 t3.micro: ~$8.50/month
- EBS 8GB: ~$0.80/month  
- Data transfer: ~$0.90/month

## 🔍 Testing & Validation

### Automated Tests:
```bash
# API Health Check
curl http://$(terraform output -raw instance_public_ip):4000/api/health

# Dashboard Access
curl -I http://$(terraform output -raw instance_public_ip):8080

# Metrics Endpoint
curl http://$(terraform output -raw instance_public_ip):4000/api/metrics/summary
```

### Manual Verification:
1. Open dashboard URL in browser
2. Verify real-time metric updates
3. Check recent builds table
4. Test API endpoints with curl/Postman

## 🧹 Cleanup

```bash
# Destroy all AWS resources
terraform destroy

# Remove local files (optional)
rm terraform.tfstate* terraform.tfvars
```

## 📚 Documentation

### Complete Guides Available:
- **[deployment.md](deployment.md)**: Step-by-step deployment guide
- **[prompts.md](prompts.md)**: AI prompt logs and workflow
- **terraform.tfvars.example**: Configuration template

### Key Topics Covered:
- Prerequisites and setup
- Terraform deployment process
- Application testing and verification
- Troubleshooting common issues
- AI tool usage and best practices
- Cost optimization and cleanup

## 🎯 Assignment Requirements Met

- ✅ **Infrastructure as Code**: 100% Terraform-managed AWS resources
- ✅ **Cloud Deployment**: Live dashboard accessible via public URL
- ✅ **AI-Native Workflow**: Complete development using AI tools
- ✅ **Documentation**: Comprehensive guides and prompt logs
- ✅ **Automation**: Zero-click deployment after initial setup

## 🔧 Troubleshooting

### Common Issues:
1. **SSH Access**: Ensure key permissions (`chmod 600 key-file`)
2. **Application Startup**: Check user data logs (`/var/log/user-data.log`)
3. **Network Access**: Verify security group rules
4. **Terraform State**: Use `terraform refresh` if state issues occur

### Debug Commands:
```bash
# SSH into instance
ssh -i cicd-dashboard-key ec2-user@$(terraform output -raw instance_public_ip)

# Check containers
sudo docker ps
sudo docker logs cicd-dashboard_backend_1

# View deployment logs
sudo tail -f /var/log/user-data.log
```

## 🚀 Next Steps

### Potential Enhancements:
1. **Custom Domain**: Add Route53 DNS and SSL certificate
2. **Load Balancing**: Implement Application Load Balancer
3. **Auto Scaling**: Add auto-scaling groups for high availability
4. **Database**: Replace in-memory storage with RDS
5. **Monitoring**: Add CloudWatch dashboards and alerts
6. **CI/CD Pipeline**: Automate deployment with GitHub Actions

### Production Considerations:
- Restrict security group CIDR blocks
- Enable detailed monitoring and logging
- Implement backup and disaster recovery
- Add environment-specific configurations
- Set up cost monitoring and alerts

## 📞 Support

For issues or questions:
1. Check the [deployment guide](deployment.md) for detailed instructions
2. Review [prompt logs](prompts.md) for AI-assisted troubleshooting
3. Validate AWS configuration and permissions
4. Check Terraform state and resource status

---

**Assignment Status**: ✅ Complete
**Deployment Time**: ~10 minutes
**AI Development Time**: ~4 hours
**Infrastructure**: 100% Code-managed
**Public Access**: ✅ Live Dashboard Available

*Demonstrating the power of AI-native development for cloud infrastructure and application deployment.*
