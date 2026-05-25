# AWS Cloud Reference Guide for DevOps 

---

## Region and Availability Zone

An **AWS Region** is a separate geographic area, such as `us-east-1`, `us-west-2`, or `eu-west-1`. Most AWS resources are regional, meaning they exist in one Region unless explicitly replicated or configured globally.

An **Availability Zone**, or AZ, is an isolated location within a Region. Each Region has multiple AZs. An AZ consists of one or more data centers with independent power, networking, and connectivity. AZs in the same Region are connected with low-latency networking.

Regions provide geographic isolation. AZs provide high availability inside a Region. A typical production design uses multiple AZs in one Region for high availability and may use multiple Regions for disaster recovery, latency, regulatory, or business continuity reasons.

Examples:

* Single-AZ EC2 instance: vulnerable to AZ failure.
* ASG across multiple AZs: can replace or balance instances across AZs.
* ALB across multiple AZs: can route to healthy targets in enabled AZs.
* RDS Multi-AZ: provides database failover across AZs.
* S3: regional service that stores data redundantly across multiple AZs by design.

Important detail: AZ names such as `us-east-1a` are mapped per AWS account. Your `us-east-1a` may not be the same physical AZ as another account’s `us-east-1a`. For cross-account alignment, AWS has AZ IDs, such as `use1-az1`.

Region is geography; AZ is an isolated failure domain within a Region. For work, always consider whether the service is global, regional, zonal, or subnet/AZ-specific.

Regions isolate geographically. AZs isolate failures inside a Region. Build across multiple AZs for high availability and across Regions for disaster recovery or global resilience.

---

## Accounts and Users in AWS

An **AWS account** is a security, billing, quota, and resource boundary. Resources such as VPCs, EC2 instances, IAM roles, S3 buckets, and RDS databases belong to an AWS account. In companies, AWS accounts are often organized by environment, team, application, or security boundary.

A strong AWS architecture often uses multiple accounts instead of putting everything in one account. This reduces blast radius and makes billing, access control, and environment separation cleaner.

### Root user

Every AWS account has a **root user**. The root user is created when the account is created and has full access to everything in the account.

Best practices:

* Do not use the root user for daily work.
* Enable MFA on root.
* Do not create root access keys.
* Store root credentials securely.
* Use root only for tasks that specifically require root.

Root user access is extremely powerful. If compromised, the whole account is at risk.

### IAM users

An **IAM user** is a long-term identity inside an AWS account. IAM users can have passwords for console access and access keys for programmatic access.

Modern AWS best practice is to avoid IAM users for humans when possible. Use federation or IAM Identity Center so humans use temporary credentials and centralized identity management.

IAM users still exist in many legacy environments, especially for older automation. For automation, roles are usually safer than IAM users because roles use temporary credentials.

### IAM roles

An **IAM role** is an identity that can be assumed by trusted principals. Roles provide temporary credentials through STS.

Roles are used for:

* EC2 instance access to AWS APIs
* Lambda execution
* ECS task permissions
* EKS workloads
* Cross-account access
* CI/CD deployments
* Federated human access

Roles are generally preferred over long-term access keys.

### AWS Organizations and multi-account design

AWS Organizations lets you centrally manage multiple AWS accounts. A common structure is:

* Management account
* Security tooling account
* Log archive account
* Network/shared services account
* Development workload accounts
* Staging workload accounts
* Production workload accounts
* Sandbox accounts

Organizations also supports **Service Control Policies**, or SCPs. SCPs do not grant permissions. They define the maximum permissions available to accounts or organizational units. Even if an IAM role allows an action, an SCP can block it.

### Operational concerns

Important account-level concerns:

* Root user protection
* MFA and federation
* CloudTrail enabled and centralized
* GuardDuty/Security Hub or similar security tooling
* Service quotas per Region/account
* Billing alarms and cost allocation tags
* Least privilege access
* Environment/account separation
* Break-glass access process

A common production issue is hitting service quotas in one account/Region, such as ENI limits, EIP limits, NAT gateway limits, or API throttling limits.

An AWS account is a major isolation boundary. Root user should be locked down. Humans should use federation/Identity Center when possible. Workloads should use roles, not long-term access keys. Multi-account design reduces blast radius.

---

## IAM Policy

An **IAM policy** is a JSON document that defines permissions in AWS. Policies answer: who can do what, to which resources, and under what conditions.
almost every AWS troubleshooting path eventually touches permissions.

### Policy structure

A policy statement commonly includes:

* `Effect`
* `Principal`
* `Action`
* `Resource`
* `Condition`

Example conceptually:

```json
{
  "Effect": "Allow",
  "Action": "s3:GetObject",
  "Resource": "arn:aws:s3:::my-bucket/*"
}
```

### Principal

The **Principal** is who the policy applies to. It can be an AWS account, IAM user, IAM role, federated user, or AWS service.

Important: 
**identity-based policies** attached to a user, group, or role usually do **not** include `Principal`, because the principal is already the identity the policy is attached to.

**Resource-based policies**, such as S3 bucket policies, KMS key policies, Lambda resource policies, SQS queue policies, and trust policies, commonly include `Principal`.

Examples of principals:

* An AWS account root principal
* An IAM role ARN
* An IAM user ARN
* A service principal such as `ec2.amazonaws.com` or `lambda.amazonaws.com`

### Action

The **Action** is the AWS API operation being allowed or denied.

Examples:

* `s3:GetObject`
* `s3:PutObject`
* `ec2:RunInstances`
* `kms:Decrypt`
* `secretsmanager:GetSecretValue`
* `sts:AssumeRole`

Wildcards are possible, such as `s3:Get*`, but least privilege usually means using more specific actions.

### Resource

The **Resource** is the AWS resource the action applies to. It is usually written as an ARN.

Examples:

* S3 bucket: `arn:aws:s3:::my-bucket`
* S3 objects: `arn:aws:s3:::my-bucket/*`
* IAM role: `arn:aws:iam::123456789012:role/MyRole`
* KMS key: `arn:aws:kms:us-east-1:123456789012:key/key-id`

Some AWS actions support resource-level permissions; others require `*`. This is a common source of confusion.

### Condition

The **Condition** limits when the policy applies. Conditions are powerful for security and least privilege.

Common condition examples:

* Require MFA
* Restrict source IP
* Restrict to a VPC endpoint
* Require TLS
* Restrict by resource tag
* Restrict by principal tag
* Restrict cross-account assume role with an external ID
* Restrict access to a specific AWS Organization

Conditions are especially important in production guardrails.

### Trust policy

A **trust policy** is attached to an IAM role and defines who can assume the role. It usually allows `sts:AssumeRole` to a principal.

Example uses:

* EC2 service assumes an instance role
* Lambda service assumes an execution role
* A CI/CD role in one account assumes a deployment role in another account
* A federated human identity assumes an admin or read-only role

A role needs two sides to work:

1. Trust policy: who can assume the role
2. Permission policy: what the role can do after it is assumed

If either side is wrong, access fails.

### Permission boundary

A **permissions boundary** sets the maximum permissions that an IAM user or role can have. It does not grant permissions by itself.

Effective permissions are the intersection of:

* Identity-based policies
* Permissions boundary
* Other controls such as SCPs and session policies

Permission boundaries are useful when you allow teams to create IAM roles but want to prevent privilege escalation. For example, a developer can create a role only if the role has a boundary that prevents admin-level actions.

### Resource-based policy

A **resource-based policy** is attached to a resource and grants access to principals.

Examples:

* S3 bucket policy
* KMS key policy
* SQS queue policy
* SNS topic policy
* Lambda resource policy
* IAM role trust policy

Resource-based policies are especially important for cross-account access because the resource owner can directly allow another account or role.

### Policy evaluation mental model

AWS policy evaluation can include identity policies, resource policies, permission boundaries, SCPs, session policies, and explicit denies.

Simplified model:

1. Default is deny
2. An explicit allow must allow the action
3. Any explicit deny wins
4. Permission boundaries and SCPs can limit what is allowed
5. Resource policies may be required depending on the service

### Common mistakes

* Writing `Principal` in an identity-based policy
* Forgetting `Resource` must include both bucket and object ARNs for S3
* Giving IAM permission but forgetting KMS key policy
* Role trust policy allows the wrong principal
* Confusing permission boundary with a policy that grants access
* Explicit deny in SCP or resource policy overrides everything
* Missing conditions such as external ID for third-party cross-account roles

IAM policies define access with Effect, Principal, Action, Resource, and Condition. Trust policies control who can assume a role. Permission boundaries limit maximum permissions. Resource-based policies are attached to resources and are key for cross-account access. Explicit deny always wins.

---

## IAM Role

An **IAM role** is an AWS identity that trusted principals can assume. Unlike IAM users, roles do not have permanent passwords or access keys. Instead, AWS STS issues temporary credentials when the role is assumed.

Roles are safer and more flexible than IAM users for most AWS access patterns.

### Common role types

Roles are used for:

* EC2 instance profiles
* Lambda execution roles
* ECS task roles
* EKS workload roles
* Cross-account deployment roles
* Federated user access roles
* AWS service-linked roles
* CI/CD pipeline roles

### Role trust policy

Every assumable role has a trust policy. The trust policy defines who is allowed to assume the role.

Examples:

* EC2 role trust policy trusts `ec2.amazonaws.com`
* Lambda role trust policy trusts `lambda.amazonaws.com`
* Cross-account role trust policy trusts a role or account from another AWS account
* Federated role trusts an identity provider

If the trust policy is wrong, the role cannot be assumed even if the permissions policy is correct.

### Role permission policy

The role’s permission policies define what it can do after being assumed.

For example, a Lambda execution role may allow:

* Write logs to CloudWatch Logs
* Read a secret from Secrets Manager
* Decrypt with a KMS key
* Write an item to DynamoDB

The trust policy and permission policy are separate. This is one of the most important IAM interview concepts.

### Role-policy attachment

A **role-policy attachment** attaches a managed policy to a role. A managed policy can be AWS-managed or customer-managed.

In infrastructure as code, you often see separate objects for:

* IAM role
* IAM policy
* Role policy attachment

For example, in Terraform:

* `aws_iam_role`
* `aws_iam_policy`
* `aws_iam_role_policy_attachment`

The role exists first, the policy defines permissions, and the attachment connects them.

Roles can also have inline policies, but managed policies are easier to reuse and manage at scale.

### Assuming role

To **assume a role**, a principal calls `sts:AssumeRole` and receives temporary credentials.

For cross-account role assumption, usually both conditions are needed:

1. The target role’s trust policy allows the source principal
2. The source principal has permission to call `sts:AssumeRole` on the target role

For AWS services like EC2 and Lambda, the service assumes the role automatically when configured correctly.

### Example cross-account deployment pattern

* CI/CD pipeline runs in a tooling account
* Production resources live in a production account
* Production account has a deployment role
* Deployment role trust policy allows the tooling account pipeline role to assume it
* Pipeline role has permission to call `sts:AssumeRole` on the deployment role
* Deployment role has permissions to update production resources

This avoids storing long-term production credentials in the CI/CD system.

### Operational concerns

Common role problems:

* Trust policy principal is wrong
* Permission policy lacks required action
* Role has AWS permissions but KMS key policy blocks it
* EC2 instance has role but no instance profile attached
* Lambda execution role lacks CloudWatch Logs permissions
* Role session duration too short for long deployments
* External ID condition mismatch for third-party access
* Overly broad permissions create privilege escalation risk

Use CloudTrail to see `AssumeRole` events and understand who assumed which role and when.

A role provides temporary credentials. Trust policy says who can assume it. Permission policies say what it can do. Role-policy attachment connects managed policies to the role. Assuming a role uses STS. Most role failures are either trust-policy failures or permission-policy failures.

---

## VPC

A **VPC**, or Virtual Private Cloud, is your private network boundary inside AWS. It is a logically isolated virtual network where you decide the IP ranges, subnets, routing, gateways, and security controls. A VPC is where you place networked resources such as EC2 instances, RDS databases, load balancers, NAT gateways, VPC endpoints, ECS tasks, EKS nodes, Lambda VPC attachments, and many other services.

A VPC belongs to **one AWS Region**, but it spans all Availability Zones in that Region. Inside the VPC, you create **subnets**, and each subnet lives in exactly one Availability Zone. This distinction matters for high availability: the VPC is regional, but your actual placement strategy is built from multiple subnets across multiple AZs.

The VPC itself defines the overall IP address space, usually with one or more IPv4 CIDR blocks such as `10.0.0.0/16`. You can also associate IPv6 CIDR blocks. CIDR planning is one of the most important early design choices because it affects subnet sizing, routing, VPC peering, VPNs, Transit Gateway attachments, future account expansion, and overlap with on-premises networks. Overlapping CIDR ranges are painful because many AWS connectivity options require non-overlapping ranges.

Common VPC building blocks:

* **CIDR blocks**: define the private IP ranges available inside the VPC.
* **Subnets**: split the VPC IP range by AZ and workload type.
* **Route tables**: decide where traffic goes based on destination.
* **Internet gateway**: allows public subnets to send and receive internet traffic.
* **NAT gateway**: lets private subnet resources make outbound connections without accepting unsolicited inbound internet traffic.
* **Security groups**: stateful firewall rules attached to resources such as EC2 instances, ENIs, load balancers, and RDS instances.
* **Network ACLs**: stateless firewall rules attached at the subnet level.
* **VPC endpoints**: private paths to supported AWS services.
* **VPC peering, Transit Gateway, VPN, and Direct Connect**: ways to connect VPCs or connect AWS to external networks.
* **DNS settings and DHCP options**: control name resolution and basic network configuration inside the VPC.

### Default VPC vs custom VPC

Many AWS accounts include a **default VPC** in each Region. A default VPC is convenient for quick testing because it already has subnets, an internet gateway, route tables, and default security settings. However, production systems usually use **custom VPCs** because you can design the CIDR ranges, subnet tiers, routing, naming, tags, security boundaries, and high availability layout intentionally.

The default VPC is useful for learning, but it can hide important networking details. In a real environment, you normally want explicit Terraform-managed VPC resources so the design is repeatable and reviewable.

### Public, private, and isolated network design

Subnets are often described as **public**, **private**, or **isolated**, but these are design patterns, not separate AWS subnet types.

* A **public subnet** has a route to an internet gateway, usually `0.0.0.0/0 -> igw-...`. For an EC2 instance to be reachable from the internet over IPv4, it also needs a public IPv4 address or Elastic IP, plus security group and NACL rules that allow the traffic.
* A **private subnet** does not route directly to an internet gateway. It often has outbound internet access through a NAT gateway, usually `0.0.0.0/0 -> nat-...`.
* An **isolated subnet** has no default route to the internet through either an internet gateway or NAT gateway. It may only route to local VPC resources, VPC endpoints, Transit Gateway, VPN, Direct Connect, or other private networks.

A common production pattern is:

* Public subnets for internet-facing load balancers, NAT gateways, and sometimes bastion hosts.
* Private application subnets for EC2, ECS, EKS, or Lambda-connected workloads.
* Private database subnets for RDS, ElastiCache, OpenSearch, or other data services.

The name of a subnet does not make it public or private. The route table does.

### Internet gateway and NAT gateway

An **internet gateway** is attached to a VPC and provides a route target for internet traffic. A public subnet normally has a default route to the internet gateway. For inbound IPv4 access to an EC2 instance, the instance needs a public IPv4 address or Elastic IP. For IPv6, internet-routable IPv6 addresses can be used directly, so the security rules become especially important.

A **NAT gateway** is usually placed in a public subnet and used by private subnets for outbound IPv4 internet access. Private instances send internet-bound traffic to the NAT gateway, and the NAT gateway sends it out through the internet gateway. Return traffic is allowed, but external hosts cannot start new inbound connections to the private instances through the NAT gateway.

For high availability, place NAT gateways in multiple AZs and route each private subnet to the NAT gateway in the same AZ. A single NAT gateway for all private subnets is cheaper but creates an AZ dependency and can add cross-AZ data transfer.

### DNS inside a VPC

VPC DNS behavior matters more than people expect. Two common VPC attributes are:

* `enableDnsSupport`: allows use of the Amazon-provided DNS resolver.
* `enableDnsHostnames`: allows public DNS hostnames for instances with public IPs in supported cases.

Private DNS is also important for VPC endpoints. For many interface endpoints, enabling private DNS makes the normal AWS service hostname resolve to private IP addresses inside the VPC. Without private DNS, applications may still try to reach the public AWS API endpoint and fail if the subnet has no NAT or internet access.

For hybrid environments, DNS can involve Route 53 private hosted zones, Route 53 Resolver inbound endpoints, outbound endpoints, and forwarding rules to on-premises DNS servers.

### Security groups vs NACLs

VPC security is usually controlled with both **security groups** and **network ACLs**, but they work differently.

* **Security groups** are stateful and attached to resources. If inbound traffic is allowed, the response traffic is automatically allowed. Security groups only have allow rules.
* **Network ACLs** are stateless and attached to subnets. You must allow both inbound and outbound traffic, including ephemeral ports for return traffic. NACLs support both allow and deny rules.

In most application designs, security groups are the primary control. NACLs are often kept simple unless there is a specific subnet-level deny or compliance requirement.

### VPC endpoint

A **VPC endpoint** lets resources in a VPC privately reach supported AWS services without using the public internet, an internet gateway, or a NAT gateway. This is very important for private subnet design.

There are two common endpoint types:

* **Gateway endpoint**: used mainly for Amazon S3 and DynamoDB. It is added as a route-table target. It does not use AWS PrivateLink and usually has no hourly charge.
* **Interface endpoint**: creates one or more elastic network interfaces in your subnets and exposes a private IP address for a service. It is powered by AWS PrivateLink. Many AWS services support interface endpoints, including Secrets Manager, STS, ECR, CloudWatch Logs, SSM, KMS, and many others.

VPC endpoints are useful when private EC2 instances, Lambda functions, ECS tasks, or EKS nodes need to call AWS APIs without public internet access. Example: private EC2 instances pulling container images from ECR often need endpoints for ECR API, ECR Docker, S3, and CloudWatch Logs if they do not have NAT access.

Common gotcha: creating an endpoint is not always enough. You may also need private DNS enabled, correct subnet placement, correct security group rules for interface endpoints, correct route table associations for gateway endpoints, and endpoint policies that allow the required actions.

Endpoints can also reduce NAT gateway traffic and help keep service calls on private AWS networking. However, endpoints are not magic. The application still needs IAM permissions, endpoint policies must allow the request, security groups must allow traffic to interface endpoint ENIs, and DNS must resolve the way the application expects.

### VPC flow logs

**VPC Flow Logs** capture metadata about IP traffic going to and from network interfaces, subnets, or the whole VPC. They do not capture packet payloads, but they are very useful for troubleshooting and auditing.

Flow logs can help answer questions like:

* Is traffic reaching the instance ENI?
* Is traffic accepted or rejected?
* What source IP and destination port are being used?
* Is an unexpected workload talking to the internet?
* Are NACLs or security groups likely blocking traffic?

Flow logs can be sent to CloudWatch Logs, S3, or Kinesis Data Firehose. They are often used with CloudWatch Logs Insights, Athena, or security tooling.

### Connecting VPCs and external networks

There are several ways to connect a VPC to other networks:

* **VPC peering**: simple one-to-one private connectivity between two VPCs.
* **Transit Gateway**: hub-and-spoke connectivity for many VPCs, VPNs, and Direct Connect attachments.
* **Site-to-Site VPN**: encrypted connectivity over the public internet between AWS and an external network.
* **Direct Connect**: private dedicated network connectivity from on-premises or colocation environments into AWS.
* **PrivateLink**: private service access where consumers connect to a service through interface endpoints without full network-level routing between VPCs.

Choosing between these depends on scale, routing needs, segmentation, overlapping CIDRs, cost, and whether consumers need full network access or only access to a specific service.

### VPC peering

**VPC peering** connects two VPCs so resources can communicate using private IP addresses. It can be same-account, cross-account, same-Region, or cross-Region. After the peering connection is created and accepted, you must update route tables on both sides to send traffic to the peering connection.

Peering is simple and useful for direct one-to-one VPC connectivity, but it has limitations. The biggest interview point is that **VPC peering is not transitive**. If VPC A is peered with VPC B, and VPC B is peered with VPC C, VPC A cannot reach VPC C through VPC B. For hub-and-spoke or many-VPC designs, AWS Transit Gateway is usually better.

Another important limitation: VPC CIDR ranges must not overlap. If two VPCs both use `10.0.0.0/16`, you cannot route between them correctly through peering. This is why early IP planning matters.

Peering also does not provide centralized inspection by itself. If you need many VPCs to share routing, attach to on-premises networks, or use centralized egress and inspection patterns, Transit Gateway is usually the more scalable design.

### Terraform notes for VPCs

In Terraform, a VPC design often includes resources like:

* `aws_vpc`
* `aws_subnet`
* `aws_internet_gateway`
* `aws_nat_gateway`
* `aws_eip`
* `aws_route_table`
* `aws_route`
* `aws_route_table_association`
* `aws_security_group`
* `aws_vpc_endpoint`
* `aws_flow_log`

Common Terraform mistakes:

* Creating subnets in only one AZ for a workload that should be highly available.
* Naming a subnet "private" but accidentally associating it with a public route table.
* Forgetting route table associations, causing subnets to use the main route table.
* Creating a NAT gateway without a public subnet, Elastic IP, or route to an internet gateway.
* Creating an interface endpoint but forgetting its security group rules.
* Using CIDR ranges that overlap with another VPC or on-premises network.
* Reusing one route table everywhere when public, private, and database subnets need different routes.
* Forgetting tags, which makes cost allocation and operations harder later.

### Common VPC troubleshooting checklist

When something cannot connect, check the path layer by layer:

* Source subnet route table.
* Destination subnet route table, if traffic must return.
* Security group inbound and outbound rules.
* Network ACL inbound and outbound rules.
* Public IP or Elastic IP requirements for internet-facing IPv4 access.
* Internet gateway or NAT gateway attachment and routes.
* VPC endpoint DNS, endpoint policy, and endpoint security group.
* DNS resolution and private hosted zone associations.
* Overlapping CIDRs or missing routes across peering, Transit Gateway, VPN, or Direct Connect.
* VPC Flow Logs for accepted or rejected traffic.

A VPC is the regional network container. Subnets are AZ-specific placement and routing boundaries. Public/private behavior is controlled mainly by route tables. Security groups protect resources, NACLs protect subnets, and endpoints let private workloads access AWS services privately. VPC peering is direct private connectivity but not transitive. Good VPC design is mostly about IP planning, routing, DNS, security boundaries, and high availability.

---

## Subnet

A **subnet** is a smaller IP range inside a VPC. Every subnet belongs to exactly one Availability Zone. This is a very important AWS networking concept: a VPC spans multiple AZs, but a subnet does not. If you want high availability across two AZs, you need at least two subnets, one in each AZ.

Example:

* VPC CIDR: `10.0.0.0/16`
* Public subnet in `us-east-1a`: `10.0.1.0/24`
* Private subnet in `us-east-1a`: `10.0.11.0/24`
* Public subnet in `us-east-1b`: `10.0.2.0/24`
* Private subnet in `us-east-1b`: `10.0.12.0/24`

Subnets are often called **public** or **private**, but that is not a special subnet type. A subnet is public if its route table has a default route, usually `0.0.0.0/0`, pointing to an internet gateway, and the instance has a public IP address or Elastic IP. A subnet is private if it does not route directly to an internet gateway. Private subnets often route outbound internet traffic through a NAT gateway.

For highly available applications, you normally place load balancers across public subnets in multiple AZs and place application servers or containers in private subnets across multiple AZs. Databases are usually placed in private DB subnets across multiple AZs.

AWS reserves several IP addresses in every subnet, so not every IP in the CIDR block is usable. In small subnets this matters a lot. For example, a `/28` subnet has 16 addresses, but fewer are usable. For EKS, ECS, Lambda ENIs, and autoscaling workloads, subnet IP exhaustion is a common real-world incident cause.

A subnet is tied to one AZ. High availability requires multiple subnets across multiple AZs. Public/private is determined mostly by routing, not by the subnet name. Always plan subnet CIDRs with future scaling and ENI-heavy workloads in mind.

---

## Route table

A **route table** controls where network traffic goes. Every subnet is associated with a route table. If you do not explicitly associate a subnet with a custom route table, it uses the VPC’s main route table.

A route table contains **routes**. A route has two main parts:

* **Destination**: the CIDR block or prefix list being matched, such as `10.0.0.0/16`, `0.0.0.0/0`, or an AWS-managed prefix list for S3.
* **Target**: where matching traffic should go, such as `local`, an internet gateway, NAT gateway, VPC endpoint, transit gateway, virtual private gateway, network interface, or VPC peering connection.

Every VPC route table includes a **local route** for the VPC CIDR, such as `10.0.0.0/16 -> local`. This allows resources inside the VPC to communicate with each other, assuming security groups and NACLs allow it. You cannot delete the local route.

The default route `0.0.0.0/0` means “all IPv4 destinations not matched by a more specific route.” For IPv6, the equivalent is `::/0`. AWS uses longest prefix match: the most specific matching route wins. For example, `10.0.5.0/24` is more specific than `10.0.0.0/16`.

Common route table patterns:

* Public subnet: `0.0.0.0/0 -> internet gateway`
* Private subnet with outbound internet: `0.0.0.0/0 -> NAT gateway`
* Private subnet accessing S3 privately: S3 prefix list -> gateway VPC endpoint
* Peered VPC: remote VPC CIDR -> VPC peering connection
* Hybrid network: on-prem CIDR -> VPN, Direct Connect, or Transit Gateway

Route table troubleshooting usually starts with: Is the source subnet associated with the expected route table? Does the destination have a route back? Is the next hop healthy and in the right state? Are security groups/NACLs allowing it? Is the destination more specific than another route?

A route table is the VPC traffic map. A route is destination plus target. Subnets use route tables. Public subnets route to an internet gateway, private subnets usually route outbound through NAT, and peered/hybrid networks need routes on both sides.

---

## Internet gateway

An **internet gateway**, or IGW, allows communication between resources in a VPC and the public internet. It is horizontally scaled, highly available, and attached to a VPC. A VPC can have one internet gateway attached at a time.

An internet gateway alone does not make an instance reachable from the internet. For an EC2 instance in a public subnet to reach or be reached from the internet, several things must be true:

1. The VPC has an internet gateway attached.
2. The subnet’s route table has a route such as `0.0.0.0/0 -> igw-...`.
3. The instance has a public IPv4 address, Elastic IP, or IPv6 address with a route.
4. The security group allows the traffic.
5. The network ACL allows the traffic.
6. The OS firewall and application are listening correctly.

In production architectures, internet gateways are commonly used by public load balancers, bastion hosts, NAT gateways, public-facing EC2 instances, and sometimes public subnets hosting edge infrastructure. Application servers and databases usually should not be directly public.

One common interview trick: a private subnet can still have internet access through a NAT gateway, but that NAT gateway itself normally sits in a public subnet that routes to the internet gateway.

The internet gateway is the VPC’s direct path to the public internet, but public reachability also requires routing, public IP addressing, and firewall rules. IGW is for public ingress/egress; NAT gateway is for private subnet outbound access.

---

## Security group

