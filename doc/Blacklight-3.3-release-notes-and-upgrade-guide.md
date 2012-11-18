Issues: https://github.com/projectblacklight/blacklight/issues?milestone=2&state=open

## Upgrade notes:

Note: Please make sure to upgrade to at least Blacklight **3.3.1** to avoid problems with compiled assets in 3.3.0. 

If you previously ran the blacklight 3.3.0 generator, after upgrading to 3.3.1: Edit your local `./app/assets/stylesheets/blacklight_themes/standard.css.scss` file, change the line (wrong) `@import 'blacklight/grids/susy';` to instead be (right) `@import 'blacklight/grids/susy_grid';`

If you previously ran the blacklight 3.2.x or 3.3.0 generator, look in your local `./config/application.rb`, *remove* the line `config.sass.line_comments = Rails.env.development?` if present. 

### Compass/susy upgrade

[Compass](https://github.com/chriseppstein/compass) (our CSS framework) and [Susy](http://susy.oddbird.net/) have been updated to a new major release. This will necessitate some changes in installations already running BL 3.2.

New installations should just use the generator as normal.

Existing installations should do the following:

**1.** In your gemfile, in `group :assets`, remove any reference to the compass gem, and add:

    gem 'sass-rails', '~> 3.2.0'
    gem 'compass-rails', '~> 1.0.0'
    gem 'compass-susy-plugin', '~> 0.9.0'

**2.** You can remove 'config/initializers/sass.rb'

**3.** You must add, if you have not already: 'config/compass.rb'
 
    require 'susy'
    project_type = :rails

**4.** Replace any references in your css:

`@import "blacklight/grids/susy_framework"` with `@import "susy"`
 
`@import "blacklight/grids/susy"` with `@import "blacklight/grids/susy_grid"` 

