import SwiftUI

struct Flashcard: Identifiable, Hashable {
    let id = UUID()
    let service: String
    let category: Category
    let prompt: String
    let answer: String
    let takeaway: String

    enum Category: String, CaseIterable, Identifiable {
        case compute = "Compute"
        case storage = "Storage"
        case database = "Database"
        case network = "Network"
        case security = "Security"
        case integration = "Integration"
        case architecture = "Architecture"

        var id: String { rawValue }
        var symbol: String {
            switch self {
            case .compute: "cpu"
            case .storage: "externaldrive"
            case .database: "cylinder"
            case .network: "network"
            case .security: "lock.shield"
            case .integration: "arrow.triangle.branch"
            case .architecture: "building.2"
            }
        }
        var tint: Color {
            switch self {
            case .compute: .orange
            case .storage: .blue
            case .database: .purple
            case .network: .cyan
            case .security: .green
            case .integration: .pink
            case .architecture: .yellow
            }
        }
    }
}

extension Flashcard {
    private static func fact(_ service: String, _ category: Category, _ answer: String, _ takeaway: String = "Think about the requirement this fact helps satisfy in an exam scenario.") -> Flashcard {
        Flashcard(service: service, category: category, prompt: "What key concept should you recall?", answer: answer, takeaway: takeaway)
    }