A **security group** is a stateful virtual firewall for AWS resources inside a VPC. It controls allowed inbound and outbound traffic for resources such as EC2 instances, elastic network interfaces, load balancers, RDS instances, ElastiCache clusters, EFS mount targets, Lambda VPC ENIs, ECS tasks, EKS worker nodes, and interface VPC endpoints.

Security groups are associated with **network interfaces**, not with subnets. When people say "the EC2 instance has this security group," that usually means the instance's ENI has that security group attached. This matters because some services create and manage ENIs for you, such as Lambda in a VPC, ECS tasks in `awsvpc` network mode, EKS pods with certain CNI features, RDS, and interface endpoints.

Security groups are **stateful**. If a request is allowed in one direction, the response traffic is automatically allowed back. For example, if an EC2 instance is allowed to receive inbound TCP `443` traffic from an ALB, the response traffic back to the ALB is allowed automatically. You do not need to open ephemeral return ports in the security group. This is one of the biggest differences between security groups and NACLs.

Security groups only support **allow rules**. There are no deny rules. If no rule allows the traffic, the traffic is denied by default. Inbound traffic is denied by default. Outbound traffic is often allowed to all destinations by default, but in stricter environments you can remove that default egress rule and define only the destinations the resource needs.

### Security group rule components

A security group rule usually includes:

* **Direction**: inbound, also called ingress, or outbound, also called egress.
* **Protocol**: TCP, UDP, ICMP, ICMPv6, or all traffic.
* **Port range**: for example `22`, `80`, `443`, `5432`, or a custom range.
* **Source or destination**: CIDR block, another security group, prefix list, or self-reference.
* **Description**: a human-readable note explaining why the rule exists.

Inbound rules use a **source**. Outbound rules use a **destination**.

Examples:

* Inbound TCP `443` from `0.0.0.0/0` means anyone on the IPv4 internet can attempt HTTPS access.
* Inbound TCP `5432` from an application security group means only resources with that application security group can attempt PostgreSQL access.
* Outbound TCP `443` to `0.0.0.0/0` means the resource can attempt HTTPS connections anywhere on the IPv4 internet, assuming routes and NACLs allow it.
* Outbound TCP `443` to a VPC endpoint security group means the resource can call that endpoint privately.

Security group rules can also include IPv6 CIDRs such as `::/0`. Do not forget IPv6 when a VPC or subnet has IPv6 enabled. A resource may be locked down for IPv4 but still exposed through an overly broad IPv6 rule.

### Referencing security groups

A powerful AWS feature is using another security group as the source or destination of a rule. For example, an RDS security group can allow inbound PostgreSQL `5432` only from the application security group. This is usually better than allowing an IP range because application instances, ECS tasks, or EKS nodes can scale and change private IPs without needing rule updates.

Important details about security group references:

* Referencing a security group does not copy the referenced group's rules.
* It means "resources that have this security group attached."
* For inbound rules, the referenced security group is the allowed source.
* For outbound rules, the referenced security group is the allowed destination.
* Security group references use private IP communication, not public IPs.
* Self-referencing rules allow resources with the same security group to communicate with each other.

Security group references are common in layered architectures:

* ALB security group allows inbound `443` from the internet.
* Application security group allows inbound app traffic only from the ALB security group.
* Database security group allows inbound database traffic only from the application security group.
* EFS security group allows inbound NFS `2049` from application or worker node security groups.
* Interface VPC endpoint security group allows inbound `443` from application security groups.

This pattern gives cleaner access control than broad VPC CIDR rules like `10.0.0.0/16`, especially when multiple applications share one VPC.

### Default security group

Every VPC has a **default security group**. By default, it usually allows inbound traffic from resources that are associated with the same default security group and allows all outbound traffic. This is convenient for quick testing, but it is usually too broad for production.

In production, avoid relying on the default security group for application access. Create purpose-specific security groups with clear names and descriptions, such as:

* `alb-public-sg`
* `app-web-sg`
* `rds-postgres-sg`
* `vpce-shared-services-sg`

Good names and rule descriptions matter because security groups become operational documentation. Six months later, you want to know why a port is open without reverse-engineering the whole system.

### Inbound and outbound design

For internet-facing workloads, the public entry point is usually a load balancer, not the application instance directly.

Common web application pattern:

* Public ALB security group: inbound `443` from `0.0.0.0/0` and `::/0` if IPv6 is used.
* Application security group: inbound application port from the ALB security group only.
* Database security group: inbound database port from the application security group only.
* Application outbound: HTTPS to required APIs, VPC endpoints, package mirrors, or internal services.

For private workloads, try to avoid direct SSH or RDP access. Prefer AWS Systems Manager Session Manager, VPN, bastion access with tight controls, or a private connectivity model. If SSH or RDP is required, restrict it to a known admin CIDR or bastion security group, not `0.0.0.0/0`.

Outbound rules deserve attention too. Many teams leave outbound open because it is convenient, but stricter environments may require least-privilege egress. Common controlled egress patterns include:

* Allow outbound `443` to interface endpoint security groups.
* Allow outbound to AWS-managed prefix lists, such as S3 prefix lists where applicable.
* Allow outbound to internal service security groups.
* Route general outbound internet traffic through centralized inspection or NAT.

### Security groups and routing

A security group rule does not create a route. It only allows traffic that can already find a network path.

For a successful connection, you normally need all of these:

* Source security group allows outbound traffic.
* Destination security group allows inbound traffic.
* Source subnet route table has a route to the destination.
* Destination has a return path, unless the traffic is handled by a stateful service path.
* Network ACLs allow the traffic in both directions.
* DNS resolves to the address you expect.
* The application is listening on the expected port.

This is a common troubleshooting trap: the security group can be correct, but the route table, NACL, DNS record, endpoint policy, operating system firewall, or application listener can still block the connection.

### Connection tracking

Because security groups are stateful, AWS tracks allowed connections. Existing tracked flows may continue briefly even after a rule change, depending on the protocol and connection state. This is why changing a security group rule is not always the same as instantly killing every existing connection.

Connection tracking is also why you usually do not need to open ephemeral ports in security groups. NACLs are different because they are stateless and must explicitly allow return traffic.

One unusual edge case: security groups do not block traffic to or from the Amazon-provided DNS resolver for the VPC. If you need DNS filtering, use Route 53 Resolver DNS Firewall or another DNS control instead of expecting a security group rule to block that resolver path.

### Security groups for common AWS services

Different services use security groups in slightly different ways:

* **EC2**: security groups attach to the instance ENI.
* **ALB**: security groups control who can reach the load balancer and where the load balancer can send traffic.
* **RDS**: database access is controlled by the DB instance or cluster security group.
* **EFS**: mount targets need inbound NFS `2049` from clients.
* **Lambda in a VPC**: Lambda-created ENIs use the selected security groups for outbound access to private resources.
* **ECS/Fargate**: tasks in `awsvpc` mode get ENIs and security groups.
* **EKS**: worker nodes and sometimes pods use security groups, depending on configuration.
* **Interface VPC endpoints**: endpoint ENIs need inbound `443` from the clients that call the service.

For managed services, always think about which side receives the connection. For example, an RDS security group needs inbound database port access from the app, while an interface endpoint security group needs inbound HTTPS from the clients.

### Terraform notes for security groups

In Terraform, security groups are commonly managed with:

* `aws_security_group`
* `aws_security_group_rule`
* `aws_vpc_security_group_ingress_rule`
* `aws_vpc_security_group_egress_rule`

Modern Terraform code often prefers separate ingress and egress rule resources because each rule has its own lifecycle and is easier to change without replacing unrelated rules. Inline rules inside `aws_security_group` can be fine for small examples, but mixing inline rules and separate rule resources for the same security group can create confusing diffs.

Good Terraform practices:

* Use clear names and descriptions for both the security group and the rules.
* Prefer security group references over broad CIDR ranges for service-to-service traffic.
* Keep public ingress rules rare and obvious.
* Model IPv4 and IPv6 rules intentionally.
* Avoid hardcoding temporary office IPs without a clear process to update them.
* Use variables or data sources for shared prefix lists when appropriate.
* Do not accidentally remove the default egress rule unless you are ready to define all required outbound access.

Common Terraform mistakes:

* Allowing `0.0.0.0/0` to SSH `22` or RDP `3389`.
* Opening a database port to the whole VPC CIDR when only the app tier needs access.
* Adding a rule to the ALB security group when the real missing rule is on the target security group.
* Forgetting that an ECS task, Lambda function, or VPC endpoint has its own security group.
* Creating circular dependencies between security groups and resources.
* Mixing inline security group rules with standalone rule resources.
* Forgetting IPv6 exposure through `::/0`.

### Common security group troubleshooting checklist

When a connection fails, check:

* Is the security group attached to the correct ENI or managed service?
* Does the source security group allow outbound traffic on the right protocol and port?
* Does the destination security group allow inbound traffic from the right source?
* Is the source a CIDR, prefix list, or security group reference, and is that the right type?
* If using a security group reference, does the source resource actually have that security group attached?
* Are you connecting to a private IP when the rule expects private security group referenced traffic?
* Is DNS resolving to a public IP when you expected a private IP?
* Do route tables and NACLs allow the traffic path?
* Is the operating system firewall blocking the port?
* Is the application actually listening on the expected interface and port?
* Did you account for IPv6 rules if IPv6 is enabled?

Security groups are stateful, resource-level, allow-only firewalls. They are usually the first thing to check when an AWS resource cannot connect to another resource, but they are only one layer. Prefer security group references for service-to-service access, keep public ingress narrow, document why each rule exists, and remember that routing, DNS, NACLs, IAM, endpoint policies, and the application itself can still affect connectivity.

---

## NACL

A **network ACL**, or NACL, is a subnet-level firewall. It controls traffic entering and leaving a subnet. Unlike security groups, NACLs are **stateless**, meaning inbound and outbound rules are evaluated separately. If you allow inbound traffic, you must also allow the return traffic in the outbound direction.

NACL rules have:

* Rule number
* Protocol
* Port range
* Source or destination CIDR
* Allow or deny action

Rules are evaluated in ascending rule number order, and the first matching rule wins. This means rule ordering matters. A lower-numbered deny can block traffic even if a later allow exists.

The default VPC NACL usually allows all inbound and outbound traffic. A custom NACL usually denies all traffic until you add allow rules. NACLs can be useful as an extra subnet-level guardrail, especially for blocking known bad CIDRs, isolating subnets, or enforcing broad network segmentation.

Because NACLs are stateless, ephemeral ports are a frequent source of confusion. For example, if a client connects to a server on TCP 443, the return traffic uses an ephemeral port on the client side. If outbound or inbound ephemeral port ranges are blocked, connections can fail even when port 443 appears open.

For most application access control, security groups are easier and more precise. NACLs are better for coarse subnet-level rules and explicit deny use cases.

NACLs are subnet-level and stateless. They support allow and deny rules. Rule order matters. Always consider both directions and ephemeral ports when troubleshooting NACL-related network issues.

---

## NAT gateway

A **NAT gateway** lets resources in private subnets initiate outbound connections while preventing unsolicited inbound connections from the internet. It is commonly used when private EC2 instances, ECS tasks, EKS nodes, or Lambda functions need to download packages, call public APIs, or reach AWS services without being directly public.

A public NAT gateway is created in a **public subnet** and is associated with an Elastic IP address. Private subnets then route outbound internet traffic through the NAT gateway. The NAT gateway itself routes to the internet gateway.

Common routing pattern:

* Public subnet route table: `0.0.0.0/0 -> internet gateway`
* Private subnet route table: `0.0.0.0/0 -> NAT gateway`

For high availability, create one NAT gateway per AZ and route each private subnet to the NAT gateway in the same AZ. If a private subnet in AZ A routes to a NAT gateway in AZ B, an AZ issue can break outbound connectivity and may also add cross-AZ data charges.

NAT gateways are managed and scalable, but they can be expensive because they have hourly charges and data processing charges. In production, reduce NAT cost by using VPC endpoints for AWS services such as S3, DynamoDB, ECR, CloudWatch Logs, Secrets Manager, STS, and KMS where appropriate.

A NAT gateway does not allow inbound connections from the internet to private instances. If you need admin access, use AWS Systems Manager Session Manager, a VPN, a bastion host, or a private connectivity model rather than exposing instances publicly.

NAT gateway is for outbound access from private subnets. It lives in a public subnet, uses an Elastic IP, and routes through an internet gateway. For HA, use one per AZ. For cost and security, replace unnecessary NAT traffic with VPC endpoints.

---

## Auto Scaling Group

An **Auto Scaling Group**, or ASG, manages a fleet of EC2 instances. Its core job is to maintain the desired number of healthy instances and optionally scale capacity up or down based on demand. ASGs are central to classic EC2-based high availability.

An ASG usually uses a **launch template** that defines how instances should be launched: AMI ID, instance type, key pair, IAM instance profile, security groups, user data, EBS mappings, tags, and network settings. The ASG also has minimum, maximum, and desired capacity.

Important capacity values:

* **Minimum capacity**: the lowest number of instances the group should run.
* **Desired capacity**: the number of instances the group tries to maintain right now.
* **Maximum capacity**: the upper scaling limit.

ASGs perform health checks. By default, they use EC2 status checks. They can also use Elastic Load Balancing health checks, so an instance that fails ALB target group health can be replaced. This is important: an EC2 instance can be “running” but still unhealthy from the application perspective.

Scaling methods include:

* **Target tracking scaling**: keep a metric around a target, such as average CPU at 50%.
* **Step scaling**: add/remove capacity based on alarm severity.
* **Scheduled scaling**: scale at known times.
* **Predictive scaling**: forecast expected demand.

ASG issues often involve bad AMIs, broken user data, failed health checks, insufficient subnet IPs, capacity shortages, IAM permissions, launch template version drift, and applications not shutting down gracefully during scale-in.

When an ASG is behind an ALB, pay attention to health check grace period, deregistration delay, lifecycle hooks, and termination policies. Lifecycle hooks can let you drain connections, upload logs, or deregister from systems before termination.

An ASG keeps EC2 capacity healthy and scalable. It launches from a launch template, maintains desired capacity, replaces unhealthy instances, and can scale based on CloudWatch metrics or schedules. Most ASG incidents are caused by launch failures, health check failures, subnet capacity, or bad deployment automation.

---

## ALB Load Balancer

An **Application Load Balancer**, or **ALB**, is an AWS Layer 7 load balancer for HTTP and HTTPS traffic. Layer 7 means it understands application-level request information such as host headers, paths, HTTP methods, headers, query strings, and sometimes authentication-related behavior. This makes it different from a Network Load Balancer, which works at Layer 4 and focuses on TCP/UDP/TLS forwarding.

An ALB is commonly used in front of EC2 instances, Auto Scaling Groups, ECS services, EKS ingress controllers, Lambda functions, and internal microservices. It gives clients a single DNS endpoint while spreading traffic across healthy backend targets. In production, an ALB is usually deployed across at least two Availability Zones for high availability.

An ALB can be **internet-facing** or **internal**. An internet-facing ALB is placed in public subnets and can receive traffic from the internet. An internal ALB is placed in private subnets and is used for private service-to-service traffic inside a VPC or connected network.

### Listener

A **listener** is the ALB component that waits for incoming client connections on a specific protocol and port, such as:

* HTTP on port 80
* HTTPS on port 443

An ALB needs at least one listener to receive traffic. A listener has **rules** that decide what action to take when a request arrives. Rules are evaluated by priority. A listener always has a default rule, and it can also have additional rules based on conditions.

Common listener actions include:

* Forward traffic to a target group
* Redirect HTTP to HTTPS
* Return a fixed response
* Authenticate users with supported identity providers

A typical production setup has:

* HTTP listener on port 80 that redirects to HTTPS
* HTTPS listener on port 443 that uses an ACM certificate and forwards traffic to a target group

For HTTPS listeners, the ALB terminates TLS. This means the client establishes HTTPS with the ALB, and the ALB can forward to targets over HTTP or HTTPS depending on your target group configuration. Terminating TLS at the ALB simplifies certificate management, but you may still use HTTPS from ALB to target if required by security policy.

### Target group

A **target group** is a group of backend targets that receive traffic from the ALB. A listener rule forwards requests to one or more target groups.

Target types include:

* **Instance**: targets are EC2 instance IDs.
* **IP**: targets are private IP addresses, commonly used with ECS awsvpc mode, EKS, or services outside the ALB’s direct instance model.
* **Lambda**: target is a Lambda function.

Target groups include health checks. The ALB only sends traffic to targets that pass health checks. Health check settings include:

* Protocol: HTTP or HTTPS
* Path: for example `/health`
* Port
* Healthy threshold
* Unhealthy threshold
* Timeout
* Interval
* Success matcher, such as HTTP 200

Health checks are one of the most important ALB troubleshooting areas. An EC2 instance can be running and reachable by SSH but still unhealthy in the target group because the application is not listening, the health path returns the wrong status code, the port is wrong, or the security group blocks ALB traffic.

### Common ALB routing patterns

ALB supports advanced routing such as:

* Host-based routing: `api.example.com` goes to API target group, `app.example.com` goes to frontend target group.
* Path-based routing: `/api/*` goes to backend service, `/static/*` goes to static service.
* Header-based routing: traffic with a certain header goes to a canary target group.
* Weighted forwarding: split traffic between target groups for blue/green or canary deployment.

This is very useful in microservice environments where many services share one load balancer but route based on domain or URL path.

### Security groups and ALB traffic

The ALB has its own security group. Backend targets also have security groups. A common secure pattern is:

* ALB security group allows inbound 443 from internet or corporate IP ranges.
* Application security group allows inbound application port only from the ALB security group.
* Application instances do not allow direct public access.

This makes the ALB the controlled entry point.

### Monitoring and SRE concerns

Important ALB CloudWatch metrics include:

* `RequestCount`
* `TargetResponseTime`
* `HTTPCode_ELB_5XX_Count`
* `HTTPCode_Target_5XX_Count`
* `HTTPCode_ELB_4XX_Count`
* `HTTPCode_Target_4XX_Count`
* `HealthyHostCount`
* `UnHealthyHostCount`
* `TargetConnectionErrorCount`

A useful interview distinction is:

* **ELB 5xx** usually means the load balancer itself could not successfully handle or forward the request.
* **Target 5xx** means the backend application returned the 5xx response.

Enable ALB access logs to S3 when you need detailed request-level analysis. These logs are useful for debugging latency, client errors, bad user agents, suspicious traffic, and backend failures.

### Common mistakes

* Listener exists but forwards to the wrong target group.
* Health check path is wrong.
* Target listens on port 8080 but target group uses port 80.
* Target security group does not allow inbound traffic from ALB security group.
* HTTP to HTTPS redirect loop due to app also forcing redirects incorrectly.
* Wrong ACM certificate attached to HTTPS listener.
* ALB subnets do not span enough AZs for high availability.
* Application requires a Host header but health check does not send the expected one.


An ALB receives traffic through **listeners** and forwards it to **target groups**. Listeners define protocol, port, certificates, and routing rules. Target groups define the backends and health checks. Most ALB issues are caused by health checks, security groups, wrong ports, TLS/certificates, or routing rules.

---

## EC2 Instance

An **EC2 instance** is a virtual machine in AWS. You choose an AMI, instance type, networking, storage, IAM role, and user data. EC2 is still one of the most important services because many workloads, Kubernetes nodes, legacy applications, agents, CI runners, and databases run on virtual machines.

### EC2 instance types

The **instance type** defines CPU, memory, network, EBS bandwidth, local instance storage, architecture, and cost. Instance families are optimized for different workloads:

* General purpose: balanced CPU/memory/network, such as `m` and `t` families
* Compute optimized: high CPU, such as `c` families
* Memory optimized: high RAM, such as `r`, `x`, and similar families
* Storage optimized: high local disk throughput, such as `i` and `d` families
* Accelerated computing: GPUs, Inferentia, Trainium, or FPGA-like acceleration

choose instance types based on workload profile, not guesswork. Watch CPU steal, memory pressure, network PPS limits, EBS bandwidth, and architecture compatibility such as x86 vs ARM/Graviton.

### EC2 instance profile

An **instance profile** is the container that lets an IAM role be attached to an EC2 instance. The application running on the instance can then get temporary credentials from the Instance Metadata Service and call AWS APIs without hardcoded access keys.

This is the correct way to allow EC2 to access S3, CloudWatch Logs, Secrets Manager, SSM, ECR, or other AWS services. Never store long-term AWS access keys on instances if an IAM role can be used.

### Root volume

The **root volume** contains the operating system. It is usually an EBS volume for modern EC2 instances. The root volume can be encrypted, resized, snapshotted, and configured to delete or persist on instance termination.

A common incident is accidentally terminating an instance and losing data because important data lived only on the root volume and the **delete-on-termination** flag was enabled. Production data should normally be on separate EBS volumes, EFS, S3, or managed databases, not only on a root disk.

### EC2 IP address

EC2 instances can have private IPs, public IPs, Elastic IPs, and IPv6 addresses depending on subnet and configuration.

* **Private IP**: used inside the VPC. Primary private IP stays with the ENI.
* **Public IPv4**: reachable from the internet if routing/firewalls allow. It may change when the instance is stopped/started unless it is an Elastic IP.
* **Elastic IP**: static public IPv4 allocated to your account until released. Useful for stable public endpoints, but often better to use DNS/load balancers instead.
* **IPv6**: globally routable if assigned and routed properly.

### ENI

An **Elastic Network Interface**, or ENI, is a virtual network card. It has private IP addresses, security groups, MAC address, and attachment to an instance. Many AWS services use ENIs behind the scenes, including Lambda in a VPC, RDS, VPC endpoints, EFS mount targets, and load balancers.

ENIs matter because they consume subnet IP addresses. In container and serverless-heavy environments, IP exhaustion can happen because too many ENIs are created.

### Operational concerns

Key EC2 operational areas:

* Patch OS and packages
* Use SSM Session Manager instead of opening SSH when possible
* Monitor CPU, memory, disk, network, and status checks
* Use AMIs and launch templates for repeatable builds
* Avoid manual snowflake instances
* Back up important EBS volumes with snapshots
* Use tags for ownership, cost, and automation
* Use least-privilege instance profiles

EC2 is a VM. The instance type defines hardware. The instance profile provides IAM credentials. Root volume holds OS. ENIs provide networking. Public IPs are not stable unless Elastic IPs are used. Monitor, patch, automate, and avoid hardcoded credentials.

---

## EBS Volumes

**Amazon EBS**, or Elastic Block Store, provides block storage for EC2 instances. Think of it like a virtual hard disk attached to a VM. EBS is used for root volumes, application data, databases running on EC2, logs, and other block-storage workloads.

An EBS volume exists in a specific Availability Zone and can normally attach to EC2 instances in that same AZ. This AZ relationship is critical: if an instance is in `us-east-1a`, its EBS volume must also be in `us-east-1a` to attach.

### EBS attachment

You can attach multiple EBS volumes to one EC2 instance, depending on instance type limits. After attaching a volume, the OS sees a block device. You may need to partition, format, mount, and add it to `/etc/fstab` for persistence after reboot.

For Linux, common steps are:

1. Create volume in same AZ
2. Attach to instance
3. Confirm device with `lsblk`
4. Create filesystem if new, such as `mkfs.xfs` or `mkfs.ext4`
5. Mount to a directory
6. Add UUID-based mount entry to `/etc/fstab`

### EBS types

Common EBS volume types:

* **gp3**: general purpose SSD, common default choice. Baseline performance can be configured independently of size
* **gp2**: older general purpose SSD, performance tied to volume size and burst credits
* **io1 / io2**: provisioned IOPS SSD for high-performance, latency-sensitive workloads
* **st1**: throughput-optimized HDD for large sequential workloads
* **sc1**: cold HDD for infrequently accessed data

For most general workloads, gp3 is preferred because it gives predictable baseline performance and often better cost/performance than gp2.

### EBS encryption

EBS encryption protects data at rest, snapshots, and data moving between the instance and EBS. It uses AWS KMS keys. You can use AWS-managed keys or customer-managed KMS keys. Many organizations enable EBS encryption by default at the account/Region level.

Important KMS permission issue: if an Auto Scaling Group, EC2 service, or another principal needs to use an encrypted AMI or encrypted EBS volume with a customer-managed KMS key, the relevant IAM principal and AWS service role must have permission to use that KMS key.

### How to expand an EBS volume

Expanding EBS is usually a two-layer process:

1. Modify the EBS volume in AWS to increase size or performance
2. Extend the partition and filesystem inside the OS

Example Linux process:

* In AWS, modify volume size from 100 GiB to 200 GiB
* On instance, verify with `lsblk`
* If partitioned, grow partition with `growpart`
* Grow filesystem:

  * XFS: `xfs_growfs /mountpoint`
  * ext4: `resize2fs /dev/device`

Common mistake: increasing the volume in AWS but forgetting to extend the filesystem, so the OS still shows the old size.

### Operational concerns

EBS performance depends on volume type, size, provisioned IOPS, throughput, instance EBS bandwidth, and workload pattern. A high-performance volume attached to a small instance can still be limited by the instance’s EBS bandwidth.

Use snapshots for backups. Snapshots are incremental and stored in S3 behind the scenes. Regularly test restore procedures, not just snapshot creation.

EBS is AZ-scoped block storage for EC2. It attaches to instances in the same AZ. Know gp3 vs gp2 vs io volumes, encryption with KMS, snapshots, and the two-step volume expansion process: modify AWS volume, then grow OS filesystem.

---

## S3 Bucket

**Amazon S3** is AWS object storage. It stores data as objects inside buckets. Each object has a key, data, metadata, and optionally a version ID. S3 is widely used for backups, logs, static websites, Terraform state, application uploads, data lakes, artifacts, CloudFront origins, and cross-account data sharing.

S3 is not a normal filesystem. It does not have real folders in the traditional sense. What looks like a folder is usually just a prefix in the object key, such as `logs/2026/05/app.log`.

S3 is a regional service, but bucket names are globally unique. This means no other AWS account can create a bucket with the same name anywhere in AWS.

### Bucket ACL

A **bucket ACL**, or Access Control List, is an older S3 permission mechanism. ACLs can grant access to a bucket or object. Historically, ACLs were often used for public objects or cross-account access.

Modern AWS best practice is usually to avoid ACLs and use **S3 Object Ownership** with **bucket owner enforced** mode. In that mode, ACLs are disabled and the bucket owner automatically owns objects. Access is then managed using IAM policies, bucket policies, and sometimes access points.

You still need to understand ACLs because legacy environments may use them, and cross-account uploads can behave strangely if object ownership is not handled correctly. A common old problem was: Account A owns the bucket, Account B uploads an object, and Account A cannot read the object because Account B owns it. Object Ownership settings help prevent this type of issue.

### Bucket versioning

**Bucket versioning** keeps multiple versions of an object. If someone overwrites or deletes an object, previous versions can still be recovered.

For example, if `config.json` is overwritten with a bad file, versioning lets you restore the previous version. If an object is deleted in a versioned bucket, S3 usually adds a delete marker instead of immediately removing all old versions.

Versioning is useful for:

* Protection from accidental deletion
* Recovery from bad deployments
* Audit/history of objects
* Replication requirements
* Terraform state protection

The downside is cost. Old versions remain stored until lifecycle rules remove or transition them. For production buckets, versioning should usually be combined with lifecycle policies to expire old versions after a defined period.

### Public access

S3 public access can happen through bucket policies, object ACLs, bucket ACLs, or access point policies. AWS provides **S3 Block Public Access** settings to prevent accidental exposure. These can be enabled at the account level or bucket level.

