require 'test/helper'
require 'autotest'
require 'shoulda'

class TestAutotestIntegration < Test::Unit::TestCase
  def temp_dir
    "#{File.dirname(__FILE__)}/tmp"
  end

  def autotest_executable
    '../../bin/autotest'
  end
  
  def unit_diff_executable
    File.expand_path("./#{File.dirname(__FILE__)}/../bin/unit_diff")
  end

  def run_autotest
    `cd #{temp_dir} && #{autotest_executable}`
  end

  def write(file, text)
    file = "#{temp_dir}/#{file}"
    dir = File.dirname(file)
    `mkdir -p #{dir}` unless File.directory?(dir)
    File.open(file, 'w'){|f| f.write text } 
  end

  def write_passing_tests times
    write('test/test_x.rb', %{ class TestX < Test::Unit::TestCase; #{times}.times{|i| define_method("test_\#{i}"){ assert true }}; end })
  end

  context 'integration' do
    context 'green run' do
      setup do
        ENV['UNIT_DIFF'] = unit_diff_executable
        `rm -rf #{temp_dir}`
        `mkdir #{temp_dir}`
        write('.autotest', "Autotest.add_hook(:all_good){print 'all_good';exit}")
      end

      teardown do
        `rm -rf #{temp_dir}`
      end

      should 'do nothing when run inside an empty directory' do
        assert_equal run_autotest, 'all_good'
      end

      should 'runs all tests' do
        write('test/test_x.rb', '')
        assert_match %r{test/test_x.rb}, run_autotest
      end

      should 'include output from tests' do
        write('test/test_x.rb', "print 'YES'")
        assert_match %r{YES}, run_autotest
      end

      should 'show one dot per passing test' do
        write_passing_tests 10
        assert_match %r{[^\.]#{'\.'*10}[^\.]}, run_autotest
      end

      should 'show test summary' do
        write_passing_tests 10
        assert_match /Finished in \d\.\d+ seconds\.\s*10 tests, 10 assertions, 0 failures, 0 errors/m, run_autotest
      end

      should 'call good hooks in correct order' do
        write('.autotest', "Autotest::ALL_HOOKS.each{|hook| Autotest.add_hook(hook){print hook;hook == :all_good ? exit : nil }}")
        write_passing_tests 1
        assert_match /\n#{%w[ran_command green all_good died]*''}$/m, run_autotest
      end
    end
  end
end