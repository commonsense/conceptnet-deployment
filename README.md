# ConceptNet Deployment

This repository facilitates the creation of new ConceptNet AWS [AMIs][] using
[Packer][] and [Puppet][].

The tutorial details creating a new EC2 instance for Packer, with appropriate
security configurations, installing Packer, and finally using this repository
to create ConceptNet AMIs from the [ConceptNet5 Github
repository][conceptnet5].

[AMIs]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html
[Packer]: http://www.packer.io
[Puppet]: https://puppet.com/
[conceptnet5]: https://github.com/commonsense/conceptnet5


## There might be an easier way

If you just want to run your own copy of ConceptNet, you can launch it from
an AMI where we've already run these instructions. See
[Running your own copy][] on the ConceptNet wiki.

[Running your own copy]: https://github.com/commonsense/conceptnet5/wiki/Running-your-own-copy



## Important things in this repository

### provision-ami.sh

Builds the ConceptNet AMI using Packer. If the build process is successful, a
new ConceptNet AMI is created, which you can launch to host a copy of
ConceptNet with a database and webserver.

This is the method of deploying ConceptNet that matches our deployment.

### setup-with-puppet.sh

A script that sets up *this* machine to run ConceptNet, instead of creating a
machine image using Packer. See "Installing ConceptNet using Puppet" below.


### manifests

Contains the Puppet files that describe how to set up ConceptNet.

### modules

