require_relative "../test_helper.rb"

class Ferret::BashTest < MiniTest::Unit::TestCase
  def setup 
    @f = Ferret.new
  end
  test "run simple script with exit status 0" do
      result = @f.run_bash_script('echo ""')
      assert_equal result[:status], 0
      assert_equal result[:out], "\n"
  end

  test "run simple script with output" do
      result = @f.run_bash_script('echo "test"')
      assert_equal result[:status], 0
      assert_equal result[:out], "test\n"
  end

  test "run script with invalid command" do
      result = @f.run_bash_script('asdf')
      assert_equal result[:status], 127
  end 
end