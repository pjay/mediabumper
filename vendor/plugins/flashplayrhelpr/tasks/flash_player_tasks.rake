namespace :flash_player do
  
  PLUGIN_ROOT = File.dirname(__FILE__) + '/../'
  
  desc 'Installs required swf & javascript files to the public/javascripts directory.'
  task :install do
    FileUtils.cp_r Dir[PLUGIN_ROOT + '/assets/swf'], RAILS_ROOT + '/public'
    FileUtils.cp Dir[PLUGIN_ROOT + '/assets/javascripts/*.js'], RAILS_ROOT + '/public/javascripts'
  end

  desc 'Removes the swf & javascripts for the plugin.'
  task :remove do
    FileUtils.rm %{ufo.js}.collect { |f| RAILS_ROOT + "/public/javascripts/" + f  }
    FileUtils.rmtree %{swf}.collect { |f| RAILS_ROOT + "/public/" + f } #trees to rm
  end
  
end