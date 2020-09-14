#!/bin/bash
#
# This script installs ConceptNet on the machine you're on with Puppet, instead
# of provisioning an AMI using Packer.

confirm() {
    # call with a prompt string or use a default
    read -r -p "${1:-Are you sure? [y/N]} " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            true
            ;;
        *)
            false
            ;;
    esac
}

echo "This script uses Puppet to manage the users and packages on the system."
echo "We recommend running it on a fresh cloud machine or VM, not on a machine you use for other things."
echo "Because this takes over management of the system, you'll need to use 'sudo' or run this script as root."

confirm 'Continue? [y/N]' && puppet apply --modulepath modules/ manifests/install/conceptnet.pp
