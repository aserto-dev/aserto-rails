# frozen_string_literal: true

module Aserto
  module Rails
    module ControllerAdditions
      module ClassMethods
        def authorize_resource(*args)
          aserto_resource_class.add_before_action(self, :authorize_resource, *args)
        end

        def aserto_resource_class
          ControllerResource
        end
      end

      def can?
        Aserto::AuthClient.new(request).is
      end

      def cannot?
        !can?
      end

      def authorize!
        raise Aserto::Rails::AccessDenied unless can?
      end

      class << self
        def included(base)
          base.extend ClassMethods
          base.helper_method :can?, :cannot? if base.respond_to? :helper_method
        end
      end
    end
  end
end

if defined? ActiveSupport
  ActiveSupport.on_load(:action_controller) do
    include Aserto::Rails::ControllerAdditions
  end
end
