require File.join(File.dirname(__FILE__), 'spec_helper')

require 'action_nginx_mem_cache_filter'

class ControllerStub < ActionController::Base
  attr_reader :prevent_action_caching
  
  def prevent_action_caching
    true
  end
  
end


describe ActionNginxMemCacheFilter do
  
  describe "initialize" do
    describe "with a expires_in option" do
      it "should set the instance variable" do
        a = ActionNginxMemCacheFilter.new(:expires_in => 'tomorrow')
        a.instance_variable_get('@expires_in').should == 'tomorrow'
      end
    end
    describe "without a expires_in option" do
      it "should set the default" do
        Time.should_receive(:now).at_least(:once).and_return Time.parse('01.01.2007 00:00')
        a = ActionNginxMemCacheFilter.new
        a.instance_variable_get('@expires_in').should == Time.parse('01.01.2007 00:05')
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
        @filter.stub!(:writing_cache_allowed?).and_return(true)
        @filter.stub!(:write_cache)
        @filter.stub!(:set_cookie)
        @filter.stub!(:delete_cookie)
      end
      it "should set the instance variables in the controller" do
        @filter.instance_variable_set('@expires_in', 'sometimes')
        @filter.instance_variable_set('@cookie_opts', {:some => :cookie_opt})
        @filter.after(@controller)
        
        @controller.instance_variable_get('@_nginx_mem_cache_expires_in').should == 'sometimes'
        @controller.instance_variable_get('@_nginx_mem_cache_cookie_opts').should == {:some => :cookie_opt}
      end
      describe "if prevent_action_caching is true" do
        before(:each) do
          @filter.stub!(:prevent_action_caching?).and_return(true)
        end
        it "should set the prevent_action_caching cookie" do
          @filter.should_receive(:set_cookie).with(@controller)
          @filter.after(@controller)
        end
      end
      describe "if prevent_action_caching is false" do
        before(:each) do
          @filter.stub!(:prevent_action_caching?).and_return(false)
        end
        describe "when writing the cache is allowed" do
          before(:each) do
            @filter.stub!(:writing_cache_allowed?).with(@controller).and_return(true)
          end
          it "should write the cache delete the prevent_action_caching cookie" do
            @filter.should_receive(:write_cache).with(@controller)
            @filter.after(@controller)
          end
        end
        describe "when writing the cache is NOT allowed" do
          before(:each) do
            @filter.stub!(:writing_cache_allowed?).with(@controller).and_return(false)
          end
          it "should write the cache delete the prevent_action_caching cookie" do
            @filter.should_receive(:write_cache).with(@controller).never
            @filter.after(@controller)
          end
        end
        it "should delete the prevent_action_caching cookie" do
          @filter.should_receive(:delete_cookie).with(@controller)
          @filter.after(@controller)
        end
      end
    end
    describe "when no caching should be performed" do
      before(:each) do
        ActionController::Base.should_receive(:perform_caching).and_return(false)
      end
      it "should return nil" do
        a = ActionNginxMemCacheFilter.new
        a.after(@controller).should be_nil
      end
    end
  end
  
end