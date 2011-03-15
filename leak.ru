$:<< ::File.expand_path(::File.dirname(__FILE__) + '/lib')

require 'bundler'
Bundler.setup
require 'bleak_house' if ENV['BLEAK_HOUSE']
require 'eventmachine'
require 'em-redis'







ASYNC_RESPONSE = [-1, {}, []].freeze
EventMachine.next_tick do
  STORE=EM::Protocols::Redis.connect(6379, '127.0.0.1')
end
$r=0

class Controller
  def vsz_memory
    `ps uax|grep thinleaker|grep #{Process.pid}|awk '{print $5}'`.to_i
  end

  def self.call(env)
    new.call(env)
  end
  def call(env)
    @res=Rack::Request.new(env)
    puts vsz_memory if ($r+=1) % 100 == 0
    t = EventMachine::Timer.new(0.1) do
      env['async.callback'].call [200, {'Content-Type' => 'text/plain'}, ['timeout']]
    end

    STORE.get('blah') do |res|
      @res=Rack::Request.new(env)
      t.cancel
      env['async.callback'].call [200, {'Content-Type' => 'text/plain'}, [res||'nil']]
      end
    ASYNC_RESPONSE
  end
end

run Controller
