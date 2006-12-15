require File.dirname(__FILE__) + '/../test_helper'
require 'playlists_controller'

# Re-raise errors caught by the controller.
class PlaylistsController; def rescue_action(e) raise e end; end

class PlaylistsControllerTest < Test::Unit::TestCase
  def setup
    @controller = PlaylistsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