    static let deck: [Flashcard] = [
        .init(service: "Lambda", category: .compute, prompt: "Maximum execution time?", answer: "15 minutes", takeaway: "For longer jobs, use ECS, Batch, Step Functions, or an async pattern."),
        .init(service: "Lambda", category: .compute, prompt: "How do you remove cold starts?", answer: "Provisioned Concurrency", takeaway: "It keeps initialized environments ready for predictable latency."),
        .init(service: "EC2", category: .compute, prompt: "Cheapest interruptible capacity?", answer: "Spot Instances", takeaway: "Use for fault-tolerant, flexible workloads; interruption notice is 2 minutes."),
        .init(service: "EC2", category: .compute, prompt: "Which placement group has lowest latency?", answer: "Cluster placement group", takeaway: "Places instances close together in one AZ; ideal for HPC."),
        .init(service: "Auto Scaling", category: .compute, prompt: "Keep CPU near 50% automatically?", answer: "Target tracking", takeaway: "It adds or removes capacity to maintain a chosen metric target."),
        .init(service: "ECS", category: .compute, prompt: "Serverless containers with no EC2 management?", answer: "Fargate", takeaway: "Pay for task vCPU and memory without managing hosts."),
        .init(service: "S3", category: .storage, prompt: "Maximum object size?", answer: "50 TB", takeaway: "Use multipart upload for large objects."),
        .init(service: "S3", category: .storage, prompt: "Requirement for Cross-Region Replication?", answer: "Versioning enabled", takeaway: "Both source and destination buckets need versioning."),
        .init(service: "S3", category: .storage, prompt: "Durability of S3 Standard?", answer: "11 nines", takeaway: "99.999999999% durability; availability is a separate measure."),
        .init(service: "EBS", category: .storage, prompt: "Can an EBS volume move across AZs?", answer: "No — it is AZ-locked", takeaway: "Use a snapshot to create a volume in another AZ or Region."),
        .init(service: "EFS", category: .storage, prompt: "Shared Linux file system protocol?", answer: "NFS", takeaway: "EFS is managed, elastic NFS storage with multi-AZ access."),
        .init(service: "FSx for Lustre", category: .storage, prompt: "Best fit?", answer: "HPC / ML high-performance file system", takeaway: "It integrates with S3 for data-heavy compute workloads."),
        .init(service: "RDS", category: .database, prompt: "Multi-AZ is for what?", answer: "High availability and automatic failover", takeaway: "The standby is synchronous; it does not serve read traffic."),
        .init(service: "RDS", category: .database, prompt: "Read Replicas are what kind of replication?", answer: "Asynchronous", takeaway: "Use them for read scaling, not automatic failover."),
        .init(service: "Aurora", category: .database, prompt: "Copies of data across 3 AZs?", answer: "6 copies", takeaway: "Aurora storage can auto-scale up to 256 TiB."),
        .init(service: "DynamoDB", category: .database, prompt: "Maximum item size?", answer: "400 KB", takeaway: "Store larger blobs in S3 and keep a pointer in DynamoDB."),
        .init(service: "DynamoDB", category: .database, prompt: "Microsecond read caching?", answer: "DAX", takeaway: "DynamoDB Accelerator is an in-memory cache for read-heavy workloads."),
        .init(service: "ElastiCache", category: .database, prompt: "Persistence and Pub/Sub?", answer: "Redis", takeaway: "Choose Memcached for simple, multi-threaded caching."),
        .init(service: "VPC", category: .network, prompt: "Reserved IP addresses per subnet?", answer: "5", takeaway: "Account for them when choosing subnet capacity."),
        .init(service: "Security Groups", category: .network, prompt: "Stateful or stateless?", answer: "Stateful", takeaway: "They have allow rules only; return traffic is automatically allowed."),
        .init(service: "Network ACLs", category: .network, prompt: "Stateful or stateless?", answer: "Stateless", takeaway: "They support allow and deny rules; configure both traffic directions."),
        .init(service: "NAT Gateway", category: .network, prompt: "Where is it placed?", answer: "Public subnet", takeaway: "It is AZ-specific; use one per AZ for resilient private-subnet egress."),
        .init(service: "CloudFront", category: .network, prompt: "Keep S3 accessible only through CloudFront?", answer: "Origin Access Control (OAC)", takeaway: "OAC is the current pattern for restricting S3 origins."),
        .init(service: "Route 53", category: .network, prompt: "AWS-resource record with free queries?", answer: "Alias record", takeaway: "Alias records point at supported AWS resources, unlike a CNAME at the zone apex."),
        .init(service: "IAM", category: .security, prompt: "Temporary AWS credentials?", answer: "IAM Role via STS", takeaway: "Roles avoid long-lived access keys and enable cross-account access."),
        .init(service: "KMS", category: .security, prompt: "Direct symmetric encryption limit?", answer: "4 KB", takeaway: "For larger data, use envelope encryption with a data key."),
        .init(service: "WAF", category: .security, prompt: "Which layer does it protect?", answer: "Layer 7", takeaway: "Use it for HTTP(S) threats such as SQL injection, XSS, and rate limits."),
        .init(service: "Shield Standard", category: .security, prompt: "Cost and protection?", answer: "Free L3/L4 DDoS protection", takeaway: "Shield Advanced adds broader protection and cost safeguards."),
        .init(service: "SQS", category: .integration, prompt: "Maximum message size?", answer: "1 MiB", takeaway: "For larger payloads, store data in S3 and send a reference through SQS."),
        .init(service: "SQS", category: .integration, prompt: "Maximum retention period?", answer: "14 days", takeaway: "Use DLQs to isolate repeatedly failing messages."),
        .init(service: "SNS", category: .integration, prompt: "Fan-out to multiple consumers?", answer: "SNS", takeaway: "Publish once to SNS; deliver to SQS queues, Lambda, email, and more."),
        .init(service: "EventBridge", category: .integration, prompt: "Event bus with content-based routing?", answer: "EventBridge", takeaway: "It can route AWS, SaaS, and custom events by rules."),
        .init(service: "API Gateway", category: .integration, prompt: "Default REST API integration timeout?", answer: "29 seconds", takeaway: "Regional and private REST APIs can request a higher timeout; asynchronous designs also help long jobs."),
        .init(service: "Well-Architected", category: .architecture, prompt: "Least operational effort means…", answer: "Prefer managed/serverless services", takeaway: "The exam often rewards AWS-managed options over self-managed infrastructure."),
        .init(service: "Disaster Recovery", category: .architecture, prompt: "Lowest RTO and RPO strategy?", answer: "Multi-site active-active", takeaway: "It is also the most expensive DR option."),
        .init(service: "Cost", category: .architecture, prompt: "Steady 1–3 year workload discount?", answer: "Savings Plans or Reserved Instances", takeaway: "Savings Plans are more flexible; RIs can offer capacity reservation."),
        .init(service: "Architecture", category: .architecture, prompt: "Decouple app components?", answer: "Use a queue (SQS)", takeaway: "Queues absorb bursts and let producers and consumers scale independently."),

        // Compute and storage
        fact("EC2", .compute, "Instance store is ephemeral and is lost on stop or termination.", "Use EBS for persistent block storage."),
        fact("EC2", .compute, "Spread placement groups support a maximum of 7 instances per Availability Zone.", "Use them for a small number of critical, isolated instances."),
        fact("EC2", .compute, "Partition placement groups isolate partitions for distributed workloads such as Hadoop and Cassandra."),
        fact("EC2", .compute, "Dedicated Hosts are for per-socket, per-core licensing and compliance requirements."),
        fact("Lambda", .compute, "Memory ranges from 128 MB to 10 GB; CPU scales with memory."),
        fact("Lambda", .compute, "The default regional concurrency quota is 1,000 executions."),
        fact("Lambda", .compute, "Ephemeral /tmp storage can be configured from 512 MB to 10 GB."),
        fact("ECS", .compute, "A task role gives application containers AWS permissions; an execution role pulls images and sends logs."),
        fact("Elastic Beanstalk", .compute, "Beanstalk manages deployments and infrastructure but you retain control of underlying AWS resources."),
        fact("S3", .storage, "S3 Standard-IA has a 30-day minimum storage duration and retrieval fees."),
        fact("S3 Glacier", .storage, "Glacier Instant Retrieval offers millisecond retrieval with a 90-day minimum."),
        fact("S3 Glacier", .storage, "Glacier Deep Archive retrieval takes 12–48 hours and has a 180-day minimum."),
        fact("S3", .storage, "Lifecycle rules automate transitions between S3 storage classes."),
        fact("EBS gp3", .storage, "gp3 includes a baseline of 3,000 IOPS and can scale to 16,000 IOPS."),
        fact("EBS gp2", .storage, "gp2 provides 3 IOPS per GB and can burst to 3,000 IOPS."),
        fact("EBS io2 Block Express", .storage, "io2 Block Express can deliver up to 256,000 IOPS."),
        fact("EBS", .storage, "st1 is throughput-optimized HDD for big data and logs; sc1 is low-cost cold HDD."),
        fact("EFS", .storage, "EFS offers General Purpose or Max I/O performance modes."),
        fact("EFS", .storage, "EFS throughput modes are Bursting, Provisioned, and Elastic."),
        fact("FSx", .storage, "FSx for Windows uses SMB, NTFS, and Active Directory integration."),
        fact("FSx", .storage, "FSx for NetApp ONTAP supports NFS, SMB, and iSCSI."),

        // Databases
        fact("RDS", .database, "Automated backups support a retention period from 1 to 35 days."),
        fact("RDS", .database, "You cannot SSH into an RDS DB instance."),
        fact("RDS Proxy", .database, "RDS Proxy provides connection pooling, IAM authentication, and faster failover."),
        fact("Aurora", .database, "Aurora Global Database provides cross-Region replication typically under one second."),
        fact("Aurora", .database, "An Aurora cluster supports one writer and up to 15 reader instances."),
        fact("DynamoDB", .database, "One WCU supports one 1 KB write per second."),
        fact("DynamoDB", .database, "One RCU supports one strongly consistent 4 KB read per second."),
        fact("DynamoDB", .database, "Global Tables provide multi-Region active-active replication."),
        fact("DynamoDB", .database, "TTL automatically expires items without consuming write throughput."),
        fact("Redshift", .database, "Redshift is a columnar, massively parallel data warehouse for analytics."),
        fact("Redshift Spectrum", .database, "Spectrum queries data directly in S3 from Redshift."),
        fact("ElastiCache", .database, "Memcached is multi-threaded, has no persistence, and suits simple caching."),

        // Network, identity and security
        fact("VPC", .network, "A VPC IPv4 CIDR can range from /16 to /28."),
        fact("VPC", .network, "Use a VPC endpoint to privately reach supported AWS services without NAT or an Internet Gateway."),
        fact("VPC Peering", .network, "VPC peering is not transitive; create direct connections or use Transit Gateway."),
        fact("Transit Gateway", .network, "Transit Gateway is a hub-and-spoke network service for many VPCs and on-premises networks."),
        fact("CloudFront", .network, "CloudFront Functions suit lightweight URL rewrites and header manipulation; Lambda@Edge is more capable."),
        fact("CloudFront", .network, "Field-level encryption protects sensitive fields at the edge."),
        fact("Route 53", .network, "Route 53 supports Simple, Weighted, Latency, Failover, Geolocation, Geoproximity, and Multi-Value routing."),
        fact("Route 53", .network, "Health checks can use HTTP, HTTPS, or TCP and run at 30- or 10-second intervals."),
        fact("ALB", .network, "An Application Load Balancer is Layer 7 and supports host- and path-based routing plus WebSockets."),
        fact("NLB", .network, "A Network Load Balancer is Layer 4, handles millions of requests per second, and offers static IPs."),
        fact("Gateway Load Balancer", .network, "GWLB is Layer 3 and uses GENEVE for third-party network appliances."),
        fact("ELB", .network, "Deregistration delay (connection draining) can be configured from 1 to 3,600 seconds."),
        fact("IAM", .security, "The root user is for initial setup and should be protected with MFA."),
        fact("IAM", .security, "A permissions boundary sets the maximum permissions an IAM identity can receive."),
        fact("KMS", .security, "Envelope encryption uses a data key for data and a KMS key to encrypt that data key."),
        fact("KMS", .security, "Key policies and IAM policies both control access to KMS keys."),
        fact("KMS", .security, "Multi-Region keys are designed for cross-Region encryption workflows."),
        fact("AWS WAF", .security, "WAF can protect ALB, API Gateway, CloudFront, and AppSync."),
        fact("Shield Advanced", .security, "Shield Advanced adds Layer 7 DDoS protection and DDoS cost protection."),
        fact("Secrets Manager", .security, "Secrets Manager is built to store and rotate credentials; Parameter Store is a simpler configuration store."),

        // Integration and architecture
        fact("SQS", .integration, "Standard queues provide at-least-once delivery and best-effort ordering."),
        fact("SQS FIFO", .integration, "FIFO queues preserve ordering and provide exactly-once processing semantics."),
        fact("SQS", .integration, "A visibility timeout prevents other consumers receiving a message while it is being processed."),
        fact("SNS", .integration, "SNS supports pub/sub fan-out and can deliver to SQS, Lambda, HTTP(S), email, and SMS."),
        fact("Step Functions", .integration, "Step Functions orchestrates multi-step workflows with retries, branching, and state."),
        fact("Kinesis Data Streams", .integration, "Kinesis Data Streams is for real-time streaming with consumers reading ordered records per shard."),
        fact("AWS Backup", .architecture, "AWS Backup centrally manages backups across supported AWS services."),
        fact("DR: Backup & Restore", .architecture, "Backup and restore has the lowest cost but the highest RTO and RPO."),
        fact("DR: Pilot Light", .architecture, "Pilot light keeps core components running and scales up during a disaster."),
        fact("DR: Warm Standby", .architecture, "Warm standby runs a scaled-down but functional version that can quickly scale up."),
        fact("Cost Optimization", .architecture, "For predictable workloads, Savings Plans often offer a flexible commitment compared with Reserved Instances."),
        fact("Well-Architected", .architecture, "The six pillars are Operational Excellence, Security, Reliability, Performance Efficiency, Cost Optimization, and Sustainability."),
        fact("Exam Tactic", .architecture, "When requirements say least operational overhead, favor managed AWS services over self-managed EC2 solutions."),

        // Current service-selection cues for architecture scenarios.
        .init(service: "S3 Express One Zone", category: .storage, prompt: "Need low-latency object access beside compute in one AZ?", answer: "S3 Express One Zone directory bucket", takeaway: "It is a single-AZ storage class, so choose it when that placement meets your resilience needs."),
        .init(service: "EventBridge Pipes", category: .integration, prompt: "Connect one event source to one target with filtering and enrichment?", answer: "EventBridge Pipes", takeaway: "Pipes can filter and enrich events before delivery to a target."),
        .init(service: "DynamoDB Global Tables", category: .database, prompt: "Need local reads and writes in multiple Regions?", answer: "DynamoDB global tables", takeaway: "Replicas are multi-active; choose the consistency mode for the workload."),
        .init(service: "Bedrock Knowledge Bases", category: .architecture, prompt: "Ground AI answers in retrieved company data?", answer: "Bedrock Knowledge Bases", takeaway: "RetrieveAndGenerate combines retrieval with model generation and source attribution."),
        .init(service: "S3", category: .storage, prompt: "A single object is 40 TB. Which upload approach?", answer: "Multipart upload", takeaway: "A single PUT request has a smaller limit than the full 50 TB object limit."),
        .init(service: "SQS", category: .integration, prompt: "A message is larger than 1 MiB. What is the pattern?", answer: "S3 payload plus SQS reference", takeaway: "Keep large payloads in S3 and put a pointer in the queue."),
        .init(service: "RDS", category: .database, prompt: "Read scaling or automatic AZ failover?", answer: "Read replicas scale reads; Multi-AZ supports failover", takeaway: "These solve different database needs."),
        .init(service: "IAM", category: .security, prompt: "An EC2 app needs AWS API access without static keys.", answer: "Attach an IAM role", takeaway: "The instance profile provides temporary credentials to the application."),
        .init(service: "CloudFront", category: .network, prompt: "Restrict an S3 origin to CloudFront only.", answer: "Origin Access Control", takeaway: "Keep the S3 bucket private and grant access to CloudFront."),
        .init(service: "Step Functions", category: .integration, prompt: "Coordinate retries, branches, and state across services.", answer: "Step Functions", takeaway: "A state machine makes the workflow explicit."),
        .init(service: "VPC Endpoint", category: .network, prompt: "Access S3 from a VPC without a NAT gateway.", answer: "S3 gateway endpoint", takeaway: "Gateway endpoints provide private routing to S3 and DynamoDB."),
        .init(service: "S3", category: .storage, prompt: "Need the cheapest archive with hours-long retrieval?", answer: "S3 Glacier Deep Archive", takeaway: "Use it when restore time is flexible."),
        .init(service: "AWS WAF", category: .security, prompt: "Block malicious HTTP requests at an ALB.", answer: "AWS WAF web ACL", takeaway: "WAF works at the application layer with web rules."),
        .init(service: "Fargate", category: .compute, prompt: "Run an ECS task without managing EC2 instances.", answer: "AWS Fargate", takeaway: "Fargate provides serverless compute for containers.")
    ]
}
