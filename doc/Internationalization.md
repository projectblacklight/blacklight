Blacklight uses the [Rails i18n framework|http://guides.rubyonrails.org/i18n.html] to provide a translatable (or, application customized) version of most text in the Blacklight default templates. Blacklight ships with a set of English translations (other languages welcome!) in [blacklight.en.yml|https://github.com/projectblacklight/blacklight/blob/master/config/locales/blacklight.en.yml].

You can also customize the English strings in your local application, which will override the Blacklight-distributed strings.

## A quick i18n example
A locale entry that looks like this:

```yaml
en:
  blacklight:
    application_name: 'Blacklight'
```

Is referenced in the Blacklight code as:

```ruby
I18n.t 'blacklight.application_name'
# OR
t('blacklight.application_name')
```

You could override this in your application's ```config/locales/en.yml```:

```yaml
en:
  blacklight:
    application_name: 'My Blacklight Application'
```

And then everywhere Blacklight views show the application name, it will use your label ("My Blacklight Application") instead of ours ("Blacklight").

There are other i18n tricks (that we use) covered in the [Rails i18n Rails guide|http://guides.rubyonrails.org/i18n.html], including pluralization, interpolation, etc.
