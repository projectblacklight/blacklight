After [[CODEBASE-325|http://jira.projectblacklight.org/jira/browse/CODEBASE-325]] is implemented, Blacklight does not require user authentication, however, if included, Blacklight can provide additional features for users ([[Bookmarks]], [[Saved Searches]], etc). Because of the wide range of institutional needs and capabilities, Blacklight does not require a specific user authentication provider.

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
gem 'blackight'
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

* `current_user`   - Which should return a user object that include Blacklight::User
* `user_session`   - Which are included in your /config/routes.rb file:

Once these are in place, you can run the Blacklight Installation Generator:

```bash
$ rails generate blacklight [MODEL NAME]
```
Where model name is the name of your user model.

Execute your migrations, and you should be good to go.
```bash
$ rake db:migrate
```

If you need to install Solr or the sample data, follow the directions from the see the [[Quickstart]].
