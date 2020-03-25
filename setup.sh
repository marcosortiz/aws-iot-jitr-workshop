###############################################################################
# Please make sure yout Cloud9 instance is using Ubuntu OS
###############################################################################

# Downloading src code
git clone https://github.com/marcosortiz/aws-iot-jitr-workshop.git
cd aws-iot-jitr-workshop

# install prereqs
sudo apt install -y jq
sudo apt install -y mosquitto-clients

# Create your s3 bucket
S3_BUCKET=<bucket-name-here>
aws s3 mb s3://$S3_BUCKET

# Upload CloudFormation template
aws cloudformation package \
--s3-bucket $S3_BUCKET \
--template-file node_modules/@aws-blocks/just-in-time-registration/cloudformation.yml \
--output-template-file cfn.package.yml

# Deploy Cloudformation template
aws cloudformation deploy \
--stack-name just-in-time-registration \
--template-file cfn.package.yml \
--capabilities CAPABILITY_IAM \
--parameter-overrides LogEventsToDynamo="true" LogEventsToCloudWatch="true"

# Create the Root CA
cd node_modules/@aws-blocks/jitr-workshop/bin/certificate-scripts
chmod +x create-and-register-ca.sh
./create-and-register-ca.sh

# Connect your first thing
chmod +x create-device-certificate.sh
./create-device-certificate.sh

IOT_ENDPOINT=$(aws iot describe-endpoint --endpoint-type iot:Data-ATS | jq -r '.endpointAddress')

mosquitto_pub -d \
--cafile aws-root-cert.pem \
--cert device-certs/device-and-ca-certificate.crt \
--key device-certs/device-certificate.key \
-h $IOT_ENDPOINT \
-p 8883 \
-t device/thing-1234-5678-9123 \
-i thing-1234-5678-9123 \
--tls-version tlsv1.2 \
-m "Hello World !"
