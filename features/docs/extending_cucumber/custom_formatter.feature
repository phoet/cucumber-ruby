Feature: Custom Formatter

  Background:
    Given a file named "features/f.feature" with:
      """
      Feature: I'll use my own
        Scenario: Just print me
          Given this step passes
      """
    And the standard step definitions

  Scenario: Subscribe to result events

    This is the recommended way to format output.

    Given a file named "features/support/custom_formatter.rb" with:
      """
      module MyCustom
        class Formatter
          def initialize(config)
            @io = config.out_stream
            config.on_event :test_case_starting do |event|
              print_test_case_name(event.test_case)
            end
          end

          def print_test_case_name(test_case)
            feature = test_case.source.first
            scenario = test_case.source.last
            @io.puts feature.short_name.upcase
            @io.puts "  #{scenario.name.upcase}"
          end
        end
      end
      """
    When I run `cucumber features/f.feature --format MyCustom::Formatter`
    Then it should pass with exactly:
      """
      I'LL USE MY OWN
        JUST PRINT ME

      """

  Scenario: Custom config
    Given a file named "features/support/custom_formatter.rb" with:
      """
      module MyCustom
        class Formatter
          def initialize(config, options={})
            config.on_event Cucumber::Events::FinishedRunningTests do |event|
              puts options.inspect
            end
          end
        end
      end
      """
    When I run `cucumber features/f.feature --format MyCustom::Formatter,foo=bar,one=two`
    Then it should pass with exactly:
      """
      { "foo": "bar", "one": "two" }
      """

  Scenario: Support legacy --out
    Given a file named "features/support/custom_formatter.rb" with:
      """
      module MyCustom
        class Formatter
          def initialize(config, options={})
            config.on_event Cucumber::Events::FinishedRunningTests do |event|
              puts options["out"]
            end
          end
        end
      end
      """
    When I run `cucumber features/f.feature --format MyCustom::Formatter --out foo/bar.file`
    Then it should pass with exactly:
      """
      Deprecated: Please don't use --out, but pass the formatter options like this intead:

        --format junit,out=path/to/output

      foo/bar.file
      """

  Scenario: Implement v2.0 formatter methods
    Note that this method is likely to be deprecated in favour of events - see above.

    Given a file named "features/support/custom_formatter.rb" with:
      """
      module MyCustom
        class Formatter
          def initialize(config)
            @io = config.out_stream
          end

          def before_test_case(test_case)
            feature = test_case.source.first
            scenario = test_case.source.last
            @io.puts feature.short_name.upcase
            @io.puts "  #{scenario.name.upcase}"
          end
        end
      end
      """
    When I run `cucumber features/f.feature --format MyCustom::Formatter`
    Then it should pass with exactly:
      """
      I'LL USE MY OWN
        JUST PRINT ME

      """

  Scenario: Use the legacy API
    This is deprecated and should no longer be used.

    Given a file named "features/support/custom_legacy_formatter.rb" with:
      """
      module MyCustom
        class LegacyFormatter
          def initialize(runtime, io, options)
            @io = io
          end

          def before_feature(feature)
            @io.puts feature.short_name.upcase
          end

          def scenario_name(keyword, name, file_colon_line, source_indent)
            @io.puts "  #{name.upcase}"
          end
        end
      end
      """
    When I run `cucumber features/f.feature --format MyCustom::LegacyFormatter`
    Then it should pass with exactly:
      """
      I'LL USE MY OWN
        JUST PRINT ME

      """

  Scenario: Use both old and new
    You can both APIs at once, for now

    Given a file named "features/support/custom_mixed_formatter.rb" with:
      """
      module MyCustom
        class MixedFormatter

          def initialize(runtime, io, options)
            @io = io
          end

          def before_test_case(test_case)
            feature = test_case.source.first
            @io.puts feature.short_name.upcase
          end

          def scenario_name(keyword, name, file_colon_line, source_indent)
            @io.puts "  #{name.upcase}"
          end
        end
      end
      """
    When I run `cucumber features/f.feature --format MyCustom::MixedFormatter`
    Then it should pass with exactly:
      """
      I'LL USE MY OWN
        JUST PRINT ME

      """
