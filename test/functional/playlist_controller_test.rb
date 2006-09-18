require File.dirname(__FILE__) + '/../test_helper'
require 'playlist_controller'

# Re-raise errors caught by the controller.
class PlaylistController; def rescue_action(e) raise e end; end

class PlaylistControllerTest < Test::Unit::TestCase
  def setup
    @controller = PlaylistController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
