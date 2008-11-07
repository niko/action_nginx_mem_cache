require File.join(File.dirname(__FILE__), 'spec_helper')

require 'action_nginx_mem_cache_helper'

class ControllerStub
  include ActionNginxMemCacheHelper
  
  def self.after_filter(*args)
  end
end

describe ActionNginxMemCacheHelper do
  
  describe "argument parsing" do
    it "should work without arguments" do
      ActionNginxMemCacheFilter.should_receive(:new).and_return('a new memcache filter')
      ControllerStub.should_receive(:after_filter).with('a new memcache filter', {})
      ControllerStub.action_nginx_mem_cache
    end
    it "should pass the filter opts to the after filter" do
      ActionNginxMemCacheFilter.should_receive(:new).and_return('a new memcache filter')
      ControllerStub.should_receive(:after_filter).with('a new memcache filter', :only => 'here')
      ControllerStub.action_nginx_mem_cache(:only => 'here')
    end
    it "should pass the caching opts to the cache class" do
      ActionNginxMemCacheFilter.should_receive(:new).with(:expires_in => 'tomorrow').and_return('a new memcache filter')
      ControllerStub.should_receive(:after_filter)
      ControllerStub.action_nginx_mem_cache(:expires_in => 'tomorrow')
    end
  end
  
end