For most private production buckets, Block Public Access should be enabled. If a bucket must serve public content, a safer common pattern is to keep the bucket private and serve content through CloudFront using Origin Access Control.

A common real-world issue is confusion between “policy allows public access” and “Block Public Access blocks it anyway.” If Block Public Access is enabled, a bucket policy that appears to allow public reads may still not work.

### SSE: server-side encryption

S3 supports server-side encryption, commonly abbreviated as **SSE**.

Common options:

* **SSE-S3**: S3-managed encryption keys. Simple and low operational overhead.
* **SSE-KMS**: AWS KMS-managed keys. Gives more control, auditability, key policies, and CloudTrail visibility.
* **SSE-C**: customer-provided encryption keys. Less common and more operationally complex.

With **SSE-KMS**, users and roles need both S3 permissions and KMS permissions. This is a very common source of `AccessDenied` errors. A role may have `s3:GetObject`, but if it lacks `kms:Decrypt` on the KMS key, it still cannot read the encrypted object.

You can also enforce encryption using bucket policies. For example, a policy can deny `PutObject` unless the request includes server-side encryption headers.

### Bucket policy

A **bucket policy** is a resource-based IAM policy attached to an S3 bucket. It controls access to the bucket and objects.

A bucket policy can be used to:

* Allow or deny cross-account access
* Allow CloudFront Origin Access Control to read objects
* Require HTTPS/TLS
* Require server-side encryption
* Restrict access to a VPC endpoint
* Restrict access to a specific AWS Organization
* Deny public access
* Allow a logging service to write logs

Important S3 policy resource patterns:

* Bucket itself: `arn:aws:s3:::my-bucket`
* Objects inside bucket: `arn:aws:s3:::my-bucket/*`

This distinction matters. Some actions apply to the bucket, such as `s3:ListBucket`. Other actions apply to objects, such as `s3:GetObject` or `s3:PutObject`.

### Operational concerns

Important things to monitor and manage:

* Bucket size and object count
* Lifecycle rules
* Versioned object growth
* Public access settings
* KMS key access
* Replication status
* CloudTrail data events for sensitive buckets
* Access logs or server access logging if needed
* Object lock and retention if compliance requires it

S3 can scale massively, but application design still matters. For example, an application that lists millions of objects frequently can be slow and expensive. Use prefixes, inventory reports, lifecycle policies, and event-driven processing where appropriate.

### Common mistakes

* Forgetting the difference between bucket ARN and object ARN
* Assuming folders are real directories
* Enabling versioning without lifecycle cleanup
* Making a bucket public accidentally
* Relying on ACLs in a modern environment where they are disabled
* Missing KMS permissions for SSE-KMS objects
* Deleting a versioned object and not understanding delete markers
* Using S3 like a low-latency local filesystem

S3 is object storage. Buckets hold objects. Use bucket policies and IAM for access, not ACLs unless you are dealing with legacy behavior. Versioning protects data but increases cost. Public access must be controlled carefully. SSE-KMS requires both S3 and KMS permissions.

---

## 2. Lambda Function

**AWS Lambda** is a serverless compute service. It runs code in response to events without requiring you to manage servers. You provide the code, runtime, memory setting, timeout, environment variables, IAM execution role, and optional VPC configuration. AWS handles provisioning, scaling, patching, and infrastructure management behind the scenes.

Lambda is used heavily in DevOps, SRE, and cloud engineering for automation and event-driven workflows. It can process S3 events, consume SQS messages, serve API Gateway requests, run scheduled jobs, react to CloudWatch/EventBridge events, automate incident response, and glue AWS services together.

### Core Lambda concepts

A Lambda function includes:

* Function code
* Runtime, such as Python, Node.js, Java, Go, .NET, or custom runtime
* Handler
* Memory size
* Timeout
* IAM execution role
* Environment variables
* Optional layers
* Optional VPC configuration
* Logging configuration
* Event source or trigger

The **handler** is the entry point that Lambda calls when the function is invoked. The handler receives an event object and context object. The event contains input data. The context contains runtime information such as request ID and remaining execution time.

### Lambda invocation

A **Lambda invocation** is one execution request sent to a function. There are three major invocation patterns:

1. Synchronous invocation
2. Asynchronous invocation
3. Event source mapping

Understanding the differences is very important for troubleshooting.

### Synchronous invocation

In **synchronous invocation**, the caller waits for the Lambda function to finish and return a response.

Examples:

* API Gateway calls Lambda for an HTTP request.
* An application directly invokes Lambda and waits for the result.
* An ALB invokes Lambda as a target.

If the function succeeds, the caller gets the response. If it fails or times out, the caller gets an error. Retry behavior is usually controlled by the caller, not automatically by Lambda.

Operational issue: if Lambda is behind API Gateway and the function times out or returns a malformed response, the client may see 502, 500, or timeout errors.

### Asynchronous invocation

In **asynchronous invocation**, the caller sends an event to Lambda and does not wait for the function result. Lambda queues the event internally and processes it.

Examples:

* S3 event notification invokes Lambda after object upload.
* SNS invokes Lambda.
* EventBridge invokes Lambda.

For asynchronous invocations, Lambda can retry failed events. You can configure failure handling using destinations or dead-letter queues. This is useful because the original caller is not waiting to handle the error.

Operational issue: async events can fail silently from the user's perspective unless you monitor Lambda errors, destinations, DLQs, and function logs.

### Event source mapping

An **event source mapping** is used when Lambda polls a source and invokes the function with records.

Common sources:

* SQS
* Kinesis Data Streams
* DynamoDB Streams
* Kafka / MSK

For SQS, Lambda polls the queue, receives messages, invokes the function with a batch, and deletes messages after successful processing. If processing fails, messages can return to the queue after the visibility timeout and eventually move to a DLQ if configured.

For streams such as Kinesis or DynamoDB Streams, ordering and iterator age matter. A failing record can block progress depending on configuration.

### Lambda logs

Lambda sends function logs to **CloudWatch Logs** if the execution role has the required permissions. By default, the log group name is usually:

```text
/aws/lambda/<function-name>
```

Inside the log group, Lambda creates log streams for execution environments. Each invocation includes system-generated START, END, and REPORT log lines, plus whatever your code writes to stdout/stderr or the runtime logger.

The REPORT line is useful because it includes duration, billed duration, memory size, maximum memory used, and sometimes initialization duration.

### Required log permissions

The Lambda execution role usually needs permissions like:

```json
{
  "Effect": "Allow",
  "Action": [
    "logs:CreateLogGroup",
    "logs:CreateLogStream",
    "logs:PutLogEvents"
  ],
  "Resource": "*"
}
```

In stricter environments, the resource can be narrowed to specific log group ARNs.

If logs do not appear, check:

* Does the function execution role have CloudWatch Logs permissions?
* Is the function actually being invoked?
* Is it running in the account/Region you are checking?
* Was the log group manually created with restrictive permissions or encryption?
* Is the function failing before writing custom logs?

### Good Lambda logging practices

Good logs should include:

* Request ID
* Correlation ID or trace ID
* Important input identifiers, not full sensitive payloads
* Downstream service names
* Error messages and stack traces
* Timing information
* Structured JSON if possible

Avoid logging:

* Passwords
* Secrets
* Tokens
* Authorization headers
* Full personally sensitive payloads
* Large event bodies unless needed and safe

For SRE work, structured logs make CloudWatch Logs Insights queries much easier.

### Lambda execution role

A Lambda function uses an **execution role**. This role controls what AWS resources the function can access.

Examples:

* Write logs to CloudWatch Logs
* Read from S3
* Write to DynamoDB
* Read a secret from Secrets Manager
* Decrypt with KMS
* Send messages to SQS
* Publish to SNS
* Put custom metrics to CloudWatch

The execution role trust policy must allow Lambda to assume the role. Its permission policies must allow the function's required actions.

A very common failure is this: Lambda has `secretsmanager:GetSecretValue`, but the secret is encrypted with a customer-managed KMS key and the role lacks `kms:Decrypt` on that key.

### Lambda environment variables and secrets

Lambda environment variables are useful for non-secret configuration such as environment name, table name, API base URL, or feature flags. They are not ideal as the only place to manage sensitive secrets.

For secrets, use Secrets Manager or SSM Parameter Store. If secrets are loaded into environment variables by deployment tooling, make sure logs, CI/CD output, and permission access are controlled.

### Timeout and memory

Lambda has a configurable timeout. If the function runs longer than the timeout, Lambda stops it.

Memory size affects both memory and CPU allocation. Increasing memory can sometimes reduce execution time because the function gets more CPU. This means a higher memory setting is not always more expensive overall if duration drops enough.

For SRE tuning, watch:

* Duration
* Timeout errors
* Max memory used
* Cold start duration
* Dependency initialization time

### Concurrency

Lambda scales by running concurrent execution environments.

Important concepts:

* **Concurrent executions**: number of function instances running at the same time.
* **Account concurrency limit**: regional limit shared by functions.
* **Reserved concurrency**: reserves and caps concurrency for one function.
* **Provisioned concurrency**: keeps execution environments initialized to reduce cold starts.

Throttling happens when Lambda cannot scale because concurrency limits are reached. For user-facing APIs, throttling can cause 429/5xx-style failures depending on integration. For queues, throttling may cause backlog and increased message age.

### Cold starts

A **cold start** happens when Lambda creates a new execution environment. Cold starts include downloading code, initializing runtime, loading dependencies, and running initialization code outside the handler.

Cold starts are more noticeable with:

* Java/.NET or heavy runtimes
* Large deployment packages
* VPC networking in some architectures
* Large dependencies
* Low-traffic functions that frequently scale from zero

Ways to reduce cold start impact:

* Keep package small
* Initialize only what is needed
* Reuse clients outside handler
* Use provisioned concurrency for latency-critical functions
* Avoid unnecessary VPC attachment

### VPC networking

By default, Lambda can call public AWS APIs and internet endpoints, but it cannot access private VPC resources. To access private resources such as RDS, ElastiCache, internal ALBs, or private services, attach Lambda to a VPC.

When Lambda is attached to a VPC, you choose subnets and security groups. Lambda creates or uses managed network interfaces to connect to the VPC.

Important gotcha: a VPC-attached Lambda placed in private subnets does not automatically have internet access. If it needs to call public AWS APIs or external APIs, it needs one of these:

* NAT gateway/instance route
* VPC endpoints for AWS services
* Private connectivity to the target service

Example incident: A Lambda is moved into private subnets so it can access RDS. Suddenly it cannot access Secrets Manager because there is no NAT gateway or Secrets Manager interface endpoint.

### Lambda with SQS

Lambda plus SQS is common for background jobs. Important settings:

* Batch size
* Visibility timeout
* Maximum batching window
* DLQ redrive policy
* Partial batch response
* Reserved concurrency

Visibility timeout should usually be longer than the expected processing time. If it is too short, messages may be processed more than once. Consumers should be idempotent.

For SRE, monitor SQS `ApproximateAgeOfOldestMessage`, queue depth, Lambda errors, throttles, and DLQ count.

### Lambda with API Gateway

When API Gateway invokes Lambda, the function usually needs to return a response in the format expected by the integration.

For proxy integrations, the response often includes:

* `statusCode`
* `headers`
* `body`
* optional `isBase64Encoded`

If the Lambda response format is invalid, API Gateway may return a 502 error even if your Lambda code appears to run.

### Lambda monitoring

Important CloudWatch metrics:

* `Invocations`
* `Errors`
* `Duration`
* `Throttles`
* `ConcurrentExecutions`
* `IteratorAge` for stream sources
* `DeadLetterErrors` where applicable

Useful alarms:

* Error rate above threshold
* Duration near timeout
* Throttles greater than zero
* DLQ messages greater than zero
* Iterator age increasing
* SQS oldest message age increasing

### Common Lambda mistakes

* Execution role missing permissions.
* KMS permissions missing for secrets or encrypted data.
* Function timeout too low.
* Memory too low, causing slow execution.
* No log retention set for Lambda log group.
* Function attached to VPC but no NAT/endpoints for outbound calls.
* Logging secrets or full sensitive events.
* Not handling duplicate SQS messages.
* Bad batch failure handling.
* API Gateway receives malformed Lambda proxy response.
* Reserved concurrency set to zero or too low.
* Deployment package too large or dependency mismatch.

### best practices

* Use least-privilege execution roles.
* Use structured logs.
* Set CloudWatch log retention.
* Use DLQs or destinations for async failures.
* Monitor errors, throttles, duration, and queue/stream lag.
* Keep functions small and focused.
* Reuse SDK clients outside the handler.
* Avoid unnecessary VPC attachment.
* Use VPC endpoints when private functions need AWS APIs.
* Make queue consumers idempotent.
* Use infrastructure as code for triggers, permissions, and log groups.

Lambda is event-driven serverless compute. Invocation can be synchronous, asynchronous, or through event source mappings. Lambda logs go to CloudWatch Logs through the execution role. The execution role controls AWS permissions. VPC-attached Lambda needs careful subnet, security group, NAT, and VPC endpoint design. Monitor errors, duration, throttles, concurrency, DLQs, and queue/stream lag.

---

## 3. API Gateway

**Amazon API Gateway** is a managed service for creating, publishing, securing, monitoring, and managing APIs. It is often used as the front door for Lambda functions, HTTP services, microservices, and serverless applications.

API Gateway can handle routing, authentication, authorization, throttling, CORS, custom domains, stages, deployments, access logs, metrics, and integration with backend services.

For DevOps/SRE, API Gateway matters because it often sits directly in the user request path. When users get 4xx, 5xx, latency, CORS, auth, or throttling issues, API Gateway is often part of the troubleshooting chain.

### API types and protocol types

API Gateway supports multiple API types:

1. **HTTP API**
2. **REST API**
3. **WebSocket API**

In API Gateway v2, protocol type is commonly:

* `HTTP`
* `WEBSOCKET`

### HTTP API

**HTTP API** is the newer, simpler, lower-cost API Gateway option for HTTP-based APIs. It is commonly used with Lambda proxy integrations or HTTP proxy integrations.

HTTP APIs are good for:

* Serverless APIs backed by Lambda
* HTTP proxy APIs to existing services
* JWT-authorized APIs
* Simple REST-style services
* Lower latency and lower cost compared with REST API in many cases

HTTP APIs support features such as:

* Routes
* Stages
* Auto deploy
* JWT authorizers
* Lambda authorizers
* CORS
* Access logs
* Custom domains
* Lambda integrations
* HTTP integrations
* Private integrations through VPC Link in supported designs

### REST API

**REST API** is the older, feature-rich API Gateway type. It may be used when you need capabilities that are not available or not equivalent in HTTP APIs.

REST APIs can support advanced features such as more detailed request/response transformation, usage plans, API keys, caching, request validation, and other mature API Gateway features.

HTTP API is often preferred for simpler, modern, lower-cost APIs; REST API is used when advanced features are needed.

### WebSocket API

**WebSocket API** supports persistent bidirectional communication between clients and backend services. It is used for chat systems, real-time dashboards, live notifications, multiplayer-style interactions, and streaming updates.

WebSocket APIs use routes such as:

* `$connect`
* `$disconnect`
* `$default`
* Custom message routes

### Routes

A **route** directs incoming API requests to a backend integration. In HTTP APIs, a route consists of:

* HTTP method
* Resource path

Examples:

```text
GET /users
GET /users/{id}
POST /users
PUT /users/{id}
PATCH /users/{id}
DELETE /users/{id}
```

The route is connected to an integration, such as a Lambda function or HTTP backend.

### GET, POST, PUT/PATCH, DELETE

Common REST-style method meanings:

* **GET**: retrieve data. Should not normally modify server state.
* **POST**: create a new resource or perform an action.
* **PUT**: replace or fully update a resource.
* **PATCH**: partially update a resource.
* **DELETE**: delete a resource.

Important correction: **UPDATE** is not normally an HTTP method in REST APIs. In API Gateway, updates are usually represented with `PUT` or `PATCH`. `UPDATE` is a SQL operation, not a standard HTTP method used for REST API routes.

### Route path parameters

Routes can include path parameters:

```text
GET /users/{userId}
DELETE /orders/{orderId}
```

The backend receives the parameter and uses it to process the request.

Routes can also use greedy path variables:

```text
ANY /{proxy+}
```

This catches multiple paths and is common in proxy-style APIs.

### ANY and $default routes

API Gateway can use `ANY` to match multiple HTTP methods for a path.

Example:

```text
ANY /proxy/{proxy+}
```

HTTP APIs can also have a `$default` route. The `$default` route catches requests that do not match any other route. This can be useful for simple proxy APIs but can also hide mistakes if you expected unmatched routes to fail clearly.

### Integrations

An **integration** connects a route to a backend.

Common integration types:

* Lambda integration
* HTTP integration
* AWS service integration
* Private integration through VPC Link

For example:

```text
GET /users  -> Lambda function ListUsers
POST /users -> Lambda function CreateUser
/api/*      -> Internal ALB through VPC Link
```

### API Gateway integration URL / integration URI

The phrase “API Gateway integration URL” usually means the backend endpoint or URI that API Gateway forwards requests to.

For **HTTP proxy integration**, the integration URI is typically a URL such as:

```text
https://internal-service.example.com/users
```

For **Lambda integration**, the integration URI is not a normal public URL. It references the Lambda function ARN/invocation path used by API Gateway.

For **private integrations**, the integration may point through a VPC Link to a private ALB/NLB or private service.

Common integration problems:

* Wrong backend URL.
* Backend expects a different path.
* TLS certificate mismatch to backend.
* API Gateway has no permission to invoke Lambda.
* VPC Link cannot reach the private load balancer.
* Security group or NACL blocks traffic.
* Lambda response format invalid.

### Lambda proxy integration

Lambda proxy integration is common with HTTP APIs. In this model, API Gateway sends request details to Lambda, and Lambda returns an HTTP-style response.

The event sent to Lambda usually includes method, path, headers, query strings, request context, and body.

The Lambda response usually includes:

```json
{
  "statusCode": 200,
  "headers": {
    "Content-Type": "application/json"
  },
  "body": "{\"message\":\"ok\"}"
}
```

If the response format is wrong, API Gateway may return a 502 Bad Gateway.

### Stages

A **stage** is a named reference to a lifecycle state or deployment of your API. Common stage names:

* `dev`
* `test`
* `staging`
* `prod`
* `$default`

For many API Gateway URLs, the stage name appears in the invoke URL:

```text
https://api-id.execute-api.region.amazonaws.com/prod/users
```

If using `$default` stage or custom domain mappings, the stage may not appear in the same obvious way.

Stages can have settings such as:

* Auto deploy
* Access logging
* Throttling
* Stage variables in REST APIs
* Default route settings

A common mistake is deploying an API to one stage but testing the URL for another stage.

### Auto deploy

**Auto deploy** means changes to the API are automatically deployed to a stage.

For development, auto deploy is convenient because route and integration changes become active quickly.

For production, some teams disable auto deploy and require explicit deployments through CI/CD. This gives better change control and reduces the risk of accidental console edits immediately affecting users.

If auto deploy is disabled and you change a route or integration, your change may not take effect until you create a deployment and associate it with the stage.

### Deployment concept

A **deployment** is a snapshot of API configuration made callable through a stage. In REST APIs, deployment management is very explicit. In HTTP APIs, auto deploy can make this feel more automatic, but the stage/deployment concept still matters operationally.

Troubleshooting question: “Did we deploy the route change to the stage that clients are using?”

### Custom domains

API Gateway default invoke URLs look like this:

```text
https://api-id.execute-api.region.amazonaws.com/stage
```

For production, you usually use a custom domain such as:

```text
https://api.example.com
```

Custom domains use ACM certificates and API mappings. A common issue is the custom domain points to the wrong stage or API mapping.

For regional API Gateway custom domains, use an ACM certificate in the same Region. For edge-optimized REST API custom domains, certificate requirements differ. For CloudFront in front of API Gateway, CloudFront viewer certificates must be in `us-east-1`.

### Authorization

API Gateway can protect APIs using several authorization methods:

* IAM authorization
* JWT authorizers
* Lambda authorizers
* Amazon Cognito user pools, depending on API type
* API keys and usage plans for certain REST/API management use cases

HTTP APIs commonly use JWT authorizers for OAuth/OIDC-style authentication.

Authorization failures usually show as 401 or 403 depending on the situation.

### CORS

**CORS**, or Cross-Origin Resource Sharing, controls whether browsers allow frontend code from one origin to call your API.

CORS is a browser security feature. An API can work perfectly in curl or Postman but fail in a browser if CORS is misconfigured.

Common CORS needs:

* Allow correct origin
* Allow methods such as GET, POST, PUT, PATCH, DELETE, OPTIONS
* Allow headers such as Authorization and Content-Type
* Handle preflight OPTIONS requests

CORS problems are often seen as browser console errors rather than backend logs.

### Throttling

API Gateway can throttle requests to protect backend services and enforce limits. Throttling may happen at account, stage, route, usage plan, or service quota levels depending on API type and configuration.

If clients exceed limits, they may receive 429 Too Many Requests.

For SRE, throttling is both a protection mechanism and a possible outage symptom. If legitimate traffic is throttled, check API Gateway metrics, quotas, route/stage settings, and backend scaling.

### Logging and monitoring

API Gateway integrates with CloudWatch metrics and logs.

Important metrics:

* Request count
* 4xx errors
* 5xx errors
* Latency
* Integration latency
* Throttles
* Authorizer errors

Access logs are extremely useful. Good access logs include:

* Request ID
* Source IP
* HTTP method
* Route key
* Path
* Status code
* Integration status
* Latency
* Integration latency
* Error message
* User agent

For Lambda integrations, correlate API Gateway request IDs with Lambda logs. For distributed systems, pass correlation IDs through headers.

### Common API Gateway status code meanings

* **400**: bad request, often malformed client input.
* **401**: unauthenticated or missing/invalid token.
* **403**: forbidden, auth policy/resource policy/IAM issue.
* **404**: no matching route or wrong path/stage.
* **429**: throttled.
* **500**: internal error.
* **502**: bad gateway, often Lambda response format issue, integration failure, or backend/TLS problem.
* **504**: integration timeout.

These are not absolute rules, but they are useful starting points.

### Common troubleshooting flow

For API Gateway problems, ask:

1. Is the client calling the correct URL, domain, stage, and path?
2. Does a matching route exist?
3. Was the route deployed to the stage?
4. Is auto deploy enabled or was a manual deployment done?
5. Is authorization configured correctly?
6. Is CORS required and configured correctly?
7. Is the integration connected to the correct backend?
8. Does API Gateway have permission to invoke Lambda?
9. Is the backend returning errors?
10. Are API Gateway logs enabled?
11. Are Lambda/backend logs showing the request?
12. Are there throttling, timeout, or quota issues?

### Common mistakes

* Creating a route but not deploying it
* Calling the wrong stage
* Using `UPDATE` instead of `PUT` or `PATCH`
* Forgetting Lambda invoke permission for API Gateway
* Lambda returns invalid proxy response format
* CORS missing OPTIONS/preflight configuration
* Custom domain mapped to wrong stage
* HTTP API chosen but needed a REST API-only feature
* Backend URL wrong in HTTP integration
* Private integration cannot reach internal load balancer
* Access logs disabled, making incidents harder to debug

### best practices

* Use infrastructure as code for APIs, routes, stages, integrations, and permissions
* Enable access logs in production
* Use structured log formats
* Monitor 4xx, 5xx, latency, integration latency, and throttling
* Use custom domains for stable production URLs
* Separate dev/stage/prod with stages or separate APIs/accounts
* Protect APIs with proper authorization
* Configure CORS intentionally, not with overly broad defaults unless acceptable
* Use throttling to protect backends
* Correlate API Gateway logs with Lambda/backend logs

API Gateway creates and manages APIs. HTTP APIs are simpler, faster, and often cheaper; REST APIs are more feature-rich; WebSocket APIs support bidirectional persistent connections. Routes map HTTP methods and paths to integrations. GET retrieves, POST creates, PUT/PATCH updates, and DELETE deletes. Stages represent deployed lifecycle environments. Auto deploy controls whether changes go live automatically. Integration URL/URI points to the backend for HTTP/private integrations or to Lambda invocation configuration for Lambda integrations. Most API Gateway problems involve routes, stages, deployment, permissions, CORS, custom domains, backend integration, or Lambda response format.

---

## Amazon CloudWatch Logs

**Amazon CloudWatch Logs** is AWS’s managed log collection, storage, search, and analysis service. It centralizes logs from AWS services, applications, containers, servers, and network/security sources. CloudWatch Logs is often where you go first when an application fails, a Lambda errors, an ECS task crashes, an API Gateway request returns 500, or an EC2-based service behaves unexpectedly.

CloudWatch Logs can receive logs from many sources, including:

* Lambda functions
* EC2 instances through the CloudWatch Agent
* ECS containers through the `awslogs` log driver or FireLens patterns
* EKS/Kubernetes logs through agents or Container Insights
* API Gateway access logs
* VPC Flow Logs
* Route 53 Resolver query logs
* CloudTrail logs
* AWS WAF logs
* Custom applications using SDKs or agents

Logs are different from metrics. **Logs explain what happened** in detail. **Metrics show numerical behavior over time**. Good observability usually needs both.

---

### Log event

A **log event** is one individual log record. It has a timestamp and message. For example:

```text
2026-05-05T12:00:00Z ERROR payment failed orderId=123 reason=timeout
```

Applications can write plain-text logs, but structured JSON logs are usually better for searching and analysis.

Example structured log:

```json
{
  "level": "ERROR",
  "service": "payment-api",
  "requestId": "abc-123",
  "orderId": "order-789",
  "message": "Payment provider timeout",
  "durationMs": 2300
}
```

Structured logs make CloudWatch Logs Insights queries much easier.

---

### Log stream

A **log stream** is a sequence of log events from the same source. The source could be:

* One Lambda execution environment
* One EC2 instance
* One ECS task/container
* One application process
* One log file source

For Lambda, AWS automatically creates log streams inside the Lambda log group. For EC2, the CloudWatch Agent can create log streams based on instance ID, hostname, log file, or custom configuration.

---

### Log group

A **log group** is a container for related log streams. Log groups are one of the most important CloudWatch Logs concepts.

Examples:

```text
/aws/lambda/payment-function
/aws/ecs/order-service
/aws/apigateway/prod-access-logs
/var/log/messages
/company/prod/payment-api
```

A log group controls shared settings such as:

* Retention period
* KMS encryption key
* Log class
* Subscription filters
* Metric filters
* Resource policy/access control
* Tags

A good naming convention helps a lot. For example:

```text
/company/environment/service/component
/company/prod/payment-api/app
/company/prod/payment-api/nginx
/company/dev/order-worker/app
```

---

### Log retention

**Log retention** controls how long CloudWatch Logs keeps log events in a log group. If no retention period is configured, logs may be kept indefinitely. This can cause unnecessary cost and compliance risk.

Typical retention examples:

* Dev/test application logs: 3–14 days
* Production application logs: 30–90 days
* Security/audit logs: 180 days, 1 year, or longer depending on compliance
* Temporary debug logs: 1–7 days
* Long-term archive: export to S3 or central SIEM/storage

log retention is a basic hygiene item. Every production log group should have a deliberate retention setting. “Never expire” should be intentional, not accidental.

