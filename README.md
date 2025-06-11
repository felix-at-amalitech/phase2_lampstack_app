# phase2_lampstack_appd

LAMP Stack Application on AWS: Project Documentation

1. Project Overview
1.1 Purpose
This project deploys a simple LAMP (Linux, Apache, MySQL, PHP) stack application on AWS using the AWS Management Console, showcasing a scalable, highly available, and secure web application. The application displays a table of healthy Ghanaian fruits and their benefits, retrieved from an RDS MySQL database, served by Apache and PHP on EC2 instances in an Auto Scaling group behind an Application Load Balancer (ALB). The deployment adheres to the AWS Well-Architected Framework, focusing on scalability, availability, security, cost optimization, and operational excellence.
1.2 Objectives

Deploy a modular LAMP stack with separate network, database, and application layers.
Ensure scalability via Auto Scaling and load balancing.
Achieve high availability with multi-AZ deployments.
Secure credentials using AWS Systems Manager (SSM) Parameter Store and IAM roles.
Resolve issues like character set mismatches and SSM parameter retrieval failures.
Provide comprehensive documentation for setup, maintenance, and troubleshooting.

1.3 Application Description

Functionality: A PHP webpage (index.php) displays a table of fruits (e.g., Pineapple, Mango) and their health benefits, queried from a MySQL table (healthy_fruits).
Traffic Estimate: Low-traffic demo (100–500 daily users, ~50 requests/second peak).
Security Level: Moderate, suitable for non-critical applications with non-sensitive data.

2. Architecture
2.1 Components

Network Layer:
VPC: LAMP-VPC (CIDR: 10.0.0.0/16).
Subnets: Two public subnets (LAMP-Public-Subnet-1, LAMP-Public-Subnet-2) in different Availability Zones (e.g., eu-west-1a, eu-west-1b).
Internet Gateway: LAMP-IGW for internet access.
Route Table: LAMP-Public-RouteTable with a route to 0.0.0.0/0 via LAMP-IGW.

Database Layer:
RDS MySQL: Instance lampdb (MySQL 8.0, db.t3.micro), Multi-AZ (optional for production), in a subnet group (lamp-db-subnet-group).
Security Group: LAMP-DB-SG allows MySQL (port 3306) from LAMP-Web-SG.
Credentials: Stored in SSM Parameter Store (/lamp/db/username, /lamp/db/password).

Application Layer:
EC2 Instances: Amazon Linux 2 (t3.micro), running Apache, PHP, and MySQL client, deployed via Auto Scaling group (LAMP-ASG).
Launch Template: LAMP-LaunchTemplate with user data script to configure Apache, PHP, and database.
ALB: LAMP-ALB distributes traffic across instances, with target group LAMP-TargetGroup.
Security Group: LAMP-Web-SG allows HTTP (80), SSH (22, restricted in production), and outbound MySQL (3306) to LAMP-DB-SG.
IAM Role: LAMP-EC2-SSM-Role for SSM Parameter Store access.

2.2 Architecture Diagram

Internet
  |
[ALB: LAMP-ALB]
  | HTTP:80
[Target Group: LAMP-TargetGroup]
  |
[Auto Scaling Group: LAMP-ASG]
  | (t3.micro, 2-4 instances)
