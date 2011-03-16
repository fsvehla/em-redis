$:<< ::File.expand_path(::File.dirname(__FILE__) + '/lib')

require 'logger'
require 'bundler'
Bundler.setup
require 'bleak_house' if ENV['BLEAK_HOUSE']
require 'eventmachine'
require 'em-redis'

ASYNC_RESPONSE = [-1, {}, []].freeze

EventMachine.next_tick do
  STORE=EM::Protocols::Redis.connect :logger => Logger.new(STDOUT), :queue_commands => false
end

$r=0
$last_vsz_memory=0

class Controller
  def vsz_memory
    `ps -p #{Process.pid} -o vsz=`.to_i
  end

  def self.call(env)
    new.call(env)
  end
  def call(env)
    @res=(0..100).map {Rack::Request.new(env) } #make use use more memory

    if ($r+=1) % 100 == 0
      mem = vsz_memory
      change = mem - $last_vsz_memory
      puts "#{mem} (#{'+' if change > 0}#{change})"
      $last_vsz_memory = mem
    end

    t = EventMachine::Timer.new(0.001) do
      env['async.callback'].call [200, {'Content-Type' => 'text/plain'}, ['timeout']]
    end

    STORE.get('blah') do |res|
      t.cancel
      env['async.callback'].call [200, {'Content-Type' => 'text/plain'}, [res||'nil']]
      end
    ASYNC_RESPONSE
  end
end

run Controller
