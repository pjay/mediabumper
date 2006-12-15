SimplyRestful
=============

SimplyRestful is a plugin for implementing verb-oriented controllers. This is
useful for implementing REST API's, where a single resource has different
behavior based on the verb (method) used to access it.

Giving credit where credit is due, this idea was inspired by reading:

  http://pezra.barelyenough.org/blog/2006/03/another-rest-controller-for-rails/

Because browsers don't yet support any verbs except GET and POST, you can send
a parameter named "_method" and the plugin will use that as the request method,
instead.

For example:

  class MessagesController < ActionController::Base
    def index
      # return all messages
    end

    def new
      # return an HTML form for describing a new message
    end
 
    def create
      # create a new message
    end

    def show
      # find and return a specific message
    end

    def edit
      # return an HTML form for editing a specific message
    end

    def update
      # find and update a specific message
    end

    def delete
      # delete a specific message
    end
  end

Your routes would be something like:

  map.resource :message

Then (using Net::HTTP to demonstrate the different verbs):

  Net::HTTP.start("localhost", 3000) do |http|
    # retrieve all messages
    response = http.get("/messages")

    # return an HTML form for defining a new message
    response = http.get("/messages/new")

    # create a new message
    response = http.post("/messages", "...")

    # retrieve message #1
    response = http.get("/messages/1")

    # return an HTML form for editing an existing message
    response = http.get("/messages/1;edit")

    # update an existing message
    response = http.put("/messages/1", "...")

    # delete an existing message
    response = http.delete("/messages/1")
  end

The #resource method accepts various options, too, to customize the resulting
routes:

  map.resource :message, :path_prefix => "/thread/:thread_id"
  # --> GET /thread/7/messages/1
 
  map.resource :message, :collection => { :rss => :get }
  # --> GET /messages;rss (maps to the #rss action)
  #     also adds a url named "rss_messages"

  map.resource :message, :member => { :mark => :post }
  # --> POST /messages/1;mark (maps to the #mark action)
  #     also adds a url named "mark_message"

  map.resource :message, :new => { :preview => :post }
  # --> POST /messages/new;preview (maps to the #preview action)
  #     also adds a url named "preview_new_message"

  map.resource :message, :new => { :new => :any, :preview => :post }
  # --> POST /messages/new;preview (maps to the #preview action)
  #     also adds a url named "preview_new_message"
  # --> /messages/new can be invoked via any request method

  map.resource :message, :controller => "categories",
        :path_prefix => "/category/:category_id",
        :name_prefix => "category_"
  # --> GET /categories/7/messages/1
  #     has named route "category_message"
