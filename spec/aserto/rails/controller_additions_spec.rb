# frozen_string_literal: true

require "active_support/all"
require "action_dispatch"

class Controller
  attr_reader :request

  def initialize(request)
    @request = request
  end
end

describe Aserto::Rails::ControllerAdditions do
  let(:request) { ActionDispatch::Request.new({}) }
  let(:controller_class) { Controller }
  let(:controller) { Controller.new(request) }
  let(:client) { Aserto::AuthClient.new(request) }

  before do
    allow(controller_class).to receive(:helper_method).with(:can?, :cannot?)
    allow(controller_class).to receive(:before_action)
    allow(controller).to receive(:params).and_return({})
    allow(request).to receive(:request_method=)
    allow(request).to receive(:path_info=)
    allow(Aserto::AuthClient).to receive(:new).and_return(client)
    allow(client).to receive(:is).and_return(true)
    controller_class.send(:include, described_class)
  end

  it "aserto_resource_class is ControllerResource by default" do
    expect(controller.class.aserto_resource_class).to eq(Aserto::Rails::ControllerResource)
  end

  it "provides a can? method" do
    expect(controller.can?(:foo, :bar)).to be(true)
  end

  it "provides a cannot? method" do
    expect(controller.cannot?(:foo, :bar)).to be(false)
  end

  describe "authorize_resource" do
    let(:aserto_resource_class) { class_double(Aserto::Rails::ControllerResource) }

    it "setups a before filter which passes call to ControllerResource" do
      allow(aserto_resource_class).to receive(:new).with(controller, nil, { foo: :bar }) { aserto_resource_class }
      controller_class.authorize_resource foo: :bar

      expect(controller_class)
        .to have_received(:before_action).with({}) { |_options, &block| block.call(controller) }
    end

    it "authorize_resource properly passes first argument as the resource name" do
      allow(aserto_resource_class).to receive(:new).with(controller, :project, { foo: :bar }) do
        aserto_resource_class
      end
      controller_class.authorize_resource :project, foo: :bar
      expect(controller_class)
        .to have_received(:before_action).with({}) { |_options, &block| block.call(controller) }
    end

    context "with conditions" do
      it "setups a before filter which passes call to ControllerResource" do
        allow(aserto_resource_class).to receive(:new).with(controller, nil, { foo: :bar }) { aserto_resource_class }
        controller_class.authorize_resource foo: :bar, except: :show, if: true

        expect(controller_class)
          .to have_received(:before_action).with({ except: :show, if: true }) do |_options, &block|
            block.call(controller)
          end
      end
    end

    context "with prepend" do
      before do
        allow(controller_class).to receive(:prepend_before_action)
      end

      it "prepends the before filter" do
        controller_class.authorize_resource foo: :bar, prepend: true
        expect(controller_class).to have_received(:prepend_before_action).with({})
      end
    end
  end
end
