#!/bin/bash
set -e

echo "Terraform Infrastructure Architect - Repo Scaffolder" >&2

# --- Defaults ---
PROJECT_NAME=""
ENVIRONMENTS="int,stg,prod"
MAIN_REGION="us-west-2"
PROD_REGION="ap-south-1"
STACKS="vpc,route53,secret-manager,sns"
WITH_EKS=false
WITH_SERVICE=false
SERVICE_NAME="litellm"
AWS_PROVIDER_VERSION="6.3.0"
TERRAFORM_VERSION="1.12.2"

# --- Parse Args ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-name)
      PROJECT_NAME="$2"; shift 2 ;;
    --environments)
      ENVIRONMENTS="$2"; shift 2 ;;
    --main-region)
      MAIN_REGION="$2"; shift 2 ;;
    --prod-region)
      PROD_REGION="$2"; shift 2 ;;
    --stacks)
      STACKS="$2"; shift 2 ;;
    --with-eks)
      WITH_EKS=true; shift ;;
    --with-service)
      WITH_SERVICE=true; shift ;;
    --service-name)
      SERVICE_NAME="$2"; shift 2 ;;
    *)
      echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$PROJECT_NAME" ]]; then
  echo "ERROR: --project-name is required" >&2
  echo "Usage: $0 --project-name <name> [--environments int,stg,prod] [--with-eks] [--with-service]" >&2
  exit 1
fi

OUTPUT_DIR="${PROJECT_NAME}-infra"
mkdir -p "$OUTPUT_DIR"
cd "$OUTPUT_DIR"

# --- Helper Functions ---

write_backend_tf() {
  cat > "$1/backend.tf" <<'EOF'
terraform {
  backend "s3" {
    bucket       = ""
    key          = ""
    region       = ""
    encrypt      = ""
    use_lockfile = ""
  }
}
EOF
}

write_providers_tf() {
  local path="$1"
  local region_var="${2:-var.region}"
  cat > "$path/providers.tf" <<EOF
provider "aws" {
  region = ${region_var}
}
EOF
}

write_terraform_tf() {
  local path="$1"
  cat > "$path/terraform.tf" <<EOF
terraform {
  required_version = ">= ${TERRAFORM_VERSION}"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "${AWS_PROVIDER_VERSION}"
    }
  }
}
EOF
}

write_standard_variables_tf() {
  local path="$1"
  cat > "$path/variables.tf" <<'EOF'
variable "env" {
  type = string
  validation {
    condition     = contains(["int", "stg", "prod"], var.env)
    error_message = "Environment must be one of: int, stg, prod."
  }
}

variable "region" {
  type = string
}
EOF
}

# --- 1. Create Directory Structure ---

mkdir -p terraform/deployments/aws
mkdir -p terraform/deployments/service
mkdir -p terraform/config/aws
mkdir -p terraform/config/service
mkdir -p .github/workflows

echo "Creating foundation stacks: $STACKS" >&2

IFS=',' read -ra STACK_ARRAY <<< "$STACKS"

# --- 2. Scaffold Foundation Stacks ---

for stack in "${STACK_ARRAY[@]}"; do
  stack=$(echo "$stack" | xargs) # trim
  mkdir -p "terraform/deployments/aws/$stack"
  mkdir -p "terraform/config/aws/$stack"

  write_backend_tf "terraform/deployments/aws/$stack"
  write_providers_tf "terraform/deployments/aws/$stack"
  write_terraform_tf "terraform/deployments/aws/$stack"

  case "$stack" in
    vpc)
      cat > "terraform/deployments/aws/vpc/variables.tf" <<'EOF'
variable "env" {
  type = string
  validation {
    condition     = contains(["int", "stg", "prod"], var.env)
    error_message = "Environment must be one of: int, stg, prod."
  }
}

variable "region" {
  type = string
}

variable "cidr" {
  description = "network cidr"
  type        = string
}

variable "azs" {
  description = "List of availability zones"
  type        = list(string)
}

variable "transit_gateway_id" {
  description = "Transit Gateway ID for VPN connectivity"
  type        = string
  default     = ""
}

variable "create_tgw_attachment" {
  description = "Whether to create Transit Gateway VPC attachment"
  type        = bool
  default     = false
}
EOF

      cat > "terraform/deployments/aws/vpc/main.tf" <<EOF
locals {
  env    = var.env
  region = var.region
  cidr   = var.cidr
  azs    = var.azs

  prefix                = "${PROJECT_NAME}-\${var.env}-\${var.region}"
  vpc_name              = "\${local.prefix}.vpc"
  internet_gateway_name = "\${local.prefix}.vpc.igw"

  subnet_private_1_name = "\${local.prefix}.vpc.a.snet.pri"
  subnet_private_2_name = "\${local.prefix}.vpc.b.snet.pri"
  subnet_public_1_name  = "\${local.prefix}.vpc.a.snet.pub"
  subnet_public_2_name  = "\${local.prefix}.vpc.b.snet.pub"

  tags = {
    Name  = local.vpc_name
    EnvName = local.prefix
    comp  = "vpc-stack"
    env   = local.env
    owner = "${PROJECT_NAME}"
    sys   = "vpc"
  }
}