Common mistake: Lambda automatically creates log groups when first invoked, but no retention is set unless you configure it through IaC or automation. This leads to thousands of log groups retaining logs forever.

---

### Log classes

CloudWatch Logs supports different log classes for different usage patterns.

The most important ones are:

* **Standard log class**: full-featured option for logs that need real-time monitoring, metric filters, subscription filters, Live Tail, and frequent access.
* **Infrequent Access log class**: lower-cost ingestion option for logs that are accessed less often and mainly used for later investigation or forensic analysis. It supports a subset of Standard features.
* **Delivery log class**: specialized delivery class used for certain Lambda log delivery use cases to S3 or Firehose, with limited CloudWatch Logs capabilities.

Important operational point: choose the log class carefully when creating the log group. Some capabilities differ between classes, and log class behavior can affect what features are available.

For most active application logs, use Standard. For large low-touch logs mainly kept for occasional investigation, Infrequent Access may reduce cost.

---

### CloudWatch Logs Insights

**CloudWatch Logs Insights** is the query engine for searching and analyzing logs. It lets you run queries across one or more log groups.

Common use cases:

* Find errors by service and time range.
* Count exceptions by type.
* Find slow requests.
* Search by request ID or trace ID.
* Group logs by status code.
* Build temporary incident investigation queries.

Example queries:

Find recent errors:

```sql
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 50
```

Count errors by message:

```sql
fields @timestamp, level, message
| filter level = "ERROR"
| stats count(*) as errorCount by message
| sort errorCount desc
```

Find slow API requests:

```sql
fields @timestamp, path, statusCode, durationMs
| filter durationMs > 1000
| sort durationMs desc
| limit 100
```

Logs Insights charges are based on data scanned, so narrow the time range and log groups before running broad queries.

---

### Metric filters

A **metric filter** searches incoming log events for a pattern and turns matching logs into CloudWatch metrics. You can then graph those metrics or create alarms from them.

Example use cases:

* Count `ERROR` log lines.
* Count failed login attempts.
* Count payment failures.
* Count application panic/crash messages.
* Extract latency or status code from logs.

Example concept:

```text
If log event contains "ERROR", increment Custom/AppErrors metric by 1
```

Metric filters are useful when the application does not directly publish a metric, but the information exists in logs.

Important caution: metric filters only apply to log events as they are ingested after the filter is created. They are not a retroactive query over old logs.

---

### Subscription filters

A **subscription filter** sends log events from a log group to another destination in near real time.

Common destinations:

* Lambda
* Kinesis Data Streams
* Amazon Data Firehose
* OpenSearch ingestion pipeline patterns
* Third-party SIEM/logging systems through streaming architecture

Use cases:

* Send security logs to a SIEM.
* Send application logs to OpenSearch or Splunk.
* Transform logs before storage.
* Real-time alert enrichment.
* Centralize logs from many accounts.

A log group can have a limited number of subscription filters, so design central logging carefully.

---

### Live Tail

**Live Tail** lets you view logs in near real time as they are ingested. It is useful during deployments, incident debugging, and testing new services.

Use cases:

* Watch Lambda logs during a test invocation.
* Observe ECS logs after a new deployment.
* Confirm an application is receiving traffic.
* Debug a short-lived problem interactively.

Live Tail is helpful, but it should not replace proper dashboards, alarms, and persistent log queries.

---

### CloudWatch Agent for EC2 and on-prem servers

EC2 does not automatically send application or OS logs to CloudWatch Logs. You usually need the **CloudWatch Agent**.

The CloudWatch Agent can collect:

* Log files such as `/var/log/messages`, `/var/log/syslog`, application logs, Nginx/Apache logs
* Custom metrics such as memory, disk, swap, process, and collectd/statsd metrics
* Metrics from on-prem servers if configured

Common EC2 log ingestion flow:

```text
Application writes /var/log/myapp/app.log
CloudWatch Agent tails that file
Agent sends log events to CloudWatch Logs log group/log stream
```

The EC2 instance role needs permissions to put logs and metrics into CloudWatch.

---

### Lambda logs

Lambda automatically sends logs to CloudWatch Logs if the execution role has the right permissions. The default log group is usually:

```text
/aws/lambda/<function-name>
```

Lambda logs include system-generated START, END, and REPORT lines. The REPORT line shows useful performance information such as duration, billed duration, memory size, and max memory used.

Common Lambda logging issues:

* Execution role lacks `logs:CreateLogGroup`, `logs:CreateLogStream`, or `logs:PutLogEvents`.
* Looking in the wrong Region.
* Function is not actually invoked.
* Log retention was never configured.
* Too much debug logging increases cost.
* Sensitive data is accidentally logged.

---

### Log encryption and KMS

CloudWatch Logs encrypts log data at rest. You can associate a customer-managed KMS key with a log group for more control.

If using a customer-managed KMS key, make sure the CloudWatch Logs service and the required IAM principals have permission to use the key. KMS policy mistakes can cause logging or reading failures.

For sensitive logs, also consider:

* Access control on log groups
* Data protection/masking
* Least-privilege IAM permissions
* Restricting who can run queries
* Centralized security account storage
* Exporting long-term logs to S3 with lifecycle and object lock if needed

---

### Sensitive data protection

Logs can accidentally contain passwords, tokens, API keys, session cookies, authorization headers, account numbers, or personal data.

Good practices:

* Never log secrets.
* Redact authorization headers.
* Use structured logging with explicit safe fields.
* Apply CloudWatch Logs data protection policies where appropriate.
* Limit access to sensitive log groups.
* Review debug logs before enabling them in production.

In interviews, mention that logging is part of security. Observability should not leak secrets.

---

### Log exports and long-term storage

CloudWatch Logs can be used for active searching and investigation, but S3 is often better for long-term archival because of lifecycle policies, storage classes, and lower long-term storage cost.

Common patterns:

* CloudWatch Logs for active operational troubleshooting.
* Subscription filters or exports to S3/OpenSearch/SIEM for long-term analysis.
* S3 lifecycle policies to transition logs to cheaper storage.
* Athena over S3 logs for ad hoc historical queries.

For compliance, make sure log retention, immutability, and access control match company policy.

---

### CloudWatch Logs cost drivers

CloudWatch Logs cost is usually driven by:

* Log ingestion volume
* Log storage volume
* Logs Insights query data scanned
* Subscription/delivery pipeline costs
* Vended logs from services such as VPC Flow Logs, WAF, CloudFront, etc.

Ways to reduce cost:

* Set retention periods.
* Avoid excessive debug logging.
* Use structured logs but avoid huge payloads.
* Do not log full request/response bodies unless necessary.
* Use sampling for noisy logs.
* Use Infrequent Access where appropriate.
* Export/archive older logs to S3.
* Narrow Logs Insights query time ranges.

---

### CloudWatch Logs troubleshooting checklist

When expected logs are missing:

1. Are you checking the correct AWS account and Region?
2. Does the log group exist?
3. Is the service configured to send logs?
4. Does the IAM role have permission to create streams and put log events?
5. For EC2, is the CloudWatch Agent installed and running?
6. Is the agent config pointing to the correct log file?
7. Does the OS user running the agent have permission to read the log file?
8. Is the application actually writing logs?
9. Is there a KMS key policy issue?
10. Is retention deleting logs earlier than expected?
11. Are subscription filters failing to deliver to downstream systems?
12. Are you searching the correct time range?


CloudWatch Logs centralizes logs from AWS services, applications, EC2, containers, Lambda, API Gateway, VPC Flow Logs, and more. Logs are organized into log groups and log streams. Set retention on every log group. Use Logs Insights for search, metric filters to create metrics from logs, and subscription filters to stream logs to other systems. For EC2, install the CloudWatch Agent. For Lambda, make sure the execution role can write logs. Watch cost, sensitive data, IAM, KMS, and retention.

---

## Amazon CloudWatch Metrics

**CloudWatch Metrics** stores numerical time-series data about AWS services, infrastructure, and applications. Metrics are the foundation for dashboards, alarms, autoscaling, anomaly detection, and health monitoring.

If logs answer “what happened?”, metrics answer “how much, how often, how slow, how many, and how bad?”

Examples:

* CPU utilization over time
* Number of HTTP 5xx errors
* ALB latency p95
* SQS queue depth
* Lambda error count
* RDS free storage
* EBS disk throughput
* Custom application checkout failure rate

---

### Metric structure

A CloudWatch metric is identified by several parts:

* **Namespace**
* **Metric name**
* **Dimensions**
* **Timestamp**
* **Value**
* **Unit**
* **Resolution**

Example:

```text
Namespace: AWS/EC2
MetricName: CPUUtilization
Dimension: InstanceId=i-1234567890abcdef
Unit: Percent
Value: 72.5
```

---

### Namespace

A **namespace** is a container for metrics. AWS services publish metrics into AWS namespaces.

Examples:

```text
AWS/EC2
AWS/RDS
AWS/Lambda
AWS/ApplicationELB
AWS/SQS
AWS/EBS
AWS/DynamoDB
```

Custom applications can publish metrics into custom namespaces, such as:

```text
Company/PaymentService
Custom/MyApp
```

Use clear namespaces for custom metrics. Avoid dumping unrelated metrics into one generic namespace.

---

### Metric name

The **metric name** identifies what is being measured.

Examples:

* `CPUUtilization`
* `Errors`
* `Duration`
* `RequestCount`
* `TargetResponseTime`
* `ApproximateAgeOfOldestMessage`
* `FreeStorageSpace`

Metric names alone are not always enough. Dimensions determine which resource or slice of the metric you are looking at.

---

### Dimensions

**Dimensions** are key-value pairs that identify what the metric applies to.

Examples:

```text
InstanceId=i-abc123
FunctionName=my-lambda
LoadBalancer=app/prod-alb/123
TargetGroup=targetgroup/api/456
DBInstanceIdentifier=prod-db
QueueName=prod-orders
```

CloudWatch treats each unique combination of namespace, metric name, and dimensions as a separate metric.

This is very important for cost and usability. High-cardinality dimensions can create many unique metrics. For example, a custom metric with `UserId` or `RequestId` as a dimension can create huge metric counts and high cost.

Good dimensions:

* Service name
* Environment
* Availability Zone
* Instance ID
* Function name
* Queue name
* Target group
* Operation name

Bad dimensions for CloudWatch custom metrics:

* Request ID
* Session ID
* User ID
* Random unique IDs
* Unbounded labels

---

### Statistics

CloudWatch stores metric data points and lets you view statistics over a period.

Common statistics:

* **Average**
* **Minimum**
* **Maximum**
* **Sum**
* **SampleCount**
* Percentiles such as p50, p90, p95, p99, where supported

Choosing the right statistic matters.

Examples:

* CPU utilization: Average may be useful.
* Error count: Sum is usually better.
* Latency: p95 or p99 is usually better than Average.
* Queue depth: Maximum or Average may both be useful depending on context.
* Healthy host count: Minimum may be important.

Averages can hide user pain. If 99 users are fast and 1 user is very slow, average latency may look fine while p99 shows the problem.

---

### Period

The **period** is the length of time over which CloudWatch aggregates metric data. Common periods are:

* 1 minute
* 5 minutes
* 1 hour

For high-resolution custom metrics, shorter periods such as 1 second, 10 seconds, or 30 seconds may be used depending on configuration and alarm type.

Shorter periods detect issues faster but may create more noise and cost. Longer periods reduce noise but detect issues more slowly.

---

### Resolution and retention

CloudWatch metrics have different retention levels depending on resolution/period:

* High-resolution data points under 60 seconds are kept for a short high-resolution window.
* 1-minute data is kept for days, then aggregated.
* 5-minute data is kept longer.
* 1-hour data is kept the longest, up to long-term historical retention.

The practical point: as metrics get older, CloudWatch stores them at coarser resolution. You can still see long-term trends, but not always fine-grained minute-by-minute details far in the past.

---

### AWS service metrics

Many AWS services publish metrics automatically.

Common examples:

#### EC2

* `CPUUtilization`
* `NetworkIn`
* `NetworkOut`
* `DiskReadOps`
* `DiskWriteOps`
* `StatusCheckFailed`

Important: EC2 memory and disk filesystem usage are not default EC2 metrics. Use the CloudWatch Agent or another monitoring agent to collect memory, disk, swap, and process-level metrics.

#### ALB

* `RequestCount`
* `TargetResponseTime`
* `HTTPCode_Target_5XX_Count`
* `HTTPCode_ELB_5XX_Count`
* `HealthyHostCount`
* `UnHealthyHostCount`

Distinguish target errors from load balancer errors. Target 5xx usually comes from the backend application. ELB 5xx can mean the load balancer could not connect to targets or had its own forwarding issue.

#### Lambda

* `Invocations`
* `Errors`
* `Duration`
* `Throttles`
* `ConcurrentExecutions`
* `IteratorAge` for stream/event source use cases

For Lambda, duration near timeout and throttles are very important operational signals.

#### SQS

* `ApproximateNumberOfMessagesVisible`
* `ApproximateNumberOfMessagesNotVisible`
* `ApproximateAgeOfOldestMessage`
* `NumberOfMessagesSent`
* `NumberOfMessagesDeleted`

For SQS, oldest message age is often more important than queue depth because it shows whether work is getting stuck.

#### RDS

* `CPUUtilization`
* `FreeableMemory`
* `FreeStorageSpace`
* `DatabaseConnections`
* `ReadIOPS`
* `WriteIOPS`
* `ReadLatency`
* `WriteLatency`
* Replica lag metrics where applicable

For RDS, storage, connections, memory, and latency are frequent incident signals.

#### EBS

* `VolumeReadOps`
* `VolumeWriteOps`
* `VolumeReadBytes`
* `VolumeWriteBytes`
* `VolumeQueueLength`
* `BurstBalance`

For EBS, volume type, queue length, throughput, IOPS, and instance EBS limits matter together.

---

### Custom metrics

**Custom metrics** are metrics your application or scripts publish to CloudWatch.

Examples:

* Number of successful checkouts
* Payment provider errors
* Job processing duration
* Cache hit rate
* Business transaction count
* API dependency failure count
* Worker backlog by job type

You can publish custom metrics using:

* AWS SDK / `PutMetricData`
* CloudWatch Agent
* Embedded Metric Format in logs
* OpenTelemetry-based integrations
* StatsD/collectd through the CloudWatch Agent

Custom metrics are powerful because AWS default metrics do not know your business logic. For example, CloudWatch can show that Lambda errors increased, but a custom metric can show that “payment authorizations failed” increased.

Cost warning: each unique metric/dimension combination can count as a separate custom metric. Avoid high-cardinality dimensions.

---

### Embedded Metric Format

**Embedded Metric Format**, or EMF, lets applications write structured JSON logs that CloudWatch can automatically extract into metrics.

This is useful because the application emits one structured log event, and CloudWatch can turn selected fields into metrics.

Use cases:

* Lambda application metrics
* Containerized service metrics
* Business metrics from app logs
* Request latency and status metrics

EMF is convenient, but still be careful with dimensions. Do not put request IDs or user IDs as metric dimensions.

---

### Detailed monitoring

Some AWS services support more detailed metric collection. For EC2, basic monitoring publishes metrics at a lower frequency, while detailed monitoring provides more frequent metrics.

Detailed monitoring is useful when you need faster detection or more granular scaling decisions, but it can increase cost.

For SRE, choose detail level based on operational need. A production Auto Scaling Group may benefit from more frequent metrics; a low-priority dev instance probably does not.

---

### Metric math

**Metric math** lets you calculate new time series from existing metrics.

Examples:

* Error rate = 5xx errors / request count * 100
* Free storage percentage = free bytes / allocated bytes * 100
* Backlog per worker = queue depth / running workers
* Availability = successful requests / total requests

Metric math is useful because raw counts are often less meaningful than ratios.

Example: 100 errors may be terrible if you had 500 requests, but not as severe if you had 50 million requests. Error rate gives better context.

---

### Metrics Insights

**CloudWatch Metrics Insights** lets you query metrics using SQL-like syntax. It is useful for exploring metrics across many resources.

Examples of use cases:

* Find top EC2 instances by CPU.
* Group Lambda errors by function.
* Aggregate metrics across an Auto Scaling Group or service.
* Explore fleet-wide behavior without manually selecting every metric.

Metrics Insights is especially helpful in accounts with many resources.

---

### Dashboards

CloudWatch dashboards display metrics, logs query widgets, alarms, and text widgets. Dashboards are useful for service health, incident response, and executive/operational visibility.

Good SRE dashboard design often follows the golden signals:

* **Latency**: how long requests take
* **Traffic**: how much demand exists
* **Errors**: how many requests fail
* **Saturation**: how full/overloaded the system is

For AWS infrastructure, also include:

* Load balancer 5xx and latency
* Target health
* CPU/memory/disk/network
* Queue depth and age
* Database connections/storage/latency
* Lambda errors/duration/throttles
* Deployment markers if available

A dashboard should help answer: “Is the service healthy, and where is the problem?”

---

### Metrics cost drivers

CloudWatch Metrics cost can come from:

* Custom metrics
* High-resolution custom metrics
* Detailed monitoring
* API requests for metric retrieval
* Dashboards
* Metric streams
* Container Insights/enhanced observability
* Alarms on metrics

Ways to reduce cost:

* Avoid high-cardinality dimensions.
* Do not publish unnecessary custom metrics.
* Use logs for highly detailed per-request data, not metrics.
* Use dimensions intentionally.
* Review unused custom metrics and dashboards.
* Use appropriate resolution.

---

### Metrics troubleshooting checklist

When a metric is missing or wrong:

1. Are you checking the correct account and Region?
2. Is the namespace correct?
3. Are the metric name and dimensions exactly correct?
4. Is the service configured to publish the metric?
5. For EC2 memory/disk, is the CloudWatch Agent installed and configured?
6. For custom metrics, is `PutMetricData` succeeding?
7. Are IAM permissions allowing metric publishing?
8. Are you using the correct period and statistic?
9. Is the metric sparse and missing data points when value is zero?
10. Is the time range too old for the selected resolution?
11. Are units mismatched?
12. Did the resource stop publishing metrics after deletion or inactivity?


CloudWatch Metrics stores time-series data. Metrics are organized by namespace, metric name, and dimensions. AWS services publish many metrics automatically, and applications can publish custom metrics. Use the right statistic: Sum for counts, p95/p99 for latency, Average only when it makes sense. EC2 memory and filesystem disk usage require the CloudWatch Agent. Avoid high-cardinality custom metric dimensions. Use metrics for dashboards, alarms, autoscaling, SLOs, and health monitoring.

---

## 3. CloudWatch Alarms / Alerts

AWS usually calls them **CloudWatch alarms**, while many teams casually call them **alerts**. A CloudWatch alarm watches a metric or expression and changes state when a defined condition is met. The alarm can then notify people, trigger automation, or drive scaling actions.

CloudWatch alarms are the bridge between metrics and action.

Example:

```text
If ALB Target 5xx error rate > 5% for 5 minutes, send alert to on-call team.
```

---

### Alarm states

A CloudWatch alarm has three main states:

* **OK**: the metric is within the expected threshold.
* **ALARM**: the metric is breaching the threshold.
* **INSUFFICIENT_DATA**: CloudWatch does not have enough data to determine OK or ALARM.

`INSUFFICIENT_DATA` is not always bad. It may happen when a new alarm is created, a metric is sparse, a resource stops publishing metrics, or the selected dimensions are wrong.

For sparse metrics such as “number of errors,” missing data may mean zero errors. For heartbeat metrics, missing data may mean a serious problem. This is why missing data configuration matters.

---

### Basic alarm configuration

A metric alarm usually includes:

* Metric namespace/name/dimensions
* Statistic, such as Average, Sum, Maximum, p95
* Period
* Evaluation periods
* Datapoints to alarm
* Threshold
* Comparison operator
* Missing data behavior
* Alarm actions
* OK actions
* Insufficient data actions

Example:

```text
Metric: AWS/ApplicationELB HTTPCode_Target_5XX_Count
Statistic: Sum
Period: 60 seconds
Evaluation periods: 5
Datapoints to alarm: 3
Threshold: > 10
Meaning: alarm if 3 out of the last 5 one-minute periods had more than 10 target 5xx errors
```

This is called an **M out of N** alarm pattern.

---

### Evaluation periods and datapoints to alarm

**Evaluation periods** define how many recent periods CloudWatch checks.

**Datapoints to alarm** defines how many of those periods must be breaching.

Example:

```text
Evaluation periods = 5
Datapoints to alarm = 3
```

This means 3 of the last 5 datapoints must breach. They do not necessarily have to be consecutive.

This is useful because it avoids alerting on one tiny spike while still detecting sustained problems.

---

### Period

The **period** is the length of each datapoint window.

Example:

* 60-second period detects issues faster.
* 5-minute period smooths noise.
* 10-second or 30-second high-resolution alarms can detect faster, but can cost more and be noisier.

Choose period based on the urgency and nature of the signal.

For a user-facing API, 1-minute periods may be appropriate. For disk usage, 5-minute or 15-minute periods may be enough. For a batch job, a longer period may make more sense.

---

### Treat missing data

CloudWatch lets you configure how missing data should be treated.

Common options conceptually:

* Treat missing data as breaching.
* Treat missing data as not breaching.
* Ignore/maintain previous state.
* Treat as missing/insufficient data.

Choosing the wrong setting can create false positives or missed incidents.

Examples:

* Error count metric: if no errors are emitted, missing may be okay and can be treated as not breaching.
* Heartbeat metric: missing means the system may be dead, so missing should be breaching.
* CPU metric from stopped EC2: missing may be expected if instance is intentionally stopped.

Always think about what “no data” means for that metric.

---

### Alarm actions

An alarm can perform actions when it enters ALARM, OK, or INSUFFICIENT_DATA states.

Common actions:

* Send notification to SNS topic
* Trigger Auto Scaling policy
* Perform EC2 actions such as stop, terminate, reboot, or recover in supported scenarios
* Create Systems Manager OpsItem
* Start incident response workflow depending on integration
* Trigger EventBridge-based automation

Most human alerting flows use SNS or an integration connected to SNS, such as email, Slack, PagerDuty, Opsgenie, ServiceNow, or another incident system.

CloudWatch alarm by itself is not the same as a full alerting process. A production alert needs routing, severity, ownership, runbook, escalation, and noise control.

---

### SNS notifications

A common alerting pattern is:

```text
CloudWatch Alarm -> SNS Topic -> Email / ChatOps / PagerDuty / Lambda / Incident tool
```

SNS is useful because multiple subscribers can receive the same alarm notification. For example:

* Email team distribution list
* Lambda enrichment function
* Incident management tool webhook
* ChatOps notification

Make sure the SNS topic policy allows CloudWatch to publish and subscribers are confirmed where required.

---

### Metric math alarms

CloudWatch alarms can be based on metric math expressions.

This is very useful for alerting on ratios and derived signals.

Examples:

```text
Error rate = 5xx count / request count * 100
```

```text
Backlog per worker = SQS visible messages / number of running consumers
```

```text
Free disk percent = free disk bytes / total disk bytes * 100
```

Metric math helps avoid bad alerts based only on raw numbers.

Example: Alerting on “100 errors” may be bad because 100 errors means different things at different traffic levels. Alerting on “error rate > 5%” is often better.

---

### Composite alarms

A **composite alarm** combines the state of multiple alarms using Boolean logic. It does not directly watch a metric; it watches other alarms.

Example:

```text
ALARM if:
  API 5xx alarm is ALARM
  AND
  high latency alarm is ALARM
```

Composite alarms are useful for reducing noise. Instead of paging on every low-level symptom, you can page only when multiple related symptoms indicate real user impact.

Use cases:

* Combine error rate and latency.
* Alert only if both regional health and service health are bad.
* Suppress noisy dependency alerts unless the main service is affected.
* Create a high-level service health alarm from several component alarms.

Be careful not to create circular dependencies between composite alarms.

---

### Anomaly detection alarms

CloudWatch anomaly detection can learn normal patterns for a metric and alarm when the metric goes outside the expected band.

Use cases:

* Traffic patterns with daily/weekly seasonality
* Request count anomalies
* Cost/usage anomalies at metric level
* Latency or error behavior that changes based on normal traffic cycles

Anomaly detection is useful when a static threshold is hard to choose. However, it still needs tuning and review. It is not a replacement for understanding the service.

---

### High-resolution alarms

High-resolution alarms can evaluate high-resolution custom metrics at shorter periods such as 10 or 30 seconds.

Use cases:

* Very latency-sensitive systems
* Fast incident detection
* Short-lived high-impact failures

Tradeoffs:

* Higher cost
* More noise if thresholds are not tuned
* Requires high-resolution custom metrics

For most infrastructure alarms, 1-minute or 5-minute periods are enough. Use high-resolution alarms when the business need justifies them.

---

### Static threshold vs dynamic threshold

A **static threshold** is a fixed number, such as CPU > 80%.

A **dynamic threshold** uses anomaly detection or other logic to compare behavior against expected patterns.

Static thresholds are simple and good for known hard limits, such as:

* Disk free space < 10%
* HealthyHostCount < 2
* SQS oldest message age > 5 minutes

Dynamic thresholds are useful for seasonal or variable signals, such as:

* Request count much lower than normal
* Latency unusually high for this hour/day
* Error count outside expected pattern

---

### Good alert design

A good alert should be:

* Actionable
* Owned by a team
* Tied to user or system impact
* Clear about severity
* Linked to a runbook
* Tuned to avoid unnecessary noise
* Tested

Bad alert:

```text
CPU high
```

Better alert:

```text
Payment API ALB target 5xx rate > 5% for 5 minutes. Check deployment, target health, Lambda/RDS dependency, and recent CloudTrail changes.
```

Best alerts tell the on-call engineer what is broken, why it matters, and where to start.

---

### Common useful AWS alarms

#### ALB / application

* Target 5xx error rate
* ELB 5xx count
* Target response time p95/p99
* Healthy host count below expected
* Target connection errors

#### EC2 / ASG

* EC2 status check failed
* ASG capacity below desired
* High CPU sustained
* High memory usage from CloudWatch Agent
* Disk usage high from CloudWatch Agent
* Instance recovery alarm for supported EC2 cases

#### Lambda

* Error rate
* Duration near timeout
* Throttles
* Concurrent executions near limit
* DLQ or destination failures
* Iterator age for streams

#### SQS

* Approximate age of oldest message
* Visible message count
* DLQ message count
* Messages not visible stuck too long

#### RDS

* Free storage low
* CPU high sustained
* Freeable memory low
* Database connections high
* Read/write latency high
* Replica lag high
* Failover event notifications

#### EBS

* Volume queue length high
* Burst balance low
* IOPS/throughput saturation

#### Networking

* NAT gateway errors or abnormal traffic
* VPN tunnel down
* Direct Connect BGP down
* VPC endpoint errors where monitored

---

### Alert severity

Not every alarm should page someone at 2 AM.

Example severity model:

* **Critical / P1**: user-facing outage, data loss risk, security incident, production down.
* **High / P2**: degraded production service, high error rate, failover risk.
* **Medium / P3**: capacity warning, non-critical dependency issue, one redundant tunnel down.
* **Low / P4**: cleanup task, cost optimization, non-urgent warning.

A single VPN tunnel down might be P3 because redundancy is lost. Both VPN tunnels down might be P1/P2 depending on business impact.

---

### Reducing alert noise

Alert fatigue is dangerous. Too many noisy alarms train engineers to ignore alerts.

