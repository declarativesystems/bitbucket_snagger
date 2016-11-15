require "bitbucket_snagger/version"
require "bitbucket"
require 'escort'
require 'git'

module BitbucketSnagger
  class BitbucketSnagger < ::Escort::ActionCommand::Base
    def initialize(username, password)
      Escort::Logger.output.puts "loggin in to bitbucket..."
      @bitbucket = BitBucket.new basic_auth: "#{username}:#{password}"
      Escort::Logger.output.puts "...done!"
    end

    def repo_exists?(project, repo)
      status = @bitbucket.repos.get project, repo
      Escort::Logger.output.puts "#{project}/#{repo} status: #{status}"
    end

    def create_repo(project, repo, upstream, description)
      description = "fixme, add a description"
      if ! repo_exists?(project, repo)
        Escort::Logger.output.puts "Creating #{project}/#{repo}"
        @bitbucket.repos.create(
          name=repo,
          description=description,
          website="https://bitbucket.com",
          is_private=false,
          has_issues=false,
          has_wiki=true
        )
      end
    end


    def sync_repo(base_url, project, repo, upstream)
      # create repo on bitbucket server if needed
      create_repo(project, repo)

      # checkout the repo as a regular git repo using git api for ruby
      Escort::Logger.output.puts "Updating #{repo}..."
      bb_checkout_url = "#{base_url}/#{project}/#{repo}.git"
      working_dir = Dir.mktmpdir
      g = Git.clone(bb_checkout_url, repo, :path => working_dir)

      # add a remote for upstream
      r = g.add_remote('upstream', upstream)

      # sync our forks master branch
      Escort::Logger.output.puts "...pulling changes from #{upstream}"
      g.pull('upstream', 'master')

      # push changes back to master
      Escort::Logger.output.puts "...pushing changes to bitbucket"
      g.push('origin', 'master')

      # example of how to set name and email if commits are being refused
      # g.config('user.name', 'Scott Chacon')
      # g.config('user.email', 'email@email.com')
      Escort::Logger.output.puts "...All done, cleaning up!"
      FileUtils.rm_rf working_dir
    end
  end
end