Contains [Puppet](https://puppet.com/docs) dependencies for provisioning ConceptNet.
These can be upgraded using the instructions under [Upgrading Modules](#Upgrading-Modules).


## Creating a ConceptNet image using Packer

This section will step through how to create a ConceptNet machine image
on Amazon Web Services. If you don't want to do this, skip to
"Installing ConceptNet using Puppet".

To safeguard AWS resources, we create AMIs from an existing EC2 instance
running Packer, as opposed to running Packer on a machine outside of AWS.

This allows the instance to access EC2 resources and make EC2 API requests to
provision the server, without the need to generate long-lived access
credentials. For more information see the [IAM role guide][].

[IAM role guide]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-ec2.html

This tutorial covers the steps needed to create an IAM role, install Packer on
an EC2 instance, and use Packer to provision a new ConceptNet AMI.

This repository will only work within the **us-east-1** region.


### Creating IAM policies

Within AWS, you need to create an [IAM role][] with an attached [policy][IAM policy].

[IAM role]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html#create-iam-role
[IAM policy]: https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_id-based

1. On the *Create role* page select EC2.

2. Next on the *Permissions* page, you'll need to attach a policy which grants
   the EC2 instance (and by extension Packer) access to the EC2 resources it
   will need to create the AMI.

   Click *Create Policy*. This will open a new dialogue window for creating the
   policy. In the policy creation page, paste the contents of
   `packer-policy.json` into the JSON tab. Give the policy a name and create
   it. The policy provided can create EC2 resources only in the us-east-1
   region. To change this, you can modify the value for the
   `"aws:RequestedRegion"` key. This is to limit the impact should an
   unauthorized user gain access to the role.

3. Back in the *Permissions* window of the *IAM role* dialogue, refresh the
   available policies with the refresh button. Then select the policy you
   created.

4. Click through the optional *Add tags* page.

5. On the *Review* page, give the new IAM role a name and create it.


### Creating the EC2 instance

The next step is to [create an EC2 instance][] that runs Packer.

[Create an EC2 instance]: https://docs.aws.amazon.com/quickstarts/latest/vmlaunch/step-1-launch-instance.html

Packer will run on this instance, and use the associated IAM role to access EC2
resources to create and provision a ConceptNet instance from which to create an
AMI.

1. On the *Choose an Amazon Machine Image* page, choose a common Linux
   distribution which supports Packer (for example, Ubuntu 20.04).

2. Next on the *Choose an Instance Type* page, select an instance type. This
   can be an inexpensive low-resource instance (for example a t2.micro), as
   it's only going to make EC2 API calls.

3. Click though to the *Configure Instance Details* page, and for *IAM role*
   select the IAM role you created.

4. Make sure the keys you use to connect to the instance are kept secret, as
   anyone with access to the instance can create EC2 resources on your account.

5. For additional security, on the *Configure Security Group*, [create a
   security group][]
   which allows only known IP addresses to connect to the instance. The details
   of security group creation are outside the scope of this tutorial.

6. *Review* and launch the instance.

[create a security group]: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-network-security.html


### Configure the instance for ConceptNet AMI provisioning

1. [Connect to the instance via SSH](https://docs.aws.amazon.com/quickstarts/latest/vmlaunch/step-2-connect-to-instance.html), and install Packer using the [provided tutorial](https://www.packer.io/intro/getting-started/install.html).

2. Clone the conceptnet-deployment repository to the instance:

```
git clone https://github.com/commonsense/conceptnet-deployment
cd conceptnet-deployment
```

### Create the AMI

To start the process of creating the AMI, run the *provision-ami.sh* script,
which sets timeout variables for Packer, and validates the Packer provisioning
JSON before building the AMI using it. *[ami_name]* is the name of the AMI
which will be created. This should be unique.

```
./provision-ami.sh [ami_name]
```

This will create a new Ubuntu 20.04 ConceptNet AMI with ConceptNet installed.
The build process starts a r4.xlarge instance with 300GB of EBS storage.

It installs ConceptNet from scratch by downloading and processing necessary
dependencies and data. **This takes about 18 hours.** If the build fails and
Packer can still connect to the relevant AWS resources, Packer will cleanup the
associated EC2 resources.

**In certain situations, Packer may not be able to terminate the instance and
storage, which will continue to incur costs.**


## Upgrading Modules

If at some point you need to update the Puppet modules that build the image,
here are some helpful commands:

- Search for modules you need: `puppet module search $module_name`
- Install module you need: `puppet module install $module_name --target-dir
  modules/`
- List installed modules to verify existence and location: `puppet module list
  --modulepath modules/`
- Uninstall module: `puppet module uninstall $module_name --modulepath modules/`
- Upgrade module: `puppet module upgrade $module_name --modulepath modules/`


## Installing ConceptNet using Puppet

This is the path we suggest if you've separately created a cloud machine or
VM where you want to build ConceptNet, and especially if you don't want to
run Amazon.

You will want to run this on a _fresh_ machine that has Puppet 5 or later.
We recommend using Ubuntu 20.04.

Don't run this on a machine you use for other things! Puppet is a cloud
automation system. It takes over the configuration of your system, because
that's what it's for.

Assuming this is what you want to do, you should run:

```
sudo ./setup-with-puppet.sh
```

When that is done, you'll have a `conceptnet` user with the ConceptNet code,
and a PostgreSQL database that's ready to support ConceptNet but currently
empty. The next thing to do is to build the ConceptNet data.

```
sudo su conceptnet
cd ~/conceptnet5
./build.sh
```

This will take several hours.

### Testing

You can test that the ConceptNet code and build process work as expected by running the test suite using _pytest_. The actual database doesn't necessarily have to be built, because the tests run a small example build as part of their setup.

First install the test dependencies:

    pip install pytest PyLD

Then you can run the test suite:

    pytest

If you have built the full ConceptNet database, you can add tests that are usually skipped that test that the database is working correctly:

    pytest --fulldb

### What you get

Here are some useful outputs of the build process:

* The `conceptnet5` PostgreSQL database, containing an index of all the edges
* `assertions/assertions.csv`: A CSV file of all the assertions in ConceptNet
* `assertions/assertions.msgpack`: The same data in the more efficient (and
  less readable) msgpack format
* `edges/`: The edges from individual sources that these assertions were built
  from.
* `stats/`: Some text files that count the distribution of different languages,
  relations, and datasets in the built data.
* `assoc/reduced.csv`: A tabular text file of just the concept-to-concept
  associations (plus additional 'negated concept' nodes that represent negative
  relations), filtered for concepts that are referred to frequently enough
* `vectors/mini.h5`: A vector space of high-quality word embeddings built from
  an ensemble of ConceptNet, word2vec, and GloVe, stored as a Pandas data frame
  in HDF5 format

Some other files you can build by request (type `snakemake` followed by the file name):

* `data/vectors/numberbatch.h5`: the full ConceptNet Numberbatch matrix, with a
  larger vocabulary and more precision than `vectors/mini.h5`
* `data/stats/evaluation.h5`: evaluation results comparing `numberbatch.h5` to
  other pre-computed word embeddings

## Running the Web server

If you ran the Puppet installation, then the Web server that serves the API will be running for you, and all you need to do is restart the process:

```
sudo systemctl restart conceptnet
```

