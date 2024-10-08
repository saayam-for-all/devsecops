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
   export AWS_PROFILE="aws_saayam"
   export REGION="us-west-2"
   aws configure --profile aws_saayam
   ```
2. Configure pulumi
   ```
   pulumi config set aws:profile aws_saayam
   pulumi config set aws:region us-west-2
   ```
3. Run Pulumi
   ```
   cd pulumi-scripts
   pulumi up
   pulumi stack output kubeconfig > kubeconfig
   pulumi stack output clusterName
   export CLUSTER_NAME="<CLUSTER_NAME>"
   pulumi stack output vpcId
   export VPC_ID="<VPC_ID>"
   pulumi stack output albPolicyArn
   export ALB_POLICY_ARN="<albPolicyArn>"
   aws eks update-kubeconfig --region us-west-2 --name $CLUSTER_NAME
   # Fix Failed CoreDNS
   kubectl rollout restart -n kube-system deployment coredns
   eksctl create iamserviceaccount \
      --cluster=$CLUSTER_NAME \
      --namespace=kube-system \
      --name=aws-load-balancer-controller \
      --role-name AmazonEKSLoadBalancerControllerRole \
      --attach-policy-arn=$ALB_POLICY_ARN \
      --approve
   helm repo add eks https://aws.github.io/eks-charts
   helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
      -n kube-system \
      --set clusterName=$CLUSTER_NAME \
      --set serviceAccount.create=false \
      --set serviceAccount.name=aws-load-balancer-controller \
      --set region=$REGION \
      --set vpcId=$VPC_ID
   cd ..
   cd kubernetes
   kubectl apply -f deployment.yml
   kubectl apply -f service.yml  
   kubectl get po -A -w
   kubectl get deploy -n kube-system   
   kubectl get deployment
   kubectl apply -f ingress.yml
   ```