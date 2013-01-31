require_relative "../test_helper.rb"

class BashTest < MiniTest::Unit::TestCase
  def setup

  end

  test "run simple script with exit status 0" do
      result = run_bash_script('echo ""')
      assert_equal result.status, 0
      assert_equal result.out, ""
  end

  test "run simple script with output" do
      result = run_bash_script('echo "test"')
      assert_equal result.status, 0
      assert_equal result.out, "test"
  end

  test "run script with non 0 return" do
      result = run_bash_script('return 1')
      assert_equal result.status, 1
      assert_equal result.out, ""
  end 

end