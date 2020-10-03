require "test_helper"

class PatternTest < Minitest::Test
  Token = Goodcheck::Pattern::Token
  Literal = Goodcheck::Pattern::Literal
  Regexp = Goodcheck::Pattern::Regexp

  def test_tokenize
    regexp = Token.compile_tokens("[NSData alloc]", {}, case_sensitive: true)
    assert_match regexp, "[NSData alloc]"
    assert_match regexp, "NSData *data = [[NSData alloc] init]"
    assert_match regexp, "NSData *data = [[NSData \nalloc] init]"
    refute_match regexp, "[NSData allocwithfoo]"
    refute_match regexp, "[NSDataBuffer Alloc]"
  end

  def test_tokenize2
    regexp = Token.compile_tokens("ASCII-8BIT", {}, case_sensitive: true)
    assert_match regexp, "encode('ASCII-8BIT')"
    refute_match regexp, "FASCII-8BITS"
  end

  def test_tokenize3
    regexp = Token.compile_tokens("<br/>", {}, case_sensitive: true)
    assert_match regexp, "Hello World<br />"
    assert_match regexp, "Hello World <br/ >"
    refute_match regexp, "Hello World <br >"
  end

  def test_tokenize4
    regexp = Token.compile_tokens("沖縄Ruby会議", {}, case_sensitive: true)
    assert_match regexp, "沖縄Ruby会議"
    assert_match regexp, "沖縄 Ruby 会議"
    refute_match regexp, "沖 縄Ruby会議"
  end

  def test_tokenize5
    regexp = Token.compile_tokens("each", {}, case_sensitive: true)
    assert_match regexp, "each()"
    assert_match regexp, "foo.each()"
    refute_match regexp, "foreach"
    refute_match regexp, "test_each_icon"
  end

  def test_tokenize6
    regexp = Token.compile_tokens("each", {}, case_sensitive: false)
    assert_match regexp, "EACH()"
    assert_match regexp, "foo.Each()"
    refute_match regexp, "FOReaCH"
    refute_match regexp, "test_each_icon"
  end

  def test_tokenize_variable_string
    regexp = Token.compile_tokens("${color:string}",
                                  { color: Token::VarPattern.empty },
                                  case_sensitive: true)

    regexp.match('"hello \\" \\\' world"').tap do |match|
      assert match
      assert_equal "hello \\\" \\' world", match[:color]
    end
  end

  def test_tokenize_variable_int
    regexp = Token.compile_tokens("${color:int}", { color: Token::VarPattern.empty }, case_sensitive: true)

    regexp.match('123').tap do |match|
      assert match
      assert_equal "123", match[:color]
    end

    regexp.match('1_2_3').tap do |match|
      assert match
      assert_equal "1_2_3", match[:color]
    end

    regexp.match('hello world').tap do |match|
      refute match
    end

    regexp.match("0").tap do |match|
      assert match
      assert_equal "0", match[:color]
    end
  end

  def test_tokenize_variable_float
    regexp = Token.compile_tokens("${color:float}", { color: Token::VarPattern.empty }, case_sensitive: true)

    regexp.match('1.23').tap do |match|
      assert match
      assert_equal "1.23", match[:color]
    end

    regexp.match('-1.23').tap do |match|
      assert match
      assert_equal "-1.23", match[:color]
    end

    regexp.match('1e+123').tap do |match|
      assert match
      assert_equal "1e+123", match[:color]
    end
  end

  def test_tokenize_variable_word
    regexp = Token.compile_tokens("${color:word}", { color: Token::VarPattern.empty }, case_sensitive: true)

    regexp.match('白色').tap do |match|
      assert match
      assert_equal "白色", match[:color]
    end

    regexp.match('black&white').tap do |match|
      assert match
      assert_equal "black&white", match[:color]
    end

    regexp.match('dark yellow').tap do |match|
      assert match
      assert_equal "dark", match[:color]
    end
  end

  def test_tokenize_variable_word2
    Token.compile_tokens("foo ${color:word}", { color: Token::VarPattern.empty }, case_sensitive: true).tap do |regexp|
      assert_equal %r{\bfoo\s+(?-mix:(?<color>\S+))}m, regexp
    end

    Token.compile_tokens("${color:word} foo", { color: Token::VarPattern.empty }, case_sensitive: true).tap do |regexp|
      assert_equal %r{(?-mix:(?<color>\S+))\s+foo\b}m, regexp
    end
  end

  def test_tokenize_variable_identifier
    regexp = Token.compile_tokens("${color:identifier}", { color: Token::VarPattern.empty }, case_sensitive: true)

    regexp.match('soutaro').tap do |match|
      assert match
      assert_equal "soutaro", match[:color]
    end

    regexp.match('p_ck_').tap do |match|
      assert match
      assert_equal "p_ck_", match[:color]
    end

    regexp.match('__gfx__').tap do |match|
      assert match
      assert_equal "__gfx__", match[:color]
    end
  end

  def test_tokenize_variable_url
    regexp = Token.compile_tokens("${color:url}", { color: Token::VarPattern.empty }, case_sensitive: true)

    regexp.match('[rails_autolink](https://github.com/tenderlove/rails_autolink)').tap do |match|
      assert match
      assert_equal "https://github.com/tenderlove/rails_autolink", match[:color]
    end
  end

  def test_tokenize_variable_email
    regexp = Token.compile_tokens("${color:email}", { color: Token::VarPattern.empty }, case_sensitive: true)

    regexp.match('Soutaro <matsumoto@soutaro.com>').tap do |match|
      assert match
      assert_equal "matsumoto@soutaro.com", match[:color]
    end
  end

  def test_tokenize_variable_no_variable
    regexp = Token.compile_tokens("${color}", { }, case_sensitive: true)

    assert_match regexp, "${ color }"
  end

  def test_literal
    pattern = Literal.new(source: "hello.world", case_sensitive: false)
    assert_equal "hello.world", pattern.source
    assert_equal %r(hello\.world)i, pattern.regexp
  end

  def test_regexp
    pattern = Regexp.new(source: "hello.world", case_sensitive: false, multiline: true)
    assert_equal "hello.world", pattern.source
    assert_equal %r(hello.world)im, pattern.regexp
  end

  def test_tokens
    pattern = Token.new(source: "hello.world", variables: {}, case_sensitive: true)
    assert_equal "hello.world", pattern.source
    assert_equal %r(\bhello\s*\.\s*world\b)m, pattern.regexp
  end

  def test_tokens_var
    pattern = Token.new(source: "bgcolor=${color:string}", variables: { color: Token::VarPattern.empty }, case_sensitive: true)

    assert_match pattern.regexp, "bgcolor='white'"
    assert_match pattern.regexp, 'bgcolor="pink"'
    refute_match pattern.regexp, 'bgcolor={gray}'
  end

  def test_tokens_no_type_word
    pattern = Token.new(source: "margin: ${size}px;", variables: { size: Token::VarPattern.empty }, case_sensitive: true)

    pattern.regexp.match("div { margin: 120px; }").tap do |match|
      assert match
      assert_equal "120", match[:size]
    end

    pattern.regexp.match("div { margin: <%= size %>px; }").tap do |match|
      assert match
      assert_equal "<%= size %>", match[:size]
    end

    pattern.regexp.match("div { margin: <%= pic.size %>px; }").tap do |match|
      assert match
      assert_equal "<%= pic.size %>", match[:size]
    end
  end

  def test_tokens_no_type_word_head
    pattern = Token.new(source: "${size}px;", variables: { size: Token::VarPattern.empty }, case_sensitive: true)

    pattern.regexp.match("div { margin: 120px; }").tap do |match|
      assert match
      # This should be different from what the user wants.
      assert_equal "div { margin: 120", match[:size]
    end
  end

  def test_tokens_no_type_word_tail
    pattern = Token.new(source: "background-color: ${color}", variables: { color: Token::VarPattern.empty }, case_sensitive: true)

    pattern.regexp.match("div { background-color: pink; margin-left: 20px; }").tap do |match|
      assert match
      # This should be different from what the user wants.
      assert_equal "pink; margin-left: 20px; }", match[:color]
    end
  end

  def test_tokens_no_type_paren
    pattern = Token.new(source: "bgcolor={${color}}", variables: { color: Token::VarPattern.empty }, case_sensitive: true)

    pattern.regexp.match("<tag bgcolor={color(pink, red)}>Hello world</tag>").tap do |match|
      assert match
      assert_equal "color(pink, red)", match[:color]
    end
    pattern.regexp.match("<tag bgcolor='white'>Hello world</tag>").tap do |match|
      refute match
    end
    pattern.regexp.match("<tag bgcolor={ { blue: 123, green: 234, red: 13 } }>Hello world</tag>").tap do |match|
      assert match
      assert_equal " { blue: 123, green: 234, red: 13 } ", match[:color]
    end
    pattern.regexp.match("<tag bgcolor={ { blue: 123, green: { hello: world() }, red: 13 } }>Hello world</tag>").tap do |match|
      assert match
      assert_equal " { blue: 123, green: { hello: world() }, red: 13 } ", match[:color]
    end
    pattern.regexp.match("<tag bgcolor={ 0{1{2{3{4{5{6}5}4}3}2}1}0 }>Hello world</tag>").tap do |match|
      assert match
      assert_equal " 0{1{2{3{4{5{6}5}4}3}2}1", match[:color]
    end
  end

  def test_var_pattern
    Token::VarPattern.new(patterns: [], negated: false).tap do |pat|
      assert pat.test("any string is okay")
    end

    Token::VarPattern.new(patterns: ["hello", "world"], negated: false).tap do |pat|
      pat.type = :string
      assert pat.test("hello")
      assert pat.test("world")
      refute pat.test("lorem")
    end

    Token::VarPattern.new(patterns: [455], negated: false).tap do |pat|
      pat.type = :number
      assert pat.test("455")
      refute pat.test("123")
    end

    Token::VarPattern.new(patterns: [/\A4./], negated: false).tap do |pat|
      pat.type = :number
      assert pat.test("455")
      refute pat.test("123")
    end
  end
end
