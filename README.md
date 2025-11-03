# terraform-3tier-app
This project demonstrates the deployment of a three-tier web application architecture on AWS, fully automated using Terraform.


---

## Technologies Used
- **AWS:** VPC, EC2, RDS, Security Groups  
- **Terraform:** Infrastructure as Code  
- **Flask:** Python backend  
- **MySQL:** Database layer  
- **HTML/CSS:** Static frontend  

---

## Key Features
- Automated provisioning of a 3-tier architecture
- Secure communication between public and private layers
- Integration of frontend, backend, and database
- Demonstrates DevOps and IaC best practices

---

## Author
**Mohamed Emad Elshafei**  
System Administrator Trainee at ITI  
Skills: AWS, Terraform, Linux, Python, Flask, MySQL, DevOps Automation

---

## How to Use
1. Clone the repository
2. Ensure AWS credentials are configured
3. Run `terraform init` and `terraform apply` to deploy the infrastructure
4. Access the frontend via the public IP of the frontend EC2
5. Backend API is accessible on port 5000 via the backend EC2 public IP