resource "aws_vpc" "vpc" {
  cidr_block           = local.cidr
  enable_dns_hostnames = true

  tags = local.tags
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id
  tags = merge(local.tags, { Name = local.internet_gateway_name })
}

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(local.cidr, 2, 0)
  availability_zone = local.azs[0]
  tags = { Name = local.subnet_private_1_name }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(local.cidr, 2, 1)
  availability_zone = local.azs[1]
  tags = { Name = local.subnet_private_2_name }
}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(local.cidr, 2, 2)
  availability_zone       = local.azs[0]
  map_public_ip_on_launch = true
  tags = { Name = local.subnet_public_1_name }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(local.cidr, 2, 3)
  availability_zone       = local.azs[1]
  map_public_ip_on_launch = true
  tags = { Name = local.subnet_public_2_name }
}

resource "aws_eip" "nat_1" { domain = "vpc" }
resource "aws_eip" "nat_2" { domain = "vpc" }

resource "aws_nat_gateway" "nat_1" {
  allocation_id = aws_eip.nat_1.id
  subnet_id     = aws_subnet.public_1.id
}

resource "aws_nat_gateway" "nat_2" {
  allocation_id = aws_eip.nat_2.id
  subnet_id     = aws_subnet.public_2.id
}

resource "aws_route_table" "internet" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(local.tags, { Name = "\${local.prefix}.vpc.rtb.internet" })
}

resource "aws_route_table" "nat_1" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(local.tags, { Name = "\${local.prefix}.vpc.rtb.nat-a" })
}

resource "aws_route_table" "nat_2" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(local.tags, { Name = "\${local.prefix}.vpc.rtb.nat-b" })
}

resource "aws_route" "internet" {
  route_table_id         = aws_route_table.internet.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_route" "nat_1" {
  route_table_id         = aws_route_table.nat_1.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_1.id
}

resource "aws_route" "nat_2" {
  route_table_id         = aws_route_table.nat_2.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_2.id
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.nat_1.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.nat_2.id
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.internet.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.internet.id
}
EOF

      cat > "terraform/deployments/aws/vpc/outputs.tf" <<'EOF'
output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "vpc_cidr" {
  value = aws_vpc.vpc.cidr_block
}

output "subnet_private_1_id" {
  value = aws_subnet.private_1.id
}

output "subnet_private_1_cidr" {
  value = aws_subnet.private_1.cidr_block
}

output "subnet_private_2_id" {
  value = aws_subnet.private_2.id
}

output "subnet_private_2_cidr" {
  value = aws_subnet.private_2.cidr_block
}

output "subnet_public_1_id" {
  value = aws_subnet.public_1.id
}

output "subnet_public_1_cidr" {
  value = aws_subnet.public_1.cidr_block
}

output "subnet_public_2_id" {
  value = aws_subnet.public_2.id
}

output "subnet_public_2_cidr" {
  value = aws_subnet.public_2.cidr_block
}
EOF
      ;;

    route53)
      cat > "terraform/deployments/aws/route53/variables.tf" <<'EOF'
variable "env" {
  type = string
}

variable "region" {
  type = string
}

variable "external_domain" {
  type = string
}

variable "internal_domain" {
  type = string
}
EOF

      cat > "terraform/deployments/aws/route53/main.tf" <<EOF
locals {
  env             = var.env
  region          = var.region
  external_domain = var.external_domain
  internal_domain = var.internal_domain
}

resource "aws_route53_zone" "external" {
  name    = local.external_domain
  comment = "External hosted zone"
  tags = {
    comp  = "hostedzone"
    env   = local.env
    owner = "${PROJECT_NAME}"
    sys   = "externalr53"
  }
}

resource "aws_route53_zone" "internal" {
  name    = local.internal_domain
  comment = "Internal hosted zone"
  tags = {
    comp  = "hostedzone"
    env   = local.env
    owner = "${PROJECT_NAME}"
    sys   = "internalr53"
  }
}
EOF

      cat > "terraform/deployments/aws/route53/outputs.tf" <<'EOF'
output "external_zone_id" {
  value = aws_route53_zone.external.zone_id
}

output "external_name" {
  value = aws_route53_zone.external.name
}

output "internal_zone_id" {
  value = aws_route53_zone.internal.zone_id
}

output "internal_name" {
  value = aws_route53_zone.internal.name
}
EOF
      ;;

    secret-manager)
      cat > "terraform/deployments/aws/secret-manager/variables.tf" <<'EOF'
variable "env" {
  type = string
}

variable "region" {
  type = string
}

variable "secrets" {
  type = map(object({
    secret_name = string
    description = string
    owner       = string
    sys         = string
  }))
}
EOF

      cat > "terraform/deployments/aws/secret-manager/main.tf" <<EOF
locals {
  env    = var.env
  region = var.region
  prefix = "${PROJECT_NAME}-\${var.env}-\${var.region}"
}

