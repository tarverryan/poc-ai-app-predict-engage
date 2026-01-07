# Lessons Learned

**Customer Engagement Prediction Platform**  
**Personal reflections on building this project**

---

## What Worked Well

**1. LocalStack for Development**
- Being able to test the entire AWS stack locally without any costs was invaluable
- Caught many integration issues before deploying to real AWS
- The only limitation was Bedrock (not available in LocalStack), which we mocked

**2. Step Functions for Orchestration**
- The visual workflow made debugging much easier than trying to trace Lambda invocations
- Built-in retry logic saved a lot of custom error handling code
- Execution history provided clear visibility into what failed and why

**3. S3 + Athena for Analytics**
- Avoiding database management was a huge win for a POC
- Parquet format with partitioning made Athena queries fast and cheap
- The pay-per-query model meant no idle costs

**4. Fargate for ML Workloads**
- Running XGBoost training with 64GB RAM would have been impossible in Lambda
- Container approach made it easy to test locally with Docker
- ECR integration was seamless

---

## What Was Harder Than Expected

**1. Athena Query Performance**
- Initially scanned way too much data (100GB+) because I didn't partition properly
- Learning curve on optimizing queries with partitioning and compression
- Had to rewrite several queries after seeing the cost implications

**2. Step Functions State Machine Definition**
- The JSON/YAML syntax is verbose and error-prone
- Testing state machines locally is difficult (ended up deploying to test)
- Debugging failed executions required understanding the execution history format

**3. Bedrock Knowledge Base Setup**
- Documentation was sparse on using S3 as vector store (most examples use OpenSearch)
- Figuring out the right data format for the knowledge base took trial and error
- Sync jobs can take a while, making iteration slow

**4. IAM Policy Complexity**
- Getting the right permissions for cross-service access was tedious
- Many services require wildcard permissions (Athena, Glue) which feels wrong
- Balancing security with simplicity for a POC was challenging

**5. Cost Estimation**
- Predicting actual costs was harder than expected
- Athena costs depend heavily on query patterns, not just data volume
- Fargate costs scale linearly but are the biggest driver

---

## What I Would Change Next

**1. Add More Comprehensive Testing**
- Currently has basic unit tests but lacks integration tests
- Would add end-to-end tests that run against LocalStack
- Would add cost regression tests to catch expensive queries

**2. Simplify the Architecture**
- The Bedrock Knowledge Base adds complexity that might not be necessary for a POC
- Could simplify to just API Gateway → Lambda → DynamoDB for predictions
- The AI Q&A feature is nice but adds significant operational overhead

**3. Better Error Handling**
- Some Lambda functions don't handle partial failures well
- Would add more granular error types and retry strategies
- Would improve error messages in Step Functions

**4. Cost Monitoring**
- Would add CloudWatch dashboards for cost tracking
- Would set up automated alerts for unexpected cost spikes
- Would add cost annotations to Step Functions executions

**5. Documentation Structure**
- The docs folder got a bit sprawling
- Would consolidate some of the architecture docs
- Would add more "getting started" examples with common use cases

**6. Data Partitioning from the Start**
- Would design data partitioning into the initial schema
- Would use date-based partitioning for time-series queries
- Would add partition projection for better query performance

---

## Common Pitfalls to Watch For

**1. Athena Query Costs**
- **Pitfall**: Writing queries that scan entire tables
- **Solution**: Always use WHERE clauses with partition filters, use LIMIT for testing
- **Cost Impact**: Can easily spend $10+ per query if not careful

**2. Fargate Task Timeouts**
- **Pitfall**: Tasks failing silently due to timeout
- **Solution**: Set appropriate timeout values, monitor CloudWatch logs
- **Cost Impact**: Failed tasks still charge for runtime

**3. S3 Lifecycle Policies**
- **Pitfall**: Data accumulating indefinitely, increasing storage costs
- **Solution**: Set lifecycle policies to delete old data (90 days for POC)
- **Cost Impact**: Can add up over time if not managed

**4. Step Functions State Machine Size**
- **Pitfall**: State machines getting too large, hard to maintain
- **Solution**: Break into smaller state machines, use nested workflows
- **Maintenance Impact**: Large state machines are hard to debug

**5. IAM Policy Wildcards**
- **Pitfall**: Using `Resource = "*"` everywhere for simplicity
- **Solution**: Document why wildcards are used, plan to tighten for production
- **Security Impact**: Over-permissive policies are a security risk

**6. LocalStack Limitations**
- **Pitfall**: Assuming LocalStack behavior matches AWS exactly
- **Solution**: Test critical paths in real AWS before relying on them
- **Reliability Impact**: Some services have different behavior in LocalStack

---

## Personal Takeaways

**What I Learned About AWS:**
- Serverless doesn't mean "no operations" - you still need monitoring, logging, and cost management
- Managed services are great, but they have their own learning curves
- Cost optimization requires understanding pricing models deeply
- IAM is powerful but complex - least privilege is easier said than done

**What I Learned About ML on AWS:**
- Lambda is great for orchestration but not for heavy compute
- Fargate fills the gap but adds operational complexity
- S3 + Athena is a viable alternative to databases for batch analytics
- Model versioning and deployment is still a challenge

**What I Learned About Building POCs:**
- Start simple, add complexity only when needed
- LocalStack is invaluable for iteration speed
- Documentation is as important as code for learning projects
- Sharing publicly forces you to think about security and cost from day one

---

## Questions I Still Have

- How would this scale to 100M+ users? What would break first?
- Is Step Functions the right choice for complex ML pipelines?
- Should I use AWS Batch instead of Fargate for better cost optimization?
- How do I handle model versioning and A/B testing in this architecture?
- What's the best way to monitor model drift and data quality?

---

## Resources That Helped

- AWS Well-Architected Framework (especially Cost Optimization pillar)
- Step Functions best practices documentation
- Athena query optimization guides
- LocalStack documentation and community
- Various AWS re:Invent talks on serverless ML

---

## Final Thoughts

This project was a great learning experience in building serverless ML pipelines. The biggest insight was that "serverless" doesn't mean "simple" - you still need to understand the services deeply to use them effectively.

The architecture works well for a POC, but I'd make several changes before considering it production-ready. The main takeaway is that AWS managed services are powerful, but they require careful design to use cost-effectively.

I'm sharing this publicly in hopes that others can learn from both the successes and the mistakes. If you're building something similar, feel free to open an issue or discussion - I'm happy to share more details about any part of this project.

---

**Author:** Ryan Tarver  
**Date:** October 2025

