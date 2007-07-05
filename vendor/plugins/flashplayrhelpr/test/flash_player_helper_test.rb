require 'rubygems'
require 'test/unit'
require File.dirname(__FILE__) + '/../lib/flash_player_helper'
require 'active_support/core_ext'
require 'action_view/helpers/tag_helper'
require 'action_view/helpers/asset_tag_helper'
require 'action_view/helpers/javascript_helper'

class FlashPlayerHelperTest < Test::Unit::TestCase
  include GotRuby::FlashPlayerHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::JavascriptHelper
  
  def test_default_player
    snippet = player
    flash_options, target_element = search_and_parse_ufo_create_method snippet
    flashvars = flash_vars_to_hash flash_options.delete(:flashvars)
    
    assert_equal "#{DEFAULT_FLASH_OPTIONS[:id]}_container", target_element
    assert_equal({}, DEFAULT_FLASH_OPTIONS.diff(flash_options))
    assert_equal({}, DEFAULT_PLAYER_OPTIONS.diff(flashvars))
  end
  
  def test_uses_default_movie_locations_for_specific_players
    [:mp3_player, :media_player, :image_slideshow, :flv_player].each do |player_type|
      player = send player_type
      assert_match(/movie:"#{DEFAULT_MOVIE_LOCATIONS[player_type]}"/, player)
    end
  end
  
  def test_player_options_translate_into_url_encoded_flashvars
    unescaped_file = '/playlists/show?album=in+search+of+sunrise+4&artist=dj+tiesto'
    escaped_file = '%2Fplaylists%2Fshow%3Falbum%3Din%2Bsearch%2Bof%2Bsunrise%2B4%26artist%3Ddj%2Btiesto'
    DEFAULT_PLAYER_OPTIONS.clear #clear the default player options, which translate into flashvars
    the_player = player :file => unescaped_file, :backcolor => '0xFFFFFF'
    flashvars = the_player.scan(/flashvars:"(\S*)"/)[0][0].split('&')
    
    assert_equal 2, flashvars.length
    assert flashvars.include?('backcolor=0xFFFFFF')
    assert flashvars.include?("file=#{escaped_file}")
  end
  
  def test_player_creates_container_with_default_msg_for_flash_object
    player = media_player({}, :id => 'my_player')
    assert player.starts_with?(%(<div id="my_player_container">#{DEFAULT_FLASH_REQUIRED_MESSAGE}</div>))
  end
  
  def test_player_creates_container_with_custom_msg_for_flash_object
    custom_msg = 'You need to enable javascript and have a Flash plugin to view this content.'
    temporarily_set_flash_required_msg(custom_msg) do
      player = mp3_player({},{:id => 'my_player'})
      assert player.starts_with?(%(<div id="my_player_container">#{custom_msg}</div>))
    end
  end
  
  def temporarily_set_flash_required_msg(msg)
    GotRuby::FlashPlayerHelper.class_eval "FLASH_REQUIRED_MESSAGE = 'You need to enable javascript and have a Flash plugin to view this content.'"
    yield
    GotRuby::FlashPlayerHelper.class_eval "remove_const :FLASH_REQUIRED_MESSAGE"
  end
  
  def test_ufo_create_method_call_specifies_container_as_target_element
    player = media_player({}, :id => 'my_player')
    args, target_element = search_and_parse_ufo_create_method(player)
    assert_equal 'my_player_container', target_element
  end
  
  def test_player_event
    assert_equal "$(\"#{DEFAULT_FLASH_OPTIONS[:id]}\").sendEvent(\"playpause\");", player_event(:playpause)
    
    assert_equal "$(\"playa\").sendEvent(\"playpause\");", player_event(:playpause, :id => 'playa')
    assert_equal "$(\"playa\").sendEvent(\"playpause\");", player_event(:playpause, :id => :playa)
    assert_equal "$(\"playa\").sendEvent(\"scrub\",5);", player_event(:scrub, 5, :id => :playa)
    assert_equal "$(\"playa\").sendEvent(\"volume\",25);", player_event(:volume, 25, :id => :playa)
    assert_equal "$(\"playa\").sendEvent(\"playitem\",2);", player_event(:playitem, 2, :id => :playa)
    assert_equal "$(\"playa\").sendEvent(\"next\");", player_event(:next, :id => :playa)
    assert_equal "$(\"playa\").sendEvent(\"prev\");", player_event(:prev, :id => :playa)
  end
  
  def test_player_event_calls_loadFile_when_action_is_to_load_file
    assert_equal "$(\"#{DEFAULT_FLASH_OPTIONS[:id]}\").loadFile(\"song.mp3\");", player_event(:load, 'song.mp3')
    assert_equal "$(\"playa\").loadFile(\"song.mp3\");", player_event(:load, 'song.mp3', :id => 'playa')
  end
  
  # searches for and parses a UFO.create() method call, returning its arguments
  # we're looking for a command like this:
  # UFO.create({width:"500", height:"500"}, 'player_div')
  def search_and_parse_ufo_create_method player
    ufo_create = player.scan(/.*UFO\.create\((.*)\)/)[0][0].strip
    # validate the create command args format: {width:"500", height:"500"}, "player_div"
    assert ufo_create =~ /\{(.+:".+")*\},\s"\S+"/
    
    args = ufo_create.gsub(/\{|\}/,'').split ','
    # assume last arg is element_id based on the last assert
    element_id = args.pop
    flash_options = {}
    args.each do |pair|
      k,v = pair.split ':'
      flash_options[k.strip.to_sym] = deserialize v.strip.gsub(/(^")|("$)/,'')  #regex 2 strip double quotes
    end
    [flash_options, element_id.strip.gsub(/"/,'')]
  end
  
  #flashvars are lumped up in a query string, like query parameters in a url
  #so this just turns a flashvars string into a hash for easier testing
  def flash_vars_to_hash flashvars_str
    flashvars = {}
    flashvars_str.split('&').collect do |var|
      k,v = var.split '='
      flashvars[k.to_sym] = deserialize CGI::unescape(v)
    end
    flashvars
  end
  
  #already some standard way to do this? :\
  def deserialize val
    case val.to_s
      when 'true': return true
      when 'false': return false
    end
    val =~ /^\d+$/ ? val.to_i : val
  end
end