resource "aws_secretsmanager_secret" "secret" {
  for_each    = var.secrets
  description = each.value.description
  name        = "\${local.prefix}-\${each.value.sys}-\${each.value.secret_name}"
  tags = {
    Name  = "\${local.prefix}-\${each.value.sys}-\${each.value.secret_name}"
    owner = each.value.owner
    sys   = each.value.sys
    comp  = "secret"
    env   = var.env
  }
}

resource "aws_secretsmanager_secret_version" "secret_version" {
  for_each      = var.secrets
  secret_id     = aws_secretsmanager_secret.secret[each.key].id
  secret_string = "dummy"

  lifecycle {
    ignore_changes = [secret_string]
  }
}
EOF
      ;;

    sns)
      cat > "terraform/deployments/aws/sns/variables.tf" <<'EOF'
variable "env" {
  type = string
}

variable "region" {
  type = string
}
EOF

      cat > "terraform/deployments/aws/sns/main.tf" <<EOF
locals {
  prefix = "\${var.env}-${PROJECT_NAME}"
}

resource "aws_sns_topic" "p0" {
  name         = "\${local.prefix}-Case-P0"
  display_name = "\${local.prefix}-Case-P0"
}

resource "aws_sns_topic" "p1" {
  name         = "\${local.prefix}-Case-P1"
  display_name = "\${local.prefix}-Case-P1"
}

resource "aws_sns_topic" "p2" {
  name         = "\${local.prefix}-Case-P2"
  display_name = "\${local.prefix}-Case-P2"
}

resource "aws_sns_topic" "report" {
  name         = "\${local.prefix}-Report"
  display_name = "\${local.prefix}-Report"
}

resource "aws_sns_topic" "notification" {
  name         = "\${local.prefix}-Notification"
  display_name = "\${local.prefix}-Notification"
}
EOF

      cat > "terraform/deployments/aws/sns/outputs.tf" <<'EOF'
output "p0_topic_arn" {
  value = aws_sns_topic.p0.arn
}

output "p1_topic_arn" {
  value = aws_sns_topic.p1.arn
}

output "p2_topic_arn" {
  value = aws_sns_topic.p2.arn
}

output "report_topic_arn" {
  value = aws_sns_topic.report.arn
}

output "notification_topic_arn" {
  value = aws_sns_topic.notification.arn
}
EOF
      ;;
  esac

  # Create a sample tfvars for int in main region
  if [[ "$stack" == "vpc" ]]; then
    cat > "terraform/config/aws/vpc/int-${MAIN_REGION}.tfvars" <<EOF
env   = "int"
region = "${MAIN_REGION}"
cidr  = "10.0.0.0/24"
azs   = ["${MAIN_REGION}a", "${MAIN_REGION}b"]
EOF
  elif [[ "$stack" == "route53" ]]; then
    cat > "terraform/config/aws/route53/int-${MAIN_REGION}.tfvars" <<EOF
env             = "int"
region          = "${MAIN_REGION}"
external_domain = "int.${PROJECT_NAME}.example.com"
internal_domain = "int.${PROJECT_NAME}.internal"
EOF
  elif [[ "$stack" == "secret-manager" ]]; then
    cat > "terraform/config/aws/secret-manager/int-${MAIN_REGION}.tfvars" <<EOF
env    = "int"
region = "${MAIN_REGION}"

secrets = {
  app-password = {
    secret_name = "app-master-password"
    description = "Master password for application database"
    owner       = "${PROJECT_NAME}"
    sys         = "app"
  }
}
EOF
  elif [[ "$stack" == "sns" ]]; then
    cat > "terraform/config/aws/sns/int-${MAIN_REGION}.tfvars" <<EOF
env    = "int"
region = "${MAIN_REGION}"
EOF
  fi
done

# --- 3. Scaffold EKS (if requested) ---

if [[ "$WITH_EKS" == true ]]; then
  echo "Creating EKS platform stack..." >&2
  mkdir -p "terraform/deployments/service/eks"
  mkdir -p "terraform/config/service/eks"

  write_backend_tf "terraform/deployments/service/eks"
  write_providers_tf "terraform/deployments/service/eks"

  cat > "terraform/deployments/service/eks/terraform.tf" <<EOF
terraform {
  required_version = ">= ${TERRAFORM_VERSION}"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "${AWS_PROVIDER_VERSION}"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.1.0"
    }
  }
}
EOF

  cat > "terraform/deployments/service/eks/variables.tf" <<'EOF'
variable "env" {
  type = string
}

variable "region" {
  type = string
}

variable "cluster_version" {
  type    = string
  default = "1.32"
}

variable "node_groups" {
  type = map(object({
    type             = string
    subnet           = string
    instance_types   = list(string)
    desired_capacity = number
    max_capacity     = number
    min_capacity     = number
    capacity_type    = optional(string, "ON_DEMAND")
    labels           = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = optional(string, null)
      effect = string
    })), [])
  }))
}
EOF

  cat > "terraform/deployments/service/eks/locals.tf" <<EOF
data "aws_caller_identity" "current" {}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "${PROJECT_NAME}-\${var.env}-\${var.region}-tf-backend"
    key    = "\${var.env}/\${var.region}/aws/vpc/terraform.tfstate"
    region = "\${var.region}"
  }
}

