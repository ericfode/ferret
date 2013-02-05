require "fileutils"
require "securerandom"
require "timeout"
require "tmpdir"
require_relative "./hash.rb"

ENV["NAME"]               ||= File.basename($0, File.extname($0)) # e.g. git_push
ENV["FERRET_DIR"]         ||= File.expand_path(File.join(__FILE__, "..", ".."))
ENV["SCRIPT"]             ||= File.expand_path($0) # $FERRET_DIR/tests/git/push or $FERRET_DIR/tests/unit/test_ferret.rb
$logdevs                  ||= [$stdout, IO.popen("logger", "w")]

class Ferret
  def run(opts={})
    if opts[:forever]
      @threads.each(&:join)
    else
      sleep opts[:time]
    end
  end

  def run_interval(interval, &block)
    @lock    ||= Mutex.new
    @threads ||= []
    @threads << Thread.new do
      loop do
        @lock.synchronize do
          Thread.current[:xid] = SecureRandom.hex(4)
          block.call
        end
        sleep interval * ENV["FREQ"].to_i
      end
    end
<<<<<<< HEAD

    log source: source, i: i, status: status, measure: measure
    log source: source, i: i, val: val, measure: "uptime"
    log source: source, i: i, at: :return, val: "%0.4f" % time, measure: "time"
  end

  def run_every_time(&block)
    run_interval(1,block)
  end

  def bash(opts={})
    opts[:bash_script] = opts[:stdin]
    test(opts)
  end

=======
  end

  def run_every_time(&block)
    run_interval(1,block)
  end

  def bash(opts={})
    opts[:bash_script] = opts[:stdin]
    test(opts)
  end

>>>>>>> dd53ffa6c11702d064b357013f30d286570016bf
  def log_uptime(source, i, time, up)
    if up 
      measure = "success"
      val = 100
    else
      measure = "failure"
      val = 0
    end

    log source: source, i: i, status: status, measure: measure
    log source: source, i: i, val: val, measure: "uptime"
    log source: source, i: i, at: :return, val: "%0.4f" % time, measure: "time"
  end

  def self.run_bash_script(script) 
    r0, w0 = IO.pipe
    r1, w1 = IO.pipe
    Thread.current[:tmp] = Dir.mktmpdir
    Thread.current[:pid] = Process.spawn("bash", "--noprofile", "-s", chdir: Thread.current[:tmp], pgroup: 0, in: r0, out: w1, err: w1)

    w0.write(script)
    r0.close
    w0.close

    Process.wait(Thread.current[:pid])
    w1.close
    { status: $?.exitstatus, out: r1.read }
  end

<<<<<<< HEAD

  def self.run_ruby_script(&block)
    { status: (yield source) ? 0 : 1, out: "" }
  end

=======
  def self.run_ruby_script(&block)
    { status: (yield source) ? 0 : 1, out: "" }
  end

>>>>>>> dd53ffa6c11702d064b357013f30d286570016bf
  def self.check_success(result, status_match, pattern_match)
      success = result[:status] == status_match
      success &&= !!(result[:out] =~ pattern_match) if pattern_match
  end

  def self.run_timeout_block(opts={}, monitor)
    result = {}
    Timeout.timeout(opts[:timeout]) do
      trys.times do |i|
        start = Time.now
        log source: source, i: i, at: :enter

        if monitor.script
          result = run_bash_script opts[:bash_script]
        else
          result = run_ruby_script block
        end
        
        check_success(result, status, opts[:pattern])

        if success
          log_uptime source, i, Time.now-start,success
          return result # break out of retry loop
        else
          result.out.each_line { |l| log source: source, i: i, at: :failure, out: "'#{l.strip}'" }
          if i == trys - 1  # only measure last failure
            log_uptime source, i, Time.now-start,success
            return result
          end
        end
      end
    end
  end

  def getsource(name)
    script = ENV["SCRIPT"].chomp(File.extname(ENV["SCRIPT"])).split("/").last(2).join("/")   # e.g. git/push or unit/test_ferret                    
    "\"#{script}.#{name}\"".gsub(/\//, ".").gsub(/_/, "-") 
  end

  def test(opts={}, &blk) 
    opts.rmerge!(name: "test", retry: 1, pattern: nil, status: 0, timeout: 180)
    source = getsource(opts[:name])
    begin
      run_timeout_block(opts, source, opts[:status], opts[:retry], blk)
    rescue Timeout::Error
      log source: source, at: :timeout, val: opts[:timeout]
      
      if Thread.current[:pid]
        Process.kill("INT", -Process.getpgid(Thread.current[:pid]))
        Process.wait(Thread.current[:pid])
      end
    end
  end

  def log(data)
    Thread.current[:xid] ||= SecureRandom.hex(4)
    data.rmerge! xid: Thread.current[:xid]
    data.rmerge! app: "#{ENV["APP"]}"
    data.reduce(out=String.new) do |s, tup|
      s << [tup.first, tup.last].join("=") << " "
    end
    @logdevs.each { |l| l << out.strip + "\n" }
  end

  class Monitor
    attr :source, :target_status,:target_pattern :trys, :timeout, :block
    def run
      print "need to implement run method"
    end
     def initialize(opts={})
      opts.rmerge!(name: "test", retry: 1, pattern: nil, status: 0, timeout: 180)
      @source         = getsource(opts[:name])
      @target_status  = opts[:status]
      @trys           = opts[:retry]
      @timeout        = opts[:timeout]
      @target_pattern = opts[:pattern] if opts[:pattern]
    end   

    def check_sucess(result)
      success = result[:status] == @target_status
      success &&= !!(result[:out] =~ @target_pattern) if @target_pattern
    end
  end
  
  class BashMonitor <Monitor
    attr :script

    def initialize(opts={}, script)
      @script = script
      super opts
    end   
    

    def run()
      result = {}
      Timeout.timeout(@timeout) do
        @trys.times do |i|
          start = Time.now
          log source: @source, i: i, at: :enter

          result = Ferret.run_bash_script @script
          
          check_success(result, status, opts[:pattern])

          if success
            log_uptime source, i, Time.now-start,success
            return result # break out of retry loop
          else
            result.out.each_line { |l| log source: source, i: i, at: :failure, out: "'#{l.strip}'" }
            if i == trys - 1  # only measure last failure
              log_uptime source, i, Time.now-start,success
              return result
            end
          end
        end
      end
    end
  end

  class RubyMonitor <Monitor
  attr :block
    def initialize(opts={}, block)
      @block = block
      super opts
    end   
  end
<<<<<<< HEAD
end

=======
end
>>>>>>> dd53ffa6c11702d064b357013f30d286570016bf
