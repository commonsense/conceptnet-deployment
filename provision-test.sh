export PACKER_LOG=1
export PACKER_LOG_PATH='./log'
packer validate \
	-var "ami_owner=$1" \
	-var "ami_name=$2" \
	provision-test.json
packer build \
	-var "ami_owner=$1" \
	-var "ami_name=$2" \
	provision-test.json