locals {
  env          = var.env
  region       = var.region
  prefix       = "${PROJECT_NAME}-\${var.env}-\${var.region}"
  cluster_name = "\${local.prefix}-eks"

  subnet_ids_by_type = {
    private = {
      a = data.terraform_remote_state.vpc.outputs.subnet_private_1_id
      b = data.terraform_remote_state.vpc.outputs.subnet_private_2_id
    }
    public = {
      a = data.terraform_remote_state.vpc.outputs.subnet_public_1_id
      b = data.terraform_remote_state.vpc.outputs.subnet_public_2_id
    }
  }

  legacy_subnet_overrides = {
    private_1 = { subnet = "private", zones = ["a"] }
    private_2 = { subnet = "private", zones = ["b"] }
    public_1  = { subnet = "public",  zones = ["a"] }
    public_2  = { subnet = "public",  zones = ["b"] }
  }

  node_group_subnet_types = {
    for name, ng in var.node_groups :
    name => try(local.legacy_subnet_overrides[ng.subnet].subnet, ng.subnet)
  }

  node_group_requested_zones = {
    for name, ng in var.node_groups :
    name => ng.zones != null ? ng.zones : try(
      local.legacy_subnet_overrides[ng.subnet].zones,
      keys(local.subnet_ids_by_type[local.node_group_subnet_types[name]])
    )
  }

  normalized_node_groups = {
    for name, ng in var.node_groups : name => merge(ng, {
      subnet = local.node_group_subnet_types[name]
      zones  = local.node_group_requested_zones[name]
    })
  }

  expanded_node_groups = {
    for item in flatten([
      for name, ng in local.normalized_node_groups : [
        for zone_index, zone in ng.zones : {
          name       = name
          node_group = ng
          zone       = zone
          capacities = {
            for cap_name, cap_total in {
              desired_capacity = ng.desired_capacity
              min_capacity     = ng.min_capacity
              max_capacity     = ng.max_capacity
            } :
            cap_name => floor(cap_total / length(ng.zones)) + (
              zone_index >= length(ng.zones) - (cap_total % length(ng.zones)) ? 1 : 0
            )
          }
        }
      ]
    ]) :
    "\${item.name}_\${item.zone}" => merge(item.node_group, {
      logical_name     = item.name
      zone             = item.zone
      subnet_ids       = [local.subnet_ids_by_type[item.node_group.subnet][item.zone]]
      desired_capacity = item.capacities.desired_capacity
      min_capacity     = item.capacities.min_capacity
      max_capacity     = item.capacities.max_capacity
    })
  }
}
EOF

  cat > "terraform/deployments/service/eks/eks.tf" <<'EOF'
resource "aws_security_group" "eks_cluster" {
  name        = "${local.prefix}-sg-eks-cluster"
  description = "EKS Cluster Security Group"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  tags = {
    Name = "${local.prefix}-sg-eks-cluster"
  }
}

resource "aws_security_group_rule" "eks_sg_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks_cluster.id
}

resource "aws_security_group" "eks_node_group" {
  name        = "${local.prefix}-sg-eks-node-group"
  description = "EKS Node Group Security Group"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  tags = {
    Name                                          = "${local.prefix}-sg-eks-node-group"
    "kubernetes.io/cluster/${local.cluster_name}" = "owned"
  }
}

