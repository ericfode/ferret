require "minitest/autorun"
require "mocha/setup"
require "debugger"
require "tmpdir"


ENV["APP"] = "ferret-tester"
ENV["SCRIPT"] = "./dummy/script.rb"
ENV["NAME"] = "test_app"
ENV["FREQ"] = 0.1.to_s
$logdevs = [StringIO.new]

require_relative "../lib/ferret.rb"

class MiniTest::Unit::TestCase
  def self.test(desc="", &block)
    define_method("test #{desc}", &block)
  end
  def setup
    ENV["TEMP_DIR"] = Dir.mktmpdir
    $logdevs = [StringIO.new]
  end
  def teardown
    $logdevs = [StringIO.new]
  end
  def logs
    $logdevs[0].rewind
    l = $logdevs[0].read
    l.gsub!(/val=([0-9]+)\.([0-9]+)/, "val=X.Y") # mask floating point values
    l.gsub!(/xid=([0-9a-f]{8})/, "xid=deadbeef")
  end
end