require_relative "test_helper"

class AnalyzerTest < Minitest::Test
  Analyzer = Goodcheck::Analyzer
  Issue = Goodcheck::Issue
  Buffer = Goodcheck::Buffer
  Rule = Goodcheck::Rule
  Pattern = Goodcheck::Pattern
  Location = Goodcheck::Location

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

  def new_rule(id, *patterns)
    Rule.new(id: id, patterns: patterns, message: "hello", justifications: [], globs: [], passes: [], fails: [])
  end

  def test_analyzer
    rule = new_rule("rule1", Pattern.literal("ipsum", case_sensitive: true))
    analyzer = Analyzer.new(buffer: buffer, rule: rule, rules: [rule])

    issues = analyzer.scan.to_a

    assert_equal ["rule1"], issues.map(&:rule).map(&:id)
    assert_equal ["ipsum"], issues.map(&:text)
    assert_equal [Location.new(start_line: 2, start_column: 0, end_line: 2, end_column: 5)], issues.map(&:location)
  end

  def test_analyzer_japanese
    rule = new_rule("rule1", Pattern.literal("吾輩", case_sensitive: true))
    analyzer = Analyzer.new(buffer: buffer, rule: rule, rules: [rule])

    issues = analyzer.scan.to_a

    assert_equal ["rule1"], issues.map(&:rule).map(&:id)
    assert_equal ["吾輩"], issues.map(&:text)
    assert_equal [Location.new(start_line: 3, start_column: 0, end_line: 3, end_column: 6)], issues.map(&:location)
  end

  def test_analyzer_tokens
    rule = new_rule("rule1", Pattern.token("[NSMutableArray new]", case_sensitive: true))
    analyzer = Analyzer.new(buffer: buffer, rule: rule, rules: [rule])

    issues = analyzer.scan.to_a

    assert_equal ["rule1"], issues.map(&:rule).map(&:id)
    assert_equal ["[ NSMutableArray
               new ]"], issues.map(&:text)
    assert_equal [Location.new(start_line: 6, start_column: 13, end_line: 7, end_column: 20)], issues.map(&:location)
  end

  def test_analyzer_no_duplicate
    rule = new_rule("rule1",
                    Pattern.regexp("N.Array", case_sensitive: false, multiline: false),
                    Pattern.regexp("NSAr.ay", case_sensitive: false, multiline: false))
    analyzer = Analyzer.new(buffer: buffer, rule: rule, rules: [rule])

    issues = analyzer.scan.to_a

    assert_equal ['rule1'], issues.map(&:rule).map(&:id)
    assert_equal ["NSArray"], issues.map(&:text)
    assert_equal [Location.new(start_line: 6, start_column: 0, end_line: 6, end_column: 7)], issues.map(&:location)
  end

  def test_analyzer_token_word_brake
    rule = new_rule("rule1", Pattern.token("Array", case_sensitive: true))
    analyzer = Analyzer.new(buffer: buffer, rule: rule, rules: [rule])

    issues = analyzer.scan.to_a
    assert_empty issues
  end
end