[EC2 Instances]
  | Apache, PHP, MySQL Client
  | User Data: Configures index.php, DB
  | IAM Role: LAMP-EC2-SSM-Role
  | SSM Parameters: /lamp/db/*
  |
[VPC: LAMP-VPC]
  | Subnets: LAMP-Public-Subnet-1, LAMP-Public-Subnet-2
  | Security Groups: LAMP-Web-SG, LAMP-DB-SG
  | Route Table: LAMP-Public-RouteTable -> IGW
  |
[RDS MySQL: lampdb]
  | Multi-AZ (optional)
  | Subnet Group: lamp-db-subnet-group
  | Database: lampdb, Table: healthy_fruits

2.3 Well-Architected Framework Alignment

Scalability: Auto Scaling group (2–4 instances) and ALB handle traffic spikes; RDS supports future read replicas.
Availability: Multi-AZ subnets and optional Multi-AZ RDS ensure uptime; ALB health checks maintain reliability.
Security: IAM role for SSM access, security groups restrict traffic, utf8mb4 prevents charset issues.
Cost Optimization: t3.micro instances and SSM Parameter Store minimize costs.
Operational Excellence: Modular setup, extensive logging, and retry logic simplify management.

3. Setup Instructions

3.1 Prerequisites

AWS Account: Permissions for VPC, EC2, RDS, ALB, Auto Scaling, SSM, IAM.
Region: eu-west-1 (update AMI ID and endpoint if different).
Browser: AWS Management Console access.
Time Estimate: ~1–2 hours.

3.2 Step-by-Step Setup
3.2.1 Network Layer

Create VPC:
VPC > Create VPC.
Name: LAMP-VPC, CIDR: 10.0.0.0/16.
Enable DNS hostnames/support.

Create Subnets:
Subnets > Create subnet.
Subnet 1: Name: LAMP-Public-Subnet-1, AZ: eu-west-1a, CIDR: 10.0.1.0/24.
Subnet 2: Name: LAMP-Public-Subnet-2, AZ: eu-west-1b, CIDR: 10.0.2.0/24.
Enable auto-assign public IP for both.

Create Internet Gateway:
Internet Gateways > Create > Name: LAMP-IGW.
Attach to LAMP-VPC.

Create Route Table:
Route Tables > Create > Name: LAMP-Public-RouteTable, VPC: LAMP-VPC.
Routes > Add: 0.0.0.0/0 -> LAMP-IGW.
Subnet associations: LAMP-Public-Subnet-1, LAMP-Public-Subnet-2.

3.2.2 Database Layer

Create Security Group:
VPC > Security Groups > Create.
Name: LAMP-DB-SG, VPC: LAMP-VPC.
Inbound: MySQL (3306) from 10.0.0.0/16.

Create Subnet Group:
RDS > Subnet Groups > Create.
Name: lamp-db-subnet-group, VPC: LAMP-VPC.
Subnets: LAMP-Public-Subnet-1, LAMP-Public-Subnet-2.

Create SSM Parameters:
Systems Manager > Parameter Store > Create parameter.
/lamp/db/username: String, Value: admin.
/lamp/db/password: SecureString, Value: 16-character password (exclude "@/\\).

Create RDS Instance:
RDS > Create database > MySQL, Free tier or db.t3.micro.
Identifier: lampdb, Username: admin, Password: Use SSM (/lamp/db/password).
VPC: LAMP-VPC, Subnet group: lamp-db-subnet-group, Security group: LAMP-DB-SG.
Database: lampdb, Multi-AZ (optional), Disable deletion protection.
Note endpoint: lampdb.czaiaq68azf6.eu-west-1.rds.amazonaws.com.

3.2.3 Application Layer

Create IAM Role:
IAM > Roles > Create role > EC2.
Policy:{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["ssm:GetParameter", "ssm:GetParameters"],
      "Resource": "arn:aws:ssm:eu-west-1:<account-id>:parameter/lamp/db/*"
    }
  ]
}

Name: LAMP-EC2-SSM-Role.

Create Security Group:
VPC > Security Groups > Create.
Name: LAMP-Web-SG, VPC: LAMP-VPC.
Inbound: HTTP (80) from 0.0.0.0/0, SSH (22) from 0.0.0.0/0 (restrict in production).
Outbound: MySQL (3306) to LAMP-DB-SG, HTTPS (443) to 0.0.0.0/0 (for SSM).

Create Launch Template:
EC2 > Launch Templates > Create.
Name: LAMP-LaunchTemplate, AMI: Amazon Linux 2 (e.g., ami-0c55b159cbfafe1f0).
Instance type: t3.micro, IAM profile: LAMP-EC2-SSM-Role.
Security group: LAMP-Web-SG.
User data: Use the script below (from previous response, addressing SSM retrieval and charset issues).

Create ALB:
EC2 > Load Balancers > Create > Application Load Balancer.
Name: LAMP-ALB, Internet-facing, VPC: LAMP-VPC.
Subnets: LAMP-Public-Subnet-1, LAMP-Public-Subnet-2.
Security group: LAMP-Web-SG.
Listener: HTTP:80, Target group: LAMP-TargetGroup (HTTP, port 80, health check: /).

Create Auto Scaling Group:
EC2 > Auto Scaling Groups > Create.
Name: LAMP-ASG, Launch template: LAMP-LaunchTemplate.
VPC: LAMP-VPC, Subnets: LAMP-Public-Subnet-1, LAMP-Public-Subnet-2.
Target group: LAMP-TargetGroup.
Desired: 2, Min: 2, Max: 4, Health checks: ELB, Grace period: 300 seconds.

3.3 User Data Script
The script configures Apache, PHP, and the database, retrieves credentials from SSM, and addresses issues like character set mismatches and SSM retrieval failures. See fruits_lamp_app.sh for details of the user data script.

4. Verification and Testing
4.1 Verification Steps

Access Application:
Visit the ALB DNS name at [http://LAMP-ALB-123456789.eu-west-1.elb.amazonaws.com](http://LAMP-ALB-123456789.eu-west-1.elb.amazonaws.com).
Confirm the “Healthy Ghanaian Fruits” table displays fruits and benefits.

Check Logs:
SSH into an EC2 instance (if key pair enabled).
User data log: cat /var/log/user-data.log (verify SSM retrieval).
Apache errors: cat /var/log/httpd/error_log.
Cloud-init: cat /var/log/cloud-init-output.log.

Monitor CloudWatch:
CloudWatch > Metrics > EC2: CPU utilization for LAMP-ASG.
ALB: RequestCount, HealthyHostCount.
RDS: DatabaseConnections, CPUUtilization.

4.2 Testing

Scalability: Simulate load (e.g., using ab) to verify Auto Scaling adds instances at 70% CPU.
Availability: Terminate an EC2 instance; confirm ALB routes traffic and Auto Scaling replaces it.
Security: Verify only HTTP (80) is accessible on ALB; RDS is not publicly accessible.

5. Troubleshooting
5.1 Common Issues and Fixes

SSM Parameter Retrieval Failure in User Data:
Symptom: DB_USER and DB_PASS are empty in /var/log/user-data.log.
Cause: IAM role credentials or network unavailable during user data execution.
Fix:
Check /var/log/user-data.log for errors (e.g., “Failed to retrieve /lamp/db/username”).
Verify IAM role permissions and attachment.
Ensure subnets have public IPs or NAT Gateway; LAMP-Web-SG allows outbound HTTPS (443).
Test SSM manually: aws ssm get-parameter --name "/lamp/db/username" --region eu-west-1.

Character Set Error:
Symptom: “Server sent charset unknown to the client”.
Cause: Incompatible MySQL client or charset mismatch.
Fix: Script uses MySQL Community Client and utf8mb4; verify RDS parameter group (character_set_client, character_set_database set to utf8mb4).

Database Connection Failure:
Symptom: “Connection failed” on webpage.
Cause: Incorrect RDS endpoint, credentials, or security group rules.
Fix:
Verify endpoint: lampdb.czaiaq68azf6.eu-west-1.rds.amazonaws.com.
Check SSM parameters: /lamp/db/username, /lamp/db/password.
Ensure LAMP-Web-SG allows outbound 3306 to LAMP-DB-SG.

5.2 Debugging

Logs: /var/log/user-data.log (SSM errors), /var/log/httpd/error_log (PHP errors).
Manual Testing:
SSH into instance: mysql -h lampdb.czaiaq68azf6.eu-west-1.rds.amazonaws.com -u <user> -p<password> --default-character-set=utf8mb4 lampdb.
Test SSM: aws ssm get-parameter --name "/lamp/db/username" --region eu-west-1.

CloudWatch Logs: Enable if needed for centralized logging.

6. Maintenance
6.1 Monitoring

CloudWatch:
Metrics: EC2 CPU, ALB latency, RDS connections.
Alarms: CPU > 70%, unhealthy ALB targets.

RDS Performance Insights: Monitor query performance.

6.2 Updates

AMI Updates: Update LAMP-LaunchTemplate with new Amazon Linux 2 AMI.
PHP/MySQL: Patch vulnerabilities via yum update.
Scaling: Adjust Auto Scaling group (e.g., Max: 6) for higher traffic.

6.3 Backup

RDS: Enable automated backups (7-day retention).
Application Code: Store index.php and user data script in version control (e.g., GitHub).

7. Clean Up
To avoid charges, delete resources in reverse order upon use completion:

Auto Scaling Group:
EC2 > Auto Scaling Groups > LAMP-ASG > Delete.

ALB and Target Group:
EC2 > Load Balancers > LAMP-ALB > Delete.
Target Groups > LAMP-TargetGroup > Delete.

Launch Template:
EC2 > Launch Templates > LAMP-LaunchTemplate > Delete.

RDS Instance:
RDS > Databases > lampdb > Delete (disable final snapshot).

SSM Parameters:
Systems Manager > Parameter Store > Delete /lamp/db/username, /lamp/db/password.

Security Groups:
VPC > Security Groups > Delete LAMP-Web-SG, LAMP-DB-SG.

VPC Resources:
Subnet Group: lamp-db-subnet-group.
Route Table: LAMP-Public-RouteTable.
Subnets: LAMP-Public-Subnet-1, LAMP-Public-Subnet-2.
Internet Gateway: LAMP-IGW.
VPC: LAMP-VPC.

8. Production Enhancements

Security:
Restrict SSH in LAMP-Web-SG to specific IPs.
Enable HTTPS on ALB with AWS Certificate Manager.
Add AWS WAF to ALB for web attack protection.

Network: Use private subnets for EC2 and RDS with NAT Gateway.
Database: Enable Multi-AZ RDS and read replicas for high availability.
Monitoring: Use CloudWatch Logs Insights for centralized logs.
CI/CD: Automate updates with AWS CodePipeline.

9. Appendix
9.1 Key Resources

VPC: LAMP-VPC (10.0.0.0/16).
RDS: lampdb.czaiaq68azf6.eu-west-1.rds.amazonaws.com.
ALB: LAMP-ALB-123456789.eu-west-1.elb.amazonaws.com.
SSM: /lamp/db/username, /lamp/db/password.

9.2 References

AWS Well-Architected Framework: <https://aws.amazon.com/architecture/well-architected/>
RDS MySQL: <https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_MySQL.html>
SSM Parameter Store: <https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html>

9.3 Version History

June 09, 2025: Initial deployment with SSM Parameter Store, charset fix, and retry logic.

10. Contact
For issues, contact the creator of this project <felix.frimpong@amalitechtraining.org>
