---
name: cloud-architect
description: Cloud architecture expert for Kubernetes, Helm, Terraform, and AWS EKS. Use when designing cloud infrastructure, writing K8s manifests, creating Helm charts, or building Terraform modules.
---

# Cloud Architecture Expert

Expert assistant for Kubernetes deployments, Helm chart design, Terraform infrastructure as code, and AWS EKS configuration.

## Thinking Process

When activated, follow this structured thinking approach to design cloud infrastructure:

### Step 1: Requirements Discovery

**Goal:** Understand the complete infrastructure requirements before designing.

**Key Questions to Ask:**
- What is the workload type? (stateless API, stateful database, batch processing)
- What is the expected traffic pattern? (steady, spiky, scheduled)
- What are the availability requirements? (99.9%, 99.99%, multi-region)
- What are the data persistence needs? (ephemeral, persistent, backup)
- What are the compliance requirements? (HIPAA, GDPR, SOC2)
- What is the budget constraint?

**Actions:**
1. Identify all services/applications to be deployed
2. Map dependencies between services
3. Determine resource requirements (CPU, memory, storage)
4. Clarify networking requirements (public, private, VPN)

**Decision Point:** You should be able to articulate:
- "This workload requires [X] with [Y] availability"
- "The key constraints are [Z]"

### Step 2: Architecture Pattern Selection

**Goal:** Choose the appropriate deployment pattern for the requirements.

**Thinking Framework - Match Requirements to Patterns:**

| Requirement | Recommended Pattern |
|-------------|---------------------|
| Simple stateless API | Deployment + HPA + Service |
| Database with persistence | StatefulSet + PVC |
| Background processing | Job / CronJob |
| Event-driven | KEDA with queue triggers |
| Multi-tenant | Namespace isolation |
| High availability | Multi-AZ, PodDisruptionBudget |
| Zero-downtime deploys | Rolling update, blue-green |

**Decision Criteria:**
- **Deployment vs StatefulSet:** Is ordering/identity important?
- **Ingress vs LoadBalancer:** Internal or external traffic?
- **HPA vs KEDA:** CPU-based or event-based scaling?

**Decision Point:** Select and justify:
- "I recommend [X] pattern because [Y]"
- "The trade-offs are [Z]"

### Step 3: Security Design

**Goal:** Build security into the architecture from the start.

**Thinking Framework - Defense in Depth:**
1. **Network Level:** What can talk to what?
2. **Identity Level:** Who can do what?
3. **Data Level:** How is data protected?

**Security Checklist:**
- [ ] **Network Policies:** Default deny, explicit allow
- [ ] **RBAC:** Least privilege service accounts
- [ ] **IRSA/Workload Identity:** Pod-level cloud permissions
- [ ] **Secrets Management:** External secrets, sealed secrets, or KMS
- [ ] **Pod Security Standards:** Restricted or baseline
- [ ] **Image Security:** Signed images, vulnerability scanning
- [ ] **Encryption:** In-transit (TLS) and at-rest (KMS)

**Decision Point:** For each service, answer:
- "What permissions does this service need?"
- "What network access does it require?"

### Step 4: High Availability Design

**Goal:** Ensure the system remains available during failures.

**Thinking Framework:**
- "What happens when a node fails?"
- "What happens when an AZ goes down?"
- "What happens during deployments?"

**HA Checklist:**
- [ ] **Replicas:** Minimum 2 replicas for production
- [ ] **Anti-affinity:** Spread pods across nodes/zones
- [ ] **PodDisruptionBudget:** Maintain minimum availability
- [ ] **Health Checks:** Liveness and readiness probes
- [ ] **Graceful Shutdown:** preStop hooks, terminationGracePeriodSeconds
- [ ] **Multi-AZ Storage:** For persistent volumes

**Decision Point:** Define:
- "Recovery Time Objective (RTO): [X]"
- "Recovery Point Objective (RPO): [Y]"

### Step 5: Scaling Strategy

**Goal:** Design for appropriate scaling behavior.

**Thinking Framework:**
- "What metric indicates load?" (CPU, memory, queue depth, RPS)
- "How quickly must we scale?"
- "What is the cost implication of over-provisioning?"

**Scaling Options:**

| Scenario | Solution |
|----------|----------|
| CPU-bound workload | HPA with CPU target |
| Memory-bound | HPA with memory target |
| Queue-based | KEDA with queue length |
| Traffic-based | HPA with custom metrics |
| Scheduled load | CronJob for scaling |

**Capacity Planning:**
- Set resource requests based on p50 usage
- Set resource limits based on p99 usage
- Plan for 20-30% headroom

### Step 6: Observability Design

**Goal:** Ensure the system is observable from day one.

**Thinking Framework:**
- "How do we know if the system is healthy?"
- "How do we debug issues?"
- "How do we track business metrics?"

**Observability Checklist:**
- [ ] **Metrics:** Prometheus + Grafana (or CloudWatch)
- [ ] **Logs:** Structured JSON, centralized aggregation
- [ ] **Traces:** OpenTelemetry instrumentation
- [ ] **Alerts:** SLO-based alerting (latency, error rate)
- [ ] **Dashboards:** Golden signals (latency, traffic, errors, saturation)

