require 'json'

env = 'staging'
site = 'org'

pro_flag = site == 'com' ? '--pro' : ''

# get gce account file from keychain
keychain_gce_accounts = ENV['TRAVIS_KEYCHAIN_DIR'] + '/travis-keychain/gce-accounts'
gce_json = File.read("#{keychain_gce_accounts}/gce-workers-#{env}.json")

# get worker config as environment variables
worker_configs = %x[trvs generate-config #{pro_flag} -p travis_worker -f env gce-workers #{env} | sed 's/^/export /']

# get worker config as JSON and format for chef
raw_json = %x[trvs generate-config #{pro_flag} -p travis_worker -f json gce-workers #{env}]
data = JSON.parse(raw_json)
env = data.map {|k, v| ["TRAVIS_" + k.to_s.upcase, v] }.to_h
out = {
  run_list: ["recipe[travis_go_worker]"],
  travis: { worker: { environment: env } }
}
chef_node_json = JSON.pretty_generate(out)

ssh_keys = File.read(ENV['TRAVIS_KEYCHAIN_DIR'] + '/travis-keychain/aws-workers/ssh-keys.pub')

# render
template = File.read('cloud-init/travis-worker-gce.bash.in')
template.sub!('___GCE_JSON___', gce_json)
template.sub!('___ENV___', worker_configs)
template.sub!('___NODE_JSON___', chef_node_json)
template.sub!('__SSH_KEYS__', ssh_keys)

puts template
