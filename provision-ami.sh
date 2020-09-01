# set an unreasonably long timeout for waiting for the AMI to become ready
# you will get an inscrutable "error: <nil>" without this
export AWS_MAX_ATTEMPTS=1000
export AWS_POLL_DELAY_SECONDS=600

export PACKER_LOG=1
export PACKER_LOG_PATH='./log'

# make sure the settings file is valid
packer validate -var "ami_name=$1" provision-ami.json

# build the AMI
packer build -on-error=abort -var "ami_name=$1" -force provision-ami.json

