module SimplyRestful
  module Routes
    def resource(entity, options={})
      plural = entity.to_s.pluralize

      collection  = options.delete(:collection) || {}
      member      = options.delete(:member) || {}
      new         = options.delete(:new) || true
      path_prefix = options.delete(:path_prefix)
      name_prefix = options.delete(:name_prefix)

      member[:edit] = :get

      new = new.is_a?(Hash) ? {:new => :get}.update(new) : { :new => :get }

      collector = Proc.new { |h,(k,v)| (h[v] ||= []) << k; h }

      collection_methods = collection.inject({}, &collector) 
      member_methods = member.inject({}, &collector)
      new_methods = new.inject({}, &collector)

      (collection_methods[:post] ||= []).unshift :create
      (member_methods[:put] ||= []).unshift :update
      (member_methods[:delete] ||= []).unshift :destroy

      path = "#{path_prefix}/#{plural}"

      collection_path = path
      new_path = "#{path}/new"
      member_path = "#{path}/:id"

      with_options :controller => (options[:controller] || plural).to_s do |map|
        collection_methods.each do |method, list|
          primary = list.shift.to_s if method != :get
          route_options = requirements_for(method)
          list.each do |action|
            map.named_route("#{name_prefix}#{action}_#{plural}", "#{collection_path};#{action}", route_options.merge(:action => action.to_s))
            map.named_route("formatted_#{name_prefix}#{action}_#{plural}", "#{collection_path}.:format;#{action}", route_options.merge(:action => action.to_s))
          end
          map.connect(collection_path, route_options.merge(:action => primary)) unless primary.blank?
          map.connect("#{collection_path}.:format", route_options.merge(:action => primary)) unless primary.blank?
        end

        map.named_route("#{name_prefix}#{plural}", collection_path, :action => "index", :conditions => { :method => :get })
        map.named_route("formatted_#{name_prefix}#{plural}", "#{collection_path}.:format", :action => "index", :conditions => { :method => :get })

        new_methods.each do |method, list|
          route_options = requirements_for(method)
          list.each do |action|
            path = action == :new ? new_path : "#{new_path};#{action}"
            name = "new_#{entity}"
            name = "#{action}_#{name}" unless action == :new
            map.named_route("#{name_prefix}#{name}", path, route_options.merge(:action => action.to_s))
            map.named_route("formatted_#{name_prefix}#{name}", action == :new ? "#{new_path}.:format" : "#{new_path}.:format;#{action}", route_options.merge(:action => action.to_s))
          end
        end

        member_methods.each do |method, list|
          route_options = requirements_for(method)
          primary = list.shift.to_s unless [:get, :post, :any].include?(method)
          list.each do |action|
            map.named_route("#{name_prefix}#{action}_#{entity}", "#{member_path};#{action}", route_options.merge(:action => action.to_s))
            map.named_route("formatted_#{name_prefix}#{action}_#{entity}", "#{member_path}.:format;#{action}", route_options.merge(:action => action.to_s))
          end
          map.connect(member_path, route_options.merge(:action => primary)) unless primary.blank?
        end

        map.named_route("#{name_prefix}#{entity}", member_path, :action => "show", :conditions => { :method => :get })
        map.named_route("formatted_#{name_prefix}#{entity}", "#{member_path}.:format", :action => "show", :conditions => { :method => :get })
      end
    end

    def resources(*entities)
      options = entities.last.is_a?(Hash) ? entities.pop : { }
      entities.each { |entity| resource(entity, options) }
    end

    private
      def requirements_for(method)
        method == :any ?
          {} :
          { :conditions => { :method => method } }
      end
  end
end
