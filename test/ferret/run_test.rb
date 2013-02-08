require_relative "../test_helper.rb"

class Monitor::RunTest < MiniTest::Unit::TestCase
 
  test "correct success values" do
    m = Monitor.new(bash_script:"echo '1'", pattern:/1/)
    result = m.run_bash_script('echo "1"')
    success = m.check_success(result)
    assert_equal success, true
  end

  test "correct success values with bad input" do
    m = Monitor.new(bash_script:"echo '1'", pattern:/1/)
    result = {status:42, out:"deadbeef"}
    success = m.check_success(result)
    assert_equal success, false
  end 

  test "correct success with class values" do
    m = Monitor.new(bash_script:"echo '1'", pattern:/1/)
    m.result = {status:0, out:"1"}
    success = m.check_success
    assert_equal success, true
  end

  test "correct success with class values and wrong out" do
    m = Monitor.new(bash_script:"echo '1'", pattern:/1/)
    m.result = {status:0, out:"42"}
    success = m.check_success
    assert_equal success, false
  end 
end

 