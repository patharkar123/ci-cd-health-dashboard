#!/bin/bash
# Quick Deployment Script for CI/CD Dashboard
# Generated with AI assistance (Cursor)

set -e

echo "🚀 CI/CD Dashboard - Quick Deployment Script"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install it first:"
        echo "  macOS: brew install terraform"
        echo "  Linux: sudo apt-get install terraform"
        echo "  Windows: choco install terraform"
        exit 1
    fi
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first:"
        echo "  macOS: brew install awscli"
        echo "  Linux: sudo apt-get install awscli"
        echo "  Windows: Download from AWS website"
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured. Please run:"
        echo "  aws configure"
        exit 1
    fi
    
    print_success "All prerequisites met!"
}

# Setup configuration
setup_config() {
    print_status "Setting up configuration..."
    
    cd infra/
    
    # Check if terraform.tfvars exists
    if [ ! -f "terraform.tfvars" ]; then
        if [ -f "terraform.tfvars.example" ]; then
            print_warning "terraform.tfvars not found. Copying from example..."
            cp terraform.tfvars.example terraform.tfvars
            print_error "Please edit terraform.tfvars and add your SSH public key!"
            echo "Required steps:"
            echo "1. Generate SSH key: ssh-keygen -t rsa -b 2048 -f cicd-dashboard-key"
            echo "2. Copy public key content: cat cicd-dashboard-key.pub"
            echo "3. Edit terraform.tfvars and paste the public key in the 'public_key' field"
            echo "4. Run this script again"
            exit 1
        else
            print_error "terraform.tfvars.example not found!"
            exit 1
        fi
    fi
    
    # Validate terraform.tfvars has public_key
    if grep -q "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ" terraform.tfvars; then
        print_success "Configuration looks good!"
    else
        print_error "Please add your SSH public key to terraform.tfvars"
        echo "Generate one with: ssh-keygen -t rsa -b 2048 -f cicd-dashboard-key"
        echo "Then copy the content of cicd-dashboard-key.pub to terraform.tfvars"
        exit 1
    fi
}

# Deploy infrastructure
deploy() {
    print_status "Initializing Terraform..."
    terraform init
    
    print_status "Planning deployment..."
    terraform plan
    
    echo ""
    read -p "Do you want to proceed with the deployment? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_warning "Deployment cancelled."
        exit 0
    fi
    
    print_status "Applying Terraform configuration..."
    terraform apply -auto-approve
    
    print_success "Infrastructure deployed successfully!"
}

# Display results
show_results() {
    print_status "Getting deployment information..."
    
    echo ""
    echo "🎉 Deployment Complete!"
    echo "======================="
    
    # Get outputs
    FRONTEND_URL=$(terraform output -raw dashboard_frontend_url 2>/dev/null || echo "Not available")
    API_URL=$(terraform output -raw dashboard_api_url 2>/dev/null || echo "Not available")
    PUBLIC_IP=$(terraform output -raw instance_public_ip 2>/dev/null || echo "Not available")
    SSH_COMMAND=$(terraform output -raw ssh_connection_command 2>/dev/null || echo "Not available")
    
    echo ""
    echo "📊 Dashboard URLs:"
    echo "  Frontend: $FRONTEND_URL"
    echo "  API:      $API_URL"
    echo ""
    echo "🌐 Public IP: $PUBLIC_IP"
    echo ""
    echo "🔐 SSH Access:"
    echo "  $SSH_COMMAND"
    echo ""
    
    print_warning "Note: Application startup may take 2-3 minutes after Terraform completes."
    print_status "You can check application logs by SSH-ing into the instance and running:"
    echo "  sudo tail -f /var/log/user-data.log"
    echo "  sudo docker ps"
    echo ""
    
    # Test API health
    print_status "Testing API health (may take a moment)..."
    sleep 30  # Give the application time to start
    
    if curl -s "http://$PUBLIC_IP:4000/api/health" > /dev/null 2>&1; then
        print_success "API is responding!"
    else
        print_warning "API not yet responding - application may still be starting up"
    fi
}

# Cleanup function
cleanup() {
    print_status "Starting cleanup..."
    
    cd infra/
    
    echo ""
    read -p "Are you sure you want to destroy all AWS resources? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        print_warning "Cleanup cancelled."
        exit 0
    fi
    
    terraform destroy -auto-approve
    print_success "All AWS resources destroyed!"
}

# Show help
show_help() {
    echo "CI/CD Dashboard Deployment Script"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  deploy    Deploy the infrastructure and application (default)"
    echo "  cleanup   Destroy all AWS resources"
    echo "  status    Show current deployment status"
    echo "  help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 deploy   # Deploy everything"
    echo "  $0 cleanup  # Destroy everything"
    echo "  $0 status   # Check deployment status"
}

# Show status
show_status() {
    print_status "Checking deployment status..."
    
    if [ ! -d "infra" ]; then
        print_error "Infrastructure directory not found!"
        exit 1
    fi
    
    cd infra/
    
    if [ ! -f "terraform.tfstate" ]; then
        print_warning "No Terraform state found. Infrastructure not deployed."
        exit 0
    fi
    
    # Check if resources exist
    INSTANCE_ID=$(terraform output -raw instance_id 2>/dev/null || echo "")
    
    if [ -n "$INSTANCE_ID" ]; then
        print_success "Infrastructure is deployed!"
        show_results
    else
        print_warning "Infrastructure state exists but resources may not be deployed properly."
    fi
}

# Main script logic
case "${1:-deploy}" in
    "deploy")
        check_prerequisites
        setup_config
        deploy
        show_results
        ;;
    "cleanup")
        cleanup
        ;;
    "status")
        show_status
        ;;
    "help")
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
