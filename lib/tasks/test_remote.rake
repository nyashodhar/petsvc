
#
# Original trick taken from these posts:
#
#   http://sanguinerane.com/override-rake-test-to-include-custom-test-groups/
#   http://www.fozworks.com/blog/2007/04/16/rake-task-to-run-a-custom-group-of-tests/
#
# This take task allows the following:
#
# 1) Run local integration tests by doing (as usual)
#
#     rake test:integration
#
#    That will only run the local integration tests under test/integration
#
# 2) Run remote tests by doing
#
#     rake test:remote
#
#    That will only run the remote integration tests under test/remote
#

Rake::Task["test:run"].clear
namespace :test do

  tests = []
  Dir["#{Rails.root}/test/remote/*_test.rb"].each {|file|
    tests << file
  }

  Rails::SubTestTask.new(:remote => "test:prepare") do |t|
    t.libs << "test"
    #t.pattern = 'test/remote/**/*_test.rb'
    t.test_files = tests
  end

  task :run do
    errors = %w(test:units test:functionals test:integration test:remote).collect do |task|
      begin
        Rake::Task[task].invoke
        nil
      rescue => e
        { :task => task, :exception => e }
      end
    end.compact

    if errors.any?
      puts errors.map { |e| "Errors running #{e[:task]}! #{e[:exception].inspect}" }.join("\n")
      abort
    end
  end
end

Rake::Task[:test].comment = "Includes test:remote"
