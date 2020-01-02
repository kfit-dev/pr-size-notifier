# Container image that runs your code
FROM ruby:2.6.0

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY entrypoint.sh /entrypoint.sh

RUN gem install specific_install
RUN gem specific_install -l https://github.com/octokit/octokit.rb.git

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/entrypoint.sh"]
