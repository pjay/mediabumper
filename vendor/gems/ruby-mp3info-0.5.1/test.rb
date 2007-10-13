#!/usr/bin/ruby -w

$:.unshift("lib/")

require "test/unit"
require "base64"
require "mp3info"
require "fileutils"
require "tempfile"

class Mp3InfoTest < Test::Unit::TestCase

  TEMP_FILE = File.join(File.dirname($0), "test_mp3info.mp3")
  BASIC_TAG2 = {
    "COMM" => "comments",
    #"TCON" => "genre_s" 
    "TIT2" => "title",
    "TPE1" => "artist",
    "TALB" => "album",
    "TYER" => "year",
    "TRCK" => "tracknum"
  }
  
  # aliasing to allow testing with old versions of Test::Unit
  alias set_up setup 
  alias tear_down teardown

  def setup
    # Command to create a dummy MP3
    # dd if=/dev/zero bs=1024 count=15 | lame --preset cbr 128 -r -s 44.1 --bitwidth 16 - - | ruby -rbase64 -e 'print Base64.encode64($stdin.read)'
    @valid_mp3 = Base64.decode64 <<EOF
//uQZAAAAAAAaQYAAAAAAA0gwAAAAAABpBwAAAAAADSDgAAATEFNRTMuOTNV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVTEFNRTMuOTNVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVV//uSZL6P8AAAaQAAAAAAAA0gAAAAAAABpAAAAAAAADSA
AAAAVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVUxBTUUzLjkzVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVf/7kmT/j/AAAGkAAAAAAAANIAAA
AAAAAaQAAAAAAAA0gAAAAFVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVM
QU1FMy45M1VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVX/+5Jk/4/w
AABpAAAAAAAADSAAAAAAAAGkAAAAAAAANIAAAABVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVTEFNRTMuOTNVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVV//uSZP+P8AAAaQAAAAAAAA0gAAAAAAABpAAAAAAAADSAAAAAVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVQ==
EOF
    @tag = {
      "title" => "title",
      "artist" => "artist",
      "album" => "album",
      "year" => 1921,
      "comments" => "comments",
      "genre" => 0,
      "genre_s" => "Blues",
      "tracknum" => 36
    }
    File.open(TEMP_FILE, "w") { |f| f.write(@valid_mp3) }
  end

  def teardown
    FileUtils.rm_f(TEMP_FILE)
  end


  def test_to_s
    Mp3Info.open(TEMP_FILE) { |info| assert(info.to_s.is_a?(String)) }
  end

  def test_not_an_mp3
    File.open(TEMP_FILE, "w") do |f|
      str = "0"*1024*1024
      f.write(str)
    end
    assert_raises(Mp3InfoError) {
      mp3 = Mp3Info.new(TEMP_FILE)
    }
  end

  def test_is_an_mp3
    assert_nothing_raised {
      Mp3Info.new(TEMP_FILE).close
    }
  end
  
  def test_detected_info
    Mp3Info.open(TEMP_FILE) do |info|
      assert_equal(info.mpeg_version, 1)
      assert_equal(info.layer, 3)
      assert_equal(info.vbr, false)
      assert_equal(info.bitrate, 128)
      assert_equal(info.channel_mode, "JStereo")
      assert_equal(info.samplerate, 44100)
      assert_equal(info.error_protection, false)
      assert_equal(info.length, 0.1305625)
    end
  end
  
  def test_vbr_mp3_length
    temp_file_vbr = File.join(File.dirname($0), "vbr.mp3")

    unless File.exists?(temp_file_vbr)
      tempfile = Tempfile.new("ruby-mp3info_test")
      tempfile.close
      system("dd if=/dev/zero of=#{tempfile.path} bs=1024 count=30000")
      raise "cannot find lame binary in path" unless system("which lame")
      system("lame -h -v -b 112 -r -s 44.1 --bitwidth 16 #{tempfile.path} #{temp_file_vbr}")
      tempfile.close!
    end

    Mp3Info.open(temp_file_vbr) do |info|
      assert(info.vbr)
      assert_equal(1152, info.samples_per_frame)
      assert_in_delta(174.210612, info.length, 0.000001)
    end
  end

  def test_removetag1
    Mp3Info.open(TEMP_FILE) { |info| info.tag1 = @tag }
    assert(Mp3Info.hastag1?(TEMP_FILE))
    Mp3Info.removetag1(TEMP_FILE)
    assert(! Mp3Info.hastag1?(TEMP_FILE))
  end

  def test_writetag1
    Mp3Info.open(TEMP_FILE) { |info| info.tag1 = @tag }
    Mp3Info.open(TEMP_FILE) { |info| assert(info.tag1 == @tag) }
  end

  def test_valid_tag1_1
    tag = [ "title", "artist", "album", "1921", "comments", 36, 0].pack('A30A30A30A4a29CC')
    valid_tag = {
      "title" => "title",
      "artist" => "artist",
      "album" => "album",
      "year" => 1921,
      "comments" => "comments",
      "genre" => "Blues",
      #"version" => "1",
      "tracknum" => 36
    }
    id3_test(tag, valid_tag)
  end
  
  def test_valid_tag1_0
    tag = [ "title", "artist", "album", "1921", "comments", 0].pack('A30A30A30A4A30C')
    valid_tag = {
      "title" => "title",
      "artist" => "artist",
      "album" => "album",
      "year" => 1921,
      "comments" => "comments",
      "genre" => "Blues",
      #"version" => "0"
    }
    id3_test(tag, valid_tag)
  end

  def id3_test(tag_str, valid_tag)
    tag = "TAG" + tag_str
    File.open(TEMP_FILE, "w") do |f|
      f.write(@valid_mp3)
      f.write(tag)
    end
    assert(Mp3Info.hastag1?(TEMP_FILE))
    #info = Mp3Info.new(TEMP_FILE)
    #FIXME validate this test
    #assert_equal(info.tag1, valid_tag)
  end

  def test_removetag2
    w = write_temp_file({"TIT2" => "sdfqdsf"})

    assert( Mp3Info.hastag2?(TEMP_FILE) )
    Mp3Info.removetag2(TEMP_FILE)
    assert( ! Mp3Info.hastag2?(TEMP_FILE) )
  end

  def test_universal_tag
    2.times do 
      tag = {"title" => "title"}
      Mp3Info.open(TEMP_FILE) do |mp3|
	tag.each { |k,v| mp3.tag[k] = v }
      end
      w = Mp3Info.open(TEMP_FILE) { |m| m.tag }
      assert_equal(tag, w)
    end
  end

  def test_id3v2_universal_tag
    tag = {}
    %w{comments title artist album}.each { |k| tag[k] = k }
    tag["tracknum"] = 34
    Mp3Info.open(TEMP_FILE) do |mp3|
      tag.each { |k,v| mp3.tag[k] = v }
    end
    w = Mp3Info.open(TEMP_FILE) { |m| m.tag }
    w.delete("genre")
    w.delete("genre_s")
    assert_equal(tag, w)
