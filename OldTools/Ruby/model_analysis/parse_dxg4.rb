#!/usr/bin/env ruby
# dxgファイルの構成を表示する

#----------------------------------------------------------------------
class BinFile
  #                    d_pos
  #          d_off       |          d_off+d_len
  #            |         |            |
  # file [-----########################------]
  # @data     [########################]

  attr_reader :pos
  attr_reader :limit

  def initialize(path)
    @file = open(path, "rb")
    @d_off = 0
    @d_len = 0
    @pos = 0
    @data = nil
    @limit = File.size(path)
  end

  # ロードした範囲内でposを設定する。
  def set_pos(pos)
    check_range(pos, 0)
    @pos = pos
  end

  # データをロードし、posをロードした先頭のデータに位置づける。
  def refill(length, offset = -1)
    if offset < 0
      offset = @d_off + @d_len
    end
    @file.seek(offset)
    @data = @file.read(length)
    raise "cannot read required length" if length != @data.length
    @d_off = offset
    @d_len = length
    @pos = offset
  end

  def string(length)
    check_range(@pos, length)
    r = @data[@pos - @d_off, length]
    @pos += length
    return r
  end

  # 指定された範囲のバイトデータを文字列表記の配列にして返す
  def hexa(length)
    check_range(@pos, length)
    r = @data[@pos - @d_off, length].unpack('C*').map do |x|
      sprintf("%02x", x)
    end
    @pos += length
    return r
  end

  # Fixnum(byte)を返す
  def byte()
    check_range(@pos, 1)
    x = @data[@pos - @d_off, 1].unpack('C*')
    @pos += 1
    return x[0]
  end

  # Array of Fixnum(byte)を返す
  def bytea(length)
    check_range(@pos, length)
    x = @data[@pos - @d_off, length].unpack('C*')
    @pos += length
    return x
  end

  # Fixnum(short)を返す
  def short()
    check_range(@pos, 2)
    x = @data[@pos - @d_off, 2].unpack('C*')
    @pos += 2
    return x[0] | (x[1] << 8)
  end

  # Array of Fixnum(short)を返す
  def shorta(length)
    check_range(@pos, 2 * length)
    x = @data[@pos - @d_off, 2 * length].unpack('C*')
    r = Array.new(length)
    length.times do |i|
      r[i] = x[i * 2 + 0] | (x[i * 2 + 1] << 8)
    end
    @pos += 2 * length
    return r
  end

  # Fixnum(int)を返す
  def int()
    check_range(@pos, 4)
    x = @data[@pos - @d_off, 4].unpack('C*')
    @pos += 4
    return x[0] | (x[1] << 8) | (x[2] << 16) | (x[3] << 24)
  end

  # Array of Fixnum(int)を返す
  def inta(length)
    check_range(@pos, 4 * length)
    x = @data[@pos - @d_off, 4 * length].unpack('C*')
    r = Array.new(length)
    length.times do |i|
      r[i] = x[i * 4 + 0] | (x[i * 4 + 1] << 8) | (x[i * 4 + 2] << 16) | (x[i * 4 + 3] << 24)
    end
    @pos += 4 * length
    return r
  end

  # Array of Floatを返す
  def floata(length)
    check_range(@pos, 4 * length)
    r = @data[@pos - @d_off, 4 * length].unpack('e*')
    @pos += 4 * length
    return r
  end

  def check_range(pos, length)
    raise "lower bound exceeded" if pos < @d_off
    raise "upper bound exceeded" if pos + length > @d_off + @d_len
  end
end

  def load_short_array(bf, ranges, desc, count, n)
    ranges << Span.new(desc, bf.pos, n * 2 * count, n, 2 * count)
    bf.refill(2 * count * n)
    r = Array.new(n)
    n.times do |i|
      r[i] = bf.shorta(count)
    end
    return r
  end

  def load_float_array(bf, ranges, desc, count, n)
    ranges << Span.new(desc, bf.pos, n * 4 * count, n, 4 * count)
    bf.refill(4 * count * n)
    r = Array.new(n)
    n.times do |i|
      r[i] = bf.floata(count)
    end
    return r
  end

