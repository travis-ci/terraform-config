# This file is intended to be loaded into a heroku console with compatible
# `Job`, `Build`, and `Repository` models available.

def percentile(values, percentile)
  values_sorted = values.sort
  k = (percentile*(values_sorted.length-1)+1).floor - 1
  f = (percentile*(values_sorted.length-1)+1).modulo(1)
  values_sorted[k] + (f * (values_sorted[k+1] - values_sorted[k]))
end

def job_durations(group: 'ec2-bench00',
                  repo: 'travis-repos/chirp-org-production')
  owner_name, name = repo.split('/', 2)
  Job.where(
    source_id: Build.where(
      repository_id: Repository.where(
        name: name, owner_name: owner_name
      ).first,
      branch: 'container-based-benchmarking'
    ).select([:id, :state]).map(&:id),
    state: 'passed'
  ).select(
    [:config, :finished_at, :started_at]
  ).to_a.select { |j| j.config[:group] == group }.map(&:duration)
end

def job_duration_percentiles(group: 'ec2-bench00', pct: [0.5, 0.9, 0.95, 0.99],
                             repo: 'travis-repos/chirp-org-production')
  values = job_durations(group: group)
  pct.map { |p| [p, percentile(values, p)] }.to_h.merge(
    group: group, n: values.count
  )
end

def job_states(repo: 'travis-repos/chirp-org-production')
  owner_name, name = repo.split('/', 2)
  Job.where(
    source_id: Build.where(
      repository_id: Repository.where(
        name: name, owner_name: owner_name
      ).first,
      branch: 'container-based-benchmarking'
    ).select([:id, :state]).map(&:id)
  ).group('state')
    .select([:state, 'count(*)'])
    .map { |j| [j.state.to_sym, j.count.to_i] }.to_h
end

$stderr.puts <<EOF
Methods:
- job_duration_percentiles(group: '', pct: [], repo: '')
- job_durations(group: '', repo: '')
- job_states(repo: '')
EOF
