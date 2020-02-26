require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
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
    Dir.chdir "docusaurus/website", &block
  end
end

namespace :benchmark do
  desc "Run benchmark"
  task :run, [:n] do |_task, args|
    require "benchmark"
    require_relative "lib/goodcheck"
    require_relative "lib/goodcheck/cli"

    target_file = File.join(__dir__, "benchmark", "gc.c")

    n = Integer(args[:n] || 1000)
    puts "n = #{n}"

    Benchmark.bm do |x|
      x.report do
        n.times { Goodcheck::CLI.new(stdout: STDOUT, stderr: STDERR).run(["check", target_file]) }
      end
    end
  end
end