Ways to reduce noise:

* Use M out of N evaluation.
* Use composite alarms.
* Alert on rates/ratios, not only raw counts.
* Add deployment-aware suppression where appropriate.
* Tune thresholds based on historical behavior.
* Use anomaly detection for seasonal metrics.
* Route warnings to tickets instead of paging.
* Delete or fix alarms that no one acts on.
* Add runbooks and ownership.

Every alert should answer: “What should the responder do?”

---

### Alert troubleshooting checklist

When an alarm triggers:

1. What metric and dimensions triggered?
2. What statistic and period are used?
3. How many datapoints breached?
4. Is missing data involved?
5. Is the alarm tied to real user impact?
6. Did a deployment or infrastructure change happen recently?
7. Are related metrics also abnormal?
8. Are logs showing errors for the same time window?
9. Is this a known noisy alarm?
10. Is the threshold still appropriate?
11. Should the alarm page, create a ticket, or just notify chat?
12. Is there a runbook?


CloudWatch alarms evaluate metrics or metric math expressions and move between OK, ALARM, and INSUFFICIENT_DATA. Important settings include statistic, period, evaluation periods, datapoints to alarm, threshold, comparison operator, and missing data behavior. Alarm actions often notify SNS, trigger scaling, or start automation. Good alerts are actionable and tied to impact. Use metric math, M out of N evaluation, composite alarms, and anomaly detection to reduce noise and improve signal quality.

---

## SQS  Simple Queue Service

**Amazon SQS**, or Simple Queue Service, is a managed message queue. It decouples producers and consumers so services do not have to call each other directly in real time. A producer sends a message to a queue, and one or more consumers process messages asynchronously.

SQS is useful for buffering traffic, smoothing spikes, retrying work, isolating failures, and building event-driven or worker-based systems. Example: an API receives upload requests and sends processing jobs to SQS. Worker instances, ECS tasks, Kubernetes workers, or Lambda functions consume the queue at their own pace.

SQS is not a pub/sub service by itself. A message in one SQS queue is normally processed by one consumer, then deleted. If many different systems all need their own copy of the same event, use SNS fanout to multiple SQS queues, EventBridge routing, or another event distribution pattern.

### Queue types

SQS has two main queue types:

* **Standard queue**: very high throughput, at-least-once delivery, and best-effort ordering.
* **FIFO queue**: first-in-first-out ordering and exactly-once processing behavior in supported conditions, but with additional requirements around message group IDs and deduplication.

Standard queues are the default choice for most background work because they scale well and are simple. They can deliver a message more than once, and messages can occasionally arrive out of order. Consumers must be **idempotent**, meaning processing the same message more than once should not corrupt data or create duplicate side effects.

FIFO queues are used when order matters, such as payment steps, inventory updates, account events, or workflows where operations must be processed in sequence. FIFO ordering is based on **message group ID**. Messages with the same message group ID are processed in order. Different message groups can be processed in parallel.

FIFO queues also use deduplication:

* **MessageDeduplicationId**: an explicit ID used to detect duplicate sends.
* **Content-based deduplication**: SQS hashes the message body to generate a deduplication ID.

Deduplication is useful when producers retry `SendMessage` after network timeouts. The important idea is that FIFO helps prevent duplicate messages being introduced into the queue, but your application should still be designed carefully because downstream side effects can still be retried or duplicated outside SQS.

### Producer and consumer flow

A typical SQS flow looks like this:

1. Producer sends a message to the queue.
2. SQS stores the message until it is received, deleted, or expires.
3. Consumer calls `ReceiveMessage`.
4. SQS returns a message and makes it invisible for the visibility timeout.
5. Consumer processes the message.
6. Consumer calls `DeleteMessage` using the receipt handle.
7. If the consumer does not delete the message before the visibility timeout expires, the message becomes visible again and can be retried.

Receiving a message does not remove it from the queue. Deleting the message after successful processing is what completes the work.

### Important SQS concepts

Important settings and concepts:

* **Visibility timeout**: after a consumer receives a message, the message is hidden from other consumers for a period.
* **Message retention**: how long SQS keeps messages that are not deleted. The default is 4 days, and the maximum is 14 days.
* **Delay queue**: delays availability of all new messages sent to the queue.
* **Message timer**: delays availability of an individual message.
* **Dead-letter queue**: stores messages that fail processing too many times.
* **Redrive policy**: controls when messages move to a DLQ, usually using `maxReceiveCount`.
* **Redrive allow policy**: controls which source queues can use a queue as a DLQ.
* **Long polling**: waits for messages before returning, reducing empty responses and API cost.
* **Short polling**: returns immediately and may sample only part of the SQS fleet.
* **In-flight message**: a message that has been received but not yet deleted.
* **Message attributes**: metadata sent with the message, useful for filtering, tracing, routing, or consumer behavior.

SQS message bodies can be up to 1 MiB. For larger payloads, a common pattern is to store the large object in S3 and send an SQS message containing the S3 bucket/key and metadata. AWS also provides extended client libraries for this pattern.

### Visibility timeout

The **visibility timeout** is one of the most important SQS concepts. When a consumer receives a message, the message remains in the queue but becomes temporarily invisible to other consumers. If processing succeeds, the consumer deletes the message. If the consumer crashes, times out, or fails to delete the message, the message becomes visible again and another consumer can receive it.

The visibility timeout should be longer than normal processing time. If it is too short, two consumers may process the same message. If it is too long, failed messages take longer to retry.

Common visibility timeout patterns:

* Set the queue visibility timeout to a safe default for normal processing.
* Use `ChangeMessageVisibility` to extend the timeout for long-running jobs.
* Use a heartbeat pattern where workers periodically extend visibility while work is still active.
* Set visibility to `0` if a worker wants to give up immediately and let another consumer retry.
* Move repeatedly failing messages to a DLQ instead of retrying forever.

The default visibility timeout is often 30 seconds, and the maximum is 12 hours from when the message is received. If a job can take longer than that, consider breaking it into smaller steps or using Step Functions.

### Dead-letter queues and retries

A **dead-letter queue**, or DLQ, stores messages that could not be processed successfully after repeated attempts. The source queue's redrive policy controls when messages move to the DLQ.

The key setting is usually:

* `maxReceiveCount`: how many times a message can be received before SQS moves it to the DLQ.

Example: if `maxReceiveCount = 5`, and the consumer receives but fails to delete the same message five times, SQS moves that message to the DLQ.

DLQs are useful because they:

* Prevent poison messages from blocking or wasting consumer capacity.
* Preserve failed messages for debugging.
* Let teams inspect payloads, error patterns, and affected customers.
* Support manual or automated redrive back to the source queue after a fix.

Do not treat a DLQ as a permanent archive. Monitor it, alert on it, and have an operational process for inspecting, fixing, redriving, or discarding messages.

### Long polling

**Long polling** lets a `ReceiveMessage` request wait for messages to arrive instead of returning immediately. This reduces empty responses, lowers API cost, and usually improves consumer efficiency.

Long polling is usually enabled with `ReceiveMessageWaitTimeSeconds` on the queue or `WaitTimeSeconds` on the receive request. The maximum wait time is 20 seconds.

In most real systems, long polling is better than tight short-poll loops. Short polling can waste API calls and return empty responses even when messages exist.

### Lambda and SQS

SQS is commonly used as a Lambda event source. Lambda polls the queue, invokes the function with batches of messages, and deletes messages after successful processing. This pattern is very useful for serverless background work.

Important Lambda plus SQS details:

* The Lambda timeout should be shorter than the SQS visibility timeout.
* Batch size affects throughput, cost, and retry blast radius.
* If the function fails the whole batch, messages can become visible again and retry.
* Partial batch response can report only failed messages so successful messages do not need to be retried.
* Configure a DLQ or source queue redrive policy for poison messages.
* Watch concurrency so the queue does not overwhelm downstream systems.

For FIFO queues with Lambda, message group IDs affect concurrency because Lambda must preserve ordering within each group.

### Ordering, duplication, and idempotency

SQS consumers should usually be idempotent. Even with FIFO queues, robust consumers are safer because retries, downstream writes, network errors, and partial failures can still create duplicate side-effect risks.

Common idempotency techniques:

* Include an operation ID, request ID, event ID, or business key in the message.
* Store processed message IDs in a database with a uniqueness constraint.
* Make updates naturally idempotent, such as setting a status instead of incrementing blindly.
* Use conditional writes in DynamoDB.
* Design external API calls with idempotency keys when supported.

For standard queues, do not depend on strict ordering. If order is required, use FIFO or redesign the workflow so each message can be processed independently.

### SQS with SNS and EventBridge

SQS is often combined with other AWS messaging services:

* **SNS to SQS**: fanout pattern where one SNS topic publishes copies to multiple SQS queues. Each consumer gets its own queue and can retry independently.
* **EventBridge to SQS**: route events from event buses or SaaS sources into a queue for durable processing.
* **SQS to Lambda**: queue-backed serverless workers.
* **SQS with ECS/EC2/EKS workers**: scalable worker fleets that poll and process jobs.

Use SQS when you want durable work queues, backpressure, and retries. Use SNS when you want pub/sub fanout. Use EventBridge when you want event routing, filtering, schema/event bus patterns, or SaaS integrations.

### Security and access control

SQS access is controlled by IAM identity policies and SQS queue resource policies.

Common permissions:

* `sqs:SendMessage` for producers.
* `sqs:ReceiveMessage`, `sqs:DeleteMessage`, and `sqs:ChangeMessageVisibility` for consumers.
* `sqs:GetQueueAttributes` and `sqs:GetQueueUrl` for discovery and monitoring.

For encrypted queues, KMS permissions may also be required. A common failure is that IAM allows SQS access but the producer or consumer lacks permission to use the KMS key.

Queue policies are important for cross-account access and service integrations. For example, an SNS topic publishing to SQS often requires an SQS queue policy allowing `sns.amazonaws.com` to call `sqs:SendMessage`, usually with a condition restricting the source topic ARN.

### Monitoring SQS

Important CloudWatch metrics to watch:

* `ApproximateNumberOfMessagesVisible`: backlog size.
* `ApproximateNumberOfMessagesNotVisible`: in-flight messages.
* `ApproximateAgeOfOldestMessage`: oldest unprocessed message age.
* `NumberOfMessagesSent`: producer volume.
* `NumberOfMessagesReceived`: consumer receive volume.
* `NumberOfMessagesDeleted`: successful delete activity.
* `NumberOfEmptyReceives`: wasted polling or not enough available work.
* DLQ visible message count.
* Consumer error rate and latency.
* Lambda event source mapping errors or throttles if using Lambda.

A queue with rising oldest message age usually means the system cannot keep up, consumers are failing, visibility timeout is too long, or downstream dependencies are slow. Scaling consumers based only on queue depth may not help if the downstream database, API, or third-party service is the bottleneck.

Oldest message age is often more important than raw queue depth because it tells you how long work is waiting.

### Terraform notes for SQS

In Terraform, SQS is commonly managed with:

* `aws_sqs_queue`
* `aws_sqs_queue_policy`
* `aws_sqs_queue_redrive_policy`
* `aws_sqs_queue_redrive_allow_policy`
* `aws_sns_topic_subscription` when subscribing a queue to SNS
* `aws_lambda_event_source_mapping` when connecting SQS to Lambda

Common Terraform settings:

* `visibility_timeout_seconds`
* `message_retention_seconds`
* `delay_seconds`
* `receive_wait_time_seconds`
* `max_message_size`
* `fifo_queue`
* `content_based_deduplication`
* `kms_master_key_id`
* `redrive_policy`

Common Terraform mistakes:

* Creating a FIFO queue without the required `.fifo` queue name suffix.
* Forgetting `MessageGroupId` when sending to a FIFO queue.
* Creating a DLQ but not configuring the source queue redrive policy.
* Setting visibility timeout shorter than Lambda or worker processing time.
* Forgetting the SQS queue policy for SNS, EventBridge, or cross-account producers.
* Enabling KMS encryption without granting producers and consumers KMS permissions.
* Using one shared queue for unrelated workloads that need different scaling, retry, or DLQ behavior.
* Not setting `receive_wait_time_seconds`, causing inefficient short polling.

### Common SQS troubleshooting checklist

When SQS-backed work is broken or delayed, check:

* Are producers successfully sending messages?
* Is the consumer polling the correct queue URL and AWS Region?
* Are messages visible, in flight, delayed, or already in the DLQ?
* Is the visibility timeout long enough for processing?
* Are consumers deleting messages after successful processing?
* Is `maxReceiveCount` too low or too high?
* Is the DLQ growing?
* Are IAM permissions and KMS key permissions correct?
* Is a queue policy missing for SNS, EventBridge, or cross-account access?
* Is Lambda throttled or failing batches?
* Are consumers scaled enough, or is a downstream dependency the real bottleneck?
* For FIFO queues, are message group IDs creating a single hot ordered group?
* Are messages larger than the queue's maximum message size?

SQS decouples systems with durable asynchronous messaging. Know standard vs FIFO, at-least-once delivery, visibility timeout, DLQs, redrive policies, long polling, Lambda event source behavior, and idempotent consumers. The most important operational metric is often oldest message age, not just queue depth.

---

## EFS and shared volume

**Amazon EFS**, or Elastic File System, is a managed shared file system. Unlike EBS, which is block storage usually attached to one instance, EFS is file storage that can be mounted by many clients at the same time.

EFS uses NFS, commonly NFSv4.1. It is useful when multiple EC2 instances, containers, or serverless functions need shared access to the same files. Examples include shared uploads, content directories, user-generated files, shared config, ML datasets, and legacy applications requiring a shared filesystem.

EFS is regional and uses **mount targets** in subnets. A mount target is an ENI in a subnet/AZ that clients use to connect to the file system. For high availability and performance, create mount targets in each AZ where clients run.

Security is controlled by:

* VPC networking
* Security groups on mount targets
* NFS port 2049
* IAM authorization if enabled
* EFS access points
* POSIX users, groups, and permissions

EFS performance depends on performance mode, throughput mode, workload pattern, and file operation behavior. It is great for shared file access, but it is not always the right choice for high-IOPS database storage. For databases, use RDS/Aurora or carefully tuned EBS unless the database explicitly supports shared filesystems.

Common EFS troubleshooting:

* Security group does not allow NFS 2049 from clients.
* No mount target in the client AZ.
* DNS resolution disabled or broken in the VPC.
* POSIX permissions block file access.
* Application expects local disk latency but gets network filesystem behavior.

EFS is often used with ECS and EKS for shared persistent storage, but you must understand access patterns. Many pods writing to the same files can create locking/contention issues.


EFS is managed shared NFS storage. Use it when multiple compute resources need simultaneous file access. It uses mount targets in subnets, security groups, NFS port 2049, and POSIX permissions. It is not a drop-in replacement for high-performance block storage.

---

## AWS RDS Database and RDS Cluster Reference

### 1. What RDS is

**Amazon RDS**, or **Relational Database Service**, is AWS’s managed relational database service. It lets you run databases like PostgreSQL, MySQL, MariaDB, Oracle, SQL Server, and Amazon Aurora without managing the underlying servers directly.

AWS handles many infrastructure tasks such as provisioning, patching, automated backups, storage management, monitoring integration, maintenance windows, and failover options. But “managed” does not mean AWS manages everything. You still own database design, indexes, queries, schema migrations, connection pooling, access control, monitoring, and restore testing.

RDS is used when your application needs relational database features such as SQL, joins, transactions, indexes, constraints, schemas, and strong consistency. It is different from DynamoDB, which is NoSQL and designed around key-value/document access patterns.

---

### 2. RDS DB instance

An **RDS DB instance** is a managed database server. It has an engine, version, compute class, storage type, storage size, VPC networking, security groups, backup settings, parameter group, maintenance window, and monitoring options.

Examples:

* RDS PostgreSQL instance
* RDS MySQL instance
* RDS SQL Server instance
* RDS Oracle instance

You do not SSH into an RDS instance or manage the operating system. AWS manages the host layer. You manage the database configuration and how your application uses it.

Important DB instance settings:

* Engine and version
* Instance class, such as `db.r6g.large`
* Storage size/type
* Single-AZ or Multi-AZ
* Publicly accessible or private
* DB subnet group
* Security group
* Backup retention
* Maintenance window
* Parameter group
* Encryption/KMS key

For production, RDS should usually be private, encrypted, backed up, monitored, and deployed with high availability where required.

---

### 3. RDS DB cluster

An **RDS DB cluster** is a grouped database architecture, mostly used when talking about **Aurora clusters** or **RDS Multi-AZ DB clusters**.

A cluster usually has:

* A writer instance/node
* One or more reader or standby instances
* Cluster-level endpoints
* Cluster-level backup/restore behavior
* Cluster parameter groups
* Multi-AZ placement

The word “cluster” is important because cluster behavior is different from a single DB instance. Failover, endpoints, backups, upgrades, and read scaling may work differently.

Two common cluster types:

1. **Amazon Aurora DB cluster**
2. **RDS Multi-AZ DB cluster**

---

### 4. DB instance vs DB cluster

A normal **DB instance** is one managed database server. It may be Single-AZ or Multi-AZ. In traditional Multi-AZ, AWS maintains a standby copy in another AZ for failover, but that standby is not normally used for reads.

A **DB cluster** usually has multiple DB nodes or a clustered storage/compute model. It commonly has writer and reader endpoints. Aurora is the most common example.

Simple comparison:

| Feature        | DB Instance                   | DB Cluster                                  |
| -------------- | ----------------------------- | ------------------------------------------- |
| Main idea      | One managed database server   | Grouped database architecture               |
| HA option      | Single-AZ or Multi-AZ standby | Multiple instances/nodes across AZs         |
| Read scaling   | Usually read replicas         | Reader endpoint/readers depending on engine |
| Endpoint type  | Instance endpoint             | Writer/reader/cluster endpoints             |
| Common example | RDS PostgreSQL instance       | Aurora PostgreSQL cluster                   |

**Multi-AZ is not the same as read replica.** Multi-AZ is mainly for high availability. Read replicas are mainly for read scaling.

---

### 5. Aurora cluster

**Amazon Aurora** is AWS’s cloud-optimized relational database engine compatible with MySQL or PostgreSQL. Aurora is different from standard RDS MySQL/PostgreSQL because it separates compute from a distributed storage layer.

An Aurora cluster usually has:

* One **writer** instance
* Zero or more **reader** instances
* A **cluster/writer endpoint**
* A **reader endpoint**
* Instance endpoints
* Distributed storage managed by Aurora

The **writer endpoint** points to the current writer and should be used for writes. The **reader endpoint** distributes read traffic across reader instances. If the writer fails, Aurora can promote a reader to become the new writer.

Applications should use the cluster endpoint and reader endpoint instead of hardcoding instance endpoints, unless there is a specific reason.

Common Aurora use cases:

* High-availability relational workloads
* Read-heavy applications using multiple readers
* Production systems needing faster failover than basic single-instance databases
* MySQL/PostgreSQL-compatible workloads that benefit from AWS-managed scaling/storage behavior

---

### 6. Traditional Multi-AZ DB instance

A traditional **RDS Multi-AZ DB instance** has a primary database in one Availability Zone and a standby in another Availability Zone.

Example:

```text
Primary DB instance: AZ A
Standby DB instance: AZ B
```

The standby is for failover, not for normal read traffic. If the primary fails, RDS fails over to the standby. The database endpoint remains the same, but DNS points to the new primary.

Important points:

* Improves availability.
* Protects against AZ or instance failure.
* Helps during some maintenance operations.
* Does not usually scale reads.
* Failover still causes a short interruption.
* Applications must reconnect after failover.

Common mistake: thinking Multi-AZ means zero downtime. It does not. It reduces downtime, but database connections can still drop during failover.

---

### 7. RDS Multi-AZ DB cluster

An **RDS Multi-AZ DB cluster** is a newer high-availability model for supported engines. It usually has a writer and readable standby instances across multiple AZs.

Example:

```text
Writer: AZ A
Readable standby: AZ B
Readable standby: AZ C
```

Compared with traditional Multi-AZ DB instances, Multi-AZ DB clusters can provide better availability, faster failover behavior, and readable standby capacity depending on the engine.

Important points:

* Built across multiple AZs.
* Has writer and readable standby instances.
* Uses cluster endpoints.
* Requires a DB subnet group with subnets in multiple AZs.
* Useful for production workloads needing higher availability.

traditional Multi-AZ DB instance and Multi-AZ DB cluster are related but not identical. Traditional Multi-AZ has a standby mainly for failover. Multi-AZ DB cluster has multiple DB instances and readable standby nodes.

---

### 8. Read replicas

A **read replica** is a separate DB instance used to offload read traffic from the primary database. It receives changes asynchronously from the source database.

Use cases:

* Scale read-heavy applications
* Run reporting queries separately
* Reduce read load on the primary
* Create cross-Region copy for disaster recovery or latency

Important point: read replicas usually have **replication lag**. If your app writes to the primary and immediately reads from a replica, it may not see the new data yet.

Read replicas are different from Multi-AZ standby:

* **Multi-AZ standby** = high availability/failover
* **Read replica** = read scaling/DR pattern

Monitor replica lag carefully. If lag becomes high, users may see stale data.

---

### 9. RDS endpoints

Applications connect to RDS through DNS endpoints, not fixed IP addresses.

Common endpoint types:

### DB instance endpoint

Used for a normal RDS DB instance.

```text
mydb.abc123.us-east-1.rds.amazonaws.com
```

### Cluster / writer endpoint

Used for writes in a cluster. It points to the current writer.

### Reader endpoint

Used for read traffic in a cluster. It can distribute connections across reader instances.

### Instance endpoint

Points to one specific DB instance. Useful for admin/debug/special routing, but not usually best for normal app traffic.

during failover, DNS changes to point to the new writer/primary. If your application, driver, or JVM caches DNS too long, it may keep trying the old target. Connection pools should handle reconnects correctly.

---

### 10. DB subnet group and private networking

A **DB subnet group** is a group of subnets where RDS can place DB instances. For production, it should include private subnets across multiple Availability Zones.

Common production pattern:

```text
Private DB subnet in AZ A
Private DB subnet in AZ B
Private DB subnet in AZ C
```

RDS should usually be placed in private subnets, not public subnets. The application connects to it privately from EC2, ECS, EKS, Lambda in VPC, VPN, Direct Connect, or another controlled private path.

To connect successfully, check:

* VPC routing
* DB subnet group
* Security groups
* NACLs
* DNS resolution
* Application/database port

---

### 11. Security groups and access

RDS access is mainly controlled with **security groups**. A secure pattern is to allow the application security group to connect to the database security group on the database port.

Example:

```text
App SG -> DB SG on TCP 5432
```

Common database ports:

* PostgreSQL: `5432`
* MySQL/MariaDB/Aurora MySQL: `3306`
* SQL Server: `1433`
* Oracle: `1521`

Avoid opening database access to `0.0.0.0/0`. Production databases should almost always be private.

Admin access should go through secure paths such as:

* VPN
* Direct Connect
* Client VPN
* Bastion host
* SSM tunnel
* Private jump host

Common connection failure causes:

* DB security group does not allow source
* App security group outbound is restricted
* NACL blocks traffic or ephemeral return ports
* DB is in private subnet but client has no route
* Wrong endpoint, port, username, or password
* Database is not publicly accessible but client is outside the network

---

### 12. Backups, snapshots, and PITR

RDS supports three important recovery tools:

1. **Automated backups**
2. **Manual snapshots**
3. **Point-in-time recovery**, or **PITR**

### Automated backups

Automated backups are created by RDS during the backup window. They allow point-in-time recovery within the configured backup retention period.

Production databases should usually have automated backups enabled.

### Manual snapshots

Manual snapshots are user-created backups. They remain until you delete them.

Take manual snapshots before:

* Major upgrades
* Risky schema migrations
* Large data changes
* Deleting a database
* Testing restore procedures

### Point-in-time recovery

PITR lets you restore a database to a specific time within the backup retention window. A PITR restore normally creates a **new DB instance or cluster**. It does not usually rewind the existing production DB in place.

Example incident:

```text
Bad migration ran at 10:15 AM.
Restore DB to 10:14 AM as a new DB.
Validate data.
Recover missing data or cut over app.
```

backups are not enough. You must test restores.

---

### 13. Cluster backup

For clusters such as Aurora, backups are usually cluster-level. A cluster snapshot captures the cluster state. Restoring creates a new cluster.

Important cluster backup points:

* Backup retention is often configured at the cluster level
* Snapshots can be copied across Regions
* Encrypted snapshots require KMS permissions
* Restores usually create a new cluster, not an in-place rollback
* DR plans must include endpoint, DNS, secrets, app config, and networking changes

For production, document the restore steps before an incident happens.

---

### 14. Encryption and KMS

RDS supports encryption at rest using AWS KMS. Encryption can cover database storage, backups, snapshots, and replicas depending on engine/configuration.

Important points:

* Encryption is usually chosen when the DB is created
* Existing unencrypted DBs may require snapshot-copy/restore workflows to become encrypted
* Encrypted snapshots require KMS permissions to copy, share, or restore
* Cross-account snapshot sharing with encryption requires KMS key policy setup
* If a KMS key is disabled or deleted, encrypted data may become unreadable

Common issue: a team has access to a snapshot but cannot restore it because they do not have permission to use the KMS key.

---

### 15. Parameter groups

A **parameter group** controls database engine settings. It is similar to a managed database configuration file.

Examples of parameters:

* Max connections
* Logging options
* Memory-related settings
* Timeouts
* Character sets
* Replication settings
* Engine-specific behavior

Some parameters are **dynamic** and apply immediately. Others are **static** and require a database reboot.

For clusters, there may be both:

* DB parameter group
* DB cluster parameter group

Common mistake: changing a parameter and expecting it to apply immediately when a reboot is required.

Best practice: manage parameter groups with infrastructure as code and test changes in non-production.

---

### 16. Maintenance and upgrades

RDS has a **maintenance window** where AWS can apply certain patches or maintenance tasks. Choose this window intentionally, usually outside business-critical hours.

RDS upgrades can be:

* **Minor upgrades**: usually bug/security fixes, lower risk but still need testing.
* **Major upgrades**: bigger compatibility changes, higher risk.

Safe upgrade process:

1. Review release notes
2. Check application driver compatibility
3. Check extensions/plugins
4. Take snapshot/backup
5. Test upgrade in non-production
6. Validate queries, migrations, and performance
7. Schedule maintenance window
8. Monitor after upgrade
9. Keep rollback/restore plan ready

For clusters, upgrades may involve writer/readers, parameter groups, failover, and possibly blue/green deployment options.

---

### 17. RDS Proxy and connection pooling

Too many database connections is one of the most common RDS production problems.

Causes:

* App creates too many connections
* No connection pooling
* Pool size too high per container/instance
* Lambda concurrency spike
* Connections are leaked
* Slow queries hold connections too long

Simple formula:

```text
Total possible connections = number of app instances × pool size per instance
```

If 50 containers each have a pool of 50, that is 2,500 possible DB connections.

**RDS Proxy** is a managed proxy that can pool and reuse database connections. It is especially useful for Lambda, serverless, and bursty workloads. It can also help applications recover more smoothly during failover.

RDS Proxy does not fix bad queries, missing indexes, or an undersized database. It mainly helps connection management.

---

### 18. Monitoring RDS

Important CloudWatch metrics:

