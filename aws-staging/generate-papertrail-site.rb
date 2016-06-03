require 'yaml'

worker_config = YAML.load(STDIN.read)
papertrail_site = worker_config['papertrail_site']

puts papertrail_site
