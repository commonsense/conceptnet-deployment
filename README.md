# ConceptNet Delivery

This repository facilitates the creation of new ConceptNet AWS [AMIs](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) using [Packer](http://www.packer.io). The tutorial details creating a new EC2 instance for Packer, with appropriate security configurations, installing Packer, and finally using this repository to create ConceptNet AMIs from the [ConceptNet5 Github repository](https://github.com/commonsense/conceptnet5).

## At a Glance
### provision-build.sh
Builds the ConceptNet AMI. If the build process is successful a new ConceptNet AMI is created with a high-performance webserver.

### provision-test.sh
Runs the ConceptNet tests. If the tests are successful a another new ConceptNet AMI is created. It's suggested that you use this AMI instead of the one created by provision-build.sh, and delete the one created by provision-build.sh.

### modules
Contains [Puppet](https://puppet.com/docs) dependencies for provisioning the server.
These can be upgraded using the instructions under [Upgrading Modules](#Upgrading-Modules).

## Usage
To safeguard AWS resources, we create AMIs from an existing EC2 instance running Packer, as opposed to running Packer on a machine outside of AWS. This allows the instance to access EC2 resources and make EC2 API requests to provision the server, without the need to generate long-lived access credentials. For more information see the [IAM role guide](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-ec2.html).
This tutorial covers the steps needed to create an IAM role, install Packer on an EC2 instance, and use Packer to provision a new ConceptNet AMI.

For security, this repository will only work within the **us-east-1** [region](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.RegionsAndAvailabilityZones.html).

### [Create your IAM role](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html#create-iam-role) with attached [policy](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_id-based)
1. On the *Create role* page select EC2.
2. Next on the *Permissions* page, you'll need to attach a policy which grants the EC2 instance (and by extension Packer) access to the EC2 resources it will need to create the AMI.

   Click *Create Policy*. This will open a new dialogue window for creating the policy. In the policy creation page, paste the contents of *packer-policy.json* into the JSON tab. Give the policy a name and create it. The policy provided can create EC2 resources only in the us-east-1 region. To change this, you can modify the value for the *"aws:RequestedRegion"* key. This is to limit the impact should an unauthorized user gain access to the role.  

3. Back in the *Permissions* window of the *IAM role* dialogue, refresh the available policies with the refresh button. Then select the policy you created.
4. Click through the optional *Add tags* page.
5. On the *Review* page, give the new IAM role a name and create it.

### [Create the EC2 instance](https://docs.aws.amazon.com/quickstarts/latest/vmlaunch/step-1-launch-instance.html) that runs Packer
Packer will run on this instance, and use the associated IAM role to access EC2 resources to create and provision a ConceptNet instance from which to create an AMI.
1. On the *Choose an Amazon Machine Image* page, choose a common Linux distribution which supports Packer (for example Amazon Linux 2, or Ubuntu 18.04).
2. Next on the *Choose an Instance Type* page, select an instance type. This can be an inexpensive low-resource instance (for example a t2.micro), as it's only going to make EC2 API calls.
3. Click though to the *Configure Instance Details* page, and for *IAM role* select the IAM role you created.
4. Make sure the keys you use to connect to the instance are kept secret, as anyone with access to the instance can create EC2 resources on your account.
5. For additional security, on the *Configure Security Group*, [create a security group](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-network-security.html) which allows only known IP addresses to connect to the instance. The details of security group creation are outside the scope of this tutorial.
6. *Review* and launch the instance.

### Configure the instance for ConceptNet AMI provisioning
1. [Connect to the instance via SSH](https://docs.aws.amazon.com/quickstarts/latest/vmlaunch/step-2-connect-to-instance.html), and install Packer using the [provided tutorial](https://www.packer.io/intro/getting-started/install.html).

2. Clone the conceptnet-packer repository to the instance, or upload it via SFTP:
```
git clone https://github.int.luminoso.com/Research/conceptnet-packer
cd conceptnet-packer
```

### Create the AMI
To start the process of creating the AMI, run the *provision.sh* script, which sets timeout variables for Packer, and validates the Packer provisioning JSON before building the AMI using it. *[ami_name]* is the name of the AMI which will be created. This should be unique.
```
./provision-build.sh [ami_name]
```

This will create a new Ubuntu 18.04 ConceptNet AMI with ConceptNet installed. The build process starts a r4.xlarge instance with 300GB of EBS storage.

It installs ConceptNet from scratch by downloading and processing necessary dependencies and data. **This takes about 18 hours.** If the build fails and Packer can still connect to the relevant AWS resources, Packer will cleanup the associated EC2 resources. **In certain situations, Packer may not be able to terminate the instance and storage, which will continue to incur costs.**


## Testing
To test, run the following command, supplying the owner id of the AMI and the AMI name. If the [pytest](https://docs.pytest.org/en/latest/) tests run successfully, a new AMI will be generated which can be used for experiments or further testing.

*[owner_id]* is the [account id](https://docs.aws.amazon.com/IAM/latest/UserGuide/console_account-alias.html) of the owner of the AMI to be tested. This will be your own account id if you created an AMI with the *provision-build.sh* script.

*[ami_name]* is the name of the AMI which will be tested.
```
./provision-test.sh [owner_id] [ami_name]
```

## Upgrading Modules
(from [Tools/puppet](https://github.int.luminoso.com/Tools/puppet))
- Checkout to your branch
- Search for modules you need: `puppet module search $module_name`
- Install module you need: `puppet module install $module_name --target-dir /path_to_puppet_repo/sdk/`
- List installed modules to verify existence and location: `puppet module list --modulepath /path_to_puppet_repo/sdk/`
- Uninstall module: `puppet module uninstall $module_name`
- Upgrade module: `puppet module upgrade $module_name`
- After performing all the tests create a PR to push it to production branch if you like it
