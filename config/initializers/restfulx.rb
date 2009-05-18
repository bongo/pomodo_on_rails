# the following patches allow us to overwrite session key on file uploads from Flash, 
# which ends up creating a new session for every File.upload() invocation.

# try settings for Rails 2.3.x first
if RAILS_GEM_VERSION =~ /^2.3/
  require 'rack/utils'

  class FlashSessionCookieMiddleware
    def initialize(app, session_key = '_session_id')
      @app = app
      @session_key = session_key
      @session_token = "_session_id"
    end

    def call(env)
      if env['HTTP_USER_AGENT'] =~ /^(Adobe|Shockwave) Flash/
        params = ::Rack::Utils.parse_query(env['QUERY_STRING'])
        debugger
        env['HTTP_COOKIE'] = [ @session_key, params[@session_token] ].join('=').freeze unless params[@session_token].nil?
      end
      @app.call(env)
    end
  end
else
  # otherwise default to Rails 2.x defaults
  class CGI::Session
    alias original_initialize initialize

    def initialize(request, option = {})
      option = scan_for_session_id(request, '_session_id', option) unless option['session_id']
      original_initialize(request, option)
    end

    def scan_for_session_id(request, session_key = '_session_id', option = {})
      query_string = if (qs = request.env_table["QUERY_STRING"]) and qs != ""
        qs
      elsif (ru = request.env_table["REQUEST_URI"][0..-1]).include?("?")
        ru[(ru.index("?") + 1)..-1]
      end
      if query_string and query_string.include?(session_key)
        option['session_id'] = query_string.scan(/#{session_key}=(.*?)(&.*?)*$/).flatten.first
      end
      return option
    end
  end
end

# If you have configured your Rails/Flex/AIR application to share authenticity_token
# comment this out to enable forgery protection. By default, this is disabled to allow
# generated code to work out of the box.
ActionController::Base.allow_forgery_protection = true