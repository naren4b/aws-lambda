# NutriScan AI: Automated Food Ingredient & Health Risk Assessment
_Amazon API Gateway | AWS Lambda | Amazon S3 | Amazon DynamoDB | Anthropic Claude_

<img width="1293" height="983" alt="aws-lambda-nha-design" src="https://github.com/user-attachments/assets/34442040-e6f8-4b07-857a-6fc63b3320a5" />

**Overview**
In compliance with government regulations, all packaged food manufacturers are required to print detailed ingredient lists on their product wrappers. However, navigating complex chemical names, hidden allergens, and nutritional jargon makes it incredibly difficult for the average consumer to make informed, healthy choices. Sending every product to a nutritionist for evaluation is slow and impractical.

**The Solution:** Consumers upload a mobile photo of a food wrapper's ingredient label. A serverless AWS architecture leverages a vision-capable Large Language Model (Anthropic Claude via Amazon Bedrock) to instantly analyze the text, evaluate dietary risks, and generate an immediate health risk rating alongside a clear, brief justification.

**Architecture & AWS Components**
This repository implements the solution using the following AWS cloud services:
- **Amazon API Gateway:** Exposes secure REST endpoints to receive the mobile image payloads and user metadata.
- **AWS Lambda:** Serves as the event-driven compute layer to handle image processing, manage backend orchestration, and coordinate database writes.
- **Amazon S3:** Provides secure object storage for original uploaded food wrapper images and compiled PDF nutritional risk reports.
- **Amazon DynamoDB:** Serves as a low-latency, stateless NoSQL datastore to hold user profiles, product barcodes, and historical scan metadata.
- **Amazon Bedrock (Anthropic Claude):** Acts as the foundational AI reasoning engine, utilizing its multimodal capabilities to extract textual ingredient lists from the image and compute precise health risk assessments.

**Key Features**
- **Automated OCR & Vision Analysis:** Eliminates manual text input by reading complex wrapper textures and fonts directly via LLM vision capabilities.
- **Instant Risk Profiling:** Flags high-risk components such as excessive sodium, synthetic additives, or specific user-configured allergens (e.g., gluten, nuts).
- **Serverless Efficiency:** Scales automatically to handle traffic spikes during peak grocery shopping hours and drops to zero idle costs when inactive.