#----------------------------------------------------------------------
class Span
  attr_accessor :desc, :start, :len, :elem_nr, :elem_size

  def initialize(desc, start, len, elem_nr, elem_size)
    @desc = desc; @start = start; @len = len
    @elem_nr = elem_nr; @elem_size = elem_size
  end

  def set_length(len)
    @len = @elem_size = len
  end

  def self.print_header
    printf "  %-20s %6s %6s %6s %6s %6s %6s %6s\n", \
    'ブロック名', '開始', '終了', '領域長', '開始', '終了', '個数', 'サイズ'
  end

  def show
    printf "  %-20s %6d %6d %6d %5xh %5xh %6d %6d\n",\
    @desc, @start, @start + @len, @len, \
    @start, @start + @len, @elem_nr, @elem_size
  end

  def self.list(spans)
    self.print_header
    spans.each do |span|
      span.show()
    end
  end
end

#----------------------------------------------------------------------

class DxgFile
  attr_reader :ranges
  attr_reader :path

  attr_reader :file_header
  attr_reader :group_list
  attr_reader :aux_list

  def initialize(path)
    bf = BinFile.new(path)
    @path = path
    @ranges = [Span.new('ファイル', 0, bf.limit, 1, bf.limit)]
    @group_list = []
    @aux_list = []

    # ファイルヘッダ部
    @file_header = FileHeader.new(bf, @ranges)

    # グループデータ部
    case @file_header.flag_a3 & 3
    when 1, 3
      @file_header.nr_groups.times do |n|
	@group_list << GroupData.new(bf, n, @ranges)
      end
    when 2
      @aux_list << AuxData.new(bf, 'a0', @ranges, @file_header)
    else
      raise "unexpected flag_a3"
    end

    expected = @file_header.next_data_offset + 20
    len = expected - bf.pos
    raise "illegal next_data_offset" if len < 0
    if len > 0
      # 今のところ出現しない模様
      @ranges << Span.new('不明1', bf.pos, len, 1, len)
      bf.refill(0, expected)
    end

    # 補助データ部
    if (@file_header.flag_a3 & 3) == 3
      @aux_list << AuxData.new(bf, 'a1', @ranges, @file_header)
    end

    if (@file_header.flag_a3 & 4) == 4
      @aux_list << AuxData.new(bf, 'b', @ranges, @file_header)
    end

    if (@file_header.flag_a3 & 8) == 8
      @aux_list << AuxData.new(bf, 'c', @ranges, @file_header)
    end

    if (@file_header.flag_a3 & 32) == 32
      @aux_list << AuxData.new(bf, 'd', @ranges, @file_header)
    end

    len = bf.limit - bf.pos
    if len > 0
      # いまのところ出現しない模様
      @ranges << Span.new('不明3', bf.pos, len, 1, len)
    end
  end

  def show(what)
    if what == 'spans'
      print "範囲\n"
      Span.list(@ranges)
    else
      # タイトルを第0レベルで表示
      case what
      when 'flags'
	print "フラグ\n"
      when 'offsets'
	print "オフセット\n"
      when 'sizes'
	print "サイズ\n"
      when 'names'
	print "名前\n"
      when 'data'
	print "データ\n"
      end

      # 中身を再帰的に表示
      @file_header.show(what)
      @group_list.each {|x| x.show(what)}
      @aux_list.each {|x| x.show(what)}
    end
  end
end

