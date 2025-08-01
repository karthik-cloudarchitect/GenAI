import boto3
import json

# Create Bedrock client
bedrock_runtime = boto3.client("bedrock-runtime", region_name="ap-southeast-2")

def lambda_handler(event, context):
    user_prompt = event.get("prompt", "Show me how to create an EKS cluster using eksctl")

    prompt = f"""You are a skilled AWS DevOps engineer.
Generate exactly one final eksctl CLI command to achieve the following request.
Only provide the command on a single line. The line must start with a hash (#) as a comment. 
Do not include any text like "Action:", no explanations, no markdown, no additional output. 
Strictly provide only this line, as shown in this example:

# eksctl create cluster --name=eksdemo1 --region=us-west-2 --zones=us-west-2a,us-west-2b --without-nodegroup

Request: {user_prompt}
"""

    response = bedrock_runtime.invoke_model(
        modelId="amazon.titan-text-lite-v1",
        contentType="application/json",
        accept="application/json",
        body=json.dumps({
            "inputText": prompt,
            "textGenerationConfig": {
                "maxTokenCount": 500,
                "temperature": 0.2,
                "topP": 1
            }
        })
    )

    response_body = json.loads(response["body"].read())

    return {
        'statusCode': 200,
        'body': response_body["results"][0]["outputText"]
    }
