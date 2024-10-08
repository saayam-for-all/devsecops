### EKS Cluster

#### Scenario: Public EKS Cluster

##### Installations steps(MacOS):
1. Install AWS CLI
2. Install eksctl
3. Setup Pulumi
4. Install kubectl and helm

##### Steps to run pulumi on DevBox(MacOS)

1. Set AWS Profile
   ```
   export AWS_PROFILE=aws_saayam
   ```
2. Configure pulumi
   ```
   pulumi config set aws:profile aws_saayam
   pulumi config set aws:region us-west-2
   ```
3. 