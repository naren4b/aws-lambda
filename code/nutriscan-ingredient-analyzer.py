import json
import os
import base64
import boto3
from datetime import datetime

# Initialize the AWS SDK clients globally for container reuse performance
s3_client = boto3.client("s3")
dynamodb = boto3.resource("dynamodb")
bedrock_client = boto3.client(service_name="bedrock-runtime")

# Resource mappings pulled from environmental variables
TABLE_NAME = os.environ.get("DYNAMODB_TABLE_NAME", "nutriscan-scans-prod")
MODEL_ID = "anthropic.claude-3-5-sonnet-20240620-v1:0"

def lambda_handler(event, context):
    try:
        # 1. Parse image metadata payload from API Gateway
        body = json.loads(event.get("body", "{}"))
        bucket = body.get("bucket")
        image_key = body.get("image_key")
        user_id = body.get("user_id", "ANONYMOUS_USER")
        
        if not bucket or not image_key:
            return {"statusCode": 400, "body": json.dumps({"error": "Missing bucket or image_key"})}

        # 2. Extract raw image bytes directly from Amazon S3 object storage
        s3_obj = s3_client.get_object(Bucket=bucket, Key=image_key)
        image_bytes = s3_obj["Body"].read()
        base64_image = base64.b64encode(image_bytes).decode("utf-8")
        
        # 3. Define the structured evaluation system instructions 
        system_prompt = (
            "Analyze the attached image of a packaged food product wrapper ingredient label with these specific steps:\n\n"
            "1. Text Extraction & Ingredient Identification: Locate and extract the primary ingredient list by looking for headers like 'Ingredients:', 'CONTAINS:', or regulatory tables.\n"
            "2. Hidden Allergen Analysis: Scan for primary dietary allergens (gluten, wheat, dairy, nuts, soy, eggs, fish) and facility cross-contamination warnings.\n"
            "3. Additives & Chemical Screening: Identify synthetic flavor enhancers (MSG), chemical preservatives (benzoate, BHA, BHT), artificial sweeteners, or trans fats.\n"
            "4. Nutritional Risk Profiling: Flag compounding factors like high-fructose corn syrup, multiple added sugars, or high relative salt/sodium compounds.\n"
            "5. Health Risk Rating: Assign a rating from 1-4:\n"
            "   - Rating 1 (Low Risk): Clean label, whole foods, no chemical preservatives or major allergens.\n"
            "   - Rating 2 (Moderate Risk): Minor processed stabilizers, low added sugar, clearly labeled allergens.\n"
            "   - Rating 3 (High Risk): Multiple synthetic additives, artificial flavors, chemical preservatives, or corn syrup.\n"
            "   - Rating 4 (Severe Risk): Heavily laden with artificial chemicals, hydrogenated trans fats, or unlabelled hazards.\n\n"
            "Provide your final response structured strictly as a clean JSON block with the following keys: 'ingredients_found', 'health_risk_rating' (the single number from 1-4), and 'brief_justification'. Do not include markdown wrappers or conversation."
        )

        # 4. Construct message payload utilizing helper format containing visual context blocks
        messages = [
            {
                "role": "user",
                "content": [
                    {
                        "type": "image",
                        "source": {
                            "type": "base64",
                            "media_type": "image/jpeg",
                            "data": base64_image
                        }
                    },
                    {
                        "type": "text",
                        "text": "Process this food label wrapper image according to instructions."
                    }
                ]
            }
        ]

        # 5. Invoke Amazon Bedrock with runtime configurations
        response = bedrock_client.invoke_model(
            modelId=MODEL_ID,
            contentType="application/json",
            accept="application/json",
            body=json.dumps({
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": 1000,
                "temperature": 0.0,
                "system": system_prompt,
                "messages": messages
            })
        )
        
        # 6. Parse and clean raw output text directly into database-ready structures
        raw_text = json.loads(response["body"].read())["content"][0]["text"].strip()
        if raw_text.startswith("```json"):
            raw_text = raw_text.split("```json")[1].split("```")[0].strip()
        
        analysis = json.loads(raw_text)

        # 7. Persist evaluation profile history record into Amazon DynamoDB NoSQL index
        scan_id = f"scan_{context.aws_request_id[:8]}"
        item = {
            "ScanID": scan_id,
            "UserID": user_id,
            "S3Location": f"s3://{bucket}/{image_key}",
            "IngredientsFound": analysis.get("ingredients_found"),
            "HealthRiskRating": int(analysis.get("health_risk_rating", 1)),
            "BriefJustification": analysis.get("brief_justification"),
            "Timestamp": datetime.utcnow().isoformat()
        }
        dynamodb.Table(TABLE_NAME).put_item(Item=item)

        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json", "Access-Control-Allow-Origin": "*"},
            "body": json.dumps({"status": "success", "scan_id": scan_id, "data": item})
        }

    except Exception as error:
        print(f"Execution failure: {str(error)}")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": "Failed to analyze food label wrapper", "details": str(error)})
        }
