# GenAI EKS Command Generator
This project provides an end-to-end serverless solution to generate production-ready AWS EKS (eksctl) commands on-demand using Amazon Bedrock foundation models (Titan), AWS Lambda, and API Gateway.


⚙️ How it works
```
User sends a JSON prompt to API Gateway endpoint.
Lambda parses prompt, builds strict prompt text, and calls Amazon Bedrock.
Bedrock generates a single-line eksctl command.
Response returned to client via API Gateway.
```

## Deploy
```
*****Clone the repo****
Ensure You have AWS Credentials/OIDC for deployment
cd terraform
terraform init
terraform plan
terraform apply
```

## Test Lambda (local CLI)
```
aws lambda invoke \
  --function-name eks-genai-handler \
  --region ap-southeast-2 \
  --cli-binary-format raw-in-base64-out \
  --payload file://payload.json \
  output.json

cat output.json
```


## Test API Gateway
```
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"prompt":"Create an EKS cluster with two managed node groups in ap-southeast-2"}' \
  https://<your-api-id>.execute-api.ap-southeast-2.amazonaws.com/dev/generate
```

## Output
```
# eksctl create cluster --name=eksdemo1 --region=ap-southeast-2 --zones=ap-southeast-2a,ap-southeast-2b --without-nodegroup
```

## Future improvements
```
Remove occasional "Action:" prefix from model.

Add API authentication.

Add frontend UI.
```

## Contributions
Feel free to fork, open issues, or submit PRs!
