#!/usr/bin/env ruby

require 'json'
require 'octokit'

webhook_event_payload = File.read(ENV['GITHUB_EVENT_PATH'])
webhook_event_payload_in_json = JSON.parse(webhook_event_payload)
repo_name = webhook_event_payload_in_json['repository']['full_name']
acceptable_pr_size = (ENV['ACCEPTABLE_PR_SIZE'] || 250).to_i

github = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])

most_recent_commit_hash = webhook_event_payload_in_json['after']

opened_pull_requests = github.pull_requests(repo_name, state: 'open')

current_pull_request = opened_pull_requests.select { |opened_pull_request| opened_pull_request['head']['sha'] == most_recent_commit_hash.to_s }.last


unless current_pull_request
  puts 'No pull request with the given PR number.'
  exit(true)
end

pr_number = current_pull_request['number']
pr = github.pull_request(repo_name, pr_number, state: 'open')

total_addition_and_deletions = pr['additions'] + pr['deletions']

github_bot_username = 'github-actions[bot]'
large_pr_comment_message = 'This pull request is big. We prefer smaller PRs whenever possible, as they are easier to review. Can this be split into a few smaller PRs?'
small_pr_comment_message = 'Good Job On Making A Smaller PR.'

pr_comments = github.issue_comments(repo_name, pr_number)

# delete previous github bot comments
github_pr_size_bot_comments = pr_comments.select do |pr_comment|
                                pr_comment['user']['login'] == github_bot_username && (pr_comment['body'] == large_pr_comment_message || pr_comment['body'] ==  small_pr_comment_message)
                              end

github_pr_size_bot_comments.each { |github_pr_size_bot_comment|  github.delete_comment(repo_name, github_pr_size_bot_comment['id']) }

if total_addition_and_deletions > acceptable_pr_size
  github.add_comment(repo_name, pr_number, large_pr_comment_message)
end

if total_addition_and_deletions < acceptable_pr_size
  github.add_comment(repo_name, pr_number, small_pr_comment_message)
end
