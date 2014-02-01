Blacklight does not require user authentication, however, if included, Blacklight can provide additional features for users ([[Bookmarks]], [[Saved Searches]], etc). Because of the wide range of institutional needs and capabilities, Blacklight does not require a specific user authentication provider. 

## Installing with Devise

If you are rolling your own user authentication system, we highly recommend [[Devise|https://github.com/plataformatec/devise]], an extremely flexible authentication solution that is relatively straightforward. For directions to install the Blacklight gem using devise, see the [[Quickstart]].

## Install and Use (with a custom user authentication system)

Create a new rails 3 application
```bash
$ rails new my_app
```

Add blacklight to your gem file 
```bash
edit ./my_app/Gemfile
```
```ruby.
# Append this line to the end of the file:
gem 'blacklight'
```

```bash
$ bundle install
```

If you have a `User` model already, the Blacklight generator will connect to it automatically during installation.  However, you will need to make sure the following named routes are included in your /config/routes.rb file:

```ruby
  match 'your_login',          :to => 'Your User Session Controller # Log in action',       :as => 'new_user_session'
  match 'your_logout',         :to => 'Your User Session Controller # Log Out action',      :as => 'destroy_user_session'
  match 'your_account_page',   :to => 'Your User Session Controller # Account edit action', :as => 'edit_user_registration'
```

One blacklight view partial uses `#to_s` on your user model to get a user-displayable account name/identifier for the currently logged in account, so you probably want to have such a method. 

Finally, you will need to make sure the following methods are available both on controllers and as helpers:

* `current_user`   - Which should return an ActiveRecord-based user object that include Blacklight::User
* `user_session`   - Which are included in your /config/routes.rb file:

Optionally,
* `guest_user` -  Which should return an ActiveRecord-based temporary guest user object available across the current user session.
* `current_or_guest_user` - Which should return the `current_user`, if available, or `guest_user`. If you don't provide this method, a stub method (that just returns `current_user`) will be provided for you.

If you are supporting guest users, if a guest user logs in, you should call `#transfer_guest_user_actions_to_current_user` to move any persisted data to the permanent user.

> The `devise-guests` gem implements the `guest_user`, `current_or_guest_user` and callbacks for Blacklight applications using devise. It may be a useful reference for rolling your own functionality. See [DeviseGuests::Controllers::Helpers](https://github.com/cbeer/devise-guests/blob/master/lib/devise-guests/controllers/helpers.rb)

Once these are in place, you can run the Blacklight Installation Generator:

```bash
$ rails generate blacklight [MODEL NAME]
```
Where model name is the name of your user model.

Execute your migrations, and you should be good to go.
```bash
$ rake db:migrate
```