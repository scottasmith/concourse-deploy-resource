	#!/usr/bin/env bash

set -o errexit
set -o pipefail
set +x

function create_uniquish_repo {
	local REPO_NAME=$1

	echo $(_normalise_repo_name $REPO_NAME)-$(date +%Y-%m-%d_%H%M%S`)
}

# Create deploy script for remote server, copy archive to it and execute script on remote
# Returns file containing script. The caller is responsible for deleting this file
#
# create_deploy_script 'repo_name' '/var/sites' 'MD5_STRING'
#
function create_deploy_script {
	local REPO_NAME=$1
	local REMOTE_DIR=$2
	local LOCAL_DIR=$3

	local SITES_DIR=$REMOTE_DIR
	local TMP_SCRIPT=$(mktemp /tmp/example.XXXXXXXXXX) || exit 1
	local NORMALISED_REPO_NAME=$(_normalise_repo_name $REPO_NAME)
    local SITE_DIR=$SITES_DIR/$LOCAL_DIR

	echo -e "#!/bin/bash\nset -o errexit\n" > $TMP_SCRIPT

	_write_deploy_build_clean $TMP_SCRIPT $SITES_DIR $NORMALISED_REPO_NAME
	_write_deploy_build_activate $TMP_SCRIPT $SITES_DIR $NORMALISED_REPO_NAME $SITE_DIR

    echo $TMP_SCRIPT
}

# Private function
#
function _write_deploy_build_clean {
	local TMP_SCRIPT=$1
	local SITES_DIR=$2
	local REPO_NAME=$3
	local DAYS_OLD="1"

	cat >> $TMP_SCRIPT <<EOF
echo "Cleaning older builds"
find $SITES_DIR -maxdepth 1 -type d -name $REPO_NAME-* | sort | head -n -8 | xargs rm -rf
EOF
}

# Private function
#
function _write_deploy_build_activate {
	local TMP_SCRIPT=$1
	local SITES_DIR=$2
	local REPO_NAME=$3
	local SITE_DIR=$4

	cat >> $TMP_SCRIPT <<EOF
pushd $SITES_DIR > /dev/null
echo "Activating deploy"
rm -rf $REPO_NAME
ln -sfT $SITE_DIR $REPO_NAME
popd > /dev/null
EOF
}

# Private function
#
function _normalise_repo_name {
	local REPO_NAME=$1

	echo $REPO_NAME | sed 's/-/_/'
}