* **CPUUtilization**: high CPU may mean heavy queries or undersized instance.
* **FreeableMemory**: low memory can cause swapping/performance issues.
* **FreeStorageSpace**: low storage can cause outages.
* **DatabaseConnections**: too many connections can block new requests.
* **ReadIOPS / WriteIOPS**: storage operation load.
* **ReadLatency / WriteLatency**: storage latency.
* **DiskQueueDepth**: pending disk I/O.
* **ReplicaLag**: delay on read replicas.
* **Deadlocks**: lock conflict indicator.
* **SwapUsage**: memory pressure.

Other useful tools:

* **Enhanced Monitoring**: OS-level database host metrics.
* **Performance Insights / Database Insights**: query load, waits, top SQL, bottlenecks.
* **CloudWatch Logs export**: database logs such as slow query logs or error logs.
* **RDS Events**: failover, backup, maintenance, storage, and configuration events.
* **CloudTrail**: who changed RDS configuration.

Good alarms:

* Free storage low
* CPU high for sustained period
* Memory low / swap high
* Connections near max
* Read/write latency high
* Replica lag high
* Backup failed
* Failover occurred
* RDS instance/cluster not available

---

### 19. Common RDS production problems

Too many connections
Applications open more DB connections than the database can handle. Fix with connection pooling, RDS Proxy, lower pool sizes, and query optimization.

Storage full
Database runs out of free storage. Monitor `FreeStorageSpace`, enable storage autoscaling where appropriate, and investigate table/index/log growth.

Slow queries
Missing indexes, inefficient joins, full table scans, or bad query plans cause high CPU, I/O, and latency. Use slow query logs and Performance Insights.

Locking/deadlocks
Long transactions or bad migrations can block queries. Keep transactions short and test migrations on realistic data.

Replica lag
Read replicas fall behind the primary. Apps may read stale data. Monitor lag and avoid sending read-after-write critical queries to replicas.

Bad migration
Schema migrations can lock tables, break old app versions, or modify too much data at once. Use backward-compatible migration patterns.

Failover problems
Applications do not reconnect properly after failover. Fix DNS caching, connection pool behavior, retry logic, and driver settings.

Security group/network issue
App cannot connect because security groups, NACLs, routes, or subnet design are wrong.

KMS permission issue
Snapshot restore, replica creation, or encrypted database access fails because the principal lacks KMS permissions.


RDS is AWS’s managed relational database service. A **DB instance** is a managed database server. A **DB cluster** is a grouped architecture used by Aurora and Multi-AZ DB clusters. Traditional Multi-AZ provides a standby for failover, while read replicas are mainly for read scaling. Aurora clusters have writer and reader endpoints and distributed storage.

For production, place RDS in private subnets, use security groups carefully, enable backups, test restores, encrypt with KMS, monitor key metrics, and design applications to handle failover and connection drops.

Most RDS incidents involve too many connections, storage full, slow queries, locks, replica lag, bad migrations, security group mistakes, KMS permissions, failed backups, or applications not handling failover correctly.

---

## AWS KMS 

### 1. What AWS KMS is

**AWS KMS**, or **Key Management Service**, is AWS’s managed service for creating, storing, controlling, and using cryptographic keys. KMS is used to encrypt and decrypt data across AWS services and applications.

You commonly see KMS used with:

* S3 server-side encryption with KMS, or SSE-KMS
* EBS volume encryption
* RDS encryption
* Secrets Manager
* CloudWatch Logs encryption
* Lambda environment variable encryption
* EKS secrets encryption
* SQS/SNS encryption
* DynamoDB encryption with customer-managed keys
* Custom application encryption

KMS is not usually where large data files are directly encrypted. Instead, KMS is commonly used for **envelope encryption**: KMS protects a data key, and the data key encrypts the actual data.

---

### 2. Envelope encryption

**Envelope encryption** is a key AWS KMS concept.

The idea is:

1. A data key encrypts your actual data
2. KMS encrypts the data key using a KMS key
3. The encrypted data key is stored with the encrypted data
4. To decrypt later, the application asks KMS to decrypt the encrypted data key
5. The plaintext data key is then used to decrypt the data

Why this matters:

* KMS does not need to encrypt large files directly
* KMS controls access to the data key
* CloudTrail can record KMS usage
* Key policies and IAM decide who can decrypt

This model is used behind the scenes by many AWS services.

### 3. KMS keys

The main resource in KMS is a **KMS key**. Older AWS documentation may call this a **customer master key**, or CMK, but the modern term is **KMS key**.

A KMS key contains key metadata and references to cryptographic key material. The key material is what is actually used for cryptographic operations.

Common KMS key types:

* **AWS owned key**
* **AWS managed key**
* **Customer managed key**

#### AWS owned key

An AWS owned key is fully owned and managed by AWS. You do not see or manage it in your account. Some AWS services use these automatically.

#### AWS managed key

An AWS managed key is created and managed by AWS for a specific AWS service in your account. You can see it, but you have limited control. These often have aliases like:

```text
alias/aws/s3
alias/aws/ebs
alias/aws/rds
```

AWS managed keys are easy to use but give less control than customer-managed keys.

#### Customer managed key

A **customer managed key** is created and managed by you. You control its key policy, aliases, rotation settings, deletion schedule, tags, and permissions.

Use customer managed keys when you need:

* More control over access
* Cross-account access
* Custom key policies
* Separation by environment/application
* Audit and compliance requirements
* Control over rotation and deletion

---

### 4. Symmetric vs asymmetric KMS keys

Most AWS service encryption uses **symmetric KMS keys**. A symmetric key uses the same key material for encryption and decryption.

Common symmetric key use cases:

* S3 SSE-KMS
* EBS encryption
* RDS encryption
* Secrets Manager encryption
* Application envelope encryption

**Asymmetric KMS keys** use a public/private key pair. They can be used for encryption/decryption or signing/verification depending on key spec.

Common asymmetric use cases:

* Digital signing
* External systems needing public key verification
* Special encryption patterns where public/private key behavior is required

### 5. Key policy

A **key policy** is the main access policy attached to a KMS key. Every KMS key has exactly one key policy.

This is one of the most important points: **IAM permission alone may not be enough.** The KMS key policy must allow the account or principal to use the key, or must allow IAM policies in the account to grant access.

A key policy controls actions such as:

* Who can administer the key
* Who can encrypt
* Who can decrypt
* Who can generate data keys
* Who can create grants
* Who can schedule key deletion

Common KMS actions:

```text
kms:Encrypt
kms:Decrypt
kms:GenerateDataKey
kms:DescribeKey
kms:CreateGrant
kms:ScheduleKeyDeletion
```

A very common production problem:

```text
An IAM role has s3:GetObject permission,
but cannot read the object because the object is encrypted with SSE-KMS
and the role lacks kms:Decrypt on the KMS key.
```

When troubleshooting KMS access, always check both:

1. The IAM policy
2. The KMS key policy

Also check resource policies, service roles, SCPs, and grants if relevant.

---

### 6. IAM policies and grants

KMS access can be controlled with:

* Key policies
* IAM policies
* Grants

#### IAM policies

IAM policies can allow a role or user to use KMS actions, but this only works if the key policy allows the account/IAM path to be used.

Example IAM permissions:

```text
kms:Decrypt
kms:GenerateDataKey
```

for a specific key ARN.

#### Grants

A **grant** is a permission mechanism often used by AWS services to use a KMS key on your behalf. Grants can allow temporary or limited use of a key without changing the full key policy.

For example, EBS, RDS, or other AWS services may use grants when working with encrypted resources.

In most troubleshooting, you do not manually create grants often, but you should know they exist.

---

### 7. Aliases

A **KMS alias** is a friendly name that points to a KMS key.

Example:

```text
alias/prod/payment-key
alias/dev/app-key
```

Aliases make infrastructure easier to read and manage. Instead of hardcoding a key ID everywhere, applications or Terraform can reference an alias.

Important points:

* An alias points to one KMS key at a time.
* You can update an alias to point to a different key.
* The alias is not the key itself.
* AWS managed keys often use aliases like `alias/aws/s3`.

Aliases are helpful for naming and key replacement strategies, but old encrypted data may still require the old key to decrypt. Do not assume changing an alias automatically re-encrypts existing data.

---

### 8. Key rotation

**Key rotation** means changing the cryptographic key material used by a KMS key.

Important concept: when KMS rotates key material, old key material is retained so data encrypted before rotation can still be decrypted. Rotation does **not** usually require you to immediately re-encrypt all existing data.

##### AWS managed keys

AWS managed KMS keys are rotated automatically by AWS.

#### Customer managed keys

For supported symmetric customer managed keys, you can enable automatic rotation. By default, automatic rotation is yearly, and AWS also supports custom rotation periods for eligible keys.

You can also perform **on-demand rotation** for supported customer managed KMS keys.

### What rotation does not do

Rotation does not:

* Delete old key material
* Change the KMS key ID
* Automatically re-encrypt all existing data
* Fix overly broad key permissions
* Replace the need for good access control

### Rotation limitations

Automatic rotation is not available for every key type. For example, it is not supported for asymmetric keys, HMAC keys, keys with imported key material, or keys in custom key stores.

```text
KMS rotation changes backing key material for future encryption,
but KMS keeps old key material so old ciphertext can still be decrypted.
```

---

### 9. Key expiry, imported key material, and deletion

The phrase **key expiry** can be confusing in KMS.

Normal AWS-generated KMS key material does **not** expire like a password or TLS certificate. A KMS key remains usable unless it is disabled, scheduled for deletion, deleted, or its key material becomes unavailable.

### Disable key

Disabling a key temporarily prevents cryptographic operations. This can break services that depend on the key, but disabling is reversible.

### 10. KMS with AWS services

KMS is used by many AWS services, but each integration has its own access pattern.

### S3 SSE-KMS

For S3 objects encrypted with SSE-KMS, a principal usually needs both:

* S3 permission, such as `s3:GetObject`
* KMS permission, such as `kms:Decrypt`

For uploads, it may need:

* `s3:PutObject`
* `kms:GenerateDataKey`

### EBS

EBS volumes and snapshots can be encrypted with KMS keys. Auto Scaling Groups using encrypted AMIs or volumes need permission to use the KMS key, often through service-linked roles or grants.

### RDS

RDS databases and snapshots can be encrypted with KMS. Restoring or sharing encrypted snapshots requires KMS permissions. Cross-account encrypted snapshot sharing often fails because the KMS key policy was not updated.

### Secrets Manager

Secrets are encrypted with KMS. Reading a secret encrypted with a customer managed key requires both Secrets Manager permissions and KMS decrypt permissions.

KMS activity is recorded in **AWS CloudTrail**. This is important for security investigations and compliance.

Useful events to monitor:

* `Decrypt`
* `Encrypt`
* `GenerateDataKey`
* `ScheduleKeyDeletion`
* `DisableKey`
* `PutKeyPolicy`
* `CreateGrant`
* `EnableKeyRotation`
* `DisableKeyRotation`

High-value alerts:

* KMS key scheduled for deletion
* KMS key disabled
* Key policy changed
* Unusual decrypt activity
* Imported key material nearing expiration
* Access denied spikes involving KMS

For imported key material, create alarms before expiration so the key does not suddenly become unusable.

### Access denied despite IAM permission

Cause: key policy does not allow the principal/account, or an SCP/resource policy blocks access.

### S3 object cannot be read

Cause: role has S3 permission but lacks `kms:Decrypt` on the KMS key.

### Secret cannot be retrieved

Cause: role has `secretsmanager:GetSecretValue` but lacks KMS decrypt permission.

### Encrypted snapshot cannot be restored

Cause: missing KMS key permissions, especially cross-account or cross-Region.

### Auto Scaling cannot launch encrypted instances

Cause: ASG/service-linked role cannot use the KMS key for encrypted AMI/EBS volumes.

### Logs stop working after KMS change

Cause: CloudWatch Logs service or readers do not have correct KMS key permissions.

### Key deletion breaks data

Cause: key was scheduled and deleted while data still depended on it.

### 15. Best practices

* Use customer managed keys when you need control, auditing, or cross-account access.
* Use AWS managed keys for simpler low-control use cases.
* Keep key policies least-privilege but not so restrictive that the key becomes unmanageable.
* Separate keys by environment, sensitivity, or workload when appropriate.
* Use aliases for readable naming.
* Enable automatic rotation for eligible customer managed keys when required by policy.
* Be extremely careful with key deletion.
* Monitor key policy changes, disabled keys, and scheduled deletions.
* Do not give broad `kms:*` permissions casually.
* Test cross-account encrypted snapshot or object access before relying on it in an incident.
* Remember that KMS permissions are often needed in addition to service permissions.

---

## 21. AWS Secrets Manager

**AWS Secrets Manager** stores, retrieves, manages, and rotates secrets such as database passwords, API keys, OAuth tokens, application credentials, webhook signing secrets, and third-party service credentials. It is much better than storing secrets in source code, AMIs, Docker images, Terraform variables, shell scripts, environment files, or plain text CI variables.

A secret can contain a plain string, key-value JSON, or binary data. In practice, JSON is common for database credentials because it can store fields like `username`, `password`, `host`, `port`, `dbname`, and `engine`. Applications retrieve secrets at runtime using AWS SDKs, AWS CLI, sidecars, platform integrations, or service-native integrations.

Secrets Manager is not only encrypted storage. It also provides:

* Secret versioning.
* Rotation support.
* IAM and resource-policy based access control.
* KMS encryption.
* Cross-account access patterns.
* Multi-Region secret replication.
* CloudTrail audit events.
* Integration with services such as RDS, Redshift, DocumentDB, Lambda, ECS, EKS, and CloudFormation.

### Secret structure

A Secrets Manager secret has metadata and one or more secret versions. The metadata includes things like the secret name, ARN, description, tags, KMS key, rotation configuration, replication information, and resource policy. The secret value itself is stored in versions.

Important version labels:

* `AWSCURRENT`: the current active version returned by default.
* `AWSPREVIOUS`: the previous version after rotation or label movement.
* `AWSPENDING`: the pending version used during rotation.

Applications usually request the default `AWSCURRENT` version. During rotation, Secrets Manager and the rotation function use staging labels to track which value is pending, current, and previous. This is important for rollback and troubleshooting because a failed rotation can leave useful clues in the version labels.

Secrets Manager does not behave like a normal Git-style history of every value forever. Labeled versions are retained, while old unlabeled versions are eventually considered deprecated and can be removed by the service.

### Access control

Access to a secret usually requires both Secrets Manager permissions and KMS permissions.

Common IAM permissions:

* `secretsmanager:GetSecretValue`: read the secret value.
* `secretsmanager:DescribeSecret`: read metadata.
* `secretsmanager:PutSecretValue`: create a new secret version.
* `secretsmanager:UpdateSecret`: update secret metadata or value.
* `secretsmanager:RotateSecret`: start rotation.
* `secretsmanager:DeleteSecret`: schedule deletion.
* `secretsmanager:RestoreSecret`: restore a scheduled-for-deletion secret.

If the secret uses a customer managed KMS key, the caller may also need:

* `kms:Decrypt` to read the secret value.
* `kms:Encrypt` or `kms:GenerateDataKey` for writes or rotation.
* Permission in the KMS key policy, not just the IAM policy.

A very common failure is: the role has `secretsmanager:GetSecretValue`, but the request fails because the KMS key policy does not allow `kms:Decrypt`.

Secrets can also have **resource policies**. Resource policies are useful for cross-account access or service integrations. Be careful with them because a broad resource policy can expose a secret even if identity policies look restrictive. When using resource policies, restrict principals, actions, resources, and conditions as tightly as possible.

### Secrets Manager vs SSM Parameter Store

Secrets Manager and Systems Manager Parameter Store can both store configuration values, but they are usually used differently.

Secrets Manager is usually preferred for:

* Secrets that need automatic rotation.
* Database credentials.
* Third-party API keys.
* Cross-account secret sharing.
* Secrets requiring stronger lifecycle and audit controls.

SSM Parameter Store is often used for:

* Non-secret application configuration.
* Simple encrypted parameters.
* Hierarchical config paths such as `/prod/app/api_url`.
* Lower-cost or high-volume config reads where rotation is not needed.

This is not a hard rule. The real decision depends on rotation needs, cost, access patterns, audit requirements, and service integrations.

### Rotation

Secrets Manager supports automatic rotation. Rotation means periodically changing the secret value and updating the target system that trusts that secret. For some managed secrets, AWS can manage rotation more directly. For many custom or database secrets, rotation uses a Lambda function.

Important operational concept: rotating a secret is not just changing the value stored in AWS. If the database password changes in Secrets Manager but not in the database, the application breaks. If the database password changes but Secrets Manager still has the old value, the application also breaks. Correct rotation coordinates both sides.

For Lambda-based rotation, the rotation function usually follows four steps:

1. **Create secret**: create a new pending secret value.
2. **Set secret**: apply the pending credential to the target system.
3. **Test secret**: verify the pending credential works.
4. **Finish secret**: move `AWSCURRENT` to the new version and move the old current version to `AWSPREVIOUS`.

Rotation functions must be idempotent because retries can happen. They also need network access to the target system. For example, an RDS rotation Lambda normally must run in a VPC with routes, security groups, and DNS that allow it to reach the database.

Common rotation strategies:

* **Single-user rotation**: update the password for the same user. Simpler, but applications using old credentials may fail during the transition.
* **Alternating-user rotation**: maintain two users and alternate which one is active. More complex, but can reduce downtime risk.
* **Custom rotation**: use a Lambda function for APIs, SaaS tokens, legacy systems, or internal services.

Applications must be designed for rotated credentials. If an application reads a secret only once at startup and keeps a database connection pool forever, rotation can still cause failures. Good applications refresh secrets, recycle connections, and handle authentication failures by reloading credentials.

### Rotation schedules

Secrets can rotate on a schedule. Schedules can use rate expressions or cron expressions. Rotation happens during a configured rotation window, similar to a maintenance window.

Useful schedule ideas:

* Rotate database credentials during low-traffic windows.
* Avoid rotating many critical secrets at exactly the same time.
* Coordinate rotation windows with application deployment and support coverage.
* Make rotation frequent enough for security policy but not so frequent that it creates unnecessary operational risk.

Secrets Manager can also rotate a secret immediately if rotation is already configured.

### Retrieving secrets safely

Applications should retrieve secrets at runtime from AWS rather than bundling them into build artifacts. Common access patterns:

* Lambda retrieves a secret during cold start and caches it between invocations.
* ECS tasks receive secrets through task definition secret injection or call Secrets Manager directly.
* EKS workloads use IAM roles for service accounts or another identity mechanism to retrieve secrets.
* EC2 applications use the instance profile role and AWS SDK.
* CI/CD systems assume a role and read deployment-time secrets only when needed.

Avoid logging secret values. Also avoid printing full environment variables, exception payloads, request bodies, Terraform plan output, or debug dumps that may contain secrets.

### Caching

Calling Secrets Manager on every request is usually unnecessary and can add latency, cost, and dependency risk. Use caching where appropriate.

Good caching behavior:

* Cache secret values in memory for a short TTL.
* Refresh before or after rotation windows.
* Reload credentials on authentication failure.
* Use AWS-provided caching libraries when they fit the language/runtime.
* Do not cache forever unless the application is restarted as part of every rotation.

Caching must be balanced with rotation. A long cache TTL can keep old credentials alive after rotation, while no caching can increase API cost and make the application more sensitive to transient AWS API issues.

### Encryption and KMS

Secrets Manager encrypts secret values with KMS. You can use the AWS managed key for Secrets Manager or a customer managed KMS key.

Use a customer managed key when you need:

* More control over key policy.
* Cross-account access.
* Separate keys per environment or workload.
* Detailed KMS audit and lifecycle controls.
* Explicit grants for service roles or rotation functions.

KMS adds another permission layer. To read a secret encrypted with a customer managed key, the principal needs Secrets Manager permission and KMS decrypt permission. For cross-account access, the secret resource policy, IAM policy, and KMS key policy all need to line up.

### Networking and VPC endpoints

Applications in private subnets can reach Secrets Manager through a NAT gateway or through an interface VPC endpoint for Secrets Manager. For stricter private-network designs, the VPC endpoint pattern is common.

For a Secrets Manager interface endpoint, check:

* Private DNS is enabled if applications use the normal regional Secrets Manager hostname.
* The endpoint security group allows inbound `443` from the application security group or subnet CIDR.
* The application subnet has working DNS.
* The endpoint policy allows the required Secrets Manager actions.
* KMS access also works, possibly through a KMS VPC endpoint if there is no NAT.

A private workload may successfully reach Secrets Manager but fail to decrypt the secret if KMS connectivity or permissions are missing.

### Common patterns

Common Secrets Manager patterns:

* Store RDS, Aurora, Redshift, or DocumentDB credentials.
* Store third-party API tokens.
* Store OAuth client secrets.
* Store webhook signing secrets.
* Store application signing keys.
* Store credentials used by CI/CD deployment roles.
* Let Lambda retrieve secrets at cold start and refresh on failure.
* Inject secrets into ECS task containers.
* Let EKS workloads retrieve secrets through AWS identity rather than static Kubernetes secrets where appropriate.
* Share a secret cross-account with a tightly scoped resource policy.

Do not use one giant shared secret for unrelated services. Separate secrets by application, environment, and access boundary so IAM can stay precise.

### Monitoring and auditing

For SRE and security monitoring, track:

* Rotation failures.
* Secrets without rotation when policy requires rotation.
* Secrets that have not been accessed for a long time.
* Secrets accessed by unexpected roles.
* Failed `GetSecretValue` calls.
* KMS `AccessDenied` errors.
* Secret deletion scheduling.
* Resource policy changes.
* KMS key policy changes.
* Application errors after rotation windows.

CloudTrail records Secrets Manager API calls, including reads such as `GetSecretValue`. Be careful with logs and events: CloudTrail records API activity, but secret values should not be logged by your application or tooling.

Useful alarms and reports:

* Rotation Lambda errors.
* Rotation Lambda duration and timeout.
* DLQ messages for custom rotation workflows, if used.
* Secrets scheduled for deletion.
* High rate of failed secret reads.
* Application authentication failures after rotation.

### Terraform notes for Secrets Manager

In Terraform, Secrets Manager is commonly managed with:

* `aws_secretsmanager_secret`
* `aws_secretsmanager_secret_version`
* `aws_secretsmanager_secret_policy`
* `aws_secretsmanager_secret_rotation`
* `aws_kms_key`
* `aws_kms_alias`
* `aws_iam_policy`
* `aws_vpc_endpoint` for private Secrets Manager access

Important Terraform warning: if you put secret values directly in Terraform configuration, variables, or `aws_secretsmanager_secret_version`, those values can end up in Terraform state. Terraform state must be treated as sensitive and stored securely, usually in an encrypted remote backend with strict access control.

Common Terraform practices:

* Manage the secret container with Terraform.
* Avoid hardcoding secret values in `.tf` files.
* Use secure pipelines or one-time processes to populate secret values.
* Mark variables as `sensitive = true`, but remember this does not remove values from state.
* Use customer managed KMS keys when access control requires it.
* Add tags for owner, environment, application, and rotation expectations.
* Be careful with deletion windows and recovery behavior.
* Avoid frequent Terraform updates to secret versions if applications or rotation processes manage values.

Common Terraform mistakes:

* Committing secret values to Git.
* Storing secrets in local state files.
* Assuming `sensitive = true` means the value is not stored anywhere.
* Creating a secret but forgetting the KMS key permissions.
* Creating rotation but forgetting Lambda permissions or VPC access.
* Replacing secret versions unexpectedly and breaking active credentials.
* Forgetting resource policies for cross-account reads.
* Using one secret for multiple unrelated workloads.

### Common Secrets Manager troubleshooting checklist

When an application cannot read or use a secret, check:

* Does the role have `secretsmanager:GetSecretValue` on the correct secret ARN?
* Does the role have `kms:Decrypt` on the KMS key?
* Does the KMS key policy allow that principal or account?
* Is the application using the correct Region?
* Is the secret scheduled for deletion?
* Is the application requesting the correct version stage, usually `AWSCURRENT`?
* Is a resource policy blocking or allowing the wrong principal?
* Is the VPC endpoint reachable from the private subnet?
* Does the VPC endpoint policy allow the action?
* Is DNS resolving the Secrets Manager endpoint correctly?
* Is the secret JSON schema what the application expects?
* Was the secret rotated but the application cache or connection pool still uses the old value?
* Did rotation update both Secrets Manager and the target system?
* Did the rotation Lambda have network access and IAM/KMS permissions?
* Are secret values accidentally being logged?

### SRE / interview summary

Secrets Manager stores and rotates secrets securely. Access requires IAM and often KMS permissions. Secret versions use staging labels such as `AWSCURRENT`, `AWSPREVIOUS`, and `AWSPENDING`. Rotation must update both Secrets Manager and the target database or service. Applications should retrieve secrets safely, cache them thoughtfully, handle rotation, and never log secret values.

---

## 22. AWS ACM

**AWS Certificate Manager**, or ACM, provisions, stores, renews, imports, exports in supported cases, and manages SSL/TLS certificates for AWS services. It is commonly used to enable HTTPS for Application Load Balancers, Network Load Balancers, CloudFront, API Gateway, App Runner, Elastic Beanstalk, and other AWS integrations.

ACM helps remove a lot of certificate operational work. Instead of manually generating private keys, creating CSRs, buying certificates, installing certificate chains, and tracking expiration dates, you can request or import certificates and attach them to supported AWS resources.

ACM manages several certificate types:

* **Public ACM certificates**: publicly trusted certificates issued by Amazon for public domain names.
* **Private certificates**: certificates issued from AWS Private CA for internal/private PKI use cases.
* **Imported certificates**: certificates issued outside ACM and imported for use with ACM-integrated services.
* **Exportable public certificates**: ACM public certificates that can be exported and installed outside integrated AWS services, if they were created as exportable certificates.

### What ACM is used for

ACM certificates are used to secure TLS connections. Common uses:

* Public HTTPS on an Application Load Balancer.
* HTTPS on CloudFront distributions.
* Custom domains for API Gateway.
* TLS on Network Load Balancers.
* Internal TLS for private services using private certificates.
* Centralized certificate management for workloads that need exported certificates.

ACM does not host your website by itself. It only manages certificates. You still need a service such as ALB, CloudFront, API Gateway, or another TLS endpoint to use the certificate.

### Public certificates

Public ACM certificates are trusted by common browsers and clients. To issue one, ACM must validate that you control the domain name.

Common validation methods:

* **DNS validation**: create CNAME records in DNS to prove domain ownership.
* **Email validation**: approve validation emails sent to domain contacts or standard admin addresses.

DNS validation is usually preferred because it is easier to automate and supports managed renewal more reliably when the validation records remain in place. Email validation can work, but it is easier to miss renewal emails or lose access to the mailbox.

Public certificates can include:

* A single domain, such as `example.com`.
* Subject alternative names, such as `www.example.com` and `api.example.com`.
* Wildcards, such as `*.example.com`.

Wildcard certificates only cover one label level. For example, `*.example.com` covers `app.example.com`, but not `dev.app.example.com`.

### Regional rules

ACM certificates are regional resources. This is one of the most important ACM interview and troubleshooting points.

Important Region behavior:

