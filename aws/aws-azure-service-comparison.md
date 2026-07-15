# AWS to Azure Service Comparison

> [!NOTE]
> These are approximate equivalents and not always 1:1 mappings. Services may differ in features, implementation, and pricing models.

| Service Category | AWS Offering | Closest Azure Equivalent | Notes |
| :---- | :---- | :---- | :---- |
| Hierarchical Structure | AWS Accounts | Azure Subscriptions | |
| Hierarchical Structure | AWS Organizational Units (OUs) | Azure Management Groups | |
| Enterprise Governance | AWS Organizations / Control Tower | Azure Management Groups / Azure Policy | |
| Resource Grouping | AWS Resource Groups / CloudFormation Stacks | Azure Resource Groups | Azure Resource Groups are mandatory deployment boundaries; AWS Resource Groups are tag-based views. |
| Identity Management | IAM | Microsoft Entra ID \+ Azure RBAC | Microsoft Entra ID is tenant-level (global); AWS IAM is primarily account-scoped. |
| Single Sign-On | IAM Identity Center | Microsoft Entra ID | |
| User Directory | IAM users / groups | Microsoft Entra users / groups | |
| Secret Storage | Secrets Manager | Azure Key Vault | |
| Configuration Store | SSM Parameter Store | Azure App Configuration / Key Vault | |
| Key Management | AWS KMS | Azure Key Vault Managed HSM / Keys | |
| Hardware Security | CloudHSM | Azure Cloud HSM / Managed HSM | |
| Virtual Servers | EC2 | Azure Virtual Machines | |
| Compute Scaling | Auto Scaling Groups | Virtual Machine Scale Sets | |
| Event-Driven Functions | Lambda | Azure Functions | |
| Application Hosting | Elastic Beanstalk | Azure App Service | Azure App Service is a managed PaaS; Beanstalk orchestrates underlying IaaS (EC2). |
| Container Management | ECS | Azure Container Apps / AKS | |
| Managed Kubernetes | EKS | AKS | |
| Serverless Container Runtime | Fargate | Azure Container Apps / Azure Container Instances | |
| Batch Processing | AWS Batch | Azure Batch | |
| Simple VPS | Lightsail | Azure VM / App Service | |
| Hybrid Cloud | AWS Outposts | Azure Stack / Azure Arc | |
| VMware | VMware Cloud on AWS | Azure VMware Solution | |
| Object Storage | S3 | Azure Blob Storage | |
| Block Storage | EBS | Azure Managed Disks | |
| File Storage | EFS | Azure Files | |
| Windows File Storage | FSx for Windows | Azure Files / Azure NetApp Files | |
| Lustre Filesystem | FSx for Lustre | Azure Managed Lustre | |
| Archive Storage | S3 Glacier | Azure Archive Storage | |
| Backup | AWS Backup | Azure Backup | |
| Disaster Recovery | Elastic Disaster Recovery | Azure Site Recovery | |
| CDN | CloudFront | Azure Front Door / Azure CDN | |
| DNS | Route 53 | Azure DNS | |
| Global Routing | Route 53 latency routing / Global Accelerator | Azure Front Door / Traffic Manager | |
| VPC | VPC | Virtual Network | |
| Subnets | VPC Subnets | VNet Subnets | |
| Security Groups | Security Groups | Network Security Groups | |
| NACLs | Network ACLs | NSG rules / Azure Firewall | AWS NACLs are stateless subnet boundaries; Azure NSGs are stateful. |
| NAT | NAT Gateway | Azure NAT Gateway | |
| Private Connectivity | PrivateLink | Azure Private Link | |
| Site-to-site VPN | AWS Site-to-Site VPN | Azure VPN Gateway | |
| Dedicated Connection | Direct Connect | ExpressRoute | |
| Transit Networking | Transit Gateway | Azure Virtual WAN | VNet Peering is equivalent to VPC Peering. |
| Load Balancer L4 | Network Load Balancer | Azure Load Balancer | |
| Load Balancer L7 | Application Load Balancer | Azure Application Gateway | |
| WAF | AWS WAF | Azure Web Application Firewall | |
| DDoS Protection | AWS Shield | Azure DDoS Protection | |
| Firewall | AWS Network Firewall | Azure Firewall | |
| API Gateway | API Gateway | Azure API Management | |
| Event Bus | EventBridge | Azure Event Grid | |
| Queue | SQS | Azure Queue Storage / Service Bus Queue | |
| Pub/Sub | SNS | Azure Service Bus Topic / Event Grid | |
| Streaming | Kinesis | Azure Event Hubs | |
| Kafka | MSK | Azure Event Hubs Kafka endpoint / Confluent on Azure | |
| Workflow | Step Functions | Azure Logic Apps / Durable Functions | |
| Scheduler | EventBridge Scheduler | Azure Logic Apps / Automation / Functions timer | |
| Relational DB | RDS | Azure SQL / Azure Database services | |
| MySQL | RDS MySQL / Aurora MySQL | Azure Database for MySQL | |
| PostgreSQL | RDS PostgreSQL / Aurora PostgreSQL | Azure Database for PostgreSQL | |
| SQL Server | RDS SQL Server | Azure SQL Managed Instance / SQL Server on Azure VM | |
| Oracle | RDS Oracle | Oracle Database@Azure / Oracle on VM | |
| NoSQL Key-value | DynamoDB | Azure Cosmos DB | |
| Document DB | DocumentDB | Azure Cosmos DB | |
| Redis | ElastiCache Redis | Azure Managed Redis / Azure Cache for Redis | |
| Memcached | ElastiCache Memcached | No exact managed equivalent; use Redis or self-managed | |
| Data Warehouse | Redshift | Azure Synapse Analytics | |
| Data Lake | S3 \+ Lake Formation | Azure Data Lake Storage \+ Microsoft Purview | |
| ETL | AWS Glue | Azure Data Factory / Synapse Pipelines | |
| Analytics Query | Athena | Azure Synapse Serverless SQL | |
| Big Data | EMR | Azure HDInsight / Databricks | |
| Databricks | Databricks on AWS | Azure Databricks | |
| Search | OpenSearch Service | Azure AI Search | |
| AI & Machine Learning | Amazon SageMaker AI | Azure Machine Learning | |
| Management & Monitoring | CloudWatch | Azure Monitor | |
| Infrastructure as Code | CloudFormation | Azure Bicep / ARM Templates | |
| Developer Tools | AWS Code Suite (CodeCommit/CodePipeline) | Azure DevOps / GitHub | AWS CodeCommit is deprecated for new customers. |
| IoT | IoT Core | Azure IoT Hub | |
