require_relative "../test_helper.rb"

class Monitor::BashTest < MiniTest::Unit::TestCase
  def setup 
    @m = Monitor.new()


  end
  test "run simple script with exit status 0" do
      result = @m.run_bash_script('echo ""')
      assert_equal result[:status], 0
      assert_equal result[:out], "\n"
  end

  test "run simple script with output" do
      result = @m.run_bash_script('echo "test"')
      assert_equal result[:status], 0
      assert_equal result[:out], "test\n"
  end

  test "run script with invalid command" do
      result = @m.run_bash_script('asdf')
      assert_equal result[:status], 127
  end 

  test "run block" do 

    result = @m.run_block( Proc.new do
      1
    end)
    assert_equal result[:status], 0
    assert_equal result[:out], ""
  end

  test "run Monitor" do
    m = Monitor.new(bash_script:"echo '1'", pattern:/1/)
    m.run
    assert_equal logs, <<-'EOF'
app=ferret-tester xid=deadbeef source="dummy.script.test" i=0 at=enter
app=ferret-tester xid=deadbeef source="dummy.script.test" i=0 status=0 measure=success
app=ferret-tester xid=deadbeef source="dummy.script.test" i=0 val=100 measure=uptime
app=ferret-tester xid=deadbeef source="dummy.script.test" i=0 at=return val=X.Y measure=time
EOF
    assert_equal m.success, true
  end

  test "run bash" do
    m = bash(name: :curl, timeout: 3900, stdin: <<-'EOSH')
      curl --fail http://blog.herokuapp.com -s
    EOSH
    assert_equal m.name, :curl
    assert_equal m.timeout, 3900
    assert_equal m.target_status, 0
    assert_equal m.target_pattern, nil
    assert_equal m.result[:status], 0
    assert_equal m.result[:out], "<html><body>You are being <a href=\"https://blog.herokuapp.com/\">redirected</a>.</body></html>"
    assert m.last_try_time.to_i < 3 

    assert_equal logs, <<-'EOF'
app=ferret-tester xid=deadbeef source="dummy.script.curl" i=0 at=enter
app=ferret-tester xid=deadbeef source="dummy.script.curl" i=0 status=0 measure=success
app=ferret-tester xid=deadbeef source="dummy.script.curl" i=0 val=100 measure=uptime
app=ferret-tester xid=deadbeef source="dummy.script.curl" i=0 at=return val=X.Y measure=time
EOF
    assert_equal m.success, true
  end
end