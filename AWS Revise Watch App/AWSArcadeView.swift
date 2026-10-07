import SwiftUI
import WatchKit

private struct CloudMission {
    let signal: String
    let routes: [String]
    let correct: Int
    let why: String
}

private enum CloudMissions {
    static let all: [CloudMission] = [
        .init(signal: "Orders arrive in bursts. Workers must process each one later.", routes: ["SQS", "SNS", "CloudFront"], correct: 0, why: "SQS buffers work so producers and consumers can scale separately."),
        .init(signal: "One event must reach billing, email, and analytics.", routes: ["EBS", "SNS", "NAT gateway"], correct: 1, why: "SNS fans one published message out to multiple subscribers."),
        .init(signal: "A private subnet needs outbound internet access.", routes: ["Internet gateway", "NAT gateway", "VPC peering"], correct: 1, why: "A NAT gateway in a public subnet enables private subnet egress."),
        .init(signal: "Store a shared Linux file system across AZs.", routes: ["EBS", "Instance store", "EFS"], correct: 2, why: "EFS is a managed shared file system using NFS."),
        .init(signal: "A database needs automatic failover in another AZ.", routes: ["RDS Multi-AZ", "Read replica", "DAX"], correct: 0, why: "RDS Multi-AZ provides a standby for high availability."),
        .init(signal: "Serve static assets near viewers worldwide.", routes: ["CloudFront", "SQS", "Direct Connect"], correct: 0, why: "CloudFront caches content at edge locations."),
        .init(signal: "Give a Lambda function short-lived AWS credentials.", routes: ["Root keys", "IAM role", "Public bucket"], correct: 1, why: "An IAM execution role supplies temporary credentials."),
        .init(signal: "A 700 KiB task must fit in one queue message.", routes: ["SQS", "SNS email", "Kinesis shard"], correct: 0, why: "An SQS message can be up to 1 MiB."),
        .init(signal: "Archive records for rare access and hours-long retrieval.", routes: ["S3 Standard", "S3 Glacier Deep Archive", "EFS"], correct: 1, why: "Deep Archive trades retrieval time for low-cost archival storage."),
        .init(signal: "Route events from a queue through filtering and enrichment.", routes: ["EventBridge Pipes", "EBS snapshots", "Route 53"], correct: 0, why: "EventBridge Pipes links a source to a target with optional filtering and enrichment."),
        .init(signal: "Run containers without managing EC2 hosts.", routes: ["ECS on EC2", "Fargate", "Dedicated Hosts"], correct: 1, why: "Fargate runs container tasks without host management."),
        .init(signal: "Keep an S3 origin private behind CloudFront.", routes: ["Public ACL", "Origin Access Control", "NAT gateway"], correct: 1, why: "Origin Access Control lets CloudFront access a private S3 origin."),
        .init(signal: "A web app needs Layer 7 request filtering.", routes: ["AWS WAF", "NACL", "EBS"], correct: 0, why: "AWS WAF filters HTTP(S) requests with web ACL rules."),
        .init(signal: "Query petabytes of warehouse data with SQL.", routes: ["ElastiCache", "Redshift", "SQS"], correct: 1, why: "Amazon Redshift is a managed data warehouse for analytics."),
        .init(signal: "Users need local reads and writes in multiple Regions.", routes: ["RDS read replica", "DynamoDB global tables", "EBS Multi-Attach"], correct: 1, why: "DynamoDB global tables have writable replicas across Regions."),
        .init(signal: "Keep a latency-sensitive S3 workload in one AZ.", routes: ["S3 Express One Zone", "S3 Deep Archive", "S3 Standard-IA"], correct: 0, why: "S3 Express One Zone uses directory buckets in one AZ for low latency."),
        .init(signal: "Retrieve company documents to ground an AI answer.", routes: ["DAX", "Bedrock Knowledge Bases", "CloudTrail"], correct: 1, why: "Bedrock Knowledge Bases supports retrieval and generation over your data."),
        .init(signal: "Orchestrate retries and branches in a workflow.", routes: ["Step Functions", "SNS", "CloudFront"], correct: 0, why: "Step Functions coordinates multi-step workflows and state."),
        .init(signal: "Encrypt a large file with a KMS-backed key.", routes: ["Direct KMS Encrypt", "Envelope encryption", "Security group"], correct: 1, why: "Envelope encryption uses a data key for the file and KMS to protect that key."),
        .init(signal: "Privately reach S3 from a VPC without NAT.", routes: ["VPC endpoint", "Internet gateway", "Public IP"], correct: 0, why: "An S3 gateway VPC endpoint offers private access without NAT."),
        .init(signal: "A 40 TB object needs one S3 key.", routes: ["S3 multipart upload", "One PUT request", "EFS"], correct: 0, why: "S3 supports objects up to 50 TB; large uploads use multipart upload.")
    ]
}

