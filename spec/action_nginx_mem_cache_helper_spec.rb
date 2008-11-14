require File.join(File.dirname(__FILE__), 'spec_helper')

require 'action_nginx_mem_cache_helper'

describe ActionNginxMemCacheHelper do
  
  describe "class methods" do
    describe "action_nginx_mem_cache" do
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
  
  describe "instance methods" do
    before(:each) do
      @controller = ControllerStub.new
    end
    describe "write_action_cache" do
      it "should default the expiration to 5 minutes" do
        options = {:raw=>true, :expires_in=>5.minutes}
        @controller.should_receive(:write_fragment).with('some_http_mem_cache_key', 'some response body', options)
        @controller.send :write_action_cache
      end
      it "should default the expiration to 5 minutes if nil is given" do
        options = {:raw=>true, :expires_in=>5.minutes}
        @controller.should_receive(:write_fragment).with('some_http_mem_cache_key', 'some response body', options)
        @controller.send :write_action_cache, nil
      end
      it "should add a given :expires_in option in seconds to Time.now" do
        options = {:raw=>true, :expires_in=>10.minutes}
        @controller.should_receive(:write_fragment).with('some_http_mem_cache_key', 'some response body', options)
        @controller.send :write_action_cache, 10.minutes
      end
      it "should not try to write keys longer than 250 (memcaches limit)" do
        request = stub('request', :env => {'HTTP_MEM_CACHE_KEY' => '10_charact' * 26})
        
        @controller.stub!(:request => request)
        @controller.should_receive(:write_fragment).never
        @controller.send(:write_action_cache).should be_false
      end
    end
  end
  
  
end