module ActionNginxMemCacheHelper
  
  def self.included(base)
    base.extend ClassMethods
  end
  
  module ClassMethods
    def action_nginx_mem_cache(opts={})
      caching_opts  = opts.reject{ |k,v| ![:expires_in, :cookie_opts].include?(k) }
      filter_opts   = opts.reject{ |k,v|  [:expires_in, :cookie_opts].include?(k) }
      
      after_filter ActionNginxMemCacheFilter.new(caching_opts), filter_opts
    end
  end
  
end