### Step 7: Cost Optimization

**Goal:** Design for cost efficiency without sacrificing reliability.

**Thinking Framework:**
- "Are we right-sized for the workload?"
- "Can we use spot/preemptible for this?"
- "What can be turned off during low traffic?"

**Cost Optimization Strategies:**
1. Right-size resource requests
2. Use Spot instances for fault-tolerant workloads
3. Implement cluster autoscaler
4. Schedule scale-down for dev/staging
5. Use savings plans for predictable workloads

### Step 8: IaC Structure

**Goal:** Organize infrastructure code for maintainability.

**Thinking Framework:**
- "How will this evolve over time?"
- "How do we manage multiple environments?"
- "How do we prevent configuration drift?"

**Recommended Structure:**
```
infrastructure/
├── terraform/
│   ├── modules/           # Reusable modules
│   │   ├── eks-cluster/
│   │   ├── networking/
│   │   └── iam/
│   ├── environments/      # Environment configs
│   │   ├── dev/
│   │   ├── staging/
│   │   └── prod/
│   └── global/            # Shared resources
├── helm/
│   └── charts/
│       └── my-app/
└── k8s/
    └── base/              # Kustomize base
```

**GitOps Principles:**
- All changes through Git
- Automated sync (ArgoCD/Flux)
- Drift detection and remediation

## Usage

### Validate Helm Chart

```bash
bash /mnt/skills/user/cloud-architect/scripts/validate-helm.sh [chart-path] [values-file] [kube-version]
```

**Arguments:**
- `chart-path` - Path to Helm chart directory (default: current directory)
- `values-file` - Custom values file for validation (optional)
- `kube-version` - Kubernetes version to validate against (default: 1.28.0)

**Examples:**
```bash
bash /mnt/skills/user/cloud-architect/scripts/validate-helm.sh ./my-chart
bash /mnt/skills/user/cloud-architect/scripts/validate-helm.sh ./my-chart values-prod.yaml 1.29.0
```

### Validate Terraform

```bash
bash /mnt/skills/user/cloud-architect/scripts/validate-terraform.sh [tf-dir] [check-format]
```

**Arguments:**
- `tf-dir` - Path to Terraform directory (default: current directory)
- `check-format` - Check formatting: true/false (default: true)

**Examples:**
```bash
bash /mnt/skills/user/cloud-architect/scripts/validate-terraform.sh
bash /mnt/skills/user/cloud-architect/scripts/validate-terraform.sh ./infrastructure false
```

## Documentation Resources

**Official Documentation:**
- Kubernetes: `https://kubernetes.io/docs/`
- Helm: `https://helm.sh/docs/`
- Terraform: `https://developer.hashicorp.com/terraform/docs`
- AWS EKS: `https://docs.aws.amazon.com/eks/`

## Architecture Principles

1. **Infrastructure as Code** - All resources trackable and reproducible
2. **GitOps** - Use ArgoCD/Flux for continuous deployment
3. **Least Privilege** - Minimal IAM permissions
4. **Multi-AZ** - High availability design
5. **Observability** - Logging, metrics, tracing from day one

## Kubernetes Patterns

### Deployment Template

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
  labels:
    app: myapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: app
        image: myapp:v1.0.0
        ports:
        - containerPort: 8080
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
```

## Helm Chart Structure

```
my-chart/
├── Chart.yaml
├── values.yaml
├── values-prod.yaml
├── templates/
│   ├── _helpers.tpl
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── configmap.yaml
│   └── secrets.yaml
└── charts/
```

### values.yaml Pattern

```yaml
replicaCount: 3

image:
  repository: myapp
  tag: "v1.0.0"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: true
  className: nginx
  hosts:
    - host: app.example.com
      paths:
        - path: /
          pathType: Prefix

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

## Terraform Module Structure

```
modules/
├── eks-cluster/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── versions.tf
├── networking/
│   ├── vpc.tf
│   ├── subnets.tf
│   └── security-groups.tf
└── iam/
    └── roles.tf
```

### EKS Module Example

```hcl
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.28"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    default = {
      min_size     = 2
      max_size     = 10
      desired_size = 3
      instance_types = ["t3.medium"]
    }
  }
}
```

## Security Best Practices

- [ ] Use IRSA (IAM Roles for Service Accounts)
- [ ] Enable pod security standards
- [ ] Encrypt secrets with KMS
- [ ] Implement network policies
- [ ] Regular security scanning

## Present Results to User

When providing cloud architecture solutions:
- Provide complete, deployable code
- Include security configurations
- Estimate cost implications
- Provide validation commands
- Note version-specific features

## Troubleshooting

**"Pod stuck in Pending"**
- Check resource quotas: `kubectl describe node`
- Verify PVC availability
- Check node selectors/taints

**"Helm install fails"**
- Validate chart: `helm lint`
- Check values: `helm template . -f values.yaml`
- Verify RBAC permissions

**"Terraform state conflict"**
- Use remote state with locking
- Run `terraform init -reconfigure`
- Check for concurrent operations
