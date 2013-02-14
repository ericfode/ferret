require "fileutils"
require "securerandom"
require "timeout"
require "tmpdir"
require "./lib/hash"
require "./lib/script"



ENV["NAME"]               ||= File.basename($0, File.extname($0)) # e.g. git_push
ENV["FERRET_DIR"]         ||= File.expand_path(File.join(__FILE__, "..", ".."))
ENV["SCRIPT"]             ||= File.expand_path($0) # $FERRET_DIR/tests/git/push or $FERRET_DIR/tests/unit/test_ferret.rb
$logdevs ||= [$stdout, IO.popen("logger", "w")]

@fail_fast = false

def fail_fast(val)
  @fail_fast = val
end

def run(opts={})
  if opts[:forever]
    @threads.each(&:join)
  else
    sleep opts[:time]
  end
end

def run_interval(interval, &block)
  @threads ||= []
  @threads << Thread.new do
    loop do
      Thread.current[:xid] = SecureRandom.hex(4)
      block.call
      sleep interval * ENV["FREQ"].to_f
    end
  end
end

def run_every_time(&block)
  run_interval 1 do 
    block.call
  end
end

def bash(opts={})
  opts[:bash_script] = opts[:stdin]
  mon = Script.new opts

  mon.run
  
  if $fail_fast && !mon.success
    exit 1
  end
  
  return mon
end

def test(opts={}, &block) 
  mon = Script.new opts do 
    block.call
  end

  mon.run
 
  if $fail_fast && !mon.success
    exit 1
  end

  return mon
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