#----------------------------------------------------------------------
class FileHeader
  attr_reader :signature
  attr_reader :flag_a1
  attr_reader :flag_a2
  attr_reader :flag_a3
  attr_reader :flag_a4
  attr_reader :nr_groups
  attr_reader :next_data_offset
  attr_reader :group_names_size
  attr_reader :group_names

  def initialize(bf, ranges)
    span = Span.new("ファイルヘッダ", bf.pos, -1, 1, -1)
    ranges << span
    bf.refill(0x18)
    @signature = bf.string(4)
    @flag_a1 = bf.short()
    @flag_a2 = bf.short()
    @flag_a3 = bf.short()
    @flag_a4 = bf.short()
    @nr_groups = bf.int()
    @next_data_offset = bf.int()
    @group_names_size = bf.int()
    bf.refill(@group_names_size)
    @group_names = bf.string(@group_names_size).split("\0")
    span.set_length(bf.pos - span.start)
  end

  def show(what)
    print "  ファイルヘッダ\n"
    case what
    when 'sizes'
      print "\tnr_groups: #{@nr_groups}\n"
    when 'offsets'
      print "\tnext_data_offset: #{@next_data_offset}\n"
    when 'flags'
      x = @flag_a3
      print "\tflag_a1: #{@flag_a1}\n" if @flag_a1 != 1
      print "\tflag_a2: #{@flag_a2}\n"
      print "\tflag_a3: [#{(x>>5)&1},#{(x>>4)&1},#{(x>>3)&1},#{(x>>2)&1},#{(x>>1)&1},#{(x>>0)&1}], #{x}\n"
      print "\tflag_a4: #{@flag_a4}\n" if @flag_a4 != 0
    when 'names'
      print "\tgroup_names: " + @group_names.join(", ") + "\n"
    end
  end
end

