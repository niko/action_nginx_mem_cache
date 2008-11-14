require File.join(File.dirname(__FILE__), 'spec_helper')

require 'action_nginx_mem_cache_filter'

describe ActionNginxMemCacheFilter do
  
  describe "initialize" do
    describe "with a expires_in option" do
      it "should set the instance variable" do
        a = ActionNginxMemCacheFilter.new(:expires_in => 'tomorrow')
        a.instance_variable_get('@expires_in').should == 'tomorrow'
      end
    end
    it "should set the cookie_opts instance variable" do
      a = ActionNginxMemCacheFilter.new :cookie_opts => {:some => :cookie_opt}
      a.instance_variable_get('@cookie_opts').should == {:some => :cookie_opt}
    end
  end
  
  describe "after" do
    before(:each) do
      @controller = ControllerStub.new
      @filter = ActionNginxMemCacheFilter.new
    end
    describe "when caching should be performed" do
      before(:each) do
        ActionController::Base.stub!(:perform_caching).and_return(true)
      end
      it "should set the instance variables in the controller" do
        @filter.instance_variable_set('@expires_in', 'sometimes')
        @filter.instance_variable_set('@cookie_opts', {:some => :cookie_opt})
        @controller.stub!(:instance_eval)
        @filter.after(@controller)
        
        @controller.instance_variable_get('@_nginx_mem_cache_expires_in').should == 'sometimes'
        @controller.instance_variable_get('@_nginx_mem_cache_cookie_opts').should == {:some => :cookie_opt}
      end
      describe "if prevent_action_caching is true" do
        before(:each) do
          @controller.stub!(:prevent_action_caching).and_return(true)
        end
        it "should not write the cache" do
          @controller.should_not_receive(:writing_action_cache_allowed?)
          @filter.after(@controller)
        end
      end
      describe "if prevent_action_caching is false" do
        before(:each) do
          @controller.stub!(:prevent_action_caching?).and_return(false)
        end
        describe "when writing the cache is allowed" do
          before(:each) do
            @controller.stub!(:writing_action_cache_allowed?).and_return(true)
          end
          it "should write the cache delete the prevent_action_caching cookie" do
            @controller.should_receive(:writing_action_cache_allowed?)
            @filter.after(@controller)
          end
        end
        describe "when writing the cache is NOT allowed" do
          before(:each) do
            @controller.stub!(:writing_action_cache_allowed?).and_return(false)
          end
          it "should write the cache delete the prevent_action_caching cookie" do
            @controller.should_receive(:write_action_cache).never
            @filter.after(@controller)
          end
        end
        it "should delete the prevent_action_caching cookie" do
          cookies = mock('cookies', :delete => true)
          @controller.should_receive(:cookies).and_return(cookies)
          @filter.after(@controller)
        end
      end
    end
    describe "when no caching should be performed" do
      before(:each) do
        ActionController::Base.should_receive(:perform_caching).and_return(false)
      end
      it "should not do anything" do
        a = ActionNginxMemCacheFilter.new
        @controller.should_receive(:instance_variable_set).never
        a.after(@controller)
      end
    end
  end
  
end