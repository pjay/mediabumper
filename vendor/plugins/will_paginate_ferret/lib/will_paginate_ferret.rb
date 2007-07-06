module WillPaginateFerret
  module Finder
    def self.included(base)
      base.extend ClassMethods
    end
    
    module ClassMethods
      def paginate_by_contents(q, options = {}, find_options = {})
        # wp_parse_options is defined in plugin will_paginate
        options, page, per_page = wp_parse_options options
        total_entries = total_hits(q, options)
        
        returning WillPaginate::Collection.new(page, per_page, total_entries) do |pager|
          options.update(:offset => pager.offset, :limit => pager.per_page)
          pager.replace find_by_contents(q, options, find_options)
        end
      end
    end
  end
end
