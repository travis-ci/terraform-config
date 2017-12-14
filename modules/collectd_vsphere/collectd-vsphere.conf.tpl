description "collectd-vsphere (collectd-vsphere-${index}-${env})"

stop on runlevel [!2345]

setuid collectd-vsphere
setgid nogroup

respawn
respawn limit 10 90

script
  COLLECTD_VSPHERE_RUNDIR=/var/tmp/run/collectd-vsphere

  if [ -f /etc/default/$UPSTART_JOB ]; then
    . /etc/default/$UPSTART_JOB
  fi

  mkfifo $COLLECTD_VSPHERE_RUNDIR/$UPSTART_JOB-output
  ( logger -t $UPSTART_JOB < $COLLECTD_VSPHERE_RUNDIR/$UPSTART_JOB-output & )
  exec > $COLLECTD_VSPHERE_RUNDIR/$UPSTART_JOB-output 2>&1
  rm $COLLECTD_VSPHERE_RUNDIR/$UPSTART_JOB-output

  cp -v /usr/local/bin/collectd-vsphere-${env} $COLLECTD_VSPHERE_RUNDIR/$UPSTART_JOB
  chmod u+x $COLLECTD_VSPHERE_RUNDIR/$UPSTART_JOB
  exec $COLLECTD_VSPHERE_RUNDIR/$UPSTART_JOB
end script

post-stop script
  COLLECTD_VSPHERE_RUNDIR=/var/tmp/run/collectd-vsphere

  if [ -f /etc/default/$UPSTART_JOB ]; then
    . /etc/default/$UPSTART_JOB
  fi

  rm -f $COLLECTD_VSPHERE_RUNDIR/$UPSTART_JOB
end script

# vim:filetype=upstart
