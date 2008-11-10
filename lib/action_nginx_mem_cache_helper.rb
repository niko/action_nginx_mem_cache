module ActionNginxMemCacheHelper
  
  def self.included(base)
    base.extend ClassMethods
    base.send :include, InstanceMethods
  end
  
  module ClassMethods
    def action_nginx_mem_cache(opts={})
      caching_opts  = opts.reject{ |k,v| ![:expires_in, :cookie_opts].include?(k) }
      filter_opts   = opts.reject{ |k,v|  [:expires_in, :cookie_opts].include?(k) }
      
      after_filter ActionNginxMemCacheFilter.new(caching_opts), filter_opts
    end
  end
  
  module InstanceMethods
    
    private
    
    # You can define a prevent_action_caching? method in your controller to prevent
    # caching p.e. for certain users.
    # Ours look like this:
    #
    # def prevent_action_caching?; !!current_member; end
    #
    def prevent_action_caching(cookie_opts={})
      cookie_opts ||= {}
      
      if respond_to?(:prevent_action_caching?) && !prevent_action_caching?
        return false
      end
      
      self.cookies[:prevent_action_caching] = {
        :value => 'true',
        :expires => Time.now + 1.year
      }.merge(cookie_opts)
    end
    
    def dont_prevent_action_caching(cookie_opts={})
      cookie_opts ||= {}
      
      self.cookies.delete :prevent_action_caching, cookie_opts
    end
    
    # Write the cache. The cache key is pulled from the HTTP_MEM_CACHE_KEY request header.
    # The HTTP_MEM_CACHE_KEY request header should be set by NginX:
    #
    # set $memcached_key_postfix  '$host$request_uri';
    # set $memcached_key          views/$memcached_key_postfix;
    # proxy_set_header Mem-Cache-Key    $memcached_key_postfix;
    #
    def write_action_cache(expires_in=Time.now + 5.minutes)
      cache_key =  request.env['HTTP_MEM_CACHE_KEY']
      write_fragment(cache_key, response.body, {:expires_in => expires_in, :raw => true})
    end
    
    # Controls caching depending on the request and the response.
    # Writing into the cache is only ok if
    # * it's a get request
    # * the status is 200
    # * the requests HTTP_MEM_CACHE_KEY header is set
    #
    def writing_action_cache_allowed?
      request.get? &&
        response.headers['Status'].to_i == 200 &&
        request.env['HTTP_MEM_CACHE_KEY']
    end
    
  end
  
end