require 'logger'
require 'active_record'


Signal.trap("TERM") do
  puts "Sending TERM signal to app"
  shutdown_app
  exit
end

Signal.trap("INT") do
  puts "Sending TERM signal to app"
  shutdown_app
  exit
end

def shutdown_app
  active_connections =  ActiveRecord::Base.respond_to?(:verify_active_connections!)
  puts "Closing connections" if  active_connections
  puts "No active connections" if  !active_connections
  ActiveRecord::Base.clear_active_connections! if active_connections
end

