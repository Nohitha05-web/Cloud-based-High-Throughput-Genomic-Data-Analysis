# Cloud-Based High-Throughput Genomic Data Analysis

## Overview:

This repository implements an automated, Infrastructure as Code (IaC) pipeline for high-throughput analysis of genomic data using AWS cloud services. We provision an S3 bucket for storage and an EC2 instance for compute with Terraform, upload the liver gene expression dataset (human_liver.tsv—35,238 genes x 903 samples from NCBI GEO), run a Python script for mean/median/variance stats and visualization (top 100 expressed genes + histogram), and retrieve results. The pipeline is reproducible, scalable, and free-tier eligible.

### Features:
- **IaC with Terraform:** Automated provisioning of S3, EC2, IAM roles, and security groups — no manual AWS Console steps required.
- **High-Throughput Analysis:** Chunked processing for large TSV files to avoid memory errors on `t3.micro` instances.
- **Direct S3 Integration:** Data is loaded directly from S3 using `boto3` — no local downloads needed.
- **Visualization:** Seaborn-based histogram of mean gene expression distribution.
- **Version Control:** All code, data, and results are tracked and committed to GitHub.
- **Cost-Effective:** Runs within the AWS Free Tier ($\sim\$0$ for demo runs).

### Prerequisites:

- **AWS Account (Free Tier):** Sign up at [aws.amazon.com](https://aws.amazon.com).
- **Terraform:** Version **v1.5+**.
- **AWS CLI:** Installed and configured using `aws configure` with IAM access key/secret, and region set to `us-east-1`.
- **Git:** For repository management.
- **Python:** Version **3.7+** (used locally for testing; EC2 installs via `user_data`).
- **EC2 Key Pair:** Create `your-ec2-keypair` in the AWS Console  
  → **EC2 > Key Pairs > Create**  
  → Download the `.pem` file  
  → Run  
  ```bash
  chmod 400 your-ec2-keypair.pem

### IAM Permissions: Attach to your IAM user (nohitha-genomics):

- `AmazonEC2FullAccess`
- `AmazonS3FullAccess`
- `IAMFullAccess`
- `AmazonSSMReadOnlyAccess`
- `AmazonS3ReadOnlyAccess`
- `IAMReadOnlyAccess`
- `AmazonEC2ReadOnlyAccess`


### Installation:

#### 1. Clone the repository:

### 1. Clone the Repository

- git clone https://github.com/Nohitha05-web/Cloud-based-High-Throughput-Genomic-Data-Analysis.git
- cd Cloud-based-High-Throughput-Genomic-Data-Analysis 

### 2. Initialize Git:

git init
git remote add origin https://github.com/Nohitha05-web/Cloud-based-High-Throughput-Genomic-Data-Analysis.git

### 3. Configure AWS CLI:

aws configure

#### 4. Customize main.tf:

curl ifconfig.me

Replace YOUR_PUBLIC_IP/32 in security group with your IP
Ensure key_name = "your-ec2-keypair"

### Usage:
#### 1. Provision Infrastructure

terraform init 
terraform plan  
terraform apply --auto-approve


#### Outputs:

ec2_public_ip = "34.224.168.140"
s3_bucket_name = "nohitha-genomics-hpc-zcpnbw61"
latest_ami_id = <sensitive>

### 2. Upload Dataset to S3

aws s3 cp human_liver.tsv s3://nohitha-genomics-hpc-zcpnbw61/

### 3. SSH to EC2 and Run Analysis
chmod 400 your-ec2-keypair.pem  
ssh -i your-ec2-keypair.pem ec2-user@34.224.168.140


#### Inside EC2:
pip3 install boto3 statsmodels    #install libraries
python3 analyze_genomics.py     # Run script 


### 4. Upload Results to S3:
Inside EC2:
aws s3 cp liver_expression_summary.csv s3://nohitha-genomics-hpc-zcpnbw61/
aws s3 cp top_expressed_genes.csv s3://nohitha-genomics-hpc-zcpnbw61/
aws s3 cp expression_histogram.png s3://nohitha-genomics-hpc-zcpnbw61/
exit


### 5. Download Results Locally

aws s3 cp s3://nohitha-genomics-hpc-zcpnbw61/top_expressed_genes.csv .
aws s3 cp s3://nohitha-genomics-hpc-zcpnbw61/liver_expression_summary.csv .
aws s3 cp s3://nohitha-genomics-hpc-zcpnbw61/expression_histogram.png .
head top_expressed_genes.csv 
xdg-open expression_histogram.png


### Results:
- **Top Expressed Genes** (`top_expressed_genes.csv`):  
  Contains the 100 genes with the highest mean expression (e.g., `ALB`, `GAPDH`).  
  Columns: `gene`, `mean_expr`, `median_expr`, `var_expr`.

- **Full Summary** (`liver_expression_summary.csv`):  
  Statistical summary for all **35,000** genes.

- **Visualization** (`expression_histogram.png`):  
  Right-skewed histogram of mean expression with **blue bars**, a **KDE curve**, and a **red line** marking the top gene.

### Cleanup:
To avoid costs:
terraform destroy --auto-approve
 
