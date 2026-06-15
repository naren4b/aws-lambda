# AI driven Fire Risk Assessments 
_S3 | AWS Lambda | DynamoDB | Claude_

In some part of the US, Home Fire Insurance Company requires home owners to trim or remove the trees arround the resendencies
Sending an inspector out to each property would be expensive 
Solution: Get high resoultion up-to-date satellite imagery, ask a LLM(Claude) for a fire risk assessment

This repo try to solve with following AWS components 
- S3 : Storing Images and Analyzed Fire Risk Assessments Reports(PDF)
- AWS Lambda: Processing the image and storing them in DB and S3 
- DynamoDB: Holds the Residence identification
- Claude: Analyze the Image and gives Fire risk rating with a brief justification 
