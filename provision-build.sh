export AWS_MAX_ATTEMPTS=1000
export AWS_POLL_DELAY_SECONDS=600
export PACKER_LOG=1
export PACKER_LOG_PATH='./log'
packer validate -var "ami_name=$1" provision-build.json
packer build -on-error=abort -var "ami_name=$1" -force provision-build.json

