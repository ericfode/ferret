class Monitor
  attr_accessor :source, :target_status, :target_pattern, :trys, :timeout, :block, :bash_script, :name
  
  attr_accessor :last_try_time, :try, :result, :start_time, :success
  
  def initialize(opts={}, &block)
    #defaults
    opts.rmerge!(name: "test", retry: 1, pattern: nil, status: 0, timeout: 180)
    
    @name           = opts[:name]
    @target_status  = opts[:status]
    @target_pattern = opts[:pattern]
    @trys           = opts[:retry]
    @timeout        = opts[:timeout]
    @bash_script    = opts[:bash_script]
    @block          = block 
    @source         = getsource
  end  

  def run_bash_script(script=@bash_script)
    r0, w0 = IO.pipe
    r1, w1 = IO.pipe

    @tmp = Dir.mktmpdir
    @pid = Process.spawn("bash", "--noprofile", "-s", chdir: @tmp, pgroup: 0, in: r0, out: w1, err: w1)

    w0.write(script)
    r0.close
    w0.close

    Process.wait(@pid)
    @pid = nil

    w1.close
    { status: $?.exitstatus, out: r1.read }
  end

  def run_block(block=@block)
    { status: (block.call) ? 0 : 1, out: "" }
  end

  def check_success(result=@result, target_status=@target_status, target_pattern=@target_pattern)
    success = result[:status] == target_status
    success &&= !!(result[:out] =~ target_pattern) if target_pattern 
    return success
  end

  def run
    begin
      @start_time = Time.now
      Timeout.timeout(@timeout) do
        trys.times do |i|
          @last_try_time_start = Time.now
          @try = i

          log source: @source, i: @try, at: :enter

          if @bash_script
            @result = run_bash_script
          elsif @block
            @result = run_block @block
          end
          
          @last_try_time = Time.now - @last_try_time_start
          @success = check_success
          
          if @success
            break
          end

        end
      end
      
      if !@success
        log_failure
      end

    rescue Timeout::Error
      log source: @source, at: :timeout, val: @timeout
      success = false
      if @pid
        Process.kill("INT", -Process.getpgid(@pid))
        Process.wait(@pid)
        @pid =nil
      end
      @last_try_time = Time.now - @last_try_time_start
    end
  
    log_uptime

    return self
  end

  def log_failure(result=@result, i=@try)
    result[:out].each_line { |l| log source: source, i: i, at: :failure, out: "'#{l.strip}'" }
  end

  def log_uptime(source=@source, success=@success, i=@try, result=@result, time=@last_try_time)
    if success
      measure = "success"
      val = 100
    else
      measure = "failure"
      val = 0
    end

    log source: source, i: try, status: result[:status], measure: measure
    log source: source, i: try, val: val, measure: "uptime"
    log source: source, i: try, at: :return, val: "%0.4f" % time, measure: "time"
  end

  def getsource(name=@name)
    script = ENV["SCRIPT"].chomp(File.extname(ENV["SCRIPT"])).split("/").last(2).join("/")   # e.g. git/push or unit/test_ferret                    
    "\"#{script}.#{@name}\"".gsub(/\//, ".").gsub(/_/, "-") 
  end

end