#    id3v2_prog_test(tag, w)
  end

  def test_id3v2_version
    written_tag = write_temp_file(BASIC_TAG2)
    assert_equal( "2.3.0", written_tag.version )
  end

  def test_id3v2_methods
    tag = { "TIT2" => "tit2", "TPE1" => "tpe1" }
    Mp3Info.open(TEMP_FILE) do |mp3|
      tag.each do |k, v|
        mp3.tag2.send("#{k}=".to_sym, v)
      end
      assert_equal(tag, mp3.tag2)
    end
  end

  def test_id3v2_basic
    w = write_temp_file(BASIC_TAG2)
    assert_equal(BASIC_TAG2, w)
    id3v2_prog_test(BASIC_TAG2, w)
  end

  def test_id3v2_trash
  end

  def test_id3v2_complex
    tag = {}
    #ID3v2::TAGS.keys.each do |k|
    ["PRIV", "APIC"].each do |k|
      tag[k] = random_string(50)
    end
    assert_equal(tag, write_temp_file(tag))
  end

  def test_id3v2_bigtag
    tag = {"APIC" => random_string(1024) }
    assert_equal(tag, write_temp_file(tag))
  end

  def test_infinite_loop_on_seek_to_v2_end
    
  end

  def test_leading_char_gets_chopped
    tag2 = BASIC_TAG2.dup
    tag2["WOAR"] = "http://foo.bar"
    w = write_temp_file(tag2)
    assert_equal("http://foo.bar", w["WOAR"])

    system(%(id3v2 --WOAR "http://foo.bar" "#{TEMP_FILE}"))

    Mp3Info.open(TEMP_FILE) do |mp3|
      assert_equal "http://foo.bar", mp3.tag2["WOAR"]
    end
  end

  def test_remove_tag
    Mp3Info.open(TEMP_FILE) do |mp3|
      tag = mp3.tag
      tag.title = "title"
      tag.artist = "artist"
      mp3.close
      mp3.reload
      assert !mp3.tag1.empty?, "tag is empty"
      mp3.removetag1
      mp3.close
      mp3.reload
      assert mp3.tag1.empty?, "tag is not empty"
    end
  end

    #test the tag with php getid3
