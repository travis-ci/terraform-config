require 'yaml'

puts YAML.load($stdin.read)['papertrail_site'] if $PROGRAM_NAME == __FILE__
