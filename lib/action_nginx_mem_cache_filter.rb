class ActionNginxMemCacheFilter
  
  def initialize(opts={})
    @expires_in = opts[:expires_in] || Time.now + 5.minutes
    @cookie_opts = opts[:cookie_opts]
  end
  
  def after(controller)
    if ActionController::Base.perform_caching
      controller.instance_variable_set('@_nginx_mem_cache_expires_in', @expires_in)
      controller.instance_variable_set('@_nginx_mem_cache_cookie_opts', @cookie_opts)
      
      if prevent_action_caching?(controller)
        set_cookie(controller)
      else
        write_cache(controller) if writing_cache_allowed?(controller)
        delete_cookie(controller)
      end
    end
  end
  
  private
    
    # You can define a prevent_action_caching? method in your controller to prevent
    # caching p.e. for certain users.
    # Ours look like this:
    #
    # def prevent_action_caching; current_member; end
    #
    def prevent_action_caching?(controller)
      controller.respond_to?(:prevent_action_caching?) && controller.prevent_action_caching?
    end
    
    # Set the cookie to prevent action caching.
    #
    def set_cookie(controller)
      controller.instance_eval do
        cookies[:prevent_action_caching] = {
          :value => 'true',
          :expires => Time.now + 1.year
        }.merge(@_nginx_mem_cache_cookie_opts)
      end
    end
    
    # Delete the cookie that prevents action caching.
    #
    def delete_cookie(controller)
      controller.instance_eval do
        cookies.delete :prevent_action_caching, @_nginx_mem_cache_cookie_opts
      end
    end
    
    # Write the cache. The cache key is pulled from the HTTP_MEM_CACHE_KEY request header.
    # The HTTP_MEM_CACHE_KEY request header should be set by NginX:
    #
    # set $memcached_key_postfix  '$host$request_uri';
    # set $memcached_key          views/$memcached_key_postfix;
    # proxy_set_header Mem-Cache-Key    $memcached_key_postfix;
    #
    def write_cache(controller)
      cache_key =  controller.request.env['HTTP_MEM_CACHE_KEY']
      controller.write_fragment(cache_key, controller.response.body, {:expires_in => @_nginx_mem_cache_expires_in, :raw => true})
    end
    
    # Controls caching depending on the request and the response.
    # Writing into the cache is only ok if
    # * it's a get request
    # * the status is 200
    # * 
    #
    def writing_cache_allowed?(controller)
      controller.request.get? &&
        controller.response.headers['Status'].to_i == 200 &&
        controller.request.env['HTTP_MEM_CACHE_KEY']
    end
    
end
