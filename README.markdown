What's this about?
==================

This is a simple Rails plugin do do action caching with memcache and have nginx pull the cached pages from memcache directly. So requests for cached pages don't even hit your Rails app server. It may not fit for all but it still could serve as a blueprint to implement s/th that suits your own caching needs. restorm.com runs this in production.

Discussion
==========

The problem with this kind of caching is that Nginx and Rails somwhow have to communicate about what to cache and where to find the cached pages (the cache_key).

To accomplish the first I decided to use use a cookie - set by Rails - to tell Nginx what NOT to cache. In out case we do a timed expiration of pages for not logged in users, but you can define your own rules. So if s/o logs in, he gets the prevent_action_caching cookie set and Nginx never passes his requests memcache.

And Nginx sets a custom header - Mem-Cache-Key - to tell Rails about the cache key. This way the construction of the cache key is done just at one place: Nginx (besides the fact that Rails adds 'views/' in front of every given action cache key).

Functionally this caching is sort of a mixture between Rails page caching and Rails action caching. You still have the possibility to define a caching rule on a per-client (not per action) basis but keep away most of load from rails. And you have the added benefit of time-based expiration. Note that the default is 5 minutes, as for usual usecase this seems to be a sensible default (at least to me). Just use `SOME_BIG_INTEGER(TM)` for no expiration.

Usage
=====

In your controllers you just call

    action_nginx_mem_cache :only => :index

with the same options as any after filter. There are two additional options for cookie options and the expiration time:

    action_nginx_mem_cache :only => :index, :cookie_opts => {:domain => SESSION_DOMAIN}, :expires_in Time.now + 10 minutes

To control, wether or not to cache the request of a certain user, define prevent_action_caching? in your controller:

    def prevent_action_caching?
      current_user
    end

To manually set or delete the prevent_action_caching cookie, use these:

    prevent_action_caching

and

    dont_prevent_action_caching

Both take the cookie-opts as options.


POST requests are automatically excluded and responses with a status other than 200 are not written to cache. If you don't run this plugin behind Nginx and if Nginx doesn't set the Mem-Cache-Key header no caching is done.

To make this plugin work you have to have rules similar to these in your Nginx configuration:

nginx.conf
==========

    set $memcached_key_postfix  '$host$request_uri'; # construct the cache key.
    set $memcached_key          views/$memcached_key_postfix;      # rails automagically prepends a 'views/' string, so we do the same.

    # We set the proxy headers to the values of the original request
    # and add a custom header for the cache-key.
    proxy_set_header  Mem-Cache-Key   $memcached_key_postfix;

    upstream backend {
      server 10.0.2.6:80;
    }

    location / {
  
      # ... typically the rules for your static files are here
  
      # We should not cache POSTs, do we? ;)  So POSTs got straight to the backend:
      if ($request_method = POST) {
        proxy_pass http://backend;
        add_header X-NXR "http post";
        break;
      }
  
      # We don't cache those, either (what would the prevent_action_caching cookie be good for otherwise).
      if ($http_cookie ~ "prevent_action_caching=true"){
        proxy_pass http://backend;
        add_header X-NXR "prevent action caching true";
        break;
      }
  
      #################
      # Mem-Cache part:
  
      # We set the default mime-type and charset explicitly so it's used for cached pages.
      default_type  text/html;
      charset       utf-8;
  
  
      # We're using /internal_backend_reference to prevent an endless loop.
      # 404 means a missed cache, 502 a missing mem-cache server.
      if ($http_cookie !~ "prevent_action_caching=true"){
        add_header X-NXR "can we pull out of cache?";
        memcached_pass   10.0.2.40:11211;
        add_header X-NXR "yes, we can!";
    
        error_page 404 502 = /internal_backend_reference;
    
        break;
      }
  
      proxy_pass http://backend;
    }

Known Bugs
==========

* 'Mem-Cache-Key's are not generated correctly for URLs with a %-sign in a query string. Further investigation pending.

More information
================

* http://wiki.codemongers.com/NginxHttpMemcachedModule
* http://www.igvita.com/2008/02/11/nginx-and-memcached-a-400-boost/
* http://weichhold.com/2008/09/12/django-nginx-memcached-the-dynamic-trio/