* Certificates for **CloudFront** must be in `us-east-1`, because CloudFront uses ACM certificates from US East, N. Virginia.
* Certificates for **ALB**, **NLB**, and most regional services must be in the same Region as the service.
* If you use ALBs in multiple Regions, you usually need a certificate in each Region.
* Imported certificates must also be imported into every Region where they are needed.

A very common mistake is requesting a certificate in the application Region and then trying to attach it to CloudFront. For CloudFront, request or import the certificate in `us-east-1`.

### Certificate lifecycle

Typical ACM public certificate lifecycle:

1. Request a certificate for one or more domain names.
2. Choose DNS or email validation.
3. Complete domain validation.
4. Wait for ACM to issue the certificate.
5. Attach the certificate to an integrated service.
6. Keep validation records in place.
7. Let ACM handle managed renewal when eligible.
8. Monitor certificate status and expiration.

The certificate must match the hostname that users actually access. If users visit `api.example.com`, the certificate needs `api.example.com` or a matching wildcard such as `*.example.com`.

### DNS validation

With DNS validation, ACM gives you one or more CNAME records. You add those records to the authoritative DNS zone for the domain. If the domain is hosted in Route 53, Terraform or the console can often create these records automatically.

Important DNS validation details:

* The validation record must be in the correct public hosted zone.
* The domain's registrar must point to the correct authoritative nameservers.
* Do not delete validation CNAME records after issuance.
* DNS propagation and wrong hosted zones are common causes of stuck validation.
* Wildcard and apex names may reuse the same validation record in some cases.

Leaving DNS validation records in place is important because ACM can use them again for managed renewal.

### Email validation

With email validation, ACM sends approval emails to domain contacts or standard addresses such as administrator/admin-style addresses for the domain. Someone must approve the request.

Email validation is less automation-friendly because:

* Mailboxes can be unmonitored.
* WHOIS privacy can make contacts unreliable.
* Renewal notices can be missed.
* Infrastructure automation cannot fully complete validation alone.

For production infrastructure, DNS validation is usually the cleaner choice.

### Managed renewal

ACM can provide managed renewal for eligible ACM-issued certificates. If the certificate is attached to an integrated AWS service and validation remains valid, renewal can happen without manual reinstallation.

Managed renewal depends on the certificate type and deployment pattern:

* Public ACM certificates with DNS validation are usually the easiest to renew automatically.
* Email-validated certificates may require responding to renewal emails.
* Imported certificates are not automatically renewed by ACM. You must obtain a new certificate and reimport it.
* Private certificates from AWS Private CA can be eligible for managed renewal when requested through ACM.
* Exported certificates may renew in ACM, but you still need a process to deploy the renewed certificate to the external server or application.

For SRE work, certificate expiration is a major preventable incident. Monitor expiration even when managed renewal is expected. Automation can fail because of deleted DNS validation records, wrong DNS zones, service disassociation, or permission issues.

### Imported certificates

ACM can import certificates that were issued outside ACM. This is useful when:

* Your organization uses a third-party certificate authority.
* You need a certificate type or policy not issued directly by ACM.
* You are migrating existing certificates into AWS-managed integrations.

Imported certificates require the certificate body, private key, and certificate chain in supported PEM formats. The private key must match the certificate.

Important imported certificate behavior:

* ACM does not provide managed renewal for imported certificates.
* You are responsible for tracking expiration.
* To preserve existing AWS service associations, reimport a renewed certificate into the same ACM certificate ARN when possible.
* Imported certificates are regional.
* For CloudFront, import into `us-east-1`.

Imported certificates are powerful but operationally risky if nobody owns renewal.

### Exportable certificates

Historically, ACM public certificates were mainly used with integrated AWS services and the private key could not be exported. ACM now supports exportable public certificates in supported cases. Exportable certificates can be useful for EC2 instances, containers, on-premises hosts, or software that needs direct access to certificate files.

Important exportable certificate points:

* Exporting includes the certificate, certificate chain, and encrypted private key.
* The exported private key must be protected carefully.
* You need a deployment process for renewed exported certificates.
* Exportable public certificates can have different pricing and lifecycle considerations than standard integrated-service ACM certificates.
* Public ACM certificates created before June 17, 2025 cannot be exported.

If the certificate is only needed on ALB, CloudFront, or API Gateway, prefer using ACM directly with the integrated service instead of exporting and managing private keys yourself.

### Private certificates and AWS Private CA

ACM integrates with AWS Private CA for private certificates. Private certificates are used for internal services, mutual TLS, service-to-service encryption, corporate devices, internal APIs, and private PKI use cases.

Important private certificate points:

* Private certificates are not publicly trusted by browsers unless clients trust your private CA root.
* You may need to distribute the private CA root certificate to clients.
* AWS Private CA has its own cost and security considerations.
* Private CA permissions matter, especially for renewal and cross-account issuance.
* Private certificates can be associated with some ACM-integrated services or exported depending on the use case.

Private certificates are good for internal trust. Public ACM certificates are good for public internet trust.

### Service integrations

Common ACM integrations:

* **Application Load Balancer**: HTTPS listeners use ACM certificates.
* **Network Load Balancer**: TLS listeners can use ACM certificates.
* **CloudFront**: viewer certificates must be in `us-east-1`.
* **API Gateway**: custom domains use ACM certificates.
* **App Runner**: custom domains can use ACM-managed certificates through the service flow.
* **Elastic Beanstalk**: environments can use ACM certificates through load balancers.

ACM certificates cannot be attached to every service in every way. Always check whether the target service supports ACM certificates, imported certificates, RSA/ECDSA key types, and the Region you are using.

### Security and IAM

ACM protects private keys for certificates used with integrated services. For standard ACM-managed public certificates attached to AWS services, you do not directly handle the private key.

Security considerations:

* Restrict who can request, import, export, delete, or renew certificates.
* Be especially careful with `acm:ExportCertificate` because it can expose private keys for exportable certificates.
* Use least-privilege IAM for Terraform and CI/CD roles.
* Tag certificates with owner, environment, application, and renewal responsibility.
* Protect Route 53 permissions because DNS validation depends on DNS control.
* Monitor certificate deletion and export events in CloudTrail.

TLS security also depends on the service configuration. For example, an ALB listener's security policy controls allowed TLS versions and ciphers. ACM provides the certificate, but the load balancer or service controls many TLS negotiation details.

### Terraform notes for ACM

In Terraform, ACM is commonly managed with:

* `aws_acm_certificate`
* `aws_acm_certificate_validation`
* `aws_route53_record` for DNS validation records
* `aws_lb_listener` or `aws_lb_listener_certificate`
* `aws_cloudfront_distribution`
* `aws_api_gateway_domain_name`
* Provider aliases for `us-east-1` CloudFront certificates

Common Terraform pattern for DNS validation:

1. Create `aws_acm_certificate` with `validation_method = "DNS"`.
2. Create Route 53 validation records from `domain_validation_options`.
3. Create `aws_acm_certificate_validation`.
4. Attach the validated certificate ARN to ALB, CloudFront, or API Gateway.

Common Terraform mistakes:

* Creating a CloudFront certificate outside `us-east-1`.
* Forgetting to use a provider alias for `us-east-1`.
* Creating validation records in the wrong hosted zone.
* Deleting DNS validation CNAME records after issuance.
* Attaching the certificate before validation completes.
* Replacing a certificate unnecessarily because SAN ordering or domain lists changed.
* Forgetting `create_before_destroy` and causing certificate downtime.
* Not reimporting renewed imported certificates into the same ARN.
* Not monitoring imported certificate expiration.

Useful Terraform lifecycle setting:

* `create_before_destroy = true` on certificates can help avoid downtime when a replacement certificate is needed.

### Monitoring and operations

For operations, monitor:

* Certificate expiration dates.
* Renewal eligibility and renewal status.
* Failed renewal events.
* Missing DNS validation records.
* Certificates not attached to any service.
* Imported certificates approaching expiration.
* CloudFront distributions still deploying a certificate change.
* CloudTrail events for certificate import, export, delete, and renewal actions.

EventBridge can be used to react to ACM events, such as approaching expiration or renewal state changes. For imported or exported certificates, monitoring matters even more because ACM may not be able to deploy renewed material automatically.

### Common ACM troubleshooting checklist

When a certificate is not issued, not attaching, or not working:

* Is the certificate in the correct Region?
* For CloudFront, is the certificate in `us-east-1`?
* Is the certificate status `ISSUED`?
* Are DNS validation CNAME records present in the authoritative public hosted zone?
* Is the domain registrar pointing to the nameservers for that hosted zone?
* Does the certificate cover the exact hostname users access?
* Is a wildcard being used for a hostname it does not cover?
* Is the certificate attached to the correct listener, distribution, or custom domain?
* Is CloudFront still deploying the distribution change?
* Is the client seeing an old certificate because of DNS or CDN propagation?
* For imported certificates, is the chain complete and in the correct order?
* For imported certificates, does the private key match the certificate?
* Is the certificate expired or close to expiration?
* Did someone delete DNS validation records needed for renewal?
* Are IAM permissions blocking Terraform or service attachment?

### SRE / interview summary

ACM manages TLS certificates for AWS services. DNS validation is preferred for automation and renewal. ALB and most regional service certificates must be in the same Region as the service; CloudFront certificates must be in `us-east-1`. Imported certificates are not automatically renewed by ACM. Most ACM incidents come from wrong Region, missing DNS validation, hostname mismatch, deleted validation records, incomplete certificate chains, or unmanaged imported certificate expiration.

---

## 23. Route 53

**Amazon Route 53** is AWS’s DNS service. It provides hosted zones, DNS records, routing policies, health checks, domain registration, and integration with AWS resources.

### DNS zone / hosted zone

A **hosted zone** is a container for DNS records for a domain, such as `example.com`. There are two main types:

* **Public hosted zone**: answers DNS queries from the internet.
* **Private hosted zone**: answers DNS queries only inside associated VPCs.

A hosted zone contains records such as A, AAAA, CNAME, MX, TXT, NS, SOA, and Route 53 alias records.

### Record

A DNS **record** maps a name to a value. Examples:

* `A`: hostname to IPv4 address
* `AAAA`: hostname to IPv6 address
* `CNAME`: hostname to another hostname
* `MX`: mail servers
* `TXT`: text values, often for verification/SPF/DKIM
* `NS`: nameservers

Records have TTLs, which tell resolvers how long to cache the answer. Lower TTLs allow faster changes but increase DNS query volume. Higher TTLs reduce query load but make changes slower to propagate.

### Alias record

A Route 53 **alias** record is an AWS-specific DNS feature. It lets you point a DNS name to certain AWS resources such as CloudFront distributions, ALBs, NLBs, API Gateway custom domains, Elastic Beanstalk environments, and S3 website endpoints.

Alias records are especially useful at the zone apex. Standard DNS does not allow a CNAME at the root domain like `example.com`, but Route 53 alias records can point the root domain to supported AWS resources.

Alias records also automatically track changes to the underlying AWS resource DNS name and do not require a separate TTL in the same way as normal records for some targets.

### Operational concerns

Common DNS issues:

* Wrong hosted zone updated.
* Domain registrar nameservers not pointing to Route 53 hosted zone.
* Record exists in private hosted zone but not public zone, or vice versa.
* CNAME used where alias is needed.
* TTL delays make changes appear inconsistent.
* Split-horizon DNS causes different answers inside vs outside VPC.
* Health-check routing policy misconfigured.

Route 53 routing policies include simple, weighted, latency-based, failover, geolocation, geoproximity, multivalue answer, and IP-based routing. For most interviews, understand simple, weighted, latency, and failover.

### SRE / interview summary

Route 53 is DNS. Hosted zones contain records. Public zones serve internet DNS; private zones serve VPC DNS. Alias records point names to AWS resources and support root domains. DNS troubleshooting requires checking zone, record, TTL, registrar nameservers, and public vs private resolution.

---

## 24. CloudFront Distribution

**Amazon CloudFront** is AWS’s content delivery network, or CDN. It caches and delivers content from edge locations close to users. It improves latency, reduces origin load, and can add security features such as TLS, AWS WAF, signed URLs/cookies, geo restrictions, and origin protection.

A **CloudFront distribution** defines how CloudFront receives viewer requests and where it sends origin requests. A distribution has domain names, origins, cache behaviors, TLS settings, logging options, security settings, and error response settings.

### CDN concept

A CDN caches content near users. When a user requests an object, CloudFront checks if it has a valid cached copy at the edge. If yes, it returns it quickly. If not, it requests the object from the origin, returns it to the user, and may cache it.

CloudFront is useful for:

* Static websites
* S3 content delivery
* APIs with global users
* Images/video/assets
* Software downloads
* Reducing ALB/API origin load
* Adding WAF at the edge

### CloudFront origin

An **origin** is the backend CloudFront gets content from. Common origins:

* S3 bucket
* ALB
* EC2 or custom HTTP server
* API Gateway
* Media services

For custom origins, ensure the origin DNS name, protocol, port, TLS certificate, and security groups are correct. If CloudFront connects over HTTPS, the origin certificate must match the origin domain name.

### Origin Access Control

**Origin Access Control**, or OAC, is the modern way to let CloudFront privately access S3 origins. With OAC, the S3 bucket can remain private, and the bucket policy allows only the CloudFront distribution to read objects.

OAC is preferred over the older Origin Access Identity model for most new designs. It helps prevent users from bypassing CloudFront and directly accessing S3 objects.

### Cache behavior

A **cache behavior** controls how CloudFront handles requests for specific path patterns. Each behavior points to an origin and defines settings such as:

* Path pattern, such as `/images/*` or `/api/*`
* Allowed HTTP methods
* Viewer protocol policy, such as redirect HTTP to HTTPS
* Cache policy
* Origin request policy
* Response headers policy
* Compression
* TTL behavior

Cache behavior ordering matters. More specific path patterns should be considered carefully. The default cache behavior catches requests that do not match other behaviors.

Cache keys determine what makes one cached response different from another. Including too many headers, cookies, or query strings in the cache key can reduce cache hit ratio. Including too few can return wrong content to users. For APIs, you often disable or limit caching; for static assets, you use long TTLs with versioned filenames.

Invalidations remove cached objects before TTL expiration, but frequent invalidations can be inefficient. A better pattern for static assets is versioned file names, such as `app.abc123.js`.

### Operational concerns

Monitor:

* Cache hit ratio
* 4xx and 5xx error rates
* Origin latency
* Total requests and bytes downloaded
* WAF blocks if enabled
* TLS/certificate status

Common issues:

* S3 bucket public blocked but OAC/bucket policy missing.
* Wrong cache behavior handles the path.
* CloudFront caches an error response longer than expected.
* Origin returns different content based on headers not included in cache key.
* Certificate for alternate domain name is missing or in wrong Region.
* DNS alias not pointing to distribution.

### SRE / interview summary

CloudFront is a CDN. Distribution routes viewer requests to origins through cache behaviors. OAC protects private S3 origins. Cache policies and cache keys are critical: they control performance, correctness, and origin load.

---

## 25. AWS Organizations

**AWS Organizations** is an account management and governance service for managing multiple AWS accounts centrally. It lets you group accounts, apply organization-wide policies, consolidate billing, create new accounts, invite existing accounts, and delegate administration of supported AWS services.

In real AWS environments, multiple accounts are normal. Instead of putting every workload into one large account, teams often separate accounts by environment, workload, business unit, or security boundary. For example:

* `management` or payer account
* `security` account
* `log-archive` account
* `shared-services` or networking account
* `dev`, `staging`, and `prod` workload accounts
* Sandbox accounts

This separation improves blast-radius control, cost tracking, IAM boundaries, service quota management, and incident response.

### Core concepts

Important AWS Organizations terms:

* **Organization**: the overall container for centrally managed AWS accounts.
* **Management account**: the account that created and owns the organization.
* **Member account**: any account that belongs to the organization but is not the management account.
* **Root**: the top-level container in the organization hierarchy.
* **Organizational unit**, or **OU**: a grouping of accounts under the root or under another OU.
* **Policy**: a governance rule attached to the root, OUs, or accounts.
* **Delegated administrator**: a member account allowed to manage an AWS service for the organization.

The management account is very powerful. It pays the bill, creates or invites accounts, moves accounts between OUs, enables service integrations, attaches organization policies, and registers delegated administrators. Because of this, production resources should usually not run in the management account.

### OUs and account structure

An **OU** groups accounts so you can manage them as a unit. Policies attached to an OU apply to accounts inside that OU and usually to accounts inside child OUs.

Common OU patterns:

* **Security OU**: accounts for security tooling, audit, and log archive.
* **Infrastructure OU**: networking, shared services, CI/CD, and platform accounts.
* **Workloads OU**: application accounts, often split into prod and non-prod.
* **Sandbox OU**: experimentation accounts with stricter cost and permission limits.
* **Suspended OU**: closed, quarantined, or inactive accounts.

Good OU design is based on governance needs, not only team names. If two sets of accounts need different controls, they may belong in different OUs.

### Consolidated billing

AWS Organizations provides **consolidated billing**. The management account pays charges for member accounts, and billing data can be viewed across the organization.

Benefits:

* One central bill for the organization.
* Easier cost allocation by account, tag, workload, or environment.
* Shared volume pricing benefits where AWS supports them.
* Reserved Instance and Savings Plans discount sharing, depending on billing settings.
* Better separation between workload ownership and payment administration.

Account-level cost visibility is one of the biggest practical reasons to use multiple accounts. A separate production account, for example, makes it much easier to understand production cost than trying to separate everything with tags inside one account.

### Service control policies

**Service control policies**, or **SCPs**, are organization-level permission guardrails. They define the maximum permissions available to IAM users and roles in member accounts.

The most important SCP rule: **SCPs do not grant permissions**. They only limit permissions. A principal still needs IAM permissions in the account. Effective permissions are the intersection of:

* What identity policies allow.
* What resource policies allow, where applicable.
* What permission boundaries and session policies allow, if used.
* What SCPs allow.
* What resource control policies allow, if used.
* Any explicit denies.

Example: if a user has `AdministratorAccess` in a member account, but an SCP denies `ec2:TerminateInstances`, that user still cannot terminate EC2 instances.

Common SCP uses:

* Deny disabling CloudTrail, AWS Config, GuardDuty, or Security Hub.
* Deny leaving the organization.
* Restrict access to approved AWS Regions.
* Deny deleting critical log buckets.
* Deny changing account-level security settings.
* Deny creating public S3 buckets.
* Deny use of services that are not approved.

SCPs apply to member accounts, including the root user of a member account. SCPs do **not** restrict users or roles in the management account. This is a major reason to keep the management account locked down and mostly empty.

### SCP allow and deny strategy

There are two common SCP strategies:

* **Deny list**: start from broad access and explicitly deny dangerous actions.
* **Allow list**: allow only approved services or actions and implicitly deny everything else.

Deny-list SCPs are easier to adopt and less likely to break workloads unexpectedly. Allow-list SCPs are stricter but require much more testing because new services and actions are denied until explicitly allowed.

Important SCP gotcha: do not remove the AWS-managed `FullAWSAccess` SCP unless you replace it carefully. Without an allow path, actions in member accounts can fail broadly.

Best practice: test SCPs in a small OU before attaching them to production OUs or the organization root.

### Resource control policies

AWS Organizations also supports **resource control policies**, or **RCPs**, for supported use cases. SCPs are principal-focused guardrails, while RCPs are resource-focused guardrails. In simple terms:

* SCPs limit what principals in member accounts can do.
* RCPs limit access to resources in member accounts.

For many interviews and day-to-day tasks, SCPs are the main Organizations policy type people discuss. But it is useful to know that Organizations policy capabilities are broader than SCPs.

### Delegated administrators and trusted access

Many AWS services integrate with AWS Organizations. Instead of managing every service from the management account, you can enable trusted access and designate a **delegated administrator** member account.

Common delegated administrator patterns:

* Security account administers GuardDuty, Security Hub, IAM Access Analyzer, Macie, Detective, Inspector, or Firewall Manager.
* Log archive account receives centralized CloudTrail and Config logs.
* Audit account has read-only visibility into organization security posture.
* Network account manages shared networking, depending on design.

Delegated administration reduces day-to-day use of the management account. The management account should be reserved for organization-level tasks that truly require it.

### AWS Control Tower relationship

**AWS Control Tower** is built on top of AWS Organizations and related services. Organizations gives you the core account hierarchy and policy engine. Control Tower adds a managed landing zone, account factory, guardrails, baseline configuration, and lifecycle workflows.

Simple comparison:

* **AWS Organizations**: account hierarchy, billing, policies, integrations.
* **AWS Control Tower**: opinionated multi-account landing zone built using Organizations and other AWS services.

You can use Organizations without Control Tower. Many companies do. Control Tower is useful when you want AWS to orchestrate more of the landing-zone setup and account vending process.

### Multi-account best practices

Common best practices:

* Keep the management account highly restricted and mostly empty.
* Use IAM Identity Center for human access across accounts.
* Use separate accounts for production and non-production.
* Use a dedicated security account for security tooling.
* Use a dedicated log archive account for immutable or centralized logs.
* Use SCPs as broad guardrails, not as a replacement for IAM.
* Standardize account naming, email ownership, tags, and contact information.
* Enable organization-wide CloudTrail, AWS Config, GuardDuty, Security Hub, and IAM Access Analyzer where appropriate.
* Use cross-account roles for automation and deployments.
* Have a clear account vending process for creating new accounts.

The main idea is blast-radius reduction. A mistake in a sandbox account should not be able to delete production logs or change organization-wide security controls.

### Account creation and lifecycle

Organizations can create new AWS accounts programmatically or through the console. New accounts can then be moved into OUs and receive inherited policies.

Account lifecycle topics:

* Account creation and bootstrapping.
* Baseline IAM roles and access.
* Required security services.
* Logging and monitoring setup.
* Network configuration.
* Budget and cost controls.
* Moving accounts between OUs.
* Closing or suspending unused accounts.

When accounts are created through automation, the first bootstrapping step often creates a cross-account admin or deployment role so platform tooling can finish setup.

### Security and compliance

Organizations is central to AWS governance. It helps enforce controls across accounts that individual account administrators cannot easily bypass.

Examples:

* Require CloudTrail to stay enabled.
* Prevent deletion of log archive buckets.
* Restrict workloads to approved Regions.
* Prevent root account usage in member accounts through monitoring and alerting.
* Enable security services across all accounts.
* Use centralized Config rules and aggregators.
* Use centralized IAM Access Analyzer.
* Use delegated security administration.

Organizations is not a complete security solution by itself. It works with IAM, CloudTrail, AWS Config, GuardDuty, Security Hub, KMS, S3 bucket policies, permission boundaries, and account-level controls.

### Terraform notes for AWS Organizations

In Terraform, AWS Organizations is commonly managed with:

* `aws_organizations_organization`
* `aws_organizations_organizational_unit`
* `aws_organizations_account`
* `aws_organizations_policy`
* `aws_organizations_policy_attachment`
* `aws_organizations_delegated_administrator`
* `aws_organizations_resource_policy`

Common Terraform practices:

* Manage organization structure from a dedicated infrastructure or management workspace.
* Be careful with account creation because AWS account lifecycle operations can be slow and partially asynchronous.
* Keep SCP JSON in version control and review changes carefully.
* Test SCP changes in a non-production OU first.
* Avoid large, complicated SCPs when smaller policies are clearer.
* Use `jsonencode()` or policy documents to avoid invalid JSON.
* Use provider aliases and cross-account roles for bootstrapping member accounts.
* Do not casually move accounts between OUs because inherited policies can change immediately.

Common Terraform mistakes:

* Attaching a restrictive SCP to the root without testing.
* Forgetting that SCPs do not grant access.
* Forgetting that SCPs do not affect the management account.
* Removing `FullAWSAccess` without a replacement allow model.
* Creating accounts manually and then struggling to import them cleanly into Terraform state.
* Assuming account creation is instant.
* Running workload resources in the management account.
* Applying OU changes without understanding inherited policies.


---

## 26. AWS WAF and Shield

**AWS WAF** and **AWS Shield** are AWS edge and application protection services. They are often used together, but they solve different problems.

* **AWS WAF** is a web application firewall for HTTP and HTTPS traffic.
* **AWS Shield** is DDoS protection for AWS resources.

WAF is about inspecting web requests and blocking suspicious application-layer traffic. Shield is about protecting availability during denial-of-service attacks.

### AWS WAF

AWS WAF lets you create a **web ACL**, or web access control list, and attach it to supported resources such as CloudFront distributions, Application Load Balancers, API Gateway REST APIs, AppSync GraphQL APIs, Cognito user pools, App Runner services, Amplify apps, and Verified Access instances.

A web ACL contains rules. Rules inspect requests and take actions such as:

* **Allow**: let the request through.
* **Block**: reject the request.
* **Count**: evaluate the rule but do not block.
* **CAPTCHA** or **Challenge**: require extra client verification in supported cases.

Common WAF rule types:

* AWS managed rule groups for common threats.
* IP allow lists or block lists.
* Geo match rules.
* Header, cookie, query string, URI path, or body inspection.
* SQL injection and cross-site scripting matching.
* Rate-based rules to limit request floods.
* Bot Control or Fraud Control features when needed.

Good practice: start new rules in **count mode** before blocking. This helps you see what would be blocked without breaking real users.

### AWS Shield

AWS Shield protects against DDoS attacks. There are two levels:

* **Shield Standard**: automatic DDoS protection included for AWS customers at no extra charge.
* **Shield Advanced**: paid advanced DDoS protection with extra detection, mitigation, visibility, cost protection features, and access to the AWS Shield Response Team for eligible cases.

Shield Standard helps protect against common network and transport layer attacks. Shield Advanced is used for higher-risk public applications, especially important CloudFront distributions, Route 53 hosted zones, Global Accelerator accelerators, Elastic IPs, and load balancers.

For application-layer DDoS attacks, Shield Advanced often works with AWS WAF. WAF rules can block or rate-limit bad HTTP traffic, while Shield provides DDoS detection and response features.

### Common architecture pattern

For internet-facing web applications:

* Route 53 points the domain to CloudFront or an ALB.
* CloudFront sits in front of the origin when global edge protection and caching are useful.
* AWS WAF web ACL is attached to CloudFront or ALB.
* AWS managed WAF rules block common web exploits.
* Rate-based rules slow down abusive clients.
* Shield Standard is always present.
* Shield Advanced is added for critical production systems with DDoS risk.

WAF is most effective when the origin cannot be bypassed. For example, with CloudFront plus an ALB origin, restrict the ALB so users cannot directly hit it and avoid WAF/CloudFront.

### Monitoring and logging

Monitor:

* WAF blocked requests.
* WAF counted requests before enabling block mode.
* Rate-based rule matches.
* Top blocked IPs, countries, paths, and user agents.
* CloudFront or ALB 4xx and 5xx rates.
* Origin latency and error rate.
* Shield events and DDoS metrics for protected resources.

WAF logs can be sent to destinations such as CloudWatch Logs, S3, or Kinesis Data Firehose, depending on configuration. Logs are useful for tuning false positives and understanding attack patterns.

### Terraform notes

In Terraform, WAF and Shield commonly use:

* `aws_wafv2_web_acl`
* `aws_wafv2_web_acl_association`
* `aws_wafv2_ip_set`
* `aws_wafv2_regex_pattern_set`
* `aws_wafv2_rule_group`
* `aws_shield_protection`
* `aws_shield_subscription`

Common mistakes:

