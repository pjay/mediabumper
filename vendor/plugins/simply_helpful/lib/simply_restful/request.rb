module SimplyRestful
  module Request
    def self.included(base)
      base.class_eval do
        alias_method :method_without_method_emulation, :method
        alias_method :method, :method_with_method_emulation
      end
    end

    def method_with_method_emulation
      @request_method ||= (method = parameters[:_method]) ?
        method.to_s.downcase.to_sym :
        method_without_method_emulation
    end
  end
end