#----------------------------------------------------------------------
class GroupData
  attr_reader :group_header
  attr_reader :mesh_list
  attr_reader :verteces
  attr_reader :normals
  attr_reader :uvs
  attr_reader :data_v
  attr_reader :weight_map
  attr_reader :unknown2
  attr_reader :nr

  def initialize(bf, n, ranges)
    @nr = n
    span = Span.new("グループ#{n}", bf.pos, -1, 1, -1)
    ranges << span

    @group_header = GroupHeader.new(bf, ranges)
    @mesh_list = Array.new()
    (@group_header.flag_b3 & 255).times do |i|
      @mesh_list[i] = MeshData.new(bf, i, ranges)
    end

    @verteces = load_float_array(bf, ranges, '  頂点座標',
				 3, @group_header.verteces_nr)
    @normals = load_float_array(bf, ranges, '  法線ベクトル',
				 3, @group_header.normals_nr)
    @uvs = load_float_array(bf, ranges, '  UV座標',
			    2, @group_header.uvs_nr)

    if @group_header.data_v_nr > 0
      ranges << Span.new('  データV', bf.pos, @group_header.data_v_nr * 4,
			 @group_header.data_v_nr, 4)
      bf.refill(@group_header.data_v_nr * 4)
      @data_v = bf.hexa(@group_header.data_v_nr * 4)
    else
      @data_v = []
    end

    @weight_map = load_float_array(bf, ranges, '  ウェイトマップ',
				   1, @group_header.weight_map_nr)

    expected = span.start + @group_header.offset_f + 8
    len = expected - bf.pos
    raise "illegal offset_f" if len < 0
    if len > 0
      # いまのところ出現しない模様
      ranges << Span.new('  不明2', bf.pos, len, 1, len)
      bf.refill(len)
      @unknown2 = bf.hexa(len)
    end

    span.set_length(bf.pos - span.start)
  end

  def show(what)
    return if what == 'flags'

    print "  グループ#{@nr}\n"

    @group_header.show(what)
    @mesh_list.each do |x|
      x.show(what)
    end

    case what
    when 'data'
      print "    頂点座標\n"
      @group_header.verteces_nr.times do |i|
	printf "\t%5d %g %g %g\n", i, @verteces[i][0], \
	@verteces[i][1], @verteces[i][2]
      end
      print "    法線ベクトル\n"
      @group_header.normals_nr.times do |i|
	printf "\t%5d %g %g %g\n", i, @normals[i][0], \
	@normals[i][1], @normals[i][2]
      end
      print "    UV座標\n"
      @group_header.uvs_nr.times do |i|
	printf "\t%5d %g %g\n", i, @uvs[i][0], @uvs[i][1]
      end
      if @data_v.length > 0
	print "    データV\n"
	printf "\tdata_v: " + @data_v.join(", ") + "\n"
      end
      if @weight_map.length > 0
	print "    ウェイトマップ\n"
	@group_header.weight_map_nr.times do |i|
	  printf "\t%5d %g\n", i, @weight_map[i][0]
	end
      end
    end
  end

  class GroupHeader
    attr_reader :flag_b1
    attr_reader :offset_f
    attr_reader :flag_b2
    attr_reader :flag_b3
    attr_reader :offset_g
    attr_reader :verteces_nr
    attr_reader :normals_nr
    attr_reader :uvs_nr
    attr_reader :data_v_nr
    attr_reader :weight_map_nr

    def initialize(bf, ranges)
      ranges << Span.new("  グループヘッダ", bf.pos, 0x24, 1, 0x24)
      bf.refill(0x24)
      @flag_b1 = bf.int()
      @offset_f = bf.int()
      @flag_b2 = bf.int()
      @flag_b3 = bf.int()
      @offset_g = bf.int()
      @verteces_nr = bf.short()
      @normals_nr = bf.short()
      @uvs_nr = bf.int()
      @data_v_nr = bf.int()
      @weight_map_nr = bf.int()
    end

    def show(what)
      return if what == 'names'

      print "    グループヘッダ\n"
      case what
      when 'sizes'
	print "\tnr_meshes: #{@flag_b3 & 255}\n"
	print "\tverteces_nr: #{@verteces_nr}\n"
	print "\tnormals_nr: #{@normals_nr}\n"
	print "\tuvs_nr: #{@uvs_nr}\n"
	print "\tdata_v_nr: #{@data_v_nr}\n"
	print "\tweight_map_nr: #{@weight_map_nr}\n"
      when 'offsets'
	print "\toffset_f: #{@offset_f}\n"
	print "\toffset_g: #{@offset_g}\n"
      end
    end
  end

  class MeshData
    attr_reader :mesh_header
    attr_reader :vertex_info
    attr_reader :face_info
    attr_reader :name_t
    attr_reader :data_u
    attr_reader :nr

    def initialize(bf, n, ranges)
      @nr = n
      span = Span.new("  メッシュ#{n}", bf.pos, -1, 1, -1)
      ranges << span

      @mesh_header = MeshHeader.new(bf, ranges)
      @vertex_info = load_short_array(bf, ranges, '    頂点情報',
				      5, @mesh_header.vertex_info_nr)
      @face_info = load_short_array(bf, ranges, '    面情報',
				    3, @mesh_header.face_info_nr)

      if @mesh_header.name_t_nr > 0
	uspan = Span.new("    名前T", bf.pos, -1, 1, -1)
	ranges << uspan
	bf.refill(4)
	len = bf.int()
	bf.refill(len)
	@name_t = bf.string(len).split("\0")
	uspan.set_length(bf.pos - uspan.start)
      else
	@name_t = []
      end

      len = (@mesh_header.data_u_nr + 3) / 4 * 4
      ranges << Span.new("    データU", bf.pos, len, 1, len)
      bf.refill(len)
      @data_u = bf.bytea(@mesh_header.data_u_nr) # 正味
      bf.string(len - @mesh_header.data_u_nr) # パディング

      span.set_length(bf.pos - span.start)
    end

    def show(what)
      return if what == 'flags'

      print "    メッシュ#{@nr}\n"
      @mesh_header.show(what)

      case what
      when 'names'
	print "\tname_t: " + @name_t.join(", ") + "\n"
      when 'data'
	print "      頂点情報\n"
	@mesh_header.vertex_info_nr.times do |i|
	  printf "\t%5d %5d %5d %5d %5d %5d\n", i, @vertex_info[i][0], \
	  @vertex_info[i][1], @vertex_info[i][2], \
	  @vertex_info[i][3], @vertex_info[i][4]
	end
	print "      面情報\n"
	@mesh_header.face_info_nr.times do |i|
	  printf "\t%5d %5d %5d %5d\n", i, @face_info[i][0], \
	  @face_info[i][1], @face_info[i][2]
	end
      end
    end
  end

  class MeshHeader
    attr_reader :vertex_info_nr
    attr_reader :face_info_nr
    attr_reader :name_t_nr
    attr_reader :data_u_nr
    attr_reader :verteces_offset

    def initialize(bf, ranges)
      ranges << Span.new("    メッシュヘッダ", bf.pos, 0x10, 1, 0x10)
      bf.refill(0x10)
      @vertex_info_nr = bf.short()
      @face_info_nr = bf.short()
      @name_t_nr = bf.int()
      @data_u_nr = bf.int()
      @verteces_offset = bf.int()
    end

    def show(what)
      print "      メッシュヘッダ\n"
      case what
      when 'sizes'
	print "\tvertex_info_nr: #{@vertex_info_nr}\n"
	print "\tface_info_nr: #{@face_info_nr}\n"
	print "\tname_t_nr: #{@name_t_nr}\n"
	print "\tdata_u_nr: #{@data_u_nr}\n"
      when 'offsets'
	print "\tverteces_offset: #{verteces_offset}\n"
      end
    end
  end