#    prog = %{
#    <?php
#      require("/var/www/root/netjuke/lib/getid3/getid3.php");
#      $mp3info = GetAllFileInfo('#{TEMP_FILE}');
#      echo $mp3info;
#    ?>
#    }
#
#    open("|php", "r+") do |io|
#      io.puts(prog)
#      io.close_write
#      p io.read
#    end

  def test_good_parsing_of_a_pathname
    fn = "Freak On `(Stone�s Club Mix).mp3"
    File.rename(TEMP_FILE, fn)
    begin
      mp3 = Mp3Info.new(fn)
      mp3.tag.title = fn
      mp3.close
      mp3.reload
      assert_equal fn, mp3.tag.title 
      mp3.close
    ensure
      File.delete(fn)
    end
  end

  #test the tag with the "id3v2" program
  def id3v2_prog_test(tag, written_tag)
    return if PLATFORM =~ /win32/
    return if `which id3v2`.empty?
    start = false
    id3v2_output = {}
    `id3v2 -l #{TEMP_FILE}`.each do |line|
      if line =~ /^id3v2 tag info/
        start = true 
	next    
      end
      next unless start
      k, v = /^(.{4}) \(.+\): (.+)$/.match(line)[1,2]
      case k
	#COMM (Comments): ()[spa]: fmg
        when "COMM"
	  v.sub!(/\(\)\[.{3}\]: (.+)/, '\1')
      end
      id3v2_output[k] = v
    end

    assert_equal( id3v2_output, written_tag, "id3v2 program output doesn't match")
  end

  def write_temp_file(tag)
    Mp3Info.open(TEMP_FILE) do |mp3|
      mp3.tag2.update(tag)
    end
    return Mp3Info.open(TEMP_FILE) { |m| m.tag2 }
    #system("cp -v #{TEMP_FILE} #{TEMP_FILE}.test")
  end

  def random_string(size)
    out = ""
    size.times { out << rand(256).chr }
    out
  end

=begin

  def test_encoder
    write_to_temp
    info = Mp3Info.new(TEMP_FILE)
    assert(info.encoder == "Lame 3.93")
  end

  def test_vbr
    mp3_vbr = Base64.decode64 <<EOF

EOF
    File.open(TEMP_FILE, "w") { |f| f.write(mp3_vbr) }
    info = Mp3Info.new(TEMP_FILE)
    assert_equal(info.vbr, true)
    assert_equal(info.bitrate, 128)
  end
=end
end
