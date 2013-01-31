require "minitest/autorun"
require "mocha/setup"
require "debugger"


ENV["APP"] = "ferret-tester"
ENV["SCRIPT"] = "./dummy/script.rb"
ENV["NAME"] = "test_app"
ENV["FREQ"] = 1.to_s
ENV["TEMP_DIR"] ="."

require_relative "../lib/ferret.rb"

class MiniTest::Unit::TestCase

  def self.test(desc="", &block)
    define_method("test #{desc}", &block)
  end

  class Ferret
    def log(args={}); end
  end
end