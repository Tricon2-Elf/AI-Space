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

  # ���ɤ����ϰ����pos�����ꤹ�롣
  def set_pos(pos)
    check_range(pos, 0)
    @pos = pos
  end

  def get_pos()
    return @pos
  end

  # �ǡ�������ɤ���pos����ɤ�����Ƭ�Υǡ����˰��֤Ť��롣
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

  # ���ꤵ�줿�ϰϤΥХ��ȥǡ�����ʸ����ɽ���ˤ����֤�
  def hexa(length)
    check_range(@pos, length)
    r = @data[@pos - @d_off, length].unpack('C*').map do |x|
      sprintf("%02x", x)
    end
    @pos += length
    return r
  end

  # String���֤�
  def hexs(length)
    return hexa(length).join(' ')
  end

  # Fixnum(int)���֤�
  def int()
    check_range(@pos, 4)
    x = @data[@pos - @d_off, 4].unpack('C*')
    @pos += 4
    return x[0] | (x[1] << 8) | (x[2] << 16) | (x[3] << 24)
  end

  # Fixnum(short)���֤�
  def short()
    check_range(@pos, 2)
    x = @data[@pos - @d_off, 2].unpack('C*')
    @pos += 2
    return x[0] | (x[1] << 8)
  end

  # Array of Fixnum(short)���֤�
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

  # Array of Fixnum(int)���֤�
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

  # Array of Float���֤�
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
    #���������ڤ�夲������Τǡ�ɬ��������Ω���ʤ�
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
    @info << ['�ե��������']
    @info << [nil, '�ѥ�', path]
    @info << [nil, '������', File.size(path)]

    # �إå�1
    @sz << Range.new('�إå�1', 0, 0x18, 1, 0x18)
    bf.refill(0x18)
    @info << ['�إå�1']
    @info << [nil, '�����ͥ���', bf.string(4)]
    @info << [nil, '�ե饰A1', bf.short()]
    @info << [nil, '�ե饰A2', bf.short()]
    @info << [nil, '�ե饰A3', bf.short()]
    @info << [nil, '�ե饰A4', bf.short()]
    name_e_nr = bf.int()
    @info << [nil, '̾���ꥹ��E�Ŀ�', name_e_nr]
    name_y_offset = bf.int()
    name_y_pos = name_y_offset + 0x14
    @info << [nil, '̾���ꥹ��Y���ե��å�', name_y_pos, tohex(name_y_pos)]
    @info << [nil, '̾���ꥹ��Y����', name_y_offset , tohex(name_y_offset)]

    # ̾���ꥹ��E
    name_e_size = bf.int()
    @sz << Range.new('̾���ꥹ��E', bf.get_pos(), name_e_size, 1, name_e_size)
    h2_start = 0x18 + name_e_size
    h2_end = h2_start + 0x34
    bf.refill(name_e_size)
    slist = bf.string(name_e_size).split("\0")
    @info << ['̾���ꥹ��E']
    slist.each_index do |i|
      @info << [nil, i, slist[i]]
    end

    name_e_nr.times do |name_e_count|
      # �إå�2
      @sz << Range.new("�إå�2[#{name_e_count}]", bf.get_pos(), 0x34, 1, 0x34)
      bf.refill(0x34)
      @info << ['�إå�2']
      @info << [nil, '�ե饰B1', flag_b1 = bf.int(), tohex(flag_b1)]
      offset_f = bf.int()
      @info << [nil, '���ե��å�F', offset_f, tohex(offset_f)]
      @info << [nil, '�ե饰B2', flag_b2 = bf.int(), tohex(flag_b2)]
      @info << [nil, '�ե饰B3', flag_b3 = bf.int(), tohex(flag_b3)]
      offset_g = bf.int()
      @info << [nil, '���ե��å�G', offset_g, tohex(offset_g)]
      verteces_nr = bf.short()
      @info << [nil, 'ĺ����ɸ��', verteces_nr, tohex(verteces_nr)]
      normals_nr = bf.short()
      @info << [nil, 'ˡ���٥��ȥ��', normals_nr, tohex(normals_nr)]
      uv_nr = bf.int()
      @info << [nil, 'UV��ɸ��', uv_nr, tohex(uv_nr)]
      @info << [nil, '�ե饰B4', bf.int()]
      data_x2_nr = bf.int()
      @info << [nil, '�ǡ���X2�Ŀ�', data_x2_nr, tohex(data_x2_nr)]
      vertex_info_nr = bf.short()
      @info << [nil, 'ĺ�������', vertex_info_nr, tohex(vertex_info_nr)]
      face_info_nr = bf.short()
      @info << [nil, '�̾����', face_info_nr, tohex(face_info_nr)]
      name_t_nr = bf.int()
      @info << [nil, '̾���ꥹ��T�Ŀ�', name_t_nr]
      data_u_nr = bf.int()
      @info << [nil, '�ǡ���U�Ŀ�', data_u_nr]
      offset_q = bf.int()
      verteces_pos = offset_q + h2_end
      @info << [nil, 'ĺ����ɸ����',
	verteces_pos, tohex(verteces_pos), offset_q, tohex(offset_q)]

      # ĺ������R
      @sz << Range.new("ĺ������[#{name_e_count}]", \
		       bf.get_pos(), 2 * 5 * vertex_info_nr, \
		       vertex_info_nr, 2 * 5)
      bf.refill(2 * 5 * vertex_info_nr)
      t = bf.shorta(5 * vertex_info_nr)
      @info << ['ĺ������']
      @data << ['ĺ������']
      r0 = r1 = r2 = 0
      vertex_info_nr.times do |i|
	@data << [nil, i, 
	  t[i * 5 + 0], t[i * 5 + 1], t[i * 5 + 2], t[i * 5 + 3], t[i * 5 + 4]]
	r0 = t[i * 5 + 0] if r0 < t[i * 5 + 0]
	r1 = t[i * 5 + 1] if r1 < t[i * 5 + 1]
	r2 = t[i * 5 + 2] if r2 < t[i * 5 + 2]
      end
      @info << [nil, 'ĺ������κ��祤��ǥå���', r0, r1, r2]

      # �̾���S
      @sz << Range.new("�̾���[#{name_e_count}]",
		       bf.get_pos(), 2 * 3 * face_info_nr,\
		       face_info_nr, 2 * 3)
      bf.refill(2 * 3 * face_info_nr)
      t = bf.shorta(3 * face_info_nr)
      @info << ['�̾���']
      @data << ['�̾���']
      face_info_nr.times do |i|
	@data << [nil, i, t[i * 3 + 0], t[i * 3 + 1], t[i * 3 + 2]]
      end
      @info << [nil, '�̾���κ��祤��ǥå���', t.sort[-1]]

      # ̾���ꥹ��T
      pos = bf.get_pos()
      bf.refill(4)
      name_t_size = bf.int()
      bf.refill(name_t_size)
      slist = bf.string(name_t_size).split("\0")
      @sz << Range.new('̾���ꥹ��T', pos, 4 + name_t_size, 1, 4 + name_t_size)
      @info << ['̾���ꥹ��T']
      slist.each_index do |i|
	@info << [nil, i, slist[i]]
      end

      # �ǡ���U
      data_u_size = (data_u_nr + 3) / 4 * 4
      @sz << Range.new('�ǡ���U', bf.get_pos(), data_u_size, 1, data_u_nr)
      bf.refill(data_u_size)
      bf.string(data_u_size)

      # ĺ����ɸV
      @sz << Range.new("ĺ����ɸ[#{name_e_count}]",
		       bf.get_pos(), 4 * 3 * verteces_nr,\
		       verteces_nr, 4 * 3)
      bf.refill(4 * 3 * verteces_nr)
      t = bf.floata(3 * verteces_nr)
      @data << ['ĺ����ɸ']
      verteces_nr.times do |i|
	@data << [nil, i, t[i * 3 + 0], t[i * 3 + 1], t[i * 3 + 2]]
      end

      # ˡ���٥��ȥ�W
      @sz << Range.new("ˡ��[#{name_e_count}]",
		       bf.get_pos(), 4 * 3 * normals_nr,\
		       normals_nr, 4 * 3)
      bf.refill(4 * 3 * normals_nr)
      t = bf.floata(3 * normals_nr)
      @data << ['ˡ���٥��ȥ�']
      normals_nr.times do |i|
	#d2 = Math::sqrt(t[i * 3 + 0] * t[i * 3 + 0] \
	#		+ t[i * 3 + 1] * t[i * 3 + 1] \
	#		+ t[i * 3 + 2] * t[i * 3 + 2])
	#raise d2.to_s if(d2 < 0.9 || d2 > 1.1)
	@data << [nil, i, t[i * 3 + 0], t[i * 3 + 1], t[i * 3 + 2]]
      end

      # UV��ɸX1
      @sz << Range.new("UV��ɸ[#{name_e_count}]",
		       bf.get_pos(), 4 * 2 * uv_nr, uv_nr, 4 * 2)
      bf.refill(4 * 2 * uv_nr)
      t = bf.floata(2 * uv_nr)
      @data << ['UV��ɸ']
      uv_nr.times do |i|
	@data << [nil, i, t[i * 2 + 0], t[i * 2 + 1]]
      end

      # �ǡ���X2
      @sz << Range.new("�ǡ���X2[#{name_e_count}]",
		       bf.get_pos(), 4 * data_x2_nr, data_x2_nr, 4)
      bf.refill(4 * data_x2_nr)
      t = bf.floata(data_x2_nr)
      @data << ['�ǡ���X2']
      data_x2_nr.times do |i|
	@data << [nil, i, t[i]]
      end
    end

    # �ǡ���X3
    data_x3_size = name_y_pos - bf.get_pos()
    @sz << Range.new('�ǡ���X3', bf.get_pos(), data_x3_size, data_x3_size, 1)

    # ̾���ꥹ��Y
    bf.refill(12, name_y_pos)
    name_y_nr = bf.int()
    name_y_xxx = bf.int()
    name_y_size = bf.int()
    @info << ['̾���ꥹ��Y']
    @info << [nil, '�Ŀ�', name_y_nr]
    @info << [nil, '????', name_y_xxx, tohex(name_y_xxx)]
    @info << [nil, '������', name_y_size, tohex(name_y_size)]
    bf.refill(name_y_size)
    slist = bf.string(name_y_size).split("\0")
    @sz << Range.new('̾���ꥹ��Y', name_y_pos, 12 + name_y_size, \
		    12 + name_y_size, 1)
    @info << ['̾���ꥹ��Y']
    slist.each_index do |i|
      @info << [nil, i, slist[i]]
    end

    # �ǡ���Z
    data_z_size = File.size(path) - bf.get_pos()
    @sz << Range.new('�ǡ���Z', bf.get_pos(), data_z_size, data_z_size, 1)
  end

  def print_summary()
    printf "%-12s,%6s,%6s,%6s,%6s,%6s,%6s,%6s\n",\
    '#', '����', '��λ', '�ΰ�Ĺ', '����', '��λ', '������', '�Ŀ�'
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
