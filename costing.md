<img width="791" height="413" alt="image" src="https://github.com/user-attachments/assets/220c6b72-b64e-4391-bd40-369620f1e33a" />

Your baseline costing heads are spot on. To help you build a highly accurate, easily scannable cheat sheet, here is a validated and expanded breakdown of AWS Lambda pricing dimensions based on official documentation.

---

## 💰 Core Costing Heads (The Baseline)

* **Invocation Count:** Billed flat at **$0.20 per million requests** (after your 1 million free tier requests). Every execution starts counting immediately, regardless of success or failure.
* **Memory Provisioned:** Selected between **128 MB and 10,240 MB** (in 1 MB increments). Memory acts as your master dial—increasing it proportionally increases available CPU power and your cost rate.
* **Duration:** Calculated from code initialization/handler start to termination, rounded up to the **nearest 1 ms**. It is calculated as $\text{Memory (in GB)} \times \text{Duration (in seconds)}$ to give you a total billable metric called **GB-seconds**.
* **Region:** Base rates fluctuate slightly by geographic AWS region depending on infrastructure costs.

---

## ⚡ Architecture Head (The 34% Hack)

* **Processor Architecture (x86 vs. Arm/Graviton2):** Running functions on Arm-based AWS Graviton2 processors delivers up to **34% better price-performance** and significantly lower per-GB-second costs compared to traditional x86 processors.

---

## 🔍 Premium & Add-On Costing Heads

If your architecture uses specialized configurations, keep these secondary heads in mind:

* **Provisioned Concurrency (Pre-Warming):** Charged a flat rate to keep environments initialization-ready to kill cold starts. You pay for the configured concurrency footprint per second, plus a modified (lower) execution duration fee.
* **Ephemeral Storage (`/tmp` space):** The first **512 MB is always free**. You are only billed per GB-second for additional storage allocated up to 10,240 MB.
* **HTTP Response Streaming:** Allowing responses to stream progressively gives you **100 GiB free per month** and free streaming for the first 6 MB of every individual request. Anything over 6 MB incurs a small per-GB processed charge.
* **Lambda Durable Functions (Stateful Workloads):** Charges apply for standard compute/replays, alongside micro-fees for state checkpoints called **Durable Operations**, volume of **Data Written**, and **Data Retention** (configurable from 1 to 90 days).
* **Tenant Isolation Mode:** Used to separate multi-tenant execution environments. You incur an extra per-environment fee whenever Lambda spins up a new isolated container.
* **SnapStart (Java/Caching):** Caching a performance snapshot introduces micro-billing for **SnapStart Caching** duration and **SnapStart Restore** events when a cold container is woken up.

---

## 📡 The "Hidden" Costs (Upstream & Downstream)

A Lambda function never lives in a vacuum. Your final architecture cost line item will always include:

* **Data Transfer:** Data inbound/outbound from outside the function's home region falls under standard EC2 data transfer fees. Same-region transfer to core services like S3, DynamoDB, and SQS is **free**.
* **CloudWatch Logs:** Lambda automatically pipes `stdout` and execution errors here. You will pay standard CloudWatch rates for **Log Ingestion** and **Log Storage**.
* **Triggers / Event Sources:** API Gateways, Amazon SQS polling units, or EventBridge buses executing the function carry their own volume-based pricing.

---

## 🎁 Pocket Rules of Thumb

> * **The Tiered Volume Discount:** Aggregate duration pricing automatically scales down across your AWS Organization if your workload consumes over 6 Billion GB-seconds a month.
> * **The Compute Savings Plan:** Committing to a 1 or 3-year term can save you up to **17%** on your duration and Provisioned Concurrency spend.
> 
> 

Would you like help calculating a quick projection based on a specific workload pattern you have in mind?
