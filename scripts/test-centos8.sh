#!/bin/bash

# Setup
export CI_TEST_USER=tapioca
export CI_TEST_PASS=queijo

# do the test
sudo useradd -d /tmp ${CI_TEST_USER}
id ${CI_TEST_USER}

sudo yum -y install \
        freeradius freeradius-utils \
        syslog-ng \
        openssh-server sshpass

echo "#######################################################"
echo "## Stop the services syslog-ng/sshd/freeradius"
( sudo rm -f /var/log/secure && \
  sudo touch /var/log/secure && \
  sudo chmod 600 /var/log/secure
)

sudo killall -q -9 syslog-ng radiusd sshd || :
# https://stackoverflow.com/questions/47973554/how-to-let-syslog-workable-in-docker
sudo sed -i 's/system()/# system()/g' /etc/syslog-ng/syslog-ng.conf
sudo /usr/sbin/syslog-ng --no-caps

echo "#######################################################"
echo "## Setup the services"
export CI_TEST_USER="$CI_TEST_USER" CI_TEST_PASS="$CI_TEST_PASS"
for i in setup-pam_radius.sh setup-freeradius.sh setup-sshd.sh; do
    script="/opt/src/pam_radius.git/scripts/ci/$i"

    echo "Calling $script"
    sudo -E $script
done

echo "#######################################################"
echo "## Start the services sshd"
echo | sudo ssh-keygen -A
sudo /usr/sbin/sshd
sudo rm -f /run/nologin # Needed to enable the log in!

echo "## Start the services radiusd"
( sudo make -C /etc/raddb/certs/ destroycerts all && \
  sudo sed 's/dh_file =/#dh_file =/g' -i /etc/raddb/mods-available/eap && \
  sudo chmod 0644 /etc/raddb/certs/server.pem
)
sudo /usr/sbin/radiusd

echo "#######################################################"
echo "## Show processes"!
ps aux | grep -E "([r]adius|[s]sh|[s]yslog)"

if ! radtest -x $CI_TEST_USER $CI_TEST_PASS localhost 0 testing123; then
  echo "ERROR: Something goes wrong with the RADIUS authentication!"
  echo "############## Show the logs in /var/log/secure"
  exit 1
fi

if ! sshpass -p "${CI_TEST_PASS}" -v \
  /usr/bin/ssh -T -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p 22 ${CI_TEST_USER}@localhost id; then
    echo "ERROR: Something goes wrong with the SSH + PAM_RADIUS authentication!"
    echo "############## Show the logs in /var/log/secure"
    sudo tail -35 /var/log/secure
    exit 1
fi