end

#----------------------------------------------------------------------

class AuxData
  attr_reader :type
  attr_reader :aux_header
  attr_reader :aux_names
  attr_reader :bone_links
  attr_reader :data_z

  def initialize(bf, type, ranges, fhdr)
    @type = type
    span = Span.new("補助データ#{type}", bf.pos, -1, 1, -1)
    ranges << span

    if type == 'a0'
      @aux_header = nil
    else
      @aux_header = AuxHeader.new(bf, ranges)
    end

    if type == 'a1' || type == 'b'
      @aux_names = AuxNames.new(bf, ranges)
    else
      @aux_names = nil
    end

    if type == 'a0'
      # - nr_groups個のBoneLinkデータ
      ranges << Span.new('  リンクa0', bf.pos, fhdr.nr_groups * 4,
			 fhdr.nr_groups, 4)
      @bone_links = Array.new(fhdr.nr_groups)
      fhdr.nr_groups.times do |i|
	@bone_links[i] = BoneLink.new(bf, ranges, i)
      end
    elsif type == 'a1'
      ranges << Span.new("  リンクa1", bf.pos, @aux_header.nr_aux_elems * 4,
			 @aux_header.nr_aux_elems, 4)
      @bone_links = Array.new(@aux_header.nr_aux_elems)
      @aux_header.nr_aux_elems.times do |i|
	@bone_links[i] = BoneLink.new(bf, ranges, i)
      end
    else
      @bone_links = []
    end
      
    if type == 'a0'
      # 補助データ内で位置のチェックはしない
      ranges << Span.new("  データ#{type}", bf.pos,
			 fhdr.nr_groups * 16 * 4, fhdr.nr_groups * 16, 4)
      bf.refill(fhdr.nr_groups * 16 * 4)
      bf.string(fhdr.nr_groups * 16 * 4)
    else
      # 補助データ内で位置のチェックをする
      case type
      when 'a1'
	ranges << Span.new("  データ#{type}", bf.pos,
			   @aux_header.nr_aux_elems * 16 * 4,
			   @aux_header.nr_aux_elems * 16, 4)
	bf.refill(@aux_header.nr_aux_elems * 16 * 4)
	bf.string(@aux_header.nr_aux_elems * 16 * 4)
      when 'b'
	uspan = Span.new("  ヘッダ#{type}", bf.pos, -1, -1, 1)
	ranges << uspan
	bf.refill(4); len = bf.int()
	bf.refill(len); bf.string(len)
	uspan.set_length(4 + len)

	ranges << Span.new("  データ#{type}", bf.pos,
			   @aux_header.nr_aux_elems * 16 * 4,
			   @aux_header.nr_aux_elems * 16, 4)
	bf.refill(@aux_header.nr_aux_elems * 16 * 4)
	bf.string(@aux_header.nr_aux_elems * 16 * 4)
      when 'c'
	ranges << Span.new("  データ#{type}", bf.pos,
			   @aux_header.nr_aux_elems * 60,
			   @aux_header.nr_aux_elems, 60)
	bf.refill(@aux_header.nr_aux_elems * 60)
	bf.string(@aux_header.nr_aux_elems * 60)
      end

      len = span.start + 8 + @aux_header.aux_list_size - bf.pos
      raise "illegal aux_list_size" if len < 0
      if len > 0
	# TODO: type=dで発生してしまう
	ranges << Span.new("  不明4", bf.pos, len, 1, len)
	bf.refill(len)
	@data_z = bf.hexa(len)
      end
    end

    span.set_length(bf.pos - span.start)
  end

  def show(what)
    return if what == 'flags'

    print "  補助データ#{@type}\n"
    if @aux_header != nil
      @aux_header.show(what)
    end
    if @aux_names != nil
      @aux_names.show(what)
    end
  end

  class AuxHeader
    attr_reader :nr_aux_elems
    attr_reader :aux_list_size

    def initialize(bf, ranges)
      ranges << Span.new('  補助データヘッダ', bf.pos, 8, 1, 8)
      bf.refill(8)
      @nr_aux_elems = bf.int()
      @aux_list_size = bf.int()
    end

    def show(what)
      print "    補助データヘッダ\n"
      case what
      when 'sizes'
	print "\tnr_aux_elems: #{@nr_aux_elems}\n"
	print "\taux_list_size: #{@aux_list_size}\n"
      end
    end
  end

  class AuxNames
    attr_reader :aux_names_size
    attr_reader :aux_names

    def initialize(bf, ranges)
      span = Span.new('  名前リスト', bf.pos, -1, 1, -1)
      ranges << span
      bf.refill(4)
      @aux_names_size = bf.int()
      bf.refill(@aux_names_size)
      @aux_names = bf.string(@aux_names_size).split("\0")
      span.set_length(bf.pos - span.start)
    end

    def show(what)
      if what == 'names'
	print "\taux_names: " + @aux_names.join(", ") + "\n"
      end
    end
  end

  class BoneLink
    attr_reader :index
    attr_reader :parent
    attr_reader :child
    attr_reader :sibling

    def initialize(bf, ranges, n)
      bf.refill(4)
      @index = bf.byte()
      @parent = bf.byte()
      @child = bf.byte()
      @sibling = bf.byte()

      raise if @index != n
    end
  end
