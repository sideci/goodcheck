require "test_helper"

class AnalyzerTest < Minitest::Test
  Analyzer = Goodcheck::Analyzer
  Issue = Goodcheck::Issue
  Buffer = Goodcheck::Buffer
  Rule = Goodcheck::Rule
  Pattern = Goodcheck::Pattern
  Location = Goodcheck::Location
  Trigger = Goodcheck::Trigger

  def buffer
    @buffer = Buffer.new(path: Pathname("foo.txt"), content: <<-EOF)
Lorem
ipsum
吾輩は猫である。
🍔
🐈
NSArray *a = [ NSMutableArray
               new ];
    EOF
  end

  def with_buffer(content, path: Pathname("foo.txt"))
    yield Buffer.new(path: path, content: content)
  end

  def new_rule(id:, message: "hello")
    Rule.new(id: id, message: message, triggers: [], justifications: [])
  end

  def new_trigger(negated: false, &block)
    Trigger.new(patterns: [], globs: [], passes: [], fails: [], negated: negated).tap(&block)
  end

  def test_analyzer
    analyzer = Analyzer.new(
      buffer: buffer,
      rule: new_rule(id: "rule1"),
      trigger: new_trigger {|trigger|
        trigger.patterns << Pattern::Literal.new(source: "ipsum", case_sensitive: true)
      }
    )

    issues = analyzer.scan.to_a

    assert_equal ["rule1"], issues.map(&:rule).map(&:id)
    assert_equal ["ipsum"], issues.map(&:text)
    assert_equal [Location.new(start_line: 2, start_column: 0, end_line: 2, end_column: 5)], issues.map(&:location)
  end

  def test_analyzer_japanese
    analyzer = Analyzer.new(
      buffer: buffer,
      rule: new_rule(id: "rule1"),
      trigger: new_trigger {|trigger|
        trigger.patterns << Pattern::Literal.new(source: "吾輩", case_sensitive: true)
      }
    )

    issues = analyzer.scan.to_a

    assert_equal ["rule1"], issues.map(&:rule).map(&:id)
    assert_equal ["吾輩"], issues.map(&:text)
    assert_equal [Location.new(start_line: 3, start_column: 0, end_line: 3, end_column: 6)], issues.map(&:location)
  end

  def test_analyzer_tokens
    analyzer = Analyzer.new(
      buffer: buffer,
      rule: new_rule(id: "rule1"),
      trigger: new_trigger {|trigger|
        trigger.patterns << Pattern::Token.new(source: "[NSMutableArray new]",
                                               variables: {},
                                               case_sensitive: true)
      }
    )

    issues = analyzer.scan.to_a

    assert_equal ["rule1"], issues.map(&:rule).map(&:id)
    assert_equal ["[ NSMutableArray
               new ]"], issues.map(&:text)
    assert_equal [Location.new(start_line: 6, start_column: 13, end_line: 7, end_column: 20)], issues.map(&:location)
  end

  def test_analyzer_tokens_var
    buffer = Buffer.new(path: Pathname("foo.txt"), content: <<-EOF)
div {
  background-color: white;
}

div {
  background-color: $pallet.secondary;
}
    EOF
    analyzer = Analyzer.new(
      buffer: buffer,
      rule: new_rule(id: "rule1"),
      trigger: new_trigger {|trigger|
        trigger.patterns << Pattern::Token.new(
          source: "background-color: ${color:word};",
          variables: {
            color: Pattern::Token::VarPattern.new(
              patterns: [
                "$pallet.main",
                "$pallet.secondary"
              ],
              negated: true
            )
          },
          case_sensitive: true
        )
      }
    )

    issues = analyzer.scan.to_a

    assert_equal ["rule1"], issues.map(&:rule).map(&:id)
    assert_equal ["background-color: white;"], issues.map(&:text)
    assert_equal [Location.new(start_line: 2, start_column: 2, end_line: 2, end_column: 26)], issues.map(&:location)
  end

  def test_analyzer_tokens_var2
    buffer = Buffer.new(path: Pathname("foo.txt"), content: <<-EOF)
