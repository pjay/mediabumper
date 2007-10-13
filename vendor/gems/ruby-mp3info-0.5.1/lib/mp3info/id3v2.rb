require "mp3info/extension_modules"

# This class is not intended to be used directly
class ID3v2 < DelegateClass(Hash) 
  VERSION_MAJ = 3
  
  TAGS = {
    "AENC" => "Audio encryption",
    "APIC" => "Attached picture",
    "COMM" => "Comments",
    "COMR" => "Commercial frame",
    "ENCR" => "Encryption method registration",
    "EQUA" => "Equalization",
    "ETCO" => "Event timing codes",
    "GEOB" => "General encapsulated object",
    "GRID" => "Group identification registration",
    "IPLS" => "Involved people list",
    "LINK" => "Linked information",
    "MCDI" => "Music CD identifier",
    "MLLT" => "MPEG location lookup table",
    "OWNE" => "Ownership frame",
    "PRIV" => "Private frame",
    "PCNT" => "Play counter",
    "POPM" => "Popularimeter",
    "POSS" => "Position synchronisation frame",
    "RBUF" => "Recommended buffer size",
    "RVAD" => "Relative volume adjustment",
    "RVRB" => "Reverb",
    "SYLT" => "Synchronized lyric/text",
    "SYTC" => "Synchronized tempo codes",
    "TALB" => "Album/Movie/Show title",
    "TBPM" => "BPM (beats per minute)",
    "TCOM" => "Composer",
    "TCON" => "Content type",
    "TCOP" => "Copyright message",
    "TDAT" => "Date",
    "TDLY" => "Playlist delay",
    "TENC" => "Encoded by",
    "TEXT" => "Lyricist/Text writer",
    "TFLT" => "File type",
    "TIME" => "Time",
    "TIT1" => "Content group description",
    "TIT2" => "Title/songname/content description",
    "TIT3" => "Subtitle/Description refinement",
    "TKEY" => "Initial key",
    "TLAN" => "Language(s)",
    "TLEN" => "Length",
    "TMED" => "Media type",
    "TOAL" => "Original album/movie/show title",
    "TOFN" => "Original filename",
    "TOLY" => "Original lyricist(s)/text writer(s)",
    "TOPE" => "Original artist(s)/performer(s)",
    "TORY" => "Original release year",
    "TOWN" => "File owner/licensee",
    "TPE1" => "Lead performer(s)/Soloist(s)",
    "TPE2" => "Band/orchestra/accompaniment",
    "TPE3" => "Conductor/performer refinement",
    "TPE4" => "Interpreted, remixed, or otherwise modified by",
    "TPOS" => "Part of a set",
    "TPUB" => "Publisher",
    "TRCK" => "Track number/Position in set",
    "TRDA" => "Recording dates",
    "TRSN" => "Internet radio station name",
    "TRSO" => "Internet radio station owner",
    "TSIZ" => "Size",
    "TSRC" => "ISRC (international standard recording code)",
    "TSSE" => "Software/Hardware and settings used for encoding",
    "TYER" => "Year",
    "TXXX" => "User defined text information frame",
    "UFID" => "Unique file identifier",
    "USER" => "Terms of use",
    "USLT" => "Unsychronized lyric/text transcription",
    "WCOM" => "Commercial information",
    "WCOP" => "Copyright/Legal information",
    "WOAF" => "Official audio file webpage",
    "WOAR" => "Official artist/performer webpage",
    "WOAS" => "Official audio source webpage",
    "WORS" => "Official internet radio station homepage",
    "WPAY" => "Payment",
    "WPUB" => "Publishers official webpage",
    "WXXX" => "User defined URL link frame"
  }

  include Mp3Info::HashKeys
  
  attr_reader :io_position

  # possibles keys:
  # :+lang+ for writing comments
  # :+encoding+: :+iso+ or :+unicode+ 
  attr_reader :options
  
  def initialize(options = {})
    @options = { 
      :lang => "ENG", 
      :encoding => :iso  #language encoding bit 0 for iso_8859_1, 1 for unicode
    }
    @options.update(options)
    
    @hash = {}
    #TAGS.keys.each { |k| @hash[k] = nil }
    @hash_orig = {}
    super(@hash)
    @valid = false
    @version_maj = @version_min = nil
  end

  def valid?
    @valid
  end

  def changed?
    @hash_orig != @hash
  end
  
  def version
    "2.#{@version_maj}.#{@version_min}"
  end

  ### gets id3v2 tag information from io
  def from_io(io)
    @io = io
    version_maj, version_min, flags = @io.read(3).unpack("CCB4")
    @unsync, ext_header, experimental, footer = (0..3).collect { |i| flags[i].chr == '1' }
    raise("can't find version_maj ('#{version_maj}')") unless [2, 3, 4].include?(version_maj)
    @version_maj, @version_min = version_maj, version_min
    @valid = true
    tag2_len = @io.get_syncsafe
    case @version_maj
      when 2
        read_id3v2_2_frames(tag2_len)
      when 3,4
        # seek past extended header if present
        @io.seek(@io.get_syncsafe - 4, IO::SEEK_CUR) if ext_header
        read_id3v2_3_frames(tag2_len)
    end
    @io_position = @io.pos
    
    @hash_orig = @hash.dup
    #no more reading
    @io = nil
    # we should now have io sitting at the first MPEG frame
  end

  def to_bin
    #TODO handle of @tag2[TLEN"]
    #TODO add of crc
    #TODO add restrictions tag

    tag = ""
    @hash.each do |k, v|
      next unless v
      next if v.respond_to?("empty?") and v.empty?
      data = encode_tag(k, v.to_s)
      #data << "\x00"*2 #End of tag

      tag << k[0,4]   #4 characte max for a tag's key
      #tag << to_syncsafe(data.size) #+1 because of the language encoding byte
      tag << [data.size].pack("N") #+1 because of the language encoding byte
      tag << "\x00"*2 #flags
      tag << data
    end

    tag_str = ""
    #version_maj, version_min, unsync, ext_header, experimental, footer 
    tag_str << [ VERSION_MAJ, 0, "0000" ].pack("CCB4")
    tag_str << to_syncsafe(tag.size)
    tag_str << tag
    p tag_str if $DEBUG
    tag_str
  end

  private


  def encode_tag(name, value)
    puts "encode_tag(#{name.inspect}, #{value.inspect})" if $DEBUG
    case name
      when "COMM"
	[ @options[:encoding] == :iso ? 0 : 1, @options[:lang], 0, value ].pack("ca3ca*")
      when /^W/ # URL link frames
        value
      else
        if @options[:encoding] == :iso
	  "\x00"+value
	else
	  "\x01"+value #Iconv.iconv("UNICODE", "ISO-8859-1", value)[0]
	end
      #data << "\x00"   
    end
  end

  ### Read a tag from file and perform UNICODE translation if needed
  def decode_tag(name, value)
    case name
      when "COMM"
        #FIXME improve this
	encoding, lang, str = value.unpack("ca3a*")
	out = value.split(0.chr).last
      when /^W/ # URL link frames
        out = value
      else
	encoding = value[0]     # language encoding bit 0 for iso_8859_1, 1 for unicode
	out = value[1..-1] 
    end

    if encoding == 1 #and name[0] == ?T
      require "iconv"
      
      #strip byte-order bytes at the beginning of the unicode string if they exists
      out[0..3] =~ /^[\xff\xfe]+$/ and out = out[2..-1]
      begin
	out = Iconv.iconv("ISO-8859-1", "UTF-16", out)[0] 
      rescue Iconv::IllegalSequence, Iconv::InvalidCharacter
      end
    end
    out
  end

  ### reads id3 ver 2.3.x/2.4.x frames and adds the contents to @tag2 hash
  ###  tag2_len (fixnum) = length of entire id3v2 data, as reported in header
  ### NOTE: the id3v2 header does not take padding zero's into consideration
  def read_id3v2_3_frames(tag2_len)
    loop do # there are 2 ways to end the loop
      name = @io.read(4)
      if name[0] == 0 or name == "MP3e" #bug caused by old tagging application "mp3ext" ( http://www.mutschler.de/mp3ext/ )
        @io.seek(-4, IO::SEEK_CUR)    # 1. find a padding zero,
	seek_to_v2_end
        break
      else
        #size = @io.get_syncsafe #this seems to be a bug
        size = @io.get32bits
	@io.read(2)