resource "aws_iam_role" "eks_cluster" {
  name = "${local.prefix}-eks-cluster"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "eks_node_group" {
  name = "${local.prefix}-eks-node-group"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_node_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry" {
  role       = aws_iam_role.eks_node_group.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_eks_cluster" "eks_cluster" {
  name     = local.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.cluster_version

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  vpc_config {
    security_group_ids = [aws_security_group.eks_cluster.id]
    subnet_ids = [
      data.terraform_remote_state.vpc.outputs.subnet_private_1_id,
      data.terraform_remote_state.vpc.outputs.subnet_private_2_id
    ]
    endpoint_private_access = true
    endpoint_public_access  = true
  }
}

data "tls_certificate" "eks_cluster" {
  url = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks_cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_cluster.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

resource "aws_launch_template" "node_groups" {
  for_each = local.expanded_node_groups

  name = replace(each.key, "_", "-")
  tags = {
    Name  = replace(each.key, "_", "-")
    owner = "${PROJECT_NAME}"
    sys   = "${PROJECT_NAME}-eks"
  }
}

resource "aws_eks_node_group" "node_groups" {
  for_each = local.expanded_node_groups

  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = replace(each.key, "_", "-")
  node_role_arn   = aws_iam_role.eks_node_group.arn
  instance_types  = each.value.instance_types
  capacity_type   = each.value.capacity_type

  scaling_config {
    desired_size = each.value.desired_capacity
    min_size     = each.value.min_capacity
    max_size     = each.value.max_capacity
  }

  subnet_ids = each.value.subnet_ids

  launch_template {
    id      = aws_launch_template.node_groups[each.key].id
    version = aws_launch_template.node_groups[each.key].latest_version
  }

  labels = try(each.value.labels, null)

  dynamic "taint" {
    for_each = try(each.value.taints, [])
    content {
      key    = taint.value.key
      value  = try(taint.value.value, null)
      effect = taint.value.effect
    }
  }
}
EOF

  cat > "terraform/deployments/service/eks/outputs.tf" <<'EOF'
output "cluster_name" {
  value = aws_eks_cluster.eks_cluster.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.eks_cluster.endpoint
}

output "oidc_provider_url" {
  value = aws_iam_openid_connect_provider.eks_cluster.url
}

output "cluster_security_group_id" {
  value = aws_security_group.eks_cluster.id
}

output "node_security_group_id" {
  value = aws_security_group.eks_node_group.id
}
EOF

  cat > "terraform/config/service/eks/int-${MAIN_REGION}.tfvars" <<EOF
env      = "int"
region   = "${MAIN_REGION}"
mainSite = "${MAIN_REGION}"

cluster_version = "1.32"

node_groups = {
  infra_cpu = {
    type             = "infra"
    subnet           = "private"
    instance_types   = ["m6a.xlarge"]
    desired_capacity = 1
    max_capacity     = 2
    min_capacity     = 1
    labels = {
      "${PROJECT_NAME}.example.com/node-use" = "infra-cpu"
    }
  }
}
EOF
fi

# --- 4. Scaffold Sample Service (if requested) ---

if [[ "$WITH_SERVICE" == true ]]; then
  echo "Creating ${SERVICE_NAME} workload stack..." >&2
  mkdir -p "terraform/deployments/service/${SERVICE_NAME}"
  mkdir -p "terraform/config/service/${SERVICE_NAME}"

  write_backend_tf "terraform/deployments/service/${SERVICE_NAME}"
  write_providers_tf "terraform/deployments/service/${SERVICE_NAME}"
  write_terraform_tf "terraform/deployments/service/${SERVICE_NAME}"

  cat > "terraform/deployments/service/${SERVICE_NAME}/variables.tf" <<EOF
variable "env" {
  type = string
}

variable "region" {
  type = string
}

variable "mainSite" {
  type    = string
  default = "${MAIN_REGION}"
}

variable "service_owner" {
  type    = string
  default = "${PROJECT_NAME}-team"
}

variable "service_sys" {
  type    = string
  default = "${SERVICE_NAME}"
}

variable "db_instance_class" {
  type    = string
  default = "db.t4g.medium"
}

variable "db_reader_count" {
  type    = number
  default = 0
}
EOF

  cat > "terraform/deployments/service/${SERVICE_NAME}/data-sources.tf" <<EOF
# Remote state: VPC configuration
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "${PROJECT_NAME}-\${var.env}-\${var.region}-tf-backend"
    key    = "\${var.env}/\${var.region}/aws/vpc/terraform.tfstate"
    region = var.region
  }
}

# Remote state: Route53 (managed from main site)
data "terraform_remote_state" "route53" {
  backend = "s3"
  config = {
    bucket = "${PROJECT_NAME}-\${var.env}-\${var.mainSite}-tf-backend"
    key    = "\${var.env}/\${var.mainSite}/aws/route53/terraform.tfstate"
    region = var.mainSite
  }
}

# Remote state: SNS topics for alerting
data "terraform_remote_state" "sns" {
  backend = "s3"
  config = {
    bucket = "${PROJECT_NAME}-\${var.env}-\${var.region}-tf-backend"
    key    = "\${var.env}/\${var.region}/aws/sns/terraform.tfstate"
    region = var.region
  }
}

# Secrets
data "aws_secretsmanager_secret" "master_password" {
  name = "${PROJECT_NAME}-\${var.env}-\${var.region}-app-app-master-password"
}

data "aws_secretsmanager_secret_version" "master_password" {
  secret_id = data.aws_secretsmanager_secret.master_password.id
}
EOF

  cat > "terraform/deployments/service/${SERVICE_NAME}/locals.tf" <<EOF
locals {
  tomtom_prefix = "${PROJECT_NAME}-\${var.env}-\${var.region}"
}
EOF

  cat > "terraform/deployments/service/${SERVICE_NAME}/rds.tf" <<EOF
# Security Group
resource "aws_security_group" "postgresql" {
  name        = "\${local.tomtom_prefix}-${SERVICE_NAME}-postgresql-sg"
  description = "PostgreSQL access for ${SERVICE_NAME}"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  tags = {
    Name  = "\${local.tomtom_prefix}-${SERVICE_NAME}-postgresql-sg"
    owner = var.service_owner
    sys   = var.service_sys
    comp  = "rds-sg"
    env   = var.env
  }
}

resource "aws_vpc_security_group_ingress_rule" "postgresql_vpc_ingress" {
  security_group_id = aws_security_group.postgresql.id
  description       = "PostgreSQL access from VPC"
  cidr_ipv4         = data.terraform_remote_state.vpc.outputs.vpc_cidr
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
}

