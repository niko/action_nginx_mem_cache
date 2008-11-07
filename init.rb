require 'action_nginx_mem_cache_filter'
require 'action_nginx_mem_cache_helper'
ActionController::Base.send :include, ActionNginxMemCacheHelper