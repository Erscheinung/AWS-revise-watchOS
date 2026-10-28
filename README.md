# AWS Revise Watch

A standalone watchOS companion for fast AWS SAA-C03 recall. The deck contains more than 100 cards covering service limits, service choices, architecture patterns, and common exam distinctions. Content is bundled on the watch for offline play.

## Use on Apple Watch

Open `AWS Revise Watch.xcodeproj` in Xcode, choose the **AWS Revise Watch** scheme, set your signing team if Xcode asks, and run it on an Apple Watch or watchOS Simulator.

- The **Study** home screen scrolls, so every mode and domain remains reachable on smaller Watch displays.
- **Quick Review** presents full-height, scrollable cards: tap to reveal, then use **Again** or **Got it**. The latter increments your local review count.
- **Crown Arcade** is a watch-native skill hub with three compact games (no quiz confirmation screens):
  - **Service Catcher**: turn the Digital Crown to steer a collector, catch the glowing target category, and dodge wrong services and red hazards. Falling speed increases, lives and combos matter, and each catch surfaces an AWS architecture fact.
  - **Service Sorter**: rotate the Crown through the category carousel while service cards move on a timed conveyor. Dispatch early with a tap or let the deadline resolve automatically; combos reward accurate sorting and mistakes end the run.
  - **Cloud Vault**: turn the Crown’s safe dial toward a hidden, moving lock position. Visual warmth and proximity haptics guide you; hold the narrow target or tap **SET PIN** to open three increasingly difficult stages.
  Each game has a concise how-to screen, touch fallbacks, a pause/resume overlay, a replay/results view, and a persisted best score. Leaving the app pauses an active run so time never drains in the background and a run never auto-resumes.
- Choose from six learning modes: Quick Review, Sprint Quiz, Scenario Lab, True / False, Match-Up, and Daily Mix.
- Mixed modes draw 36 prompts across AWS domains. Focused domain reviews use the cards available for that domain. The card order rotates daily so more of the deck appears across sessions.

The app is intentionally independent of an iPhone companion so it can be installed directly on the watch.

## AWS content sources

The static deck was refreshed against official AWS documentation on **October 7, 2026**. AWS service quotas and certification coverage can change; the app does not fetch live AWS data. In particular, the SQS message limit is 1 MiB, the S3 object limit is 50 TB, Aurora storage can grow to 256 TiB, and the default API Gateway REST integration timeout is 29 seconds with an increase available for Regional and private REST APIs.

- [SAA-C03 exam guide](https://docs.aws.amazon.com/aws-certification/latest/solutions-architect-associate-03.html)
- [SQS message quotas](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/quotas-messages.html)
- [S3 object sizes](https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingObjects.html) and [upload methods](https://docs.aws.amazon.com/AmazonS3/latest/userguide/upload-objects.html)
- [Aurora storage scale](https://docs.aws.amazon.com/rds/latest/auroraextendedcontent/aurora-faq-scalability.html)
- [API Gateway REST quotas](https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-execution-service-limits-table.html)
- [EventBridge Pipes](https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-pipes.html), [S3 Express One Zone](https://docs.aws.amazon.com/AmazonS3/latest/userguide/directory-bucket-high-performance.html), [DynamoDB global tables](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/GlobalTables.html), and [Bedrock Knowledge Bases](https://docs.aws.amazon.com/bedrock/latest/userguide/kb-how-retrieval.html)
