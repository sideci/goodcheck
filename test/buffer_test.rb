require_relative "test_helper"

class BufferTest < Minitest::Test
  Buffer = Goodcheck::Buffer

  CONTENT = <<-EOF
Lorem
ipsum
吾輩は猫である。
🍔
🐈
  EOF

  def test_line_starts
    buffer = Buffer.new(path: Pathname("a.txt"), content: CONTENT)

    assert_equal 0..6, buffer.line_starts[0]
    assert_equal 6..12, buffer.line_starts[1]
    assert_equal 12..37, buffer.line_starts[2]
    assert_equal 37..42, buffer.line_starts[3]
    assert_equal 42..47, buffer.line_starts[4]
    assert_nil buffer.line_starts[6]
  end

  def test_location_for_position
    buffer = Buffer.new(path: Pathname("a.txt"), content: CONTENT)

    assert_equal [1, 0], buffer.location_for_position(0)
    assert_equal [1, 1], buffer.location_for_position(1)
    assert_equal [1, 5], buffer.location_for_position(5)
    assert_equal [2, 0], buffer.location_for_position(6)
    assert_equal [3, 0], buffer.location_for_position(12)
    assert_nil buffer.location_for_position(120)
  end

  def test_position_for_location
    buffer = Buffer.new(path: Pathname("a.txt"), content: CONTENT)

    assert_equal 0, buffer.position_for_location(1, 0)
    assert_equal 1, buffer.position_for_location(1, 1)
    assert_equal 5, buffer.position_for_location(1, 5)
    assert_equal 6, buffer.position_for_location(2, 0)
    assert_nil buffer.position_for_location(100, 0)
  end
end