# DB Subnet Group
resource "aws_db_subnet_group" "postgres" {
  name = "\${local.tomtom_prefix}-${SERVICE_NAME}-rds-subnet-group"
  subnet_ids = [
    data.terraform_remote_state.vpc.outputs.subnet_private_1_id,
    data.terraform_remote_state.vpc.outputs.subnet_private_2_id
  ]

  tags = {
    Name  = "\${local.tomtom_prefix}-${SERVICE_NAME}-rds-subnet-group"
    owner = var.service_owner
    sys   = var.service_sys
    comp  = "rds-subnet-group"
    env   = var.env
  }
}

# Aurora PostgreSQL Cluster
resource "aws_rds_cluster" "postgres" {
  cluster_identifier = "\${local.tomtom_prefix}-${SERVICE_NAME}-rds-cluster"
  engine             = "aurora-postgresql"
  engine_version     = "16.4"

  database_name   = "${SERVICE_NAME}"
  master_username = "${SERVICE_NAME}_admin"
  master_password = data.aws_secretsmanager_secret_version.master_password.secret_string

  db_subnet_group_name   = aws_db_subnet_group.postgres.name
  vpc_security_group_ids = [aws_security_group.postgresql.id]

  backup_retention_period = var.env == "prod" ? 30 : 7
  skip_final_snapshot     = var.env == "int"

  tags = {
    Name  = "\${local.tomtom_prefix}-${SERVICE_NAME}-rds-cluster"
    owner = var.service_owner
    sys   = var.service_sys
    comp  = "rds-cluster"
    env   = var.env
  }
}

resource "aws_rds_cluster_instance" "postgres_writer" {
  identifier         = "\${local.tomtom_prefix}-${SERVICE_NAME}-rds-writer"
  cluster_identifier = aws_rds_cluster.postgres.id
  instance_class     = var.db_instance_class
  engine             = aws_rds_cluster.postgres.engine
  engine_version     = aws_rds_cluster.postgres.engine_version

  tags = {
    Name  = "\${local.tomtom_prefix}-${SERVICE_NAME}-rds-writer"
    owner = var.service_owner
    sys   = var.service_sys
    comp  = "rds-instance"
    env   = var.env
  }
}

# Route53 DNS
resource "aws_route53_record" "postgres_writer" {
  zone_id = data.terraform_remote_state.route53.outputs.internal_zone_id
  name    = "${SERVICE_NAME}-postgres-\${var.region}.\${data.terraform_remote_state.route53.outputs.internal_name}"
  type    = "CNAME"
  ttl     = 60
  records = [aws_rds_cluster.postgres.endpoint]
}
EOF

  cat > "terraform/config/service/${SERVICE_NAME}/int-${MAIN_REGION}.tfvars" <<EOF
env      = "int"
region   = "${MAIN_REGION}"
mainSite = "${MAIN_REGION}"

service_owner = "${PROJECT_NAME}-team"
service_sys   = "${SERVICE_NAME}"

db_instance_class = "db.t4g.medium"
db_reader_count   = 0
EOF
fi

# --- 5. Makefile ---

cat > "terraform/makefile" <<EOF
# ENV: prod/stg/int
ENV=\$(ENVIRONMENT)
# REGION: us-east-1/us-west-2/eu-central-1/ap-northeast-1
AWS_REGION=\$(REGION)
SITE=\$(ENV)-\$(AWS_REGION)
# MODULE: aws/service
MODULE=\$(MODULE_TYPE)
# COMPONENT: resource name/service name
COMP=\$(COMPONENT)
# Folder path for the deployment
DEPLOY_PATH=deployments/\$(MODULE)/\$(COMP)
# Lock ID for force unlock
ID=\$(LOCK_ID)

fmt:
	@echo "SITE = '\$(SITE)'"
	@echo "MODULE = '\$(MODULE)'"
	@echo "COMP = '\$(COMP)'"
	cd deployments/\$(MODULE)/\$(COMP) && \\
	terraform fmt -recursive

validate:
	@echo "SITE = '\$(SITE)'"
	@echo "MODULE = '\$(MODULE)'"
	@echo "COMP = '\$(COMP)'"
	@echo "DEPLOY_PATH = '\$(DEPLOY_PATH)'"
	cd deployments/\$(MODULE)/\$(COMP) && \\
	terraform validate

tf_apply:
	@echo "SITE = '\$(SITE)'"
	@echo "MODULE = '\$(MODULE)'"
	@echo "COMP = '\$(COMP)'"
	@echo "DEPLOY_PATH = '\$(DEPLOY_PATH)'"

	cd \$(DEPLOY_PATH) && \\
	terraform init -reconfigure \\
	 -backend-config="bucket=${PROJECT_NAME}-\$(SITE)-tf-backend" \\
	 -backend-config="key=\${ENV}/\${AWS_REGION}/\$(MODULE)/\${COMP}/terraform.tfstate" \\
	 -backend-config="region=\${AWS_REGION}" \\
	 -backend-config="encrypt=true" \\
	 -backend-config="use_lockfile=true" && \\
	terraform validate && \\
	terraform apply -var-file=../../../config/\$(MODULE)/\$(COMP)/\$(SITE).tfvars -auto-approve

