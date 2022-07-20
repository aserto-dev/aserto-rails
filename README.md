# Aserto Rails

Aserto authorization library for Ruby and Ruby on Rails.

## Prerequisites
* [Ruby](https://www.ruby-lang.org/en/downloads/) 2.7 or newer.
* An [Aserto](https://console.aserto.com) account.

## Installation
Add to your application Gemfile:

```ruby
gem "aserto-rails"
```

And then execute:
```bash
bundle install
```
Or install it yourself as:
```bash
gem install aserto-rails
```

## Configuration
The following configuration settings are required for the authorization middleware:
 - policy_id
 - tenant_id
 - authorizer_api_key
 - policy_root

These settings can be retrieved from the [Policy Settings](https://console.aserto.com/ui/policies) page of your Aserto account.

The middleware accepts the following optional parameters:

| Parameter name | Default value | Description |
| -------------- | ------------- | ----------- |
| service_url | `"authorizer.prod.aserto.com:8443"` | Sets the URL for the authorizer endpoint. |
| decision | `"allowed"` | The decision that will be used by the middleware when creating an authorizer request. |
| logger | `STDOUT` | The logger to be used by the middleware. |
| identity_mapping | `{ type: :none }` | The strategy for retrieveing the identity, possible values: `:jwt, :sub, :none` |

## Identity
To determine the identity of the user, the middleware can be configured to use a JWT token or a claim using the `identity_mapping` config.
```ruby
# configure the middleware to use a JWT token form the `my-auth-header` header.
config.identity_mapping = {
  type: :jwt,
  from: "my-auth-header",
}
```
```ruby
# configure the middleware to use a claim from the JWT token.
# This will decode the JWT token and extract the `sub` field from payload.
config.identity_mapping = {
  type: :sub,
  from: :sub,
}
```

The whole identity resolution can be overwritten by providing a custom function.
```ruby
# config/initializers/aserto.rb

# needs to return a hash with the identity having `type` and `identity` keys.
# supported types: `:jwt, :sub, :none`
Aserto.with_identity_mapper do |request|
  {
    type: :sub,
    identity: "my custom identity",
  }
end
```

## URL path to policy mapping
By default, when computing the policy path, the middleware:
* converts all slashes to dots
* converts any character that is not alpha, digit, dot or underscore to underscore
* converts uppercase characters in the URL path to lowercases

This behavior can be overwritten by providing a custom function:

```ruby
# config/initializers/aserto.rb

# must return a String
Aserto.with_policy_path_mapper do |policy_root, request|
  method = request.request_method
  path = request.path_info

  "custom: #{policy_root}.#{method}.#{path}"
end
```

## Resource
A resource can be any structured data that the authorization policy uses to evaluate decisions. By default, middleware do not include a resource in authorization calls.

This behavior can be overwritten by providing a custom function:

```ruby
# config/initializers/aserto.rb

# must return a Hash
Aserto.with_resource_mapper do |request|
  { resource:  request.path_info }
end
```
## Examples

```ruby
# config/initializers/aserto.rb

Rails.application.config.middleware.use Aserto::Authorization do |config|
  config.enabled = true
  config.policy_id = "my-policy-id"
  config.tenant_id = "my-tenant-id"
  config.authorizer_api_key = Rails.application.credentials.aserto[:authorizer_api_key]
  config.policy_root = "peoplefinder"
  config.service_url = "authorizer.eng.aserto.com:8443"
  config.decision = "allowed"
  config.logger = Rails.logger
  config.identity_mapping = {
    type: :sub,
    from: :sub
  }
end
```

## Controller helpers

The `authorize!` method in the controller will raise an exception if the user is not able to perform the given action.

```ruby
def show
  authorize!
  @post = Post.find(params[:id])
end
```

Setting this for every action can be tedious, therefore the `authorize_resource` method is provided to
automatically authorize all actions in a RESTful style resource controller.
It will use a before action to load the resource into an instance variable and authorize it for every action.

```ruby
class PostsController < ApplicationController
  authorize_resource

  def show
    # getting a single post authorized
  end

  def index
    # getting all posts is authorized
  end
end
```

## Development
Prerequisites:

    - go >= 1.17 to run mage
    - Ruby >= 2.7.0 to run the code


 Run `bundle install` to install dependencies. Then, run `bundle exec rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/aserto-dev/aserto-rails. This project is intended to be a safe, welcoming space for collaboration.

## License

The gem is available as open source under the terms of the [Apache-2.0 License](https://www.apache.org/licenses/LICENSE-2.0).
