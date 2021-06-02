require "test_helper"

class UnarchiverTest < Minitest::Test
  Unarchiver = Goodcheck::Unarchiver

  SAMPLE_FILE = Pathname(__dir__) / "fixtures" / "goodcheck-test-rules.tar.gz"

  def test_tar_gz?
    subject = Unarchiver.new

    assert subject.tar_gz?("a.tar.gz")
    assert subject.tar_gz?("a/b.tar.gz")
    assert subject.tar_gz?(Pathname("a/b.tar.gz"))

    refute subject.tar_gz?("a.gz")
    refute subject.tar_gz?(".tar.gz")
    refute subject.tar_gz?("a.tar.gz2")
  end

  def test_tar_gz
    block_args = []
    Unarchiver.new.tar_gz(SAMPLE_FILE.read) do |content, filename|
      block_args << [content, filename]
    end

    assert_equal ["rules/a.yml", "rules/goodcheck.yml", "rules/foo.txt", "rules/sub/b.yaml"], block_args.map(&:last)
    assert_match "- id: rule.a", block_args[0][0]
    assert_match "- id: rule.b", block_args[3][0]
  end

  def test_tar_gz_with_filter
    subject = Unarchiver.new(file_filter: ->(filename) { filename.end_with?(".yaml") })

    filenames = []
    subject.tar_gz(SAMPLE_FILE.read) do |_content, filename|
      filenames << filename
    end

    assert_equal ["rules/sub/b.yaml"], filenames
  end
end
