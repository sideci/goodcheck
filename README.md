![Goodcheck logo](logo/GoodCheck%20Horizontal.png)

# Goodcheck - Regexp based customizable linter

Are you reviewing a pull request if the change contains deprecated API calls?
Do you want to post a comment to ask the developer if a method call satisfies some condition for use without causing an issue?
What if a misspelling like `Github` for `GitHub` can be found automatically?

Give Goodcheck a try to do them instead of you! 🎉

Goodcheck is a customizable linter. You can define pairs of patterns and messages.
It checks your program and when it detects a piece of text matching with the defined patterns, it prints your message which tells your teammates why it should be revised and how.
Some part of the code reviewing process can be automated.
With Goodcheck the only thing you have to do is define the rules, pairing patterns with messages, and then those same patterns won’t bother you anymore. 😆

## Getting started

Goodcheck is provided as a Ruby gem. To install it, run:

```console
$ gem install goodcheck
```

Check out the [documentation](docusaurus/docs/getstarted.md) for more details.

## Development

After checking out the repository, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

To release a new version, follows the steps below:

1. Update the version number in [`version.rb`](lib/goodcheck/version.rb).
2. Add the new version's entry to the [changelog](CHANGELOG.md).
3. Update the documentation via `bundle exec rake docs:update_version`.
4. Commit the above changes like `git commit -m 'Version 1.2.3'`.
5. Run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).
6. Publish the updated documentation like `GIT_USER=some_user USE_SSH=true bundle exec rake docs:publish`.

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/sider/goodcheck).
