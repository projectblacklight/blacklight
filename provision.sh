#!/usr/bin/env bash
sudo yum install -y epel-release
sudo yum install -y curl git java-1.7.0-openjdk-devel nodejs yum-utils gcc bzip2 kernel-devel dkms

su - vagrant -c 'gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3'
su - vagrant -c 'curl -sSL https://get.rvm.io | bash -s stable'
su - vagrant -c 'rvm 2.2.3 --install --default'
su - vagrant -c 'gem install bundler'
su - vagrant -c 'cd /home/vagrant/sync && bundle install'
su - vagrant -c 'cd /home/vagrant/sync && rake engine_cart:generate'

echo "
Now to start Solr and Blacklight run the following from within the Blacklight directory:

vagrant ssh
cd /home/vagrant/sync
rake blacklight:server[\"-b 0.0.0.0\"]

Now you can make changes to Blacklight and see the results.
"
