#!/usr/bin/env bash

set_hostname() {
    echo "oauth-vagrant" > /etc/hostname
    echo "127.0.0.1 oauth-vagrant" >> /etc/hosts
    hostname oauth-vagrant
}

install_sysvinit_script() {
    SYSVINIT_FILENAME=/etc/init.d/oauthforever
    if [[ ! -e "$SYSVINIT_FILENAME" ]]; then
	cp /vagrant/sysvinit.example $SYSVINIT_FILENAME
	chmod a+rx $SYSVINIT_FILENAME
	update-rc.d oauthforever start 20 2 3 4 5 . stop 20 0 1 6 .
    fi
}

update_apt_sources() {
    # nodejs
    apt-key adv --keyserver keyserver.ubuntu.com --recv C7917B12
    echo 'deb http://ppa.launchpad.net/chris-lea/node.js/ubuntu precise main' | tee /etc/apt/sources.list.d/10nodejs.list
    # Update apt-get to get 10gen stable packages
    apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10
    echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | tee /etc/apt/sources.list.d/10gen.list
}

ping_result="$(ping -c 2 8.8.4.4 2>&1)"
if [[ $ping_result != *bytes?from* ]]; then
    ping_result="$(ping -c 2 4.2.2.2 2>&1)"
fi

if [[ $ping_result == *bytes?from* ]]; then
    if [ ! -e "/etc/vagrant-provisioned" ]; then
	echo "Starting Vagrant provisioning process..."
	set_hostname
	update_apt_sources

	apt-get update --assume-yes
	apt-get install -y make g++ git curl vim libcairo2-dev libav-tools nfs-common portmap mongodb-10gen=2.4.10 nodejs libcap2-bin

	# Pin to the exact version above
	echo "mongodb-10gen hold" | dpkg --set-selections

	touch /etc/vagrant-provisioned
    else
	echo "Vagrant provisioning already completed. Skipping..."
	# TODO: do upgrade
	exit 0
    fi

    su vagrant <<EOF
cd /home/vagrant
cp /vagrant/package.json .
echo "Installing npm modules..."
npm install
sed -i "s/8081/80/" node_modules/oauth2-provider/examples/simple_express3.js
EOF
    
    # allow bind < 1024 for non-root users
    setcap cap_net_bind_service=ep /usr/bin/nodejs

    if [[ ! -d "/usr/bin/forever" ]]; then
	npm install -g forever
    fi

    install_sysvinit_script
    /etc/init.d/oauthforever restart

    echo "-----------------------------------------------------------------"
    echo "OAuth test up at : http://192.168.33.10"
    echo "More info at     : https://github.com/ammmir/node-oauth2-provider"
    echo "-----------------------------------------------------------------"
fi
