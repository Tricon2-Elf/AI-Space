#!/usr/bin/env ruby
# adv_presetdata.csv��񤭴����������Υץꥻ�åȰ��֤�Ĵ��������
# �������ץꥻ�åȰ��֤��ɲä���
#
# �Ȥ���
#	% ruby rewrite_adv_presets.rb aisp_root_dir
# 
# �񤭴���������
#	- ��¸�ץꥻ�åȰ��֤�Ĵ�� (ADJUST_VALUE)
#	- ��¸�ޥåפ˿����ץꥻ�åȰ��֤��ɲ�
#	- �����ޥåפȿ����ץꥻ�åȰ��֤��ɲ� (EXTRA_MAPS)
#	  �ر�ʳ��Υ��ɤ���Ѳ�ǽ�ˤ���
# 
# �ɲä���ץꥻ�å�
#	- zN(�����ǹ⤵�Τ�Ĵ��)
#	- (xNyNdN(����å�), dirN, distN) �ѻ�

require 'nkf'
require 'fileutils'

# ��¸�ץꥻ�åȰ��֤��Ф���Ĵ����
ADJUST_VALUE = [
  # X, Z, Y
  0, 0, 0,
  # roll, dist, pitch, yaw
  0, 0, 0, 0,
]

# ��ɸ���ϰ� (�ǡ�����map.csv����)
PRESET_POS = {
  # map,      xsize, zsize, xcenter, zcenter
  # �ر�ޥå�
  '10010100' => [50400, 43200, 400, -6400],
  '10020100' => [50400, 33600, 22800, -2400],
  '10030100' => [36000, 26400, 10800, -1200],
  # ���𳹥ޥå�
  '10010400' => [50400, 43200, 400, -6400],
  '10020400' => [50400, 33600, 22800, -2400],
  '10030400' => [36000, 26400, 10800, -1200],
  #�����ϥХ�ޥåפˤĤ��Ƥϡ�zcenter���ͤ����������Τ��֤������Ƥ���
  #'10990100' => [21600, 14400, -10800, -19200],
  '10990100' => [21600, 14400, -10800, 0],
  #'10990200' => [24000, 28800, -9600, -8400],
  '10990200' => [24000, 28800, -9600, 0],
}

# �ɲä��뿷���ޥå�
EXTRA_MAPS = [
  ['10010200', '������������,��Ź��'], 
  ['10010300', '������������,�����رඵ��'], 
  ['10020200', '����ʥ���,��Ź��'], 
  ['10020300', '����ʥ���,����⹻����'], 
  ['10030200', '����åե���,��Ź��'], 
  ['10030300', '����åե���,�С��٥ʳرඵ��'], 
  ['10990100', '�����ϥХ���,�����ϥХ�'], 
  ['10990200', '�����ϥХ���,UDX'],
  ['20000000', '�ޥ��롼��,�ޥ��롼��(6��)'],
  ['20000010', '�ޥ��롼��,�ޥ��롼��(8��)'],
  ['20000020', '�ޥ��롼��,�ޥ��롼��(10��)'],
  ['20000030', '�ޥ��롼��,�ޥ��롼��(12.5��)'], 
  ['19001003', '����¾,���ơ���'], 
  ['19001004', '����¾,������'], 
  ['10900100', '����¾,���Х����ᥤ��'], 
  ['10900200', '����¾,�ż���'], 
  ['10990300', '����¾,�����ĥӥ���'],
  ['10990400', 'TPS,��ӡ�'],
  ['40990200', 'TPS,UDX'],
  ['90000000', '����¾,��ȿ�Գ�Υ����'],
]

DIR_DATA = [
  # dist, yaw
  [1.0, 0],	# �ޥåײ�
  [1.0, +2],	# �ޥåױ�
  [0.5, 0],	# �ޥå׾�
  [1.0, -2],	# �ޥå׺�
]

#----------------------------------------------------------------------

def format(label, x, y, z, roll, dist, pitch, yaw)
  return "#{label},#{label},#{x},#{z},#{y},#{roll},#{dist},#{pitch},#{yaw},"
end

