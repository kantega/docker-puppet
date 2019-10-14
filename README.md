# Puppet

Docker compose setup of the Puppet server stack

## Getting started with Puppet server

Most of this setup works out of the box, but there are some limitations/issues to get PuppetDB automatically up and running.

Start by copying the `environment-template` to `.env` and set the versions you want to use/build, postgres password, puppetserver hostname (should be set to what agents will be using), etc.

Further, edit `docker-compose.yaml` and ensure that the ssl folder volume mount for the `puppetdb` service is commented _out_

```
vim docker-compose.yaml
[...]
#    - ./data/puppetdb/ssl:/etc/puppetlabs/puppetdb/ssl
[...]
```
Then, optionally (otherwise, comment it out in docker-compose.yaml), build the Puppetboard application:
```
cd ..
git clone https://github.com/voxpupuli/puppetboard
cd puppetboard
docker build -t puppetboard .
```
Back in the folder where you checked out puppet, start the stack with:
```
docker-compose up -d
```
This will create and start postgres, puppet, puppetdb and puppetboard. Puppetdb will create certificates and act as though it were a puppet agent, and wait for the puppetserver to sign its CSR. So, while the containers is running, exec into the puppetserver and sign the puppetdb cert.

```
docker exec -it puppet bash
puppetserver ca sign --certname puppetdb
```
If you're tailing the logs, you'll see that puppetdb (eventually) continues its setup and starts the puppetdb service. At this point, the stack works, but the certificates for puppetdb isn't persistent, so copy out puppetdb's certs with:
```
docker cp puppetdb:/etc/puppetlabs/puppetdb/ssl data/puppetdb/ssl
chown -R 999:999 data/puppetdb/ssl
```
Now, edit `docker-compose.yaml` again and comment _in_ the ssl cert volume mount for puppetdb:
```
vim docker-compose.yaml
[...]
    - ./data/puppetdb/ssl:/etc/puppetlabs/puppetdb/ssl
[...]
```
And, finally, reboot the whole stack to ensure that it's working as expected:
```
docker-compose down && docker-compose up -d && docker-compose logs -f
```

## Encrypting secrets with eyaml

Setup according to https://github.com/voxpupuli/hiera-eyaml
It basically boils down to:
* install the eyaml package (included in the `Dockerfile`)
* Create the keys with `eyaml createkeys`
* Start encrypting secrets described in https://github.com/voxpupuli/hiera-eyaml#basic-usage

## Setting up a Puppet agent

First, install the latest Puppet yum repo (here Puppet6 on CentOS/RedHat7):

```
rpm -Uvh https://yum.puppet.com/puppet6/puppet6-release-el-7.noarch.rpm
```

Install the Puppet agent package

```
yum install puppet-agent
```

Tell the client where to find the Puppet Server and which environment it should join
```
vim /etc/puppetlabs/puppet/puppet.conf
[agent]
server=puppet.example.com
environment=production
```
Before you do a "puppet-run", ensure that you have a `hostname --fqdn` following the DNS name scheme used for your organization. You can change hostname with e.g.
```
hostnamectl set-hostname postgres01.prod.oslo.example.com
```
You can also specify a certname equal to or different from `$(hostname --fqdn)` in `puppet.conf` with `certname=`

Do the first puppet run, creating the certificates for this server:
```
/opt/puppetlabs/bin/puppet agent -t
```
At this stage, the certificates created is up for signing at the Puppet server. Log into the Puppet server and sign this certificate, e.g:
```
ssh puppet.example.com                                            # Log into the puppet server
docker exec -it puppet bash                                       # Exec into the container running puppet
puppetserver ca list --all                                        # Optional step, listing all certificates signed and unsigned
puppetserver ca sign --certname postgres01.prod.oslo.example.com  # Actuall signing of certificate
puppetserver ca list --all                                        # Optional step, listing all certificates (for verification)
exit                                                              # Exit out of container and server
```
At this stage, the relationship between the Puppet server and the agent is established. *Back on the Puppet agent* (postgres01.prod.oslo.example.com), do another puppet run
```
/opt/puppetlabs/bin/puppet agent -t
```
You should now see text flying across the screen with a bunch of Puppet-specific config but also the configuration you have defined for this host in your environment.

## Autosign based on bash script

With _policy based autosigning_, incomming CSRs can be signed based on logic in an executable, e.g. `bash`
For the puppetserver, set the $AUTOSIGN environment variable to the path to the script and volume mount this script in docker-compose. The script could look something like:

```
#!/usr/bin/env bash

re="^([a-z][a-z][a-z][a-z][a-z][a-z])\.(example)\.(com)$"

if [[ $1 =~ $re ]]; then
  # Autosign approved
  exit 0
else
  # Autosign denied
  exit 1
fi
```
Reference: [policy based autosigning](https://puppet.com/docs/puppet/6.2/ssl_autosign.html#enabling-policy-based-autosigning)

