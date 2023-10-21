# Coaching - Building and Automating a Dockerized Python Web Application using Trunk Based Development

Creating a feature-flagged Python web application and deploying it through a pipeline involves multiple stages, including writing the application, integrating the feature flag, and setting up a CI/CD pipeline for deployment. 


Step 1: Writing the Flask Application

First, we'll create a simple Flask application. If you don't have Flask installed, you can install it using 
``````
pip install Flask
``````
Now, create a file named app.py and write your Flask application. Below is a simple web application with a feature flag for demonstration:

```python
# app.py
from flask import Flask
import os

app = Flask(__name__)

# Feature flag
NEW_FEATURE = os.getenv("NEW_FEATURE") == "true"


@app.route('/')
def hello_world():
    if NEW_FEATURE:
        return 'New Feature is ON!'
    else:
        return 'Old Feature is running.'


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')
```

In this script, we check for an environment variable "NEW_FEATURE" to toggle between features.

Step 2: Dockerizing the Flask Application

For easier deployment, you can containerize your application with Docker. Create a file named Dockerfile in your project directory and add the following content:



````Dockerfile
# Use an official Python runtime as a parent image
FROM python:3.8-slim

#### Set environment variables ####
# This prevents Python from writing out pyc files
ENV PYTHONDONTWRITEBYTECODE 1
#Force the stdout and stderr streams to be unbuffered
ENV PYTHONUNBUFFERED 1 

# Set work directory
WORKDIR /app

# Install dependencies
COPY requirements.txt /app/
RUN pip install --upgrade pip && pip install -r requirements.txt

# Copy project
COPY . /app/

# Run the application
CMD ["python", "app.py"]
```````

And don't forget to define your Flask dependency in a requirements.txt file:
``````
Flask==2.0.2 # Use the current version you're working with
``````


Step 3: Setting Up GitHub Actions for CI/CD

Manually create a .github/workflows directory in your project, then add a workflow file, e.g., ci-cd-pipeline.yml.

Define the following workflow in the ci-cd-pipeline.yml. This configuration sets up a CI/CD pipeline that automatically deploys your Dockerized application when you push to the repository.

``````
name: CI/CD Pipeline

on:
  push:
    branches:
      - main  

jobs:
  build:
    runs-on: ubuntu-latest
    environment: dev

    steps:
      - name: Check out code
        uses: actions/checkout@v2
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v1
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ap-southeast-1
      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v1
  
      - name: Build, tag, and push image to Amazon ECR
        id: build-image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          ECR_REPOSITORY: sctp-my-app
          IMAGE_TAG: latest
        run: |
          # Build a docker container and
          # push it to ECR so that it can
          # be deployed to ECS.
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          echo "::set-output name=image::$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG"
       # deploy the ECS cluster and related resources(We are using the pushed image to deploy the ECS fargate task)
      - name: 'Setup Terraform'
        uses: hashicorp/setup-terraform@v1

      - name: 'Terraform Init'
        run: terraform init
        working-directory: ./terraform

      - name: 'Terraform Plan'
        run: terraform plan
        working-directory: ./terraform

      - name: 'Terraform Apply'
        run: terraform apply -var='environment=[{"name":"NEW_FEATURE","value":"${{ secrets.NEW_FEATURE }}"}]' -auto-approve
         # Be cautious with auto-approve in production environments
        working-directory: ./terraform
``````


Step 4: Pushing Your Code

Add the files to your local Git repository:

```
git add .
```
Commit the changes:
``````
git commit -m "Add a feature-flagged Flask app with CI/CD"
``````
Push your changes to GitHub:
``````
git push origin main
``````
After you push your code, GitHub Actions triggers the CI/CD pipeline based on your workflow definition and deploys it on ECS cluster as a container.

Please ensure you have the necessary secrets (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY) stored in your repository's Environment secrets section. Store NEW_FEATURE variable in your repository's Environment variables section.


NEW_FEATURE is a feature toggle.

To hide the feature 
``````
NEW_FEATURE=false 
``````

To expose the new feature
``````
NEW_FEATURE=true 
``````

once the feature is ready to deploy,you can turn on the feature by setting NEW_FEATURE=true in your repository's Environment secrets section.

