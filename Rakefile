require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.test_files = FileList["test/**/*_test.rb"]
  t.warning = true
end

Rake::TestTask.new(:bench) do |t|
  t.libs << "test"
  t.test_files = FileList["test/**/*_benchmark.rb"]
  t.warning = true
end

task :default => :test

namespace :docker do
  task :build do
    sh 'docker', 'build', '-t', 'sider/goodcheck:dev', '.'
  end
end

namespace :docs do
  desc "Install dependencies for the documentation website"
  task :install_deps do
    on_docs_dir do
      sh "yarn", "install"
    end
  end

  desc "Start the documentation development server"
  task :start => [:install_deps] do
    puts ""
    puts "!!!"
    puts "!!! Open the URL in your browser: http://127.0.0.1:3000/goodcheck/docs/next/getstarted"
    puts "!!!"
    puts ""

    on_docs_dir do
      sh "yarn", "run", "start"
    end
  end

  desc "Build the documentation website"
  task :build => [:install_deps] do
    on_docs_dir do
      sh "yarn", "run", "build"
    end
  end

  desc "Update the version of the documentation website"
  task :update_version => [:install_deps] do
    on_docs_dir do
      sh "yarn", "run", "version", Goodcheck::VERSION
    end
  end

  desc "Publish the documentation website"
  task :publish => [:build] do
    on_docs_dir do
      sh "yarn", "run", "publish-gh-pages"
    end
  end

  def on_docs_dir(&block)
    dir = File.join(__dir__, "docusaurus", "website")
    Dir.chdir(dir, &block)
  end
end
