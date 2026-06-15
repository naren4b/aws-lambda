# AI driven Fire Risk Assessments 
_API Gateway | AWS Lambda | S3 | DynamoDB | Claude_

In some part of the US, Home Fire Insurance Company requires home owners to trim or remove the trees arround the resendencies
Sending an inspector out to each property would be expensive 
Solution: Get high resoultion up-to-date satellite imagery, ask a LLM(Claude) for a fire risk assessment

This repo try to solve with following AWS components 
- API Gateway: receives the request with Image and metadata information.
- AWS Lambda: Processing the image and storing them in DB and S3 
- S3 : Storing Images and Analyzed Fire Risk Assessments Reports(PDF)
- DynamoDB: Holds the Residence identification
- Claude: Analyze the Image and gives Fire risk rating with a brief justification 
<img width="1293" height="959" alt="aws-fra-design" src="https://github.com/user-attachments/assets/5a65a303-00cc-4b5d-b833-f7917d6a23d8" />
