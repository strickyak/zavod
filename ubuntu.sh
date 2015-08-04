#!/bin/bash
# Assimilate an Ubuntu host.
#   Usage:
#     sh ubuntu remote.host.name
set -ex
REMOTE=$1 ; shift
case $REMOTE in
  [1-9a-z]* ) : ok ;;
  * ) echo "Bad REMOTE: '$REMOTE'" >&2 ; exit 13
esac
# Assume that this script lives in a /zavod/ directory.
DIR="$(dirname $0)"

function Ssh () {
   ssh -lroot $REMOTE "$@"
}
function Rsync () {
   rsync -a "$1" "root@$REMOTE:$2"
}

Ssh true   # Test ssh.

Rsync "$DIR/" /opt/zavod/

cat <<'HERE' | Ssh 'cat > /etc/cron.d/zavod'
55 2 * * 1 root shutdown -rf now
1 * * * * root PATH="/usr/sbin:/sbin:$PATH" date; df; mount -v; df -h; date   >>/tmp/zavod-apt.log 2>&1
2 * * * * root PATH="/usr/sbin:/sbin:$PATH" apt-get -q -y update   >>/tmp/zavod-apt.log 2>&1
9 * * * * root PATH="/usr/sbin:/sbin:$PATH" apt-get -q -y upgrade   >>/tmp/zavod-apt.log 2>&1
HERE

cat <<'HERE' | Ssh 'cat > /etc/rc.local'
(( sleep 3; /opt/zavod/boot.sh >>/tmp/zavod-boot.log 2>&1 )& )&
HERE

(
  Ssh apt-get -q -y check
  Ssh apt-get -q -y update
  Ssh apt-get -q -y upgrade
  Ssh apt-get -q -y update
  Ssh apt-get -q -y upgrade
  Ssh apt-get -q -y autoclean
  Ssh apt-get -q -y autoremove
  Ssh apt-get -q -y check
  Ssh apt-get -q -y install tcl git golang-go
)
