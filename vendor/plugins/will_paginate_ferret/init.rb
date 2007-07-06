require 'will_paginate_ferret'
ActiveRecord::Base.send(:include, WillPaginateFerret::Finder)
