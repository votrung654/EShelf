# CloudFormation Templates

AWS CloudFormation templates for eShelf infrastructure (Lab 1).

## Templates

| Template | Description |
|----------|-------------|
| `vpc-stack.yaml` | VPC, Subnets, IGW, NAT Gateway, Route Tables |
| `ec2-stack.yaml` | Bastion Host, Application Servers, Security Groups |

## Deployment

### 1. Deploy VPC Stack

```bash
aws cloudformation create-stack \
  --stack-name eshelf-vpc-dev \
  --template-body file://templates/vpc-stack.yaml \
  --parameters \
    ParameterKey=ProjectName,ParameterValue=eshelf \
    ParameterKey=Environment,ParameterValue=dev
```

### 2. Wait for VPC Stack

```bash
aws cloudformation wait stack-create-complete \
  --stack-name eshelf-vpc-dev
```

### 3. Deploy EC2 Stack

```bash
aws cloudformation create-stack \
  --stack-name eshelf-ec2-dev \
  --template-body file://templates/ec2-stack.yaml \
  --parameters \
    ParameterKey=ProjectName,ParameterValue=eshelf \
    ParameterKey=Environment,ParameterValue=dev \
    ParameterKey=KeyPairName,ParameterValue=your-key-name \
    ParameterKey=AllowedSSHCIDR,ParameterValue=YOUR_IP/32
```

### 4. Get Outputs

```bash
# VPC Stack outputs
aws cloudformation describe-stacks \
  --stack-name eshelf-vpc-dev \
  --query 'Stacks[0].Outputs'

# EC2 Stack outputs
aws cloudformation describe-stacks \
  --stack-name eshelf-ec2-dev \
  --query 'Stacks[0].Outputs'
```

## Validation

### Validate Templates

```bash
# Validate VPC template
aws cloudformation validate-template \
  --template-body file://templates/vpc-stack.yaml

# Validate EC2 template
aws cloudformation validate-template \
  --template-body file://templates/ec2-stack.yaml
```

### Lint with cfn-lint

```bash
# Install cfn-lint
pip install cfn-lint

# Lint templates
cfn-lint templates/vpc-stack.yaml
cfn-lint templates/ec2-stack.yaml
```

## Testing with Taskcat

### 1. Install Taskcat

```bash
pip install taskcat
```

### 2. Create taskcat.yml

```yaml
project:
  name: eshelf
  regions:
    - ap-southeast-1
tests:
  vpc-test:
    template: templates/vpc-stack.yaml
  ec2-test:
    template: templates/ec2-stack.yaml
    parameters:
      KeyPairName: test-key
```

### 3. Run Tests

```bash
taskcat test run
```

## Update Stack

```bash
aws cloudformation update-stack \
  --stack-name eshelf-vpc-dev \
  --template-body file://templates/vpc-stack.yaml
```

## Delete Stack

```bash
# Delete EC2 stack first
aws cloudformation delete-stack --stack-name eshelf-ec2-dev

# Wait for deletion
aws cloudformation wait stack-delete-complete --stack-name eshelf-ec2-dev

# Delete VPC stack
aws cloudformation delete-stack --stack-name eshelf-vpc-dev
```

## Troubleshooting

### Stack creation failed

```bash
# Get stack events
aws cloudformation describe-stack-events \
  --stack-name eshelf-vpc-dev

# Get failure reason
aws cloudformation describe-stack-events \
  --stack-name eshelf-vpc-dev \
  --query 'StackEvents[?ResourceStatus==`CREATE_FAILED`]'
```

### Export already exists

If you get "Export already exists" error, change the export names in the template or delete the old stack first.

