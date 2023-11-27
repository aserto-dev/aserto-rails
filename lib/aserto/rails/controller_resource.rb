# frozen_string_literal: true

module Aserto
  module Rails
    class ControllerResource
      def initialize(controller, *args)
        @controller = controller
        @params = controller.params
        @options = args.extract_options!
        @name = args.first
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
      def check_resource
        client = Aserto::AuthClient.new(@controller.request)
        raise Aserto::AccessDenied unless client.check(**(@options[:params] || {}))
      end

      def authorize_resource
        raise Aserto::AccessDenied unless Aserto::AuthClient.new(@controller.request).is
      end

      class << self
        def add_before_action(controller_class, method, *args)
          options = args.extract_options!
          resource_name = args.first
          before_action_method = before_callback_name(options)
          controller_class.send(before_action_method, options.slice(:only, :except, :if, :unless)) do |controller|
            controller.class.aserto_resource_class
                      .new(controller, resource_name, options.except(:only, :except, :if, :unless)).send(method)
          end
        end

        def before_callback_name(options)
          options.delete(:prepend) ? :prepend_before_action : :before_action
        end
      end
    end
  end
end
