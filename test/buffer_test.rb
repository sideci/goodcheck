require "test_helper"

class BufferTest < Minitest::Test
  Buffer = Goodcheck::Buffer

  CONTENT = <<-EOF
Lorem
ipsum
吾輩は猫である。
🍔
🐈
  EOF

  def assert_string_range(string, expected, actual)
    assert_equal expected, actual
    assert_equal string.byteslice(expected), string.byteslice(actual)
  end

  def test_line_ranges
    buffer = Buffer.new(path: Pathname("a.txt"), content: CONTENT)

    assert_equal 6, buffer.line_ranges.size
    assert_string_range CONTENT, 0..5, buffer.line_ranges[0]
    assert_string_range CONTENT, 6..11, buffer.line_ranges[1]
    assert_string_range CONTENT, 12..36, buffer.line_ranges[2]
    assert_string_range CONTENT, 37..41, buffer.line_ranges[3]
    assert_string_range CONTENT, 42..46, buffer.line_ranges[4]
    assert_string_range CONTENT, 47..47, buffer.line_ranges[5]
  end

  def test_location_for_position
    buffer = Buffer.new(path: Pathname("a.txt"), content: CONTENT)

    assert_equal [1, 1], buffer.location_for_position(0)
    assert_equal [1, 2], buffer.location_for_position(1)
    assert_equal [1, 5], buffer.location_for_position(4)
    assert_equal [1, 6], buffer.location_for_position(5)
    assert_equal [2, 1], buffer.location_for_position(6)
    assert_equal [3, 1], buffer.location_for_position(12)
    assert_equal [4, 1], buffer.location_for_position(37)
    assert_equal [5, 1], buffer.location_for_position(42)
    assert_equal [6, 1], buffer.location_for_position(47)
    assert_nil buffer.location_for_position(120)
  end

  def test_disabled_line
    buffer = Buffer.new(path: Pathname("a.txt"), content: <<-EOF
    Lorem
    ipsum # goodcheck-disable-line
    吾輩は猫である。
    # goodcheck-disable-next-line
    🍔
    🐈
      EOF
    )

    assert_equal false, buffer.line_disabled?(1)
    assert_equal true, buffer.line_disabled?(2)
    assert_equal false, buffer.line_disabled?(3)
    assert_equal false, buffer.line_disabled?(4)
    assert_equal true, buffer.line_disabled?(5)
    assert_equal false, buffer.line_disabled?(6)
    assert_equal false, buffer.line_disabled?(7)
  end

  def test_disabled_line_js
    buffer = Buffer.new(path: Pathname("a.js"), content: <<-EOF
    Lorem
    ipsum // goodcheck-disable-line
    吾輩は猫である。
    // goodcheck-disable-next-line
    🍔
    🐈
      EOF
    )

    assert_equal false, buffer.line_disabled?(1)
    assert_equal true, buffer.line_disabled?(2)
    assert_equal false, buffer.line_disabled?(3)
    assert_equal false, buffer.line_disabled?(4)
    assert_equal true, buffer.line_disabled?(5)
    assert_equal false, buffer.line_disabled?(6)
    assert_equal false, buffer.line_disabled?(7)
  end

  def test_disabled_line_md
    buffer = Buffer.new(path: Pathname("a.md"), content: <<-EOF
    Lorem
    ipsum <!-- goodcheck-disable-line -->
    吾輩は猫である。
    <!-- goodcheck-disable-next-line -->
    🍔
    🐈
      EOF
    )

    assert_equal false, buffer.line_disabled?(1)
    assert_equal true, buffer.line_disabled?(2)
    assert_equal false, buffer.line_disabled?(3)
    assert_equal false, buffer.line_disabled?(4)
    assert_equal true, buffer.line_disabled?(5)
    assert_equal false, buffer.line_disabled?(6)
    assert_equal false, buffer.line_disabled?(7)
  end

  def test_disabled_line_css
    buffer = Buffer.new(path: Pathname("a.css"), content: <<-EOF
    .lorem {
      font-size: 1.2rem; /* goodcheck-disable-line */
    }
    .ipsum {
      /* goodcheck-disable-next-line */
      font-size: 1.5rem;
      font-weight: bold;
    }
      EOF
    )

    assert_equal false, buffer.line_disabled?(1)
    assert_equal true, buffer.line_disabled?(2)
    assert_equal false, buffer.line_disabled?(3)
    assert_equal false, buffer.line_disabled?(4)
    assert_equal false, buffer.line_disabled?(5)
    assert_equal true, buffer.line_disabled?(6)
    assert_equal false, buffer.line_disabled?(7)
    assert_equal false, buffer.line_disabled?(8)
  end

  def test_disabled_line_jsx
    buffer = Buffer.new(path: Pathname("a.jsx"), content: <<-EOF
    <div>
      <p>Lorem ipsum</p> {/* goodcheck-disable-line */}
      {/* goodcheck-disable-next-line */}
      <div>🍔</div>
      <div>🚒</div>
      {  /* goodcheck-disable-next-line */  }
      <div>🚓</div>
      <div>🚂</div>
      <div>🚃</div> {	/* goodcheck-disable-line */	}
    </div>
      EOF
    )

    assert_equal false, buffer.line_disabled?(1)
    assert_equal true, buffer.line_disabled?(2)
    assert_equal false, buffer.line_disabled?(3)
    assert_equal true, buffer.line_disabled?(4)
    assert_equal false, buffer.line_disabled?(5)
    assert_equal false, buffer.line_disabled?(6)
    assert_equal true, buffer.line_disabled?(7)
    assert_equal false, buffer.line_disabled?(8)
    assert_equal true, buffer.line_disabled?(9)
  end
end

