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
    static let deck: [Flashcard] = [
        .init(service: "Lambda", category: .compute, prompt: "Maximum execution time?", answer: "15 minutes", takeaway: "For longer jobs, use ECS, Batch, Step Functions, or an async pattern."),
        .init(service: "Lambda", category: .compute, prompt: "How do you remove cold starts?", answer: "Provisioned Concurrency", takeaway: "It keeps initialized environments ready for predictable latency."),
        .init(service: "EC2", category: .compute, prompt: "Cheapest interruptible capacity?", answer: "Spot Instances", takeaway: "Use for fault-tolerant, flexible workloads; interruption notice is 2 minutes."),
        .init(service: "EC2", category: .compute, prompt: "Which placement group has lowest latency?", answer: "Cluster placement group", takeaway: "Places instances close together in one AZ; ideal for HPC."),
        .init(service: "Auto Scaling", category: .compute, prompt: "Keep CPU near 50% automatically?", answer: "Target tracking", takeaway: "It adds or removes capacity to maintain a chosen metric target."),
        .init(service: "ECS", category: .compute, prompt: "Serverless containers with no EC2 management?", answer: "Fargate", takeaway: "Pay for task vCPU and memory without managing hosts."),
        .init(service: "S3", category: .storage, prompt: "Maximum object size?", answer: "5 TB", takeaway: "Use multipart upload for large objects (recommended over 100 MB)."),
        .init(service: "S3", category: .storage, prompt: "Requirement for Cross-Region Replication?", answer: "Versioning enabled", takeaway: "Both source and destination buckets need versioning."),
        .init(service: "S3", category: .storage, prompt: "Durability of S3 Standard?", answer: "11 nines", takeaway: "99.999999999% durability; availability is a separate measure."),
        .init(service: "EBS", category: .storage, prompt: "Can an EBS volume move across AZs?", answer: "No — it is AZ-locked", takeaway: "Use a snapshot to create a volume in another AZ or Region."),
        .init(service: "EFS", category: .storage, prompt: "Shared Linux file system protocol?", answer: "NFS", takeaway: "EFS is managed, elastic NFS storage with multi-AZ access."),
        .init(service: "FSx for Lustre", category: .storage, prompt: "Best fit?", answer: "HPC / ML high-performance file system", takeaway: "It integrates with S3 for data-heavy compute workloads."),
        .init(service: "RDS", category: .database, prompt: "Multi-AZ is for what?", answer: "High availability and automatic failover", takeaway: "The standby is synchronous; it does not serve read traffic."),
        .init(service: "RDS", category: .database, prompt: "Read Replicas are what kind of replication?", answer: "Asynchronous", takeaway: "Use them for read scaling, not automatic failover."),
        .init(service: "Aurora", category: .database, prompt: "Copies of data across 3 AZs?", answer: "6 copies", takeaway: "Aurora storage auto-scales up to 128 TB."),
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
        .init(service: "SQS", category: .integration, prompt: "Maximum message size?", answer: "256 KB", takeaway: "Use the Extended Client Library with S3 for larger payloads."),
        .init(service: "SQS", category: .integration, prompt: "Maximum retention period?", answer: "14 days", takeaway: "Use DLQs to isolate repeatedly failing messages."),
        .init(service: "SNS", category: .integration, prompt: "Fan-out to multiple consumers?", answer: "SNS", takeaway: "Publish once to SNS; deliver to SQS queues, Lambda, email, and more."),
        .init(service: "EventBridge", category: .integration, prompt: "Event bus with content-based routing?", answer: "EventBridge", takeaway: "It can route AWS, SaaS, and custom events by rules."),
        .init(service: "API Gateway", category: .integration, prompt: "Maximum synchronous integration timeout?", answer: "29 seconds", takeaway: "For longer work, return quickly and use an asynchronous design."),
        .init(service: "Well-Architected", category: .architecture, prompt: "Least operational effort means…", answer: "Prefer managed/serverless services", takeaway: "The exam often rewards AWS-managed options over self-managed infrastructure."),
        .init(service: "Disaster Recovery", category: .architecture, prompt: "Lowest RTO and RPO strategy?", answer: "Multi-site active-active", takeaway: "It is also the most expensive DR option."),
        .init(service: "Cost", category: .architecture, prompt: "Steady 1–3 year workload discount?", answer: "Savings Plans or Reserved Instances", takeaway: "Savings Plans are more flexible; RIs can offer capacity reservation."),
        .init(service: "Architecture", category: .architecture, prompt: "Decouple app components?", answer: "Use a queue (SQS)", takeaway: "Queues absorb bursts and let producers and consumers scale independently.")
    ]
}
