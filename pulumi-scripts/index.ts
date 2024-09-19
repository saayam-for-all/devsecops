import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";
import * as awsx from "@pulumi/awsx";


const config = new pulumi.Config();
const region = aws.config.region || "us-east-1";
const vpcName = config.get("vpcName") || "eks-vpc"

//Create VPC
const vpc = new awsx.ec2.Vpc(vpcName, {});

export const privateSubnetIds = vpc.privateSubnetIds
export const publicSubnetIds = vpc.publicSubnetIds
