class ActionNginxMemCacheFilter
  
  def initialize(opts={})
    @expires_in = opts[:expires_in]
    @cookie_opts = opts[:cookie_opts]
  end
  
  def after(controller)
    if ActionController::Base.perform_caching
      controller.instance_variable_set('@_nginx_mem_cache_expires_in', @expires_in)
      controller.instance_variable_set('@_nginx_mem_cache_cookie_opts', @cookie_opts)
      
      controller.instance_eval do
        unless prevent_action_caching(@_nginx_mem_cache_cookie_opts)
          write_action_cache(@_nginx_mem_cache_expires_in) if writing_action_cache_allowed?
          dont_prevent_action_caching(@_nginx_mem_cache_cookie_opts)
        end
      end
    end
  end
  
end
