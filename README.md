Recommendations:

1. The nginx servers are hosted into private subnet if we want to connect to that nginx server for any deployment issues,  we requred bastion host to connect to that servers.
2. Implement Security tools on each devops phase ex : Pre-commit hooks i.e if the code contains any database connections or accesskey thee code wont commit.
     SCA
     SAST
     DAST
 3. Implement cloudcustodian tool to write the policy and to check the resources deployed into the AWS.
 4. Implement EKS, or serverless kubernetes architecture fargate that will resduce your infrastructure costs.
 5. Instead of using dockerhub to store our images we will use the AWS ECR, AWS EKS to deploy our applications.
 6. In ECR we have an option to scan the image before pushing to the ECR repository.
 7. Apart from this we will implement Aqua scan to scan the docker images.
