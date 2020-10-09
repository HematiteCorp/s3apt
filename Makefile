BUCKET=your-bucket-to-put-templates
PREFIX=s3apt/
DOMAIN=your.domain.to.serve.s3apt.example.com
DOMAIN_CERT=your.domain.to.serve.s3apt.example.com

.PHONY:
create-cfn-bucket-stack: upload-templates
	aws cloudformation create-stack \
		--region us-east-1 \
		--stack-name s3apt-bucket \
		--template-url https://s3.amazonaws.com/$(BUCKET)/$(PREFIX)s3-apt-bucket.yml \
		--capabilities CAPABILITY_NAMED_IAM \
		--parameters ParameterKey=DomainName,ParameterValue=$(DOMAIN)

.PHONY:
create-cfn-api-stack: upload-templates
	$(eval CERT := $(shell aws acm list-certificates --region us-east-1 | jq ".CertificateSummaryList | map(select(.DomainName == \"$(DOMAIN_CERT)\"))[0].CertificateArn"))
	aws cloudformation create-stack \
		--region us-east-1 \
		--stack-name s3apt-api \
		--template-url https://s3.amazonaws.com/$(BUCKET)/$(PREFIX)s3-apt-api.yml \
		--capabilities CAPABILITY_NAMED_IAM \
		--parameters ParameterKey=S3BucketStackName,ParameterValue=s3apt-bucket \
		             ParameterKey=AcmCertificateArn,ParameterValue=$(CERT)

.PHONY:
delete-cfn-api-stack:
	aws cloudformation delete-stack \
		--region us-east-1 \
		--stack-name s3apt-api

.PHONY:
upload-templates:
	aws s3 cp ./cloudformation/s3-apt-bucket.yml s3://$(BUCKET)/$(PREFIX)
	aws s3 cp ./cloudformation/s3-apt-api.yml s3://$(BUCKET)/$(PREFIX)

