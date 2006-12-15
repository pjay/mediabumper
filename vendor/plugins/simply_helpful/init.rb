require 'simply_restful'

# Wheeee! Monkey-patching!

ActionController::AbstractRequest.send :include, SimplyRestful::Request
ActionController::Routing::RouteSet::Mapper.send :include, SimplyRestful::Routes