div.icon {
  margin-top: 30px;
}

div.title {
  margin-top: $space-big;
}
    EOF
    analyzer = Analyzer.new(
      buffer: buffer,
      rule: new_rule(id: "rule1"),
      trigger: new_trigger {|trigger|
        trigger.patterns << Pattern::Token.new(
          source: "margin-top: ${size:int}px;",
          variables: {
            size: Pattern::Token::VarPattern.new(
              patterns: [],
              negated: false
            )
          },
          case_sensitive: true
        )
      }
    )

    issues = analyzer.scan.to_a

    assert_equal ["rule1"], issues.map(&:rule).map(&:id)
    assert_equal ["margin-top: 30px;"], issues.map(&:text)
    assert_equal [Location.new(start_line: 2, start_column: 2, end_line: 2, end_column: 19)], issues.map(&:location)
  end

  def test_analyzer_tokens_var3
    buffer = Buffer.new(path: Pathname("foo.txt"), content: <<-EOF)
@charset "euc-jp";
    EOF
    analyzer = Analyzer.new(
      buffer: buffer,
      rule: new_rule(id: "rule1"),
      trigger: new_trigger(negated: true) {|trigger|
        trigger.patterns << Pattern::Token.new(
          source: "@charset ${set:string};",
          variables: {
            size: Pattern::Token::VarPattern.new(
              patterns: [/utf-8/i],
              negated: false
            )
          },
          case_sensitive: true
        )
      }
    )

    issues = analyzer.scan.to_a

    assert_equal ["rule1"], issues.map(&:rule).map(&:id)
    assert_equal [nil], issues.map(&:text)
    assert_equal [nil], issues.map(&:location)
  end

  def test_analyzer_no_duplicate
    analyzer = Analyzer.new(
      buffer: buffer,
      rule: new_rule(id: "rule1"),
      trigger: new_trigger {|trigger|
        trigger.patterns << Pattern::Regexp.new(source: "N.Array", case_sensitive: false, multiline: false)
        trigger.patterns << Pattern::Regexp.new(source: "NSAr.ay", case_sensitive: false, multiline: false)
      }
    )

    issues = analyzer.scan.to_a

    assert_equal ["rule1"], issues.map(&:rule).map(&:id)
    assert_equal ["NSArray"], issues.map(&:text)
    assert_equal [Location.new(start_line: 6, start_column: 0, end_line: 6, end_column: 7)], issues.map(&:location)
  end

  def test_analyzer_token_word_brake
    analyzer = Analyzer.new(
      buffer: buffer,
      rule: new_rule(id: "rule1"),
      trigger: new_trigger {|trigger|
        trigger.patterns << Pattern::Token.new(source: "Array", variables: {}, case_sensitive: true)
      }
    )

    issues = analyzer.scan.to_a
    assert_empty issues
  end

  def test_analyzer_token_word_brake2
    with_buffer(<<-CONTENT) do |buffer|
test1
test
atest
      CONTENT
      analyzer = Analyzer.new(
        buffer: buffer,
        rule: new_rule(id: "rule1"),
        trigger: new_trigger {|trigger|
          trigger.patterns << Pattern::Regexp.new(source: '(\btest\b|foo)', case_sensitive: false, multiline: false)
        }
      )

      assert_equal 1, analyzer.scan.count
    end
  end

  def test_analyzer_empty_pattern
    with_buffer(<<-CONTENT, path: Pathname("foo.txt")) do |buffer|
test1
test
atest
    CONTENT
      analyzer = Analyzer.new(
        buffer: buffer,
        rule: new_rule(id: "rule1"),
        trigger: new_trigger {|trigger|
          trigger.globs << Goodcheck::Glob.new(pattern: "*.txt", encoding: nil, exclude: nil)
        }
      )

      issues = analyzer.scan.to_a

      assert_equal 1, issues.size
      assert_nil issues[0].range
      assert_nil issues[0].text
    end
  end
end
