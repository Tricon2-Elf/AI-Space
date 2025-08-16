class BinFile
  #                    d_pos
  #          d_off       |          d_off+d_len
  #            |         |            |
  # file [-----########################------]
  # @data     [########################]

  def initialize(path)
    @file = open(path, "rb")
    @d_off = 0
    @d_len = 0
    @data = nil
  end

  # ロードした範囲内でposを設定する。
  def set_pos(pos)
    check_range(pos, 0)
    @pos = pos
  end

  def get_pos()
    return @pos
  end

  # データをロードし、posをロードした先頭のデータに位置づける。
  def refill(length, offset = -1)
    if offset < 0
      offset = @d_off + @d_len
    end
    raise "too large to read (something is going wrong)" if length > 10000
    @file.seek(offset)
    @data = @file.read(length)
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

  # 指定された範囲のバイトデータを文字列表記にして返す
  def hexa(length)
    check_range(@pos, length)
    r = @data[@pos - @d_off, length].unpack('C*').map do |x|
      sprintf("%02x", x)
    end
    @pos += length
    return r
  end

  # Stringを返す
  def hexs(length)
    return hexa(length).join(' ')
  end

  # Fixnum(int)を返す
  def int()
    check_range(@pos, 4)
    x = @data[@pos - @d_off, 4].unpack('C*')
    @pos += 4
    return x[0] | (x[1] << 8) | (x[2] << 16) | (x[3] << 24)
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

  def check_range(p, length)
    raise "lower bound exceeded" if p < @d_off
    raise "upper bound exceeded" if p + length > @d_off + @d_len
  end
end

#----------------------------------------------------------------------
class Range
  attr_reader :desc, :start, :len, :elem_nr, :elem_size
  def initialize(desc, start, len, elem_nr, elem_size)
    #サイズの切り上げがあるので、必ずしも成立しない
    #raise if len != elem_size * elem_nr
    @desc = desc; @start = start; @len = len
    @elem_nr = elem_nr; @elem_size = elem_size
  end
end

#----------------------------------------------------------------------