tf_plan:
	@echo "SITE = '\$(SITE)'"
	@echo "MODULE = '\$(MODULE)'"
	@echo "COMP = '\$(COMP)'"
	@echo "DEPLOY_PATH = '\$(DEPLOY_PATH)'"

	cd \$(DEPLOY_PATH) && \\
	terraform init -reconfigure \\
	 -backend-config="bucket=${PROJECT_NAME}-\$(SITE)-tf-backend" \\
	 -backend-config="key=\$(ENV)/\$(AWS_REGION)/\$(MODULE)/\${COMP}/terraform.tfstate" \\
	 -backend-config="region=\${AWS_REGION}" \\
	 -backend-config="encrypt=true" \\
	 -backend-config="use_lockfile=true" && \\
	terraform validate && \\
	terraform plan -var-file=../../../config/\$(MODULE)/\$(COMP)/\$(SITE).tfvars -out=.planfile

tf_force_unlock:
	@echo "SITE = '\$(SITE)'"
	@echo "MODULE = '\$(MODULE)'"
	@echo "COMP = '\$(COMP)'"
	@echo "LOCK_ID = '\$(ID)'"

	cd \$(DEPLOY_PATH) && \\
	terraform init -reconfigure \\
	 -backend-config="bucket=${PROJECT_NAME}-\$(SITE)-tf-backend" \\
	 -backend-config="key=\$(ENV)/\$(AWS_REGION)/\$(MODULE)/\${COMP}/terraform.tfstate" \\
	 -backend-config="region=\${AWS_REGION}" \\
	 -backend-config="encrypt=true" \\
	 -backend-config="use_lockfile=true" && \\
	terraform force-unlock -force \$(ID)
EOF

# --- 6. GitHub Actions ---

mkdir -p .github/workflows

cat > ".github/workflows/plan.yaml" <<'EOF'
name: plan
run-name: "[${{ inputs.environment }}/${{ inputs.region }}] Plan ${{ inputs.module_type }}/${{ inputs.component }}"

on:
  workflow_dispatch:
    inputs:
      environment:
        description: "Select the environment"
        required: true
        type: choice
        options:
          - int
          - stg
          - prod
      region:
        description: "Select the region"
        required: true
        type: choice
        options:
          - us-west-2
          - ap-south-1
          - eu-central-1
          - eu-west-2
          - ap-northeast-1
      module_type:
        description: "Select the module type"
        required: true
        type: choice
        options:
          - aws
          - service
      component:
        description: "Enter the component name"
        required: true
        type: string

permissions:
  id-token: write
  contents: read

jobs:
  parameter_check:
    uses: ./.github/workflows/parameter_check.yaml
    with:
      environment: ${{ inputs.environment }}
      region: ${{ inputs.region }}
      module_type: ${{ inputs.module_type }}
      component: ${{ inputs.component }}
      action: plan

  plan:
    runs-on: ubuntu-latest
    needs: parameter_check
    env:
      ENVIRONMENT: ${{ inputs.environment }}
      REGION: ${{ inputs.region }}
      MODULE_TYPE: ${{ inputs.module_type }}
      COMPONENT: ${{ inputs.component }}
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "1.14.4"

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ vars.AWS_ROLE_CICD_ARN }}
          aws-region: ${{ env.REGION }}

      - name: Terraform Plan
        working-directory: terraform
        run: |
          make tf_plan
EOF

cat > ".github/workflows/apply.yaml" <<'EOF'
name: apply
run-name: "[${{ inputs.environment }}/${{ inputs.region }}] Deploy ${{ inputs.module_type }}/${{ inputs.component }}"

on:
  workflow_dispatch:
    inputs:
      environment:
        description: "Select the environment"
        required: true
        type: choice
        options:
          - int
          - stg
          - prod
      region:
        description: "Select the region"
        required: true
        type: choice
        options:
          - us-west-2
          - ap-south-1
          - eu-central-1
          - eu-west-2
          - ap-northeast-1
      module_type:
        description: "Select the module type"
        required: true
        type: choice
        options:
          - aws
          - service
      component:
        description: "Enter the component name"
        required: true
        type: string

permissions:
  id-token: write
  contents: read

jobs:
  parameter_check:
    uses: ./.github/workflows/parameter_check.yaml
    with:
      environment: ${{ inputs.environment }}
      region: ${{ inputs.region }}
      module_type: ${{ inputs.module_type }}
      component: ${{ inputs.component }}
      action: apply

  apply:
    runs-on: ubuntu-latest
    needs: parameter_check
    environment: ${{ inputs.environment }}-${{ inputs.region }}
    env:
      ENVIRONMENT: ${{ inputs.environment }}
      REGION: ${{ inputs.region }}
      MODULE_TYPE: ${{ inputs.module_type }}
      COMPONENT: ${{ inputs.component }}
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "1.14.4"

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ vars.AWS_ROLE_CICD_ARN }}
          aws-region: ${{ env.REGION }}

      - name: Terraform Apply
        working-directory: terraform
        run: |
          make tf_apply
EOF

cat > ".github/workflows/parameter_check.yaml" <<'EOF'
name: parameter_check

on:
  workflow_call:
    inputs:
      environment:
        required: true
        type: string
      region:
        required: true
        type: string
      module_type:
        required: true
        type: string
      component:
        required: true
        type: string
      action:
        default: "apply"
        type: string

