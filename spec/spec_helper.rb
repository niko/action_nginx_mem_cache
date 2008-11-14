require 'rubygems'
require 'spec'

$:.unshift File.dirname(__FILE__)
$:.unshift File.join(File.dirname(__FILE__), '../lib')

require 'active_support'
require 'action_controller'
require 'action_controller/test_process'

require File.join(File.dirname(__FILE__), '../init')

class ControllerStub < ActionController::Base
  include ActionNginxMemCacheHelper
  
  def self.after_filter(*args)
  end
  
  def request
    AnmcTestRequest.new({
      "controller" => "whatever",
      "action"     => "some_action",
      "_method"    => "get"
    })
  end
  
  def response
    AnmcTestResponse.new
  end
  
  def self.perform_caching
    true
  end
  
end

class AnmcTestResponse < ActionController::TestResponse
  
  def body
    'some response body'
  end
  
end

class AnmcTestRequest < ActionController::TestRequest
  
  def env
    {
      'HTTP_MEM_CACHE_KEY' => 'some_http_mem_cache_key'
    }
  end
  
end