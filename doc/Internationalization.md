Blacklight uses the [Rails i18n framework](http://guides.rubyonrails.org/i18n.html) to provide multilingual version of most text in the Blacklight default templates. Blacklight ships with a set of English and French translations in [config/locales](https://github.com/projectblacklight/blacklight/blob/master/config/locales/).

In addition to multilingual support, developments can also e.g. customize the English strings in Blacklight-based applications, which provides a way to change text without overriding templates and partials.

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
