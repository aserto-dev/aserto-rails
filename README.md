# Aserto Rails

Aserto authorization library for Ruby and Ruby on Rails.

Built on top of [aserto](https://github.com/aserto-dev/aserto-ruby) and [aserto-grpc-authz](https://github.com/aserto-dev/ruby-grpc-authz).

## Prerequisites
* [Ruby](https://www.ruby-lang.org/en/downloads/) 2.7 or newer.
* [Rails](https://rubyonrails.org/) 6 or newer.
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
The following configuration settings are required for authorization:
 - policy_id
 - tenant_id
 - authorizer_api_key
 - policy_root

These settings can be retrieved from the [Policy Settings](https://console.aserto.com/ui/policies) page of your Aserto account.

Optional parameters:

| Parameter name | Default value | Description |
| -------------- | ------------- | ----------- |
| service_url | `"authorizer.prod.aserto.com:8443"` | Sets the URL for the authorizer endpoint. |
| decision | `"allowed"` | The decision that will be used when executing an authorizer request. |
| logger | `STDOUT` | The logger to be used. |
| identity_mapping | `{ type: :none }` | The strategy for retrieveing the identity, possible values: `:jwt, :sub, :none` |

## Identity
To determine the identity of the user, the gem can be configured to use a JWT token or a claim using the `identity_mapping` config.
```ruby
# configure the gem to use a JWT token form the `my-auth-header` header.
config.identity_mapping = {
  type: :jwt,
  from: "my-auth-header",
}
```
```ruby
# configure the gem to use a claim from the JWT token.
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
By default, when computing the policy path:
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
A resource can be any structured data that the authorization policy uses to evaluate decisions. By default, gem do not include a resource in authorization calls.

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
require "aserto/rails"

Aserto.configure do |config|
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

The `aserto_authorize!` method in the controller will raise an exception if the user is not able to perform the given action.

```ruby
def show
  aserto_authorize!
  @post = Post.find(params[:id])
end
```

Setting this for every action can be tedious, therefore the `aserto_authorize_resource` method is provided to
automatically authorize all actions in a RESTful style resource controller.
It will use a before action to load the resource into an instance variable and authorize it for every action.

```ruby
class PostsController < ApplicationController
  aserto_authorize_resource
  # aserto_authorize_resource only: %i[show]
  # aserto_authorize_resource except: %i[index]

  def show
    # getting a single post authorized
  end

  def index
    # getting all posts is authorized
  end
end
```

## Check Permissions

The current user's permissions can then be checked using the `allowed?`, `visible?` and `enabled?` methods in views and controllers.

```erb
<% if allowed? :get, "/posts/:id", @post %>
  <%= link_to "View", @post %>
<% end %>
```

## Development
Prerequisites:

    - go >= 1.17 to run mage
    - Ruby >= 2.7.0 to run the code


 Run `bundle install` to install dependencies. Then, run `bundle exec rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.


aserto-rails uses [appraisals](https://github.com/thoughtbot/appraisal) to test the code base against multiple versions
of Rails, as well as the different model adapters.

When first developing, you need to run `bundle exec appraisal install`, to install the different sets.

You can then run all appraisal files (like CI does), with `bundle exec appraisal rake spec` or just run a specific set `bundle exec appraisal rails_7.0.0 rake spec`.

If you'd like to run a specific set of tests within a specific file or folder you can use `SPEC=path/to/file/or/folder bundle exec appraisal rails_7.0.0 rake spec rake`.

Eg: `SPEC=spec/aserto/rails/controller_additions_spec.rb:31 bundle exec appraisal rails_7.0.0 rake spec rake`

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/aserto-dev/aserto-rails. This project is intended to be a safe, welcoming space for collaboration.

## License

The gem is available as open source under the terms of the [Apache-2.0 License](https://www.apache.org/licenses/LICENSE-2.0).