* Creating a CloudFront WAF web ACL in the wrong scope. CloudFront uses `CLOUDFRONT` scope and is managed from `us-east-1`.
* Enabling block mode before checking false positives.
* Forgetting to associate the web ACL with the resource.
* Assuming WAF protects non-HTTP traffic.
* Leaving the origin publicly reachable and bypassable.
* Not enabling logs, making tuning difficult.
* Assuming Shield Advanced protects every resource automatically; resources must be configured for protection.

---

## 27. AWS Cost Explorer and Trusted Advisor

**AWS Cost Explorer** and **AWS Trusted Advisor** are operational visibility tools. Cost Explorer helps you understand AWS spend. Trusted Advisor inspects your AWS environment and recommends improvements across cost, security, performance, fault tolerance, service quotas, and operational excellence.

### AWS Cost Explorer

**Cost Explorer** is used to analyze AWS cost and usage over time. It helps answer questions like:

* Which service is driving this month's bill?
* Which account, Region, tag, or usage type changed?
* How much are we forecasted to spend?
* Did a deployment or workload change increase cost?
* Are Reserved Instances or Savings Plans helping?

Cost Explorer supports filtering and grouping by dimensions such as service, linked account, Region, usage type, purchase option, tag, and cost category. In AWS Organizations, the management account can view consolidated cost data across member accounts.

Common Cost Explorer uses:

* Monthly cost review.
* Service-level cost breakdowns.
* Forecasting future spend.
* Finding cost spikes.
* Checking Savings Plans and Reserved Instance coverage.
* Reviewing rightsizing recommendations for EC2.
* Building chargeback or showback views using tags and cost categories.

Cost Explorer is not real-time. Cost and usage data can lag, so use CloudWatch metrics or service-specific dashboards for immediate operational signals.

### AWS Trusted Advisor

**AWS Trusted Advisor** checks your AWS environment and provides recommendations. The main categories are:

* Cost optimization.
* Performance.
* Security.
* Fault tolerance.
* Service limits or service quotas.
* Operational excellence.

Examples of Trusted Advisor findings:

* Idle or underused resources.
* Exposed security groups.
* MFA not enabled on root.
* Service quota usage approaching limits.
* Missing fault-tolerance configuration.
* Opportunities to reduce cost.

Trusted Advisor access depends on the AWS Support plan. All accounts get access to selected core checks. Broader check access and API access require eligible paid support plans such as Business Support+, Enterprise Support, or Unified Operations.

### How they work together

Cost Explorer shows where money is going. Trusted Advisor points out specific improvement opportunities.

Example workflow:

1. Cost Explorer shows EC2 cost increased in `prod`.
2. Group by usage type, Region, account, or tag to isolate the source.
3. Trusted Advisor or Compute Optimizer highlights idle or oversized instances.
4. Engineering reviews whether the recommendation is safe.
5. After cleanup, Cost Explorer confirms the cost trend improved.

Do not blindly apply cost recommendations. A resource that looks idle may be a standby, disaster recovery component, batch worker, or seasonal system.

### Monitoring and operations

Good FinOps habits:

* Review Cost Explorer weekly or monthly.
* Use AWS Budgets for alerts.
* Use cost allocation tags consistently.
* Create cost categories for teams, products, or environments.
* Review Trusted Advisor cost and security findings regularly.
* Track recommendations to owners, not just dashboards.
* Watch service quota findings before launches or traffic events.

### Terraform notes

Cost Explorer and Trusted Advisor are mostly visibility services, not infrastructure that you heavily build with Terraform. Terraform is more often used for supporting controls:

* `aws_budgets_budget`
* `aws_ce_anomaly_monitor`
* `aws_ce_anomaly_subscription`
* IAM policies for billing, Cost Explorer, Support, and Trusted Advisor access.
* Consistent resource tagging for cost allocation.

Common mistakes:

* Not tagging resources, making cost allocation hard.
* Looking only at total bill instead of grouping by account, service, Region, and tag.
* Ignoring forecasted spend until the invoice arrives.
* Treating Trusted Advisor recommendations as automatically safe.
* Not having the right Support plan for full Trusted Advisor checks or API access.
* Forgetting that cost data can lag.

---

## 28. Amazon ElastiCache

**Amazon ElastiCache** is a managed in-memory data store used for caching, fast lookups, sessions, rate limits, leaderboards, queues, and temporary application state. It helps reduce database load and improve latency by keeping frequently used data in memory.

ElastiCache supports:

* **Valkey**: open-source Redis-compatible engine, commonly used for new Redis-style workloads.
* **Redis OSS**: Redis-compatible in-memory data store.
* **Memcached**: simpler distributed cache for key-value caching.

Valkey and Redis OSS support richer data structures, replication, persistence options, pub/sub, sorted sets, streams, and more advanced cache patterns. Memcached is simpler and often used for straightforward ephemeral caching.

### Common use cases

* Cache database query results.
* Store application sessions.
* Store rate-limit counters.
* Speed up expensive API responses.
* Cache authentication or authorization lookups.
* Store short-lived feature flags or config.
* Implement leaderboards or counters.

ElastiCache is usually placed in private subnets. Applications connect over the VPC using security groups. For Valkey or Redis OSS, the default port is often `6379`; for Memcached, the default port is often `11211`.

### High availability and scaling

For Valkey and Redis OSS, production clusters often use replication groups with Multi-AZ and automatic failover. A primary node handles writes, and replicas can handle reads and failover. Cluster mode can shard data across node groups for larger datasets or higher throughput.

Important design points:

* Use Multi-AZ for important production caches.
* Size memory with headroom to avoid evictions.
* Understand your eviction policy.
* Use TTLs so stale cache entries expire.
* Design the app to survive cache misses or cache failover.
* Do not treat cache as the only copy of critical durable data unless the architecture explicitly accepts that risk.

### Security

ElastiCache security usually involves:

* Private subnet placement.
* Security groups allowing only application clients.
* Encryption in transit, meaning TLS.
* Encryption at rest where supported.
* Redis/Valkey AUTH, RBAC users, or IAM authentication where supported.
* KMS keys for encryption at rest when customer managed keys are required.

IAM authentication for Valkey and Redis OSS uses short-lived IAM authentication tokens and requires TLS. For many apps, Redis/Valkey AUTH or RBAC is still common.

### Monitoring and troubleshooting

Watch:

* CPU utilization.
* Memory usage and freeable memory.
* Evictions.
* Cache hit ratio.
* Current connections.
* Replication lag.
* Network bytes in/out.
* Engine-specific errors.

Common problems:

* Security group does not allow client access.
* App is in a subnet or VPC that cannot route to the cache.
* Cache memory fills up and starts evicting useful keys.
* Hot keys overload one shard.
* TTLs are missing or too long.
* Client connection pool is too small or too large.
* App treats cache as durable storage and loses data during failover.

### Terraform notes

Common Terraform resources:

* `aws_elasticache_subnet_group`
* `aws_elasticache_replication_group`
* `aws_elasticache_cluster`
* `aws_elasticache_parameter_group`
* `aws_elasticache_user`
* `aws_elasticache_user_group`

Common mistakes:

* Putting ElastiCache in public subnets.
* Forgetting subnet groups.
* Opening cache ports too broadly.
* Not enabling Multi-AZ for production.
* Under-sizing memory and causing evictions.
* Trying to enable some encryption settings after creation when replacement or migration is required.

---

## 29. Amazon Cognito

**Amazon Cognito** provides identity features for web and mobile applications. It is commonly used for user sign-up, sign-in, password reset, MFA, social login, enterprise federation, JWT tokens, and temporary AWS credentials for authenticated users.

Cognito has two main parts:

* **User pools**: user directories and authentication for applications.
* **Identity pools**: federate authenticated users into temporary AWS credentials through IAM roles.

Simple rule: user pools answer "who is the user?" Identity pools answer "what AWS credentials can this user get?"

### User pools

A **user pool** is a managed user directory. It can store users, passwords, attributes, groups, MFA settings, app clients, domains, and federation settings. From an application perspective, a user pool can act as an OIDC identity provider and issue JWTs.

Common user pool features:

* Sign-up and sign-in.
* Email and phone verification.
* Password policies.
* MFA with SMS, email, TOTP, and newer passwordless options where supported.
* Hosted UI or managed login.
* Social identity providers such as Google, Apple, Facebook, and Amazon.
* SAML and OIDC enterprise federation.
* Lambda triggers for custom authentication, validation, migration, and token customization.
* Groups and custom attributes.

Important tokens:

* **ID token**: identity information about the user.
* **Access token**: authorization scopes and group claims for APIs.
* **Refresh token**: used to get new tokens without signing in again.

APIs often validate Cognito JWTs using API Gateway authorizers, ALB authentication, application middleware, or custom JWT validation.

### Identity pools

An **identity pool** can exchange an authenticated identity for temporary AWS credentials. It can work with Cognito user pools, social identity providers, SAML/OIDC providers, or developer-authenticated identities.

Identity pools are useful when a client app needs direct, limited access to AWS resources, such as:

* Uploading a file to S3.
* Calling AppSync.
* Reading a scoped DynamoDB item.
* Publishing to IoT Core.

Be careful: identity pools give AWS credentials to clients. IAM roles must be tightly scoped.

### Security and operations

Good Cognito practices:

* Use strong password policies and MFA where appropriate.
* Use custom domains and HTTPS for production login flows.
* Keep app client callback and logout URLs strict.
* Do not put app client secrets in browser or mobile apps.
* Validate JWT issuer, audience/client ID, expiration, and signature.
* Use groups or custom claims carefully for authorization.
* Monitor failed sign-ins, account takeover signals, and unusual traffic.
* Understand SMS/email delivery limits and configuration.

Common mistakes:

* Confusing user pools with identity pools.
* Using ID tokens where access tokens are expected.
* Trusting JWT claims without validating the signature.
* Over-permissive identity pool IAM roles.
* Wrong callback URL or OAuth flow settings.
* Forgetting hosted UI domain configuration.
* Relying only on Cognito groups for complex authorization logic.

### Terraform notes

Common Terraform resources:

* `aws_cognito_user_pool`
* `aws_cognito_user_pool_client`
* `aws_cognito_user_pool_domain`
* `aws_cognito_user_group`
* `aws_cognito_identity_pool`
* `aws_cognito_identity_pool_roles_attachment`
* `aws_lambda_permission` for Cognito triggers

Cognito changes can affect live authentication flows, so review Terraform plans carefully. Some settings are hard to change after creation, and app client changes can break login flows if callback URLs, OAuth scopes, or token settings are wrong.

---

## 30. AWS EKS

**Amazon EKS**, or Elastic Kubernetes Service, is AWS's managed Kubernetes service. AWS manages the Kubernetes control plane, while you manage the workloads, worker capacity, Kubernetes add-ons, networking, IAM integration, upgrades, observability, and application reliability.

EKS is used when teams want Kubernetes APIs and ecosystem tooling without running the Kubernetes control plane themselves.

### EKS architecture model

```text
AWS account / Region
+-- VPC
    +-- Public subnets
    |   +-- NAT gateways
    |   +-- Internet-facing load balancers
    +-- Private subnets
    |   +-- EKS worker nodes or Fargate pods
    |   +-- Application pods
    +-- EKS cluster
        +-- AWS-managed control plane
        |   +-- API server
        |   +-- etcd
        |   +-- scheduler
        |   +-- controller manager
        +-- Data plane
            +-- Managed node groups
            +-- Self-managed nodes
            +-- Fargate profiles
```

The control plane is highly available and managed by AWS. The data plane is where your pods run. Data plane capacity can be EC2-backed nodes, Fargate, or a mix depending on the workload.

### Main AWS resources in EKS

| AWS resource | Purpose |
|---|---|
| **EKS cluster** | Managed Kubernetes control plane |
| **VPC** | Network boundary for the cluster |
| **Subnets** | Where nodes, pods, and load balancers run |
| **Security groups** | Firewall rules for control plane, nodes, and load balancers |
| **IAM roles** | Permissions for cluster, nodes, add-ons, and pods |
| **EC2 instances** | Worker nodes when using node groups |
| **Auto Scaling Groups** | Backing capacity for managed/self-managed node groups |
| **EBS volumes** | Persistent block storage for pods |
| **EFS file systems** | Shared file storage for pods |
| **ALB/NLB** | Exposes Kubernetes services and ingress traffic |
| **CloudWatch** | Logs, metrics, Container Insights, and alarms |
| **ECR** | Stores container images |
| **Route 53** | DNS records for applications |
| **KMS** | Encryption for Kubernetes secrets and volumes |

### Control plane vs data plane

```text
AWS manages                         You manage
-----------                         ----------
EKS control plane                   Worker nodes / Fargate
API server                          Pods
etcd                                Deployments, Services, Ingress
scheduler                           Add-ons
controller manager                  IAM and RBAC mappings
control plane availability          Application availability
```

AWS handles the Kubernetes control plane availability, but that does not automatically make your application highly available. Your workloads still need enough replicas, multiple AZs, healthy nodes, correct disruption budgets, and working dependencies.

### Basic request flow

```text
User
-> Route 53 DNS
-> AWS load balancer: ALB or NLB
-> Kubernetes Ingress or Service
-> Pod
-> Application container
```

Example:

```text
api.example.com
-> ALB
-> Ingress
-> Service
-> Deployment pods
```

The AWS Load Balancer Controller commonly creates ALBs from Kubernetes `Ingress` objects and NLBs from Kubernetes `Service` objects.

### Important EKS add-ons

| Add-on | Kubernetes component | Purpose |
|---|---|---|
| **VPC CNI** | `aws-node` DaemonSet | Gives pods IPs from the VPC |
| **CoreDNS** | `coredns` Deployment | Kubernetes DNS |
| **kube-proxy** | `kube-proxy` DaemonSet | Service networking |
| **EBS CSI Driver** | CSI controller/node pods | Mounts EBS volumes into pods |
| **EFS CSI Driver** | CSI controller/node pods | Mounts EFS file systems into pods |
| **AWS Load Balancer Controller** | Deployment | Creates ALB/NLB resources |
| **Cluster Autoscaler** | Deployment | Adds/removes EC2 nodes based on pending pods |
| **Karpenter** | Controller | Provisions right-sized nodes quickly |
| **Metrics Server** | Deployment | Enables `kubectl top` and HPA CPU/memory scaling |
| **ExternalDNS** | Deployment | Creates Route 53 DNS records |
| **Fluent Bit / CloudWatch Agent** | DaemonSet | Sends logs and metrics to CloudWatch |
| **Prometheus/Grafana** | Deployments/StatefulSets | Monitoring dashboards and alerting |
| **cert-manager** | Deployment | Manages Kubernetes TLS certificates |

Some add-ons can be installed as EKS managed add-ons. Others are commonly installed with Helm, Kubernetes manifests, or GitOps tooling.

### Add-ons mapped to Kubernetes resources

| Add-on | Kubernetes resources usually created |
|---|---|
| VPC CNI | `DaemonSet/aws-node`, `ServiceAccount`, `ClusterRole` |
| CoreDNS | `Deployment/coredns`, `Service/kube-dns`, `ConfigMap` |
| kube-proxy | `DaemonSet/kube-proxy`, `ConfigMap` |
| EBS CSI Driver | `Deployment/ebs-csi-controller`, `DaemonSet/ebs-csi-node`, `CSIDriver`, `StorageClass` |
| AWS Load Balancer Controller | `Deployment`, `ServiceAccount`, `IngressClass`, `TargetGroupBinding` |
| Metrics Server | `Deployment`, `APIService`, `Service` |
| Cluster Autoscaler | `Deployment`, `ServiceAccount`, `ClusterRole` |
| Karpenter | `Deployment`, `ServiceAccount`, `NodePool`, `EC2NodeClass` |
| ExternalDNS | `Deployment`, `ServiceAccount`, `ClusterRole` |
| Fluent Bit | `DaemonSet`, `ConfigMap`, `ServiceAccount` |
| Prometheus | `StatefulSet/Deployment`, `ServiceMonitor`, `PrometheusRule`, `PVC` |
| Grafana | `Deployment`, `Service`, `ConfigMap`, `Secret` |
| cert-manager | `Deployments`, `Issuer`, `ClusterIssuer`, `Certificate` |

### Networking model

```text
VPC
+-- Public subnet AZ-a
|   +-- ALB / NAT gateway
+-- Public subnet AZ-b
|   +-- ALB / NAT gateway
+-- Private subnet AZ-a
|   +-- Worker node
|       +-- Pod IP from VPC CIDR
|       +-- Pod IP from VPC CIDR
+-- Private subnet AZ-b
    +-- Worker node
        +-- Pod IP from VPC CIDR
        +-- Pod IP from VPC CIDR
```

With the AWS VPC CNI, pods usually get real VPC IP addresses.

```text
Pod IP = VPC IP
```

This is different from many Kubernetes environments where pod IPs come from an overlay network. In EKS, subnet sizing matters because pods consume VPC IPs. A cluster can fail to schedule pods even when EC2 nodes exist if the subnets are out of available IP addresses.

Important networking notes:

* Use private subnets for worker nodes in most production clusters.
* Use public subnets for internet-facing ALBs/NLBs and NAT gateways.
* Tag subnets correctly so the AWS Load Balancer Controller can discover them.
* Private clusters may need VPC endpoints for EKS, ECR API, ECR Docker, S3, STS, CloudWatch Logs, KMS, and other AWS services.
* The EKS API endpoint can be public, private, or both.

### IAM and Kubernetes access

```text
IAM role for EKS cluster
-> Allows EKS to manage cluster control plane operations

IAM role for node group
-> Allows EC2 nodes to join the cluster, pull ECR images, and write logs

IAM role for service account / Pod Identity
-> Allows individual pods to access AWS services
```

EKS has two access layers:

* **AWS IAM** controls who can authenticate to the EKS API and call AWS APIs.
* **Kubernetes RBAC** controls what users and service accounts can do inside the cluster.

For pod access to AWS services, prefer pod-level IAM instead of broad permissions on the node role.

Common pod identity patterns:

* **IRSA**, or IAM Roles for Service Accounts.
* **EKS Pod Identity**, where available and appropriate.

Example:

```text
external-dns pod
-> Kubernetes service account
-> IRSA or Pod Identity role
-> Route 53 permissions
```

Common IAM users:

| Component | AWS permission needed |
|---|---|
| AWS Load Balancer Controller | ALB/NLB, target groups, security groups |
| ExternalDNS | Route 53 |
| EBS CSI Driver | EBS volumes and snapshots |
| EFS CSI Driver | EFS mount targets and access points |
| Cluster Autoscaler | Auto Scaling Groups and EC2 |
| Karpenter | EC2, pricing, launch templates, and IAM pass role |
| Fluent Bit | CloudWatch Logs |
| cert-manager | Route 53 DNS validation, optional |

### Storage model

```text
Pod
-> PersistentVolumeClaim
-> StorageClass
-> CSI driver
-> AWS storage resource
```

Common storage choices:

* **EBS**: block storage for one pod/node attachment pattern. EBS volumes are AZ-specific.
* **EFS**: shared file storage that can be mounted by many pods across AZs.
* **S3**: object storage accessed by the application SDK, not a normal POSIX filesystem.

For EBS-backed pods, the scheduler must place the pod in the same AZ as the EBS volume. During AZ failure or rescheduling, this can matter a lot. Stateful workloads need careful topology, backup, and failover design.

### Scaling model

EKS scaling has several layers:

* **Horizontal Pod Autoscaler**, or HPA, scales pod replicas.
* **Vertical Pod Autoscaler**, or VPA, recommends or changes pod resource requests.
* **Cluster Autoscaler** adds/removes nodes when pods cannot schedule.
* **Karpenter** provisions right-sized nodes based on pending pods.
* **Managed node group scaling** controls EC2 minimum, maximum, and desired capacity.

Important scaling gotcha: pod CPU and memory requests must be realistic. Kubernetes schedules based on requests, not actual usage. Bad requests lead to poor bin packing, pending pods, node pressure, or surprise cost.

### Common production EKS layout

```text
EKS cluster
+-- kube-system
|   +-- aws-node
|   +-- coredns
|   +-- kube-proxy
|   +-- ebs-csi-driver
|   +-- metrics-server
+-- ingress
|   +-- aws-load-balancer-controller
+-- monitoring
|   +-- prometheus
|   +-- grafana
|   +-- alertmanager
+-- logging
|   +-- fluent-bit
+-- cert-manager
|   +-- cert-manager pods
+-- application namespaces
    +-- dev
    +-- staging
    +-- production
```

Production clusters should usually include:

* Multiple AZs.
* Multiple node groups or node pools.
* Pod disruption budgets for important services.
* Topology spread constraints or pod anti-affinity.
* Centralized logging and metrics.
* Least-privilege IAM for add-ons and workloads.
* Upgrade plan for Kubernetes, node AMIs, and add-ons.

### Operations and troubleshooting

Watch:

* Pods stuck `Pending`.
* Pods in `CrashLoopBackOff`.
* Node `NotReady`.
* CoreDNS failures.
* VPC CNI IP allocation errors.
* ALB/NLB target health.
* Image pull errors from ECR.
* Cluster Autoscaler or Karpenter events.
* CPU, memory, and disk pressure.

Useful commands:

* `kubectl get nodes`
* `kubectl get pods -A`
* `kubectl describe pod <pod>`
* `kubectl logs <pod>`
* `kubectl get events -A --sort-by=.lastTimestamp`
* `kubectl describe node <node>`

Common EKS incidents:

* Nodes cannot join because the node IAM role, bootstrap, security group, or endpoint access is wrong.
* Pods cannot start because ECR access, image tags, or pull secrets are wrong.
* Pods cannot call AWS APIs because IRSA or Pod Identity is misconfigured.
* Services are unreachable because load balancer controller permissions or subnet tags are wrong.
* Pods cannot schedule because the cluster is out of node capacity or subnet IPs.
* DNS fails because CoreDNS is unhealthy or overloaded.

### Terraform notes

Common Terraform resources:

* `aws_eks_cluster`
* `aws_eks_node_group`
* `aws_eks_addon`
* `aws_iam_openid_connect_provider`
* `aws_iam_role`
* `aws_iam_role_policy_attachment`
* `aws_security_group`
* `aws_subnet`

Many teams use the community `terraform-aws-eks` module because production EKS has many connected resources.

Common Terraform mistakes:

* Creating subnets that are too small for pod IP usage.
* Forgetting subnet tags for load balancers.
* Giving node roles broad permissions instead of using pod-level IAM.
* Not planning add-on versions before cluster upgrades.
* Upgrading the control plane without upgrading node groups and add-ons.
* Not enabling enough logs, metrics, and alerts for troubleshooting.

---

## Interview Scenario: Availability Zone Failure

Question: An AWS Availability Zone goes down. How should your system be designed to handle this, and what would you check during the incident?

Your system should be designed so **one AZ failure does not take the service down**.

### Design expectations

1. **Run across multiple AZs**

   * EC2, EKS, or ECS workloads should run across at least 2-3 AZs.
   * Auto Scaling Groups, node groups, and service subnets should span multiple AZs.

2. **Use load balancers across AZs**

   * ALB or NLB should route traffic only to healthy targets.
   * Health checks should remove failed AZ targets automatically.
   * Cross-zone load balancing should be understood and configured intentionally.

3. **Use Multi-AZ databases**

   * RDS Multi-AZ should be used for automatic failover.
   * Aurora should have instances across multiple AZs.
   * Read replicas can help read scaling, but they are not a replacement for Multi-AZ failover design.

4. **Avoid single-AZ dependencies**

   * NAT gateways, caches, EBS volumes, internal services, worker nodes, and deployment tooling should not all depend on one AZ.
   * For NAT, a common production pattern is one NAT gateway per AZ with private subnets routed to the local NAT gateway.

5. **Keep enough capacity in remaining AZs**

   * Healthy AZs should have enough capacity to absorb traffic after one AZ is lost.
   * Autoscaling should be able to add capacity quickly, but the system should not rely only on slow scale-out during an outage.

### Incident checks

1. **Confirm the scope**

   * Check AWS Health Dashboard.
   * Identify the affected AZ and services.
   * Confirm whether the issue is one AZ, one service, one VPC, or the application itself.

2. **Check load balancer health**

   * Review `HealthyHostCount`.
   * Review `UnHealthyHostCount`.
   * Review `TargetResponseTime`.
   * Review ALB/NLB `4xx` and `5xx` metrics.
   * Confirm traffic is shifting away from unhealthy targets.

3. **Check application capacity**

   * Check CPU, memory, latency, error rate, and request count by AZ.
   * Confirm remaining instances, pods, or tasks are not overloaded.
   * Scale out in healthy AZs if needed.

4. **Check database failover**

   * For RDS, verify whether failover happened successfully.
   * Check database connections, latency, locks, and error rates.
   * Confirm the application reconnect behavior is working.

5. **Check AZ-specific dependencies**

   * NAT gateways.
   * ElastiCache or Redis nodes.
   * EBS-backed workloads.
   * Internal services.
   * Worker queues and consumers.
   * Private endpoints or network appliances.

6. **Reduce impact**

   * Disable traffic to the bad AZ if needed.
   * Scale out in healthy AZs.
   * Pause non-critical jobs.
   * Increase retry backoff if systems are recovering.
   * Communicate status and mitigation steps.

### Interview-style answer

"I would design the system active-active across multiple AZs, with load balancers, autoscaling, Multi-AZ databases, and no single-AZ dependencies. During the incident, I would confirm the affected AZ, check load balancer target health, verify traffic has moved to healthy AZs, make sure remaining capacity is enough, and confirm database failover and dependent services are healthy."

---

## Interview Scenario: AWS Bill Spike

Question: Your AWS bill suddenly spikes overnight. How would you identify the cause?

Start by identifying **what changed, where the cost is coming from, and whether the spend is still increasing**.

### Investigation steps

1. **Use Cost Explorer**

   * Compare yesterday, today, week-to-date, and month-to-date spend.
   * Group by service, linked account, Region, usage type, tag, and cost category.
   * Look for one service or account that changed sharply.

2. **Check usage breakdown**

   * Look at usage quantity, not only dollars.
   * Common spike sources include EC2, NAT gateway data processing, inter-AZ data transfer, CloudWatch Logs, S3 requests, EBS snapshots, RDS, Lambda invocations, and data transfer out.

3. **Review recent changes**

   * Check deployments, Terraform applies, autoscaling events, batch jobs, migrations, and new logging changes.
   * Review CloudTrail for resource creation or configuration changes.

4. **Look for runaway resources**

   * EC2 instances left running.
   * EBS volumes or snapshots accumulating.
   * NAT gateway traffic spike.
   * CloudWatch logs ingesting too much data.
   * Lambda retry loops.
   * S3 lifecycle rules missing or misconfigured.
   * Autoscaling misconfiguration.

5. **Stop or contain the spend**

   * Disable runaway jobs.
   * Scale down accidental capacity.
   * Add temporary rate limits.
   * Reduce excessive logs.
   * Fix retry loops.
   * Notify owners and document the cause.

### Interview-style answer

"I would start in Cost Explorer and group spend by service, account, Region, usage type, and tags to find what changed. Then I would correlate the spike with recent deployments, autoscaling events, CloudTrail activity, and service metrics. Common causes are runaway EC2, NAT/data transfer, CloudWatch Logs, snapshots, Lambda retries, or misconfigured autoscaling. After identifying the source, I would contain the spend, notify the owner, and add a budget or anomaly alert to catch it earlier next time."

---