end

def dump(path)
  system("god -Ax -tx1 #{path} > `basename #{path}`.txt")
  system("cp -p #{path} `basename #{path}`")
end

def show_all(path)
  begin
    dxg = DxgFile.new(path)
    dxg.show('spans')
    dxg.show('flags')
    #dxg.show('offsets')
    dxg.show('sizes')
    dxg.show('names')
    #dxg.show('data')
  rescue
    print "  Error: failed!\n"
    dump(path)
    raise $!
  end
end

def test
  [
    '../../unpacked/chara/2/01201/model/201201_0_02_000.dxg',

    # 単数グループ / 複数グループ / グループデータなし
    '../../unpacked/chara/1/00100/model/100100_1_01_000.dxg',
    '../../unpacked/chara/1/00101/model/100101_1_02_000.dxg',
    '../../unpacked/chara/1/00101/model/100101_1_00_000.dxg',

    # 00xxx1
    '../../unpacked/chara/8/00002/model/800002_1_00_000.dxg', # 000001
    '../../unpacked/chara/1/00101/model/100101_1_03_000.dxg', # 000011
    '../../unpacked/chara/1/00100/model/100100_1_01_000.dxg', # 000111
    '../../unpacked/item/1/10/00100/model/11000100_1_0.dxg',  # 001001
    '../../unpacked/item/1/10/00010/model/11000010_1_0.dxg',  # 001111

    # 10xxx1
    '../../unpacked/chara/4/01001/model/401001_0_01_000.dxg', # 100011
    '../../unpacked/chara/1/00101/model/100101_1_01_000.dxg', # 100111

    # x0xxx0
    '../../unpacked/chara/4/01001/model/401001_0_00_000.dxg', # 000110
    '../../unpacked/chara/1/00101/model/100101_1_00_000.dxg', # 100110
  ].each do |path|
    print "#### #{path} ####\n"
    show_all(path)
    dump(path)
  end
end

if ARGV[0] == '-test'
  test()
else
  show_all(ARGV[0])
end
