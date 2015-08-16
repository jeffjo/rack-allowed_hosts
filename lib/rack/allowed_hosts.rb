require 'rack/allowed_hosts/version'

# Rack::AllowedHosts
module Rack
  class AllowedHosts

    attr_reader :allowed_hosts

    def initialize(app, &block)
      @app = app

      # Call the block
      instance_eval(&block)
    end

    def allow(*hosts)
      @allowed_hosts ||= []

      # Also allow the for `allow ['host-a.com', 'host-b.com']` etc.
      if hosts.size == 1 && hosts[0].is_a?(Array)
        hosts = hosts[0]
      end

      hosts.each do |host|
        @allowed_hosts << matcher_for(host)
      end
    end

    def call(env)
      host = env['HTTP_HOST'].split(':').first
      unless host_allowed?(host)
        return [403, {'Content-Type' => 'text/html'}, ['<h1>403 Forbidden</h1>']]
      end

      # Fetch the result
      @app.call(env)
    end

    def host_allowed?(host)
      return false unless @allowed_hosts.is_a? Array
      return false if host.nil?

      @allowed_hosts.each do |pattern|
        return true if pattern.match host
      end

      false
    end

    def matcher_for(host)
      parts = host.split('.')
      pattern = nil
      parts.each do |part|
        if pattern.nil?
          pattern = prepared_part(part)
        else
          pattern = /#{pattern}\.#{prepared_part(part)}/
        end
      end
      /\A#{pattern}\Z/
    end

    def prepared_part(part)
      if part == '*'
        /.*/
      else
        part
      end
    end
  end
end