class DxgFileParser
  def initialize
    @sz = []
    @info = []
    @data = []
  end

  def tohex(n)
    return sprintf("0x%x", n)
  end

  def parse(path)
    bf = BinFile.new(path)
    bf.refill(0x18)
    bf.set_pos(0x8)
    flag_a3 = bf.short()
    bf.refill(0, 0)

    if((flag_a3 & 1) == 1)
      parse_type1(path)
    else
      parse_type2(path)
    end      
  end

  def parse_type2(path)
  end

  def parse_type1(path)
    bf = BinFile.new(path)
    @info << ['ファイル情報']
    @info << [nil, 'パス', path]
    @info << [nil, 'サイズ', File.size(path)]

    # ヘッダ1
    @sz << Range.new('ヘッダ1', 0, 0x18, 1, 0x18)
    bf.refill(0x18)
    @info << ['ヘッダ1']
    @info << [nil, 'シグネチャ', bf.string(4)]
    @info << [nil, 'フラグA1', bf.short()]
    @info << [nil, 'フラグA2', bf.short()]
    @info << [nil, 'フラグA3', bf.short()]
    @info << [nil, 'フラグA4', bf.short()]
    name_e_nr = bf.int()
    @info << [nil, '名前リストE個数', name_e_nr]
    name_y_offset = bf.int()
    name_y_pos = name_y_offset + 0x14
    @info << [nil, '名前リストYオフセット', name_y_pos, tohex(name_y_pos)]
    @info << [nil, '名前リストY位置', name_y_offset , tohex(name_y_offset)]

    # 名前リストE
    name_e_size = bf.int()
    @sz << Range.new('名前リストE', bf.get_pos(), name_e_size, 1, name_e_size)
    h2_start = 0x18 + name_e_size
    h2_end = h2_start + 0x34
    bf.refill(name_e_size)
    slist = bf.string(name_e_size).split("\0")
    @info << ['名前リストE']
    slist.each_index do |i|
      @info << [nil, i, slist[i]]
    end

    name_e_nr.times do |name_e_count|
      # ヘッダ2
      @sz << Range.new("ヘッダ2[#{name_e_count}]", bf.get_pos(), 0x34, 1, 0x34)
      bf.refill(0x34)
      @info << ['ヘッダ2']
      @info << [nil, 'フラグB1', flag_b1 = bf.int(), tohex(flag_b1)]
      offset_f = bf.int()
      @info << [nil, 'オフセットF', offset_f, tohex(offset_f)]
      @info << [nil, 'フラグB2', flag_b2 = bf.int(), tohex(flag_b2)]
      @info << [nil, 'フラグB3', flag_b3 = bf.int(), tohex(flag_b3)]
      offset_g = bf.int()
      @info << [nil, 'オフセットG', offset_g, tohex(offset_g)]
      verteces_nr = bf.short()
      @info << [nil, '頂点座標数', verteces_nr, tohex(verteces_nr)]
      normals_nr = bf.short()
      @info << [nil, '法線ベクトル数', normals_nr, tohex(normals_nr)]
      uv_nr = bf.int()
      @info << [nil, 'UV座標数', uv_nr, tohex(uv_nr)]
      @info << [nil, 'フラグB4', bf.int()]
      data_x2_nr = bf.int()
      @info << [nil, 'データX2個数', data_x2_nr, tohex(data_x2_nr)]
      vertex_info_nr = bf.short()
      @info << [nil, '頂点情報数', vertex_info_nr, tohex(vertex_info_nr)]
      face_info_nr = bf.short()
      @info << [nil, '面情報数', face_info_nr, tohex(face_info_nr)]
      name_t_nr = bf.int()
      @info << [nil, '名前リストT個数', name_t_nr]
      data_u_nr = bf.int()
      @info << [nil, 'データU個数', data_u_nr]
      offset_q = bf.int()
      verteces_pos = offset_q + h2_end
      @info << [nil, '頂点座標位置',
	verteces_pos, tohex(verteces_pos), offset_q, tohex(offset_q)]

      # 頂点情報R
      @sz << Range.new("頂点情報[#{name_e_count}]", \
		       bf.get_pos(), 2 * 5 * vertex_info_nr, \
		       vertex_info_nr, 2 * 5)
      bf.refill(2 * 5 * vertex_info_nr)
      t = bf.shorta(5 * vertex_info_nr)
      @info << ['頂点情報']
      @data << ['頂点情報']
      r0 = r1 = r2 = 0
      vertex_info_nr.times do |i|
	@data << [nil, i, 
	  t[i * 5 + 0], t[i * 5 + 1], t[i * 5 + 2], t[i * 5 + 3], t[i * 5 + 4]]
	r0 = t[i * 5 + 0] if r0 < t[i * 5 + 0]
	r1 = t[i * 5 + 1] if r1 < t[i * 5 + 1]
	r2 = t[i * 5 + 2] if r2 < t[i * 5 + 2]
      end
      @info << [nil, '頂点情報の最大インデックス', r0, r1, r2]

      # 面情報S
      @sz << Range.new("面情報[#{name_e_count}]",
		       bf.get_pos(), 2 * 3 * face_info_nr,\
		       face_info_nr, 2 * 3)
      bf.refill(2 * 3 * face_info_nr)
      t = bf.shorta(3 * face_info_nr)
      @info << ['面情報']
      @data << ['面情報']
      face_info_nr.times do |i|
	@data << [nil, i, t[i * 3 + 0], t[i * 3 + 1], t[i * 3 + 2]]
      end
      @info << [nil, '面情報の最大インデックス', t.sort[-1]]

      # 名前リストT
      pos = bf.get_pos()
      bf.refill(4)
      name_t_size = bf.int()
      bf.refill(name_t_size)
      slist = bf.string(name_t_size).split("\0")
      @sz << Range.new('名前リストT', pos, 4 + name_t_size, 1, 4 + name_t_size)
      @info << ['名前リストT']
      slist.each_index do |i|
	@info << [nil, i, slist[i]]
      end

      # データU
      data_u_size = (data_u_nr + 3) / 4 * 4
      @sz << Range.new('データU', bf.get_pos(), data_u_size, 1, data_u_nr)
      bf.refill(data_u_size)
      bf.string(data_u_size)

      # 頂点座標V
      @sz << Range.new("頂点座標[#{name_e_count}]",
		       bf.get_pos(), 4 * 3 * verteces_nr,\
		       verteces_nr, 4 * 3)
      bf.refill(4 * 3 * verteces_nr)
      t = bf.floata(3 * verteces_nr)
      @data << ['頂点座標']
      verteces_nr.times do |i|
	@data << [nil, i, t[i * 3 + 0], t[i * 3 + 1], t[i * 3 + 2]]
      end

      # 法線ベクトルW
      @sz << Range.new("法線[#{name_e_count}]",
		       bf.get_pos(), 4 * 3 * normals_nr,\
		       normals_nr, 4 * 3)
      bf.refill(4 * 3 * normals_nr)
      t = bf.floata(3 * normals_nr)
      @data << ['法線ベクトル']
      normals_nr.times do |i|
	#d2 = Math::sqrt(t[i * 3 + 0] * t[i * 3 + 0] \
	#		+ t[i * 3 + 1] * t[i * 3 + 1] \
	#		+ t[i * 3 + 2] * t[i * 3 + 2])
	#raise d2.to_s if(d2 < 0.9 || d2 > 1.1)
	@data << [nil, i, t[i * 3 + 0], t[i * 3 + 1], t[i * 3 + 2]]
      end

      # UV座標X1
      @sz << Range.new("UV座標[#{name_e_count}]",
		       bf.get_pos(), 4 * 2 * uv_nr, uv_nr, 4 * 2)
      bf.refill(4 * 2 * uv_nr)
      t = bf.floata(2 * uv_nr)
      @data << ['UV座標']
      uv_nr.times do |i|
	@data << [nil, i, t[i * 2 + 0], t[i * 2 + 1]]
      end

      # データX2
      @sz << Range.new("データX2[#{name_e_count}]",
		       bf.get_pos(), 4 * data_x2_nr, data_x2_nr, 4)
      bf.refill(4 * data_x2_nr)
      t = bf.floata(data_x2_nr)
      @data << ['データX2']
      data_x2_nr.times do |i|
	@data << [nil, i, t[i]]
      end
    end

    # データX3
    data_x3_size = name_y_pos - bf.get_pos()
    @sz << Range.new('データX3', bf.get_pos(), data_x3_size, data_x3_size, 1)

    # 名前リストY
    bf.refill(12, name_y_pos)
    name_y_nr = bf.int()
    name_y_xxx = bf.int()
    name_y_size = bf.int()
    @info << ['名前リストY']
    @info << [nil, '個数', name_y_nr]
    @info << [nil, '????', name_y_xxx, tohex(name_y_xxx)]
    @info << [nil, 'サイズ', name_y_size, tohex(name_y_size)]
    bf.refill(name_y_size)
    slist = bf.string(name_y_size).split("\0")
    @sz << Range.new('名前リストY', name_y_pos, 12 + name_y_size, \
		    12 + name_y_size, 1)
    @info << ['名前リストY']
    slist.each_index do |i|
      @info << [nil, i, slist[i]]
    end

    # データZ
    data_z_size = File.size(path) - bf.get_pos()
    @sz << Range.new('データZ', bf.get_pos(), data_z_size, data_z_size, 1)
  end

  def print_summary()
    printf "%-12s,%6s,%6s,%6s,%6s,%6s,%6s,%6s\n",\
    '#', '開始', '終了', '領域長', '開始', '終了', 'サイズ', '個数'
    @sz.each do |ss|
      printf "%-12s,%6d,%6d,%6d,%5xh,%5xh,%6d,%6d\n",\
      ss.desc, ss.start, ss.start + ss.len, ss.len, \
      ss.start, ss.start + ss.len, ss.elem_size, ss.elem_nr
    end
  end

  def print_detail()
    @info.each do |ii|
      if ii[0] != nil
	print ii.join(", ") + "\n"
      else
	print "\t" + ii[1..-1].join(", ") + "\n"
      end
    end
  end
end

parser = DxgFileParser.new
#parser.parse('../../unpacked/chara/1/00100/model/100100_1_01_000.dxg')
parser.parse(ARGV[0])
parser.print_summary()
parser.print_detail()
