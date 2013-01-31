require "minitest/autorun"
require "mocha/setup"
require "debugger"
<<<<<<< HEAD
require "tmpdir"
=======
>>>>>>> Refactoring and adding tests`


ENV["APP"] = "ferret-tester"
ENV["SCRIPT"] = "./dummy/script.rb"
ENV["NAME"] = "test_app"
ENV["FREQ"] = 1.to_s
<<<<<<< HEAD
$logdevs = [StringIO.new]
=======
ENV["TEMP_DIR"] ="."
>>>>>>> Refactoring and adding tests`

require_relative "../lib/ferret.rb"

class MiniTest::Unit::TestCase
<<<<<<< HEAD
  def self.test(desc="", &block)
    define_method("test #{desc}", &block)
  end
  def setup
    ENV["TEMP_DIR"] = Dir.mktmpdir
    $logdevs[0].rewind
    $logdevs[0].truncate(0)
  end

  def logs
    $logdevs[0].rewind
    l = $logdevs[0].read
    l.gsub!(/val=([0-9]+)\.([0-9]+)/, "val=X.Y") # mask floating point values
    l.gsub!(/xid=([0-9a-f]{8})/, "xid=deadbeef")
=======

  def self.test(desc="", &block)
    define_method("test #{desc}", &block)
  end

  class Ferret
    def log(args={}); end
>>>>>>> Refactoring and adding tests`
  end
end