# frozen_string_literal: true

module Aserto
  module Rails
    module ControllerAdditions
      module ClassMethods
        def aserto_authorize_resource(*args)
          aserto_resource_class.add_before_action(self, :authorize_resource, *args)
        end

        def aserto_check_resource(*args)
          aserto_resource_class.add_before_action(self, :check_resource, *args)
        end

        def aserto_resource_class
          ControllerResource
        end
      end
      class << self
        def included(base)
          base.extend ClassMethods
          base.helper_method :allowed?, :visible?, :enabled? if base.respond_to? :helper_method
        end
      end

      def allowed?(action = nil, path = nil, resource = nil)
        augment_request!(action, path, resource)
        Aserto::AuthClient.new(request).allowed?
      end

      def visible?(action = nil, path = nil, resource = nil)
        augment_request!(action, path, resource)
        Aserto::AuthClient.new(request).visible?
      end

      def enabled?(action = nil, path = nil, resource = nil)
        augment_request!(action, path, resource)
        Aserto::AuthClient.new(request).enabled?
      end

      def aserto_authorize!
        raise Aserto::AccessDenied unless Aserto::AuthClient.new(request).is
      end

      #
      # Authorization call based on check relation
      #
      # @param [String] object_id
      # @param [String] object_type
      # @param [String] relation
      #
      # @return [nil]
      #
      # @raise Aserto::AccessDenied
      #
      def check!(object_id:, object_type:, relation:, options: {})
        raise Aserto::AccessDenied unless Aserto::AuthClient.new(request).check(
          object_id: object_id, object_type: object_type, relation: relation, options: options
        )
      end

      private

      def augment_request!(action, path, resource)
        if resource
          Aserto.with_resource_mapper do
            {
              resource: resource.as_json.transform_keys(&:to_s)
            }
          end
        end
        request.request_method = action.to_s.upcase if action
        request.path_info = path if path
      end
    end
  end
end

if defined? ActiveSupport
  ActiveSupport.on_load(:action_controller) do
    include Aserto::Rails::ControllerAdditions
  end
end
