require_relative "../test_helper.rb"

class Ferret::RunTest < MiniTest::Unit::TestCase
  def setup 
    @f = Ferret.new
  end

  test "correct success values" do
    result = @f.run_bash_script('echo "1"')
    success = @f.check_success(result,0,/1/)
    assert_equal success, true
  end

  test "run bash once" do
    bash_script = "echo '1'"
    source =  @f.getsource("test")
    result = @f.run_timeout_block source, 0, 5, bash_script: bash_script, pattern: /1/, timeout: 30
    assert_equal logs, <<EOF
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.true i=0 at=enter
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.true i=0 status=0 measure=success
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.true i=0 val=100 measure=uptime
app=ferret-dev.ferret-minitest xid=deadbeef source=unit.test-ferret.true i=0 at=return val=X.Y measure=time
EOF
  end
end

 