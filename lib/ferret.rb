require "fileutils"
require "securerandom"
require "timeout"
require "tmpdir"
require_relative "./hash.rb"

ENV["NAME"]               ||= File.basename($0, File.extname($0)) # e.g. git_push
ENV["FERRET_DIR"]         ||= File.expand_path(File.join(__FILE__, "..", ".."))
ENV["SCRIPT"]             ||= File.expand_path($0) # $FERRET_DIR/tests/git/push or $FERRET_DIR/tests/unit/test_ferret.rb
ENV["TEMP_DIR"]           ||= Dir.mktmpdir
$logdevs                  ||= [$stdout, IO.popen("logger", "w")]


trap("EXIT") do
  log fn: :exit
  $logdevs.each { |dev| next if !dev.pid; Process.kill("INT", dev.pid); Process.wait(dev.pid) }
  FileUtils.rm_rf ENV["TEMP_DIR"]
end

def run(opts={})
  if opts[:forever]
    $threads.each(&:join)
  else
    sleep opts[:time]
  end
end

def run_interval(interval, &block)
  $lock    ||= Mutex.new
  $threads ||= []
  $threads << Thread.new do
    loop do
      $lock.synchronize do
        Thread.current[:xid] = SecureRandom.hex(4)
        block.call
      end
      sleep interval * ENV["FREQ"].to_i
    end
  end
end

def run_every_time(&block)
  run_interval(1,block)
end

def bash(opts={})
  opts[:bash_script] = opts[:stdin]
  test(opts)
end

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

def run_bash_script(script) 
  r0, w0 = IO.pipe
  r1, w1 = IO.pipe

  Thread.current[:pid] = Process.spawn("bash", "--noprofile", "-s", chdir: ENV["TEMP_DIR"], pgroup: 0, in: r0, out: w1, err: w1)

  w0.write(script)
  r0.close
  w0.close

  Process.wait(Thread.current[:pid])
  w1.close
  { status: $?.exitstatus, out: r1.read }
end

def run_ruby_script(&block)
  { status: (yield source) ? 0 : 1, out: "" }
end

def check_success(result, status_match, pattern_match)
    success = result.status == opts[:status]
    success &&= !!(result.out =~ opts[:pattern]) if opts[:pattern]
end

def run_timeout_block(opts={}, source, status, trys, &block)
  Timeout.timeout(opts[:timeout]) do
    trys.times do |i|
      start = Time.now
      log source: source, i: i, at: :enter

      if opts[:bash]
        result = run_bash_script opts[:bash_script]
      else
        result = run_ruby_script block
      end
      
      check_success(result, status, opts[:pattern])

      if success
        log_uptime source, i, Time.now-start,success
        return success # break out of retry loop
      else
        result.out.each_line { |l| log source: source, i: i, at: :failure, out: "'#{l.strip}'" }
        if i == trys - 1  # only measure last failure
          log_uptime source, i, Time.now-start,success
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
  $logdevs.each { |l| l << out.strip + "\n" }
end