jobs:
  parameter_check:
    runs-on: ubuntu-latest
    env:
      ENVIRONMENT: ${{ inputs.environment }}
      REGION: ${{ inputs.region }}
      MODULE_TYPE: ${{ inputs.module_type }}
      COMPONENT: ${{ inputs.component }}
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Check if the Component Exists
        run: |
          COMP_PATH="terraform/deployments/${{ env.MODULE_TYPE }}/${{ env.COMPONENT }}"
          if [ ! -d "$COMP_PATH" ]; then
            echo "Error: Folder $COMP_PATH does not exist."
            exit 1
          fi

      - name: Check if the Config File Exists
        run: |
          CONFIG_FILE="terraform/config/${{ env.MODULE_TYPE }}/${{ env.COMPONENT }}/${{ env.ENVIRONMENT }}-${{ env.REGION }}.tfvars"
          if [ ! -f "$CONFIG_FILE" ]; then
            echo "Error: Config file $CONFIG_FILE does not exist."
            exit 1
          fi

      - name: Check Production Branch Guard
        if: ${{ inputs.environment == 'prod' && (inputs.action == 'apply' || inputs.action == 'force_unlock') }}
        run: |
          if [ "${GITHUB_REF}" != "refs/heads/master" ]; then
            echo "Production deployments must be made from the master branch"
            exit 1
          fi

      - name: Check formatting
        working-directory: terraform
        run: |
          make fmt MODULE_TYPE=${{ env.MODULE_TYPE }} COMPONENT=${{ env.COMPONENT }}
EOF

# --- 7. README.md ---

cat > "README.md" <<EOF
# ${PROJECT_NAME}-infrastructure

Terraform-based infrastructure management with multi-environment and multi-region support.

## Project Structure

\`\`\`
terraform/
├── makefile              # Deployment automation
├── deployments/
│   ├── aws/              # Foundation stacks (VPC, DNS, Secrets, SNS)
│   └── service/          # Platform and workload stacks (EKS, ${SERVICE_NAME})
└── config/               # Environment-specific values (.tfvars)
    ├── aws/
    └── service/
\`\`\`

## Quick Start

### Prerequisites
- Terraform >= ${TERRAFORM_VERSION}
- AWS CLI configured
- Make

### Deployment Order

1. **Foundation stacks** (must be applied first):
   \`\`\`bash
   cd terraform
   make tf_apply ENV=int AWS_REGION=${MAIN_REGION} MODULE_TYPE=aws COMPONENT=vpc
   make tf_apply ENV=int AWS_REGION=${MAIN_REGION} MODULE_TYPE=aws COMPONENT=route53
   make tf_apply ENV=int AWS_REGION=${MAIN_REGION} MODULE_TYPE=aws COMPONENT=secret-manager
   make tf_apply ENV=int AWS_REGION=${MAIN_REGION} MODULE_TYPE=aws COMPONENT=sns
   \`\`\`

2. **Platform stacks**:
   \`\`\`bash
   make tf_apply ENV=int AWS_REGION=${MAIN_REGION} MODULE_TYPE=service COMPONENT=eks
   \`\`\`

3. **Workload stacks**:
   \`\`\`bash
   make tf_apply ENV=int AWS_REGION=${MAIN_REGION} MODULE_TYPE=service COMPONENT=${SERVICE_NAME}
   \`\`\`

### Plan Before Apply

Always run plan first to inspect changes:
\`\`\`bash
make tf_plan ENV=int AWS_REGION=${MAIN_REGION} MODULE_TYPE=aws COMPONENT=vpc
\`\`\`

## GitHub Actions

- **plan**: Manual plan workflow
- **apply**: Manual apply workflow
- **parameter_check**: Validates inputs, checks formatting, enforces branch guards

## Important Notes

1. **Backend Buckets**: You must create the S3 buckets before running Terraform:
   - \`${PROJECT_NAME}-int-${MAIN_REGION}-tf-backend\`
   - (one per environment/region)

2. **Secrets**: The secret-manager stack creates containers with dummy values.
   Update real values via AWS Console or a separate secret injection workflow.

3. **OIDC**: CI uses OIDC for AWS authentication. Configure the trust policy
   in AWS IAM to allow GitHub Actions to assume the deployment role.
EOF

# --- 8. .gitignore ---

cat > ".gitignore" <<'EOF'
# Terraform
.terraform/
*.tfstate
*.tfstate.*
*.tfvars
!config/**/*.tfvars
.terraform.lock.hcl
plan.out
.planfile

# IDE
.idea/
.vscode/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db
EOF

echo "========================================" >&2
echo "Scaffolded: ${OUTPUT_DIR}" >&2
echo "========================================" >&2
echo "" >&2
echo "Foundation stacks: $STACKS" >&2
if [[ "$WITH_EKS" == true ]]; then
  echo "Platform stack: eks" >&2
fi
if [[ "$WITH_SERVICE" == true ]]; then
  echo "Workload stack: ${SERVICE_NAME}" >&2
fi
echo "" >&2
echo "Directory tree:" >&2
find . -type f | sort | head -40 >&2

exit 0