struct AWSArcadeView: View {
    @AppStorage("cloudRunBest") private var best = 0
    @State private var missionIndex = 0
    @State private var flightPlan = Array(CloudMissions.all.indices).shuffled()
    @State private var lane = 1.0
    @State private var submitted: Int?
    @State private var hull = 3
    @State private var score = 0
    @State private var streak = 0
    @State private var routed = false
    @State private var ended = false
    @FocusState private var crownFocused: Bool

    private let runLength = 10
    private var mission: CloudMission { CloudMissions.all[flightPlan[missionIndex]] }
    private var selected: Int { submitted ?? min(2, max(0, Int(lane.rounded()))) }
    private var success: Bool { selected == mission.correct }

    var body: some View {
        Group {
            if ended { endView }
            else { flightView }
        }
        .navigationTitle("Cloud Run")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var flightView: some View {
        VStack(spacing: 5) {
            HStack {
                Label("\(hull)", systemImage: "heart.fill").foregroundStyle(.pink)
                Spacer()
                Text("\(missionIndex + 1)/\(runLength)").foregroundStyle(.cyan)
                Spacer()
                Label("\(score)", systemImage: "bolt.fill").foregroundStyle(.yellow)
            }
            .font(.system(size: 10, weight: .bold, design: .monospaced))

            Text(mission.signal)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: 39)

            HStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { index in
                    VStack(spacing: 3) {
                        Image(systemName: selected == index ? "paperplane.fill" : "circle.grid.cross")
                            .font(.system(size: 14, weight: .bold))
                        Text(mission.routes[index])
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .lineLimit(2)
                            .minimumScaleFactor(0.75)
                            .frame(height: 25)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .foregroundStyle(routeColor(index))
                    .background(routeColor(index).opacity(selected == index ? 0.22 : 0.08), in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(routeColor(index).opacity(selected == index ? 0.9 : 0.25)))
                    .onTapGesture { if !routed { lane = Double(index); crownFocused = true } }
                }
            }
            .focusable(true)
            .focused($crownFocused)
            .digitalCrownRotation($lane, from: 0, through: 2, by: 1, sensitivity: .low, isContinuous: false, isHapticFeedbackEnabled: true)

            if routed {
                ScrollView {
                    VStack(spacing: 3) {
                        Text(success ? "ROUTE CLEAR  +\(10 + max(0, streak - 1) * 5)" : "PACKET LOST  -1 HULL")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundStyle(success ? .green : .pink)
                        Text(mission.why)
                            .font(.system(size: 10, design: .rounded))
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxHeight: 43)
                Button(hull == 0 || missionIndex + 1 == runLength ? "Results" : "Next sector") { advance() }
                    .tint(.cyan)
            } else {
                Button("Route packet") { route() }.tint(.cyan)
            }
            Text(routed ? "\(streak) streak · best \(best)" : "Turn Crown to steer · tap to route")
                .font(.system(size: 9, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 3)
        .buttonStyle(.borderedProminent)
        .onAppear { crownFocused = true }
    }

    private var endView: some View {
        VStack(spacing: 7) {
            Image(systemName: hull > 0 ? "sparkles" : "heart.slash.fill")
                .font(.system(size: 30)).foregroundStyle(.cyan)
            Text(hull > 0 ? "Mission complete" : "Ship repaired")
                .font(.system(.headline, design: .rounded))
            Text("\(score) points · best \(best)")
                .font(.system(size: 12, design: .rounded)).foregroundStyle(.secondary)
            Button("Fly again") { restart() }.tint(.cyan).buttonStyle(.borderedProminent)
        }
    }

    private func routeColor(_ index: Int) -> Color {
        if routed && index == mission.correct { return .green }
        if routed && index == selected && !success { return .pink }
        return selected == index ? .cyan : .gray
    }

    private func route() {
        guard !routed else { return }
        submitted = selected
        if success {
            streak += 1
            score += 10 + (streak - 1) * 5
            best = max(best, score)
            WKInterfaceDevice.current().play(.success)
        } else {
            hull -= 1
            streak = 0
            WKInterfaceDevice.current().play(.failure)
        }
        routed = true
    }

    private func advance() {
        if hull == 0 || missionIndex + 1 == runLength { ended = true; return }
        missionIndex += 1
        lane = 1
        submitted = nil
        routed = false
        crownFocused = true
    }

    private func restart() {
        missionIndex = 0
        flightPlan.shuffle()
        lane = 1
        submitted = nil
        hull = 3
        score = 0
        streak = 0
        routed = false
        ended = false
        crownFocused = true
    }
}