# ����åɤˤ��äƥץꥻ�åȰ��֤����
def generate_grid(x0, x1, xstep, y0, y1, ystep, z)
  r = []

  (0 ... xstep).each do |ix|
    x = x0 + (x1 - x0) * ix / (xstep - 1)
    (0 ... ystep).each do |iy|
      y = y0 + (y1 - y0) * iy / (ystep - 1)
      DIR_DATA.each_index do |id|
        r << format("x#{ix}y#{iy}d#{id}", # label
		    x, y, z,
		    0, DIR_DATA[id][0], # roll, dist
		    0, DIR_DATA[id][1]) # pitch, yaw
      end
    end
  end
  return r
end

# �⤵�ˤ��äƥץꥻ�å��ͤ����
def generate_z(x, y, dist)
  r = []
  40.step(160, 40) do |z|
    r << format("z#{z}", x, y, z, 0, dist, 0, 0)
  end
  return r
end

def generate_yaw(x, y, z, dist)
  r = []
  (0..30).each do |d|
    yaw = (d - 15) * Math::PI / 15
    r << format("dir#{d}", x, y, z, 0, dist, 0, yaw)
  end
  return r
end

def generate_dist(x, y, z)
  r = []
  (0..30).each do |d|
    dist = 0.7 + d * 0.001
    r << format("dist#{d}", x, y, z, 0, dist, 0, 0)
  end
  return r
end

#----------------------------------------------------------------------

def add_new_presets(map)
  if PRESET_POS.has_key?(map)
    p = PRESET_POS[map]
    xc = p[2]; x0 = p[2] - p[0]/2; x1 = p[2] + p[0]/2
    yc = 0; y0 = -10000; y1 = +10000
    z = p[3] + p[1] / 4
  else
    # �Ȥꤢ����-1500��+1500���ϰϤˤ��Ƥߤ�
    xc = 0; x0 = -1500; x1 = +1500
    yc = 0; y0 = -1500; y1 = +1500
    z = 100
  end

  #r = generate_grid(x0, x1, 9, y0, y1, 9, z)
  #r = r + generate_z(xc, yc, 1)
  #r = r + generate_yaw(xc, yc, z, 1.0)
  #r = r + generate_dist(xc, yc, z)
  return generate_z(xc, yc, 1)
end

def adjust_pos(data)
  (0 .. 6).each do |i|
    data[2 + i] = data[2 + i].to_f + ADJUST_VALUE[i]
  end
  data[9] = ''
  return data
end

def convert_existing(in_data)
  out_data = []
  curr_map = nil

  (0 ... in_data.length).each do |i|
    input = in_data[i]

    # ��¸�ޥåפ˿��������֤��ɲ�
    if input =~ /^\[MAP(\d+)\]$/
      curr_map = $1
      out_data << "[MAP#{curr_map}]"
      out_data = out_data + add_new_presets(curr_map)
      out_data << "# �ʲ�������Υǡ���"
      next
    end

    # ��¸�ǡ����ν񤭴���
    data = input.split(/,/)
    if curr_map != nil && data.length > 8
      data = adjust_pos(data)
      out_data << data.join(',')
    else
      out_data << input
    end
  end
  return out_data
end

def add_extra_maps
  r = ['']
  EXTRA_MAPS.each_index do |map|
    r << "[MAP#{EXTRA_MAPS[map][0]}]"
    r << "# #{EXTRA_MAPS[map][1]}"
    r << add_new_presets(EXTRA_MAPS[map][0])
    r << ''
  end
  return r
end

def convert(in_data)
  out_data = convert_existing(in_data)
  out_data << add_extra_maps()
  return out_data
end

def main(dir)
  src = "#{dir}/adv_presetdata.csv.dist"
  dst = "#{dir}/adv_presetdata.csv"
  if !FileTest.exists?(src) && FileTest.exists?(dst)
    FileUtils.cp(dst, src, {:preserve => true})
  end

  ifp = open("#{dir}/adv_presetdata.csv.dist")
  ofp = open("#{dir}/adv_presetdata.csv", "wb")

  in_data = NKF.nkf('-W16L -e -d', ifp.read).split("\n")
  out_data = convert(in_data)
  ofp.print NKF.nkf('-w16L -E -c', out_data.join("\n"))
  #ofp.print NKF.nkf('-e -c', out_data.join("\n")) # �ƥ�����
  ofp.close
  ifp.close
end

main(ARGV[0])
