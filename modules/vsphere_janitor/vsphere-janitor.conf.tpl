description "vSphere Janitor (vsphere-janitor-${env})"

stop on runlevel [!2345]

setuid vsphere-janitor
setgid nogroup

respawn
respawn limit 10 90

script
  VSPHERE_JANITOR_RUNDIR=/var/tmp/run/vsphere-janitor

  if [ -f /etc/default/$UPSTART_JOB ]; then
    . /etc/default/$UPSTART_JOB
  fi

  mkfifo $VSPHERE_JANITOR_RUNDIR/$UPSTART_JOB-output
  ( logger -t $UPSTART_JOB < $VSPHERE_JANITOR_RUNDIR/$UPSTART_JOB-output & )
  exec > $VSPHERE_JANITOR_RUNDIR/$UPSTART_JOB-output 2>&1
  rm $VSPHERE_JANITOR_RUNDIR/$UPSTART_JOB-output

  cp -v /usr/local/bin/vsphere-janitor-${env} $VSPHERE_JANITOR_RUNDIR/$UPSTART_JOB
  chmod u+x $VSPHERE_JANITOR_RUNDIR/$UPSTART_JOB
  exec $VSPHERE_JANITOR_RUNDIR/$UPSTART_JOB
end script

post-stop script
  VSPHERE_JANITOR_RUNDIR=/var/tmp/run/vsphere-janitor

  if [ -f /etc/default/$UPSTART_JOB ]; then
    . /etc/default/$UPSTART_JOB
  fi

  rm -f $VSPHERE_JANITOR_RUNDIR/$UPSTART_JOB
end script

# vim:filetype=upstart
