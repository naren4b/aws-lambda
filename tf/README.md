## 🏗️ Production Setup & Execution Lifecycle

To successfully deploy and test the **NutriScan AI** infrastructure, execute the following implementation steps sequentially. Each stage maps out the exact permissions and resources required for our serverless processing pipeline.

---

### Step 1: Create a Custom IAM Policy

To enforce the principle of least privilege, create a targeted IAM policy. This grants your Lambda execution environment narrow access limits to only the precise datastores, buckets, and model endpoints needed for the image processing workload.

Ensure your policy allows the following fine-grained actions:

* 
**`s3:GetObject`**: Restricted specifically to your raw intake prefix within your custom S3 storage bucket.


* 
**`dynamodb:PutItem`**: Restricted to write scan metadata payloads strictly to your dedicated DynamoDB table index.


* 
**`bedrock:InvokeModel`**: Scoped exclusively to the **Anthropic Claude 3.5 Sonnet** foundation model ARN (`arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-3-5-sonnet-20240620-v1:0`).


* 
**CloudWatch Logs Permissions**: Allow `logs:CreateLogGroup`, `logs:CreateLogStream`, and `logs:PutLogEvents` to securely track execution telemetry and container status.



---

### Step 2: Create a Lambda IAM Execution Role

Create an IAM service role for AWS Lambda and attach the trust relationship policy so the Lambda service can assume it:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "lambda.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}

```

Attach the custom IAM policy created in Step 1 to this role.

---

### Step 3: Create and Deploy the AWS Lambda Function

1. Provision a Lambda function named `nutriscan-ingredient-analyzer`.


2. Choose **Python 3.11** as the runtime environment.


3. Select the **Arm64 (AWS Graviton)** architecture to maximize execution performance while reducing compute runtime fees.


4. Attach the IAM execution role built in Step 2.


5. Inject the environment variable mapping (`DYNAMODB_TABLE_NAME`) to route writes directly to your active metadata table name.


6. Set the function execution **Timeout to 30 seconds** to accommodate the time required for the Large Language Model's multimodal vision analysis.



---

### Step 4: Create the Amazon DynamoDB Table

Provision your tracking datastore using a fast, serverless on-demand scaling policy:

* 
**Table Name:** `nutriscan-scans-prod` 


* 
**Partition Key (Hash Key):** `ScanID` (String type) 


* 
**Billing Mode:** Pay-per-request (On-Demand) to drop idle infrastructure costs to zero when no scans are actively being processed.



---

### Step 5: Provision Amazon S3 Storage

Create a globally unique S3 bucket named `nutriscan-storage-prod-xyz` to serve as your secure object storage layer. Enable a strict **Public Access Block** to protect consumer uploads from unauthorized internet access.

---

### Step 6: Create and Deploy Amazon API Gateway

1. Create a new **REST API** gateway.
2. Build a resource path root named `/scan`.
3. Create a secure **POST** method on that endpoint and link it directly to your `nutriscan-ingredient-analyzer` Lambda function via a standard Proxy Integration setup.


4. Enable **CORS** compliance headers so mobile apps or web frontends can securely deliver payloads to the gateway endpoint.


5. Deploy the API to a production stage named `prod`.

---

### Step 7: Test the End-to-End Lambda Function Pipeline

To simulate a real-world client upload, execute a test payload via your API Gateway endpoint or trigger the Lambda function directly using the following sample JSON structure:

```json
{
  "body": "{\"bucket\": \"nutriscan-storage-prod-xyz\", \"image_key\": \"raw-images/sample_label.jpg\", \"user_id\": \"user_test_99\"}"
}

```

#### Expected CloudWatch Logs Lifecycle Outcome

When the execution completes, check your CloudWatch logging streams to verify the internal serverless workflow completed smoothly:

1. 
**S3 Handshake Verification:** The logs will confirm that the raw image bytes were downloaded into memory from your S3 path.


2. 
**Bedrock Inference Delivery:** The prompt is applied, sending the base64-encoded image payload to Claude for real-time nutritional screening.


3. 
**Structured Response and DB Write:** Claude returns a clean JSON block containing the identified ingredients, health risk rating (1-4), and short justification. This is successfully saved as a normalized item in DynamoDB.



---

### Step 8: Clean Up Infrastructure Resources

To avoid ongoing charges for retained cloud components when you are done testing, tear down your deployed infrastructure:

1. Delete the API Gateway deployment stage and REST API definitions.
2. Remove the Lambda function and delete its related CloudWatch log groups to stop storage fees.


3. Delete the DynamoDB table.


4. Empty all uploaded wrapper images and PDF reports from your S3 bucket, then delete the bucket itself.


5. Delete the IAM roles and custom policies created for the project.



---