=begin
        size_str = @io.read(4)

	@io.getc #flags part 1
	# just read the unsync bit
	b = @io.getc
	unsync = ((b >> 1) & 1) == 1

	if unsync
	  size = (size_str[0] << 21) + (size_str[1] << 14) + (size_str[2]<< 7) + size_str[3]
	else
	  size = size_str.unpack("N").first
	end
	require "to_b"
=end
        puts "name '#{name}' size #{size}" if $DEBUG
        #@io.seek(2, IO::SEEK_CUR)     # skip flags
        add_value_to_tag2(name, size)
#        case name
#          when /^T/
#            puts "tag is text. reading" if $DEBUG
##	    data = read_id3_string(size-1)
##	    add_value_to_tag2(name, data)
#          else
#	    decode_tag(
#            #@file.seek(size-1, IO::SEEK_CUR)  
#            puts "tag is binary, skipping" if $DEBUG
#            @io.seek(size, IO::SEEK_CUR)  
#        end

#	case name
#	  #FIXME DRY
#	  when "COMM"
#            data = read_id3v2_frame(size)
#	    lang = data[0,3]
#	    data = data[3,-1]
#	  else
#	end
      end
      break if @io.pos >= tag2_len # 2. reach length from header
    end
  end    

  ### reads id3 ver 2.2.x frames and adds the contents to @tag2 hash
  ###  tag2_len (fixnum) = length of entire id3v2 data, as reported in header
  ### NOTE: the id3v2 header does not take padding zero's into consideration
  def read_id3v2_2_frames(tag2_len)
    loop do
      name = @io.read(3)
      if name[0] == 0
        @io.seek(-3, IO::SEEK_CUR)
	seek_to_v2_end
        break
      else
        size = (@io.getc << 16) + (@io.getc << 8) + @io.getc
	add_value_to_tag2(name, size)
        break if @io.pos >= tag2_len
      end
    end
  end    
  
  ### Add data to tag2["name"]
  ### read lang_encoding, decode data if unicode and
  ### create an array if the key already exists in the tag
  def add_value_to_tag2(name, size)
    puts "add_value_to_tag2" if $DEBUG
    raise("tag size too big for tag #{name.inspect} unsync #{@unsync} ") if size > 50_000_000
    data_io = @io.read(size)
    data = decode_tag(name, data_io)
    if self.keys.include?(name)
      unless self[name].is_a?(Array)
        self[name] = self[name].to_a
      end
      self[name] << data
    else
      self[name] = data 
    end
    p data if $DEBUG
  end
  
  ### runs thru @file one char at a time looking for best guess of first MPEG
  ###  frame, which should be first 0xff byte after id3v2 padding zero's
  def seek_to_v2_end
    until @io.getc == 0xff
      raise EOFError if @io.eof?
    end
    @io.seek(-1, IO::SEEK_CUR)
  end
  
  ### convert an 32 integer to a syncsafe string
  def to_syncsafe(num)
    n = ( (num<<3) & 0x7f000000 )  + ( (num<<2) & 0x7f0000 ) + ( (num<<1) & 0x7f00 ) + ( num & 0x7f )
    [n].pack("N")
  end

#  def method_missing(meth, *args)
#    m = meth.id2name
#    return nil if TAGS.has_key?(m) and self[m].nil?
#    super
#  end
end

