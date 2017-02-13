description "Travis Worker (travis-worker-${env})"

stop on runlevel [!2345]

setuid travis-worker
setgid nogroup

respawn
respawn limit 10 90

script
  TRAVIS_WORKER_RUN_DIR=/var/tmp/run/travis-worker

  if [ -f /etc/default/$UPSTART_JOB ]; then
    . /etc/default/$UPSTART_JOB
  fi

  mkfifo $TRAVIS_WORKER_RUN_DIR/$UPSTART_JOB-output
  ( logger -t $UPSTART_JOB < $TRAVIS_WORKER_RUN_DIR/$UPSTART_JOB-output & )
  exec > $TRAVIS_WORKER_RUN_DIR/$UPSTART_JOB-output 2>&1
  rm $TRAVIS_WORKER_RUN_DIR/$UPSTART_JOB-output

  cp -v /usr/local/bin/travis-worker-${env} $TRAVIS_WORKER_RUN_DIR/$UPSTART_JOB
  chmod u+x $TRAVIS_WORKER_RUN_DIR/$UPSTART_JOB
  exec $TRAVIS_WORKER_RUN_DIR/$UPSTART_JOB
end script

post-stop script
  TRAVIS_WORKER_RUN_DIR=/var/tmp/run/travis-worker

  if [ -f /etc/default/$UPSTART_JOB ]; then
    . /etc/default/$UPSTART_JOB
  fi

  rm -f $TRAVIS_WORKER_RUN_DIR/$UPSTART_JOB
end script

# vim:filetype=upstart
