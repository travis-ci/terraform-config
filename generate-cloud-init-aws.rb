require 'yaml'

env = 'staging'
site = 'org'

keychain_aws = ENV['TRAVIS_KEYCHAIN_DIR'] + '/travis-keychain/aws-workers'
docker_rsa = File.read("#{keychain_aws}/docker_rsa.key")
worker_yml = File.read("#{keychain_aws}/aws-workers-#{site}-#{env}.yml")

worker_config = YAML.load(worker_yml)
papertrail_site = worker_config['papertrail_site']

# render
template = File.read('cloud-init/travis-worker-aws.bash.in')
template.sub!('__QUEUE__', 'docker')
template.sub!('__ENV__', env)
template.sub!('__SITE__', site)
template.sub!('__WORKER_YML__', worker_yml)
template.sub!('__DOCKER_RSA__', docker_rsa)
template.sub!('__PAPERTRAIL_SITE__', papertrail_site)
template.sub!('__DOCKER_COUNT__', '1')

puts template
