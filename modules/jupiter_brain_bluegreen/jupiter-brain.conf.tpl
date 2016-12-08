description "Jupiter Brain (jupiter-brain-${env})"

start on (started networking)
stop on runlevel [!2345]

instance $INST

setuid jupiter-brain
setgid nogroup

respawn
respawn limit 10 90

script
  JUPITER_BRAIN_RUN_DIR=/var/tmp/run/jupiter-brain

  if [ -f /etc/default/$UPSTART_JOB ]; then
    . /etc/default/$UPSTART_JOB
  fi

  if [ -f /etc/default/$UPSTART_JOB-$INST ] ; then
    . /etc/default/$UPSTART_JOB-$INST
  fi

  cp -v /usr/local/bin/jb-server-${env} $JUPITER_BRAIN_RUN_DIR/$UPSTART_JOB-$INST
  chmod u+x $JUPITER_BRAIN_RUN_DIR/$UPSTART_JOB-$INST
  exec $JUPITER_BRAIN_RUN_DIR/$UPSTART_JOB-$INST
end script

post-stop script
  JUPITER_BRAIN_RUN_DIR=/var/tmp/run/jupiter-brain

  if [ -f /etc/default/$UPSTART_JOB ]; then
    . /etc/default/$UPSTART_JOB
  fi

  rm -f $JUPITER_BRAIN_RUN_DIR/$UPSTART_JOB-$INST
end script

# vim:filetype=upstart
