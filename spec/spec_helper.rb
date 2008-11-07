require 'spec'
require 'flexmock'

$:.unshift File.dirname(__FILE__)
$:.unshift File.join(File.dirname(__FILE__), '../lib')

require 'active_support'
require 'action_controller'

require File.join(File.dirname(__FILE__), '../init')