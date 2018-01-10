# config valid only for current version of Capistrano
lock "3.8.1"

set :application, 'blog'
set :repo_url, 'git@github.com:Liber17321/blog.git'  # 这里填的是每个人自己的repo地址


# Default branch is :master

# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp



# Default value for :format is :airbrussh.

# set :format, :airbrussh


# You can configure the Airbrussh format using :format_options.

# These are the defaults.

# set :format_options, command_output: true, log_file: 'log/capistrano.log', color: :auto, truncate: :auto


# Default value for :pty is false

# set :pty, true


# Default value for :linked_files is []

# append :linked_files, 'config/database.yml', 'config/secrets.yml'
set :linked_files, ['.env']

set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/secrets.yml')

# Default value for linked_dirs is []

# append :linked_dirs, 'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'public/system'

set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle')


namespace :deploy do
  desc 'create_db'
  task :create_db do
    on roles(:app) do
      within release_path do
        execute :bundle, :exec, :"rails db:create RAILS_ENV=#{fetch(:stage)}"
      end
    end
  end

  desc 'Uploads required config files'
  task :upload_configs do
    on roles(:all) do
      upload!(".env.#{fetch(:stage)}", "#{deploy_to}/shared/.env")
    end
  end

  desc 'Seeds database'
  task :seed do
    on roles(:app) do
      within release_path do
        execute :bundle, :exec, :"rails db:seed RAILS_ENV=#{fetch(:stage)}"
      end
    end
  end

  before 'deploy:migrate', 'deploy:create_db'
  after :finished, 'deploy:seed'
  after :finished, 'app:restart'
end

namespace :app do
  desc 'Start application'
  task :start do
    on roles(:app) do
      within "#{fetch(:deploy_to)}/current/" do
        execute :bundle, :exec, :"puma -C config/puma.rb -e #{fetch(:stage)}"
      end
    end
  end

  desc 'Stop application'
  task :stop do
    on roles(:app) do
      within "#{fetch(:deploy_to)}/current/" do
        execute :bundle, :exec, :'pumactl -F config/puma.rb stop'
      end
    end
  end

  desc 'Restart application'
  task :restart do
    on roles(:app) do
      within "#{fetch(:deploy_to)}/current/" do
        if test("[ -f #{deploy_to}/current/tmp/pids/puma.pid ]")
          execute :bundle, :exec, :'pumactl -F config/puma.rb stop'
        end

        execute :bundle, :exec, :"puma -C config/puma.rb -e #{fetch(:stage)}"
      end
    end
  end
end
