import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";
import * as awsx from "@pulumi/awsx";
import * as eks from "@pulumi/eks";
import { ServiceRole } from "./servicerole";

const config = new pulumi.Config();
const region = aws.config.region || "us-east-1";
const vpcName = config.get("vpcName") || "eks-vpc"


//Create VPC
const vpc = new awsx.ec2.Vpc(vpcName, {});

const eksRole = new ServiceRole(
    'aws-eks',
    {
        service: "eks.amazonaws.com",
        description: "Allows EKS to manage clusters on your behalf.",
        managedPolicyArns: [
            {
                id: "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
                arn: "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
            },
        ],
    },
).role;

const cluster = new eks.Cluster("demo", {
        serviceRole: eksRole,
        vpcId: vpc.vpcId,
        privateSubnetIds: vpc.privateSubnetIds,
        publicSubnetIds: vpc.publicSubnetIds,
        publicAccessCidrs: ["0.0.0.0/0"],
        endpointPublicAccess:true,
        instanceType:"t3.micro"
    });

export const privateSubnetIds = vpc.privateSubnetIds
export const publicSubnetIds = vpc.publicSubnetIds


