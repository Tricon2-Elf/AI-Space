#!/usr/bin/env ruby
# adv_presetdata.csvを書き換え、カメラのプリセット位置を調整したり
# 新しいプリセット位置を追加する
#
# 使い方
#	% ruby rewrite_adv_presets.rb aisp_root_dir
# 
# 書き換える内容
#	- 既存プリセット位置の調整 (ADJUST_VALUE)
#	- 既存マップに新規プリセット位置を追加
#	- 新規マップと新規プリセット位置を追加 (EXTRA_MAPS)
#	  学園以外のワールドを使用可能にする
# 
# 追加するプリセット
#	- zN(原点で高さのみ調整)
#	- (xNyNdN(グリッド), dirN, distN) 廃止

require 'nkf'
require 'fileutils'

# 既存プリセット位置に対する調整値
ADJUST_VALUE = [
  # X, Z, Y
  0, 0, 0,
  # roll, dist, pitch, yaw
  0, 0, 0, 0,
]

# 座標の範囲 (データはmap.csvから)
PRESET_POS = {
  # map,      xsize, zsize, xcenter, zcenter
  # 学園マップ
  '10010100' => [50400, 43200, 400, -6400],
  '10020100' => [50400, 33600, 22800, -2400],
  '10030100' => [36000, 26400, 10800, -1200],
  # 住宅街マップ
  '10010400' => [50400, 43200, 400, -6400],
  '10020400' => [50400, 33600, 22800, -2400],
  '10030400' => [36000, 26400, 10800, -1200],
  #アキハバラマップについては、zcenterの値がおかしいので置き換えている
  #'10990100' => [21600, 14400, -10800, -19200],
  '10990100' => [21600, 14400, -10800, 0],
  #'10990200' => [24000, 28800, -9600, -8400],
  '10990200' => [24000, 28800, -9600, 0],
}

# 追加する新規マップ
EXTRA_MAPS = [
  ['10010200', 'ダ・カーポ島,商店街'], 
  ['10010300', 'ダ・カーポ島,風見学園教室'], 
  ['10020200', 'クラナド島,商店街'], 
  ['10020300', 'クラナド島,光坂高校教室'], 
  ['10030200', 'シャッフル島,商店街'], 
  ['10030300', 'シャッフル島,バーベナ学園教室'], 
  ['10990100', 'アキハバラ島,アキハバラ'], 
  ['10990200', 'アキハバラ島,UDX'],
  ['20000000', 'マイルーム,マイルーム(6畳)'],
  ['20000010', 'マイルーム,マイルーム(8畳)'],
  ['20000020', 'マイルーム,マイルーム(10畳)'],
  ['20000030', 'マイルーム,マイルーム(12.5畳)'], 
  ['19001003', 'その他,ステージ'], 
  ['19001004', 'その他,撮影用'], 
  ['10900100', 'その他,アバターメイク'], 
  ['10900200', 'その他,電車内'], 
  ['10990300', 'その他,外神田ビル内'],
  ['10990400', 'TPS,ロビー'],
  ['40990200', 'TPS,UDX'],
  ['90000000', 'その他,違反者隔離部屋'],
]

DIR_DATA = [
  # dist, yaw
  [1.0, 0],	# マップ下
  [1.0, +2],	# マップ右
  [0.5, 0],	# マップ上
  [1.0, -2],	# マップ左
]

#----------------------------------------------------------------------

def format(label, x, y, z, roll, dist, pitch, yaw)
  return "#{label},#{label},#{x},#{z},#{y},#{roll},#{dist},#{pitch},#{yaw},"
end

# グリッドにそってプリセット位置を作成
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

# 高さにそってプリセット値を作成
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
    # とりあえず-1500〜+1500の範囲にしてみる
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

    # 既存マップに新しい位置を追加
    if input =~ /^\[MAP(\d+)\]$/
      curr_map = $1
      out_data << "[MAP#{curr_map}]"
      out_data = out_data + add_new_presets(curr_map)
      out_data << "# 以下、本来のデータ"
      next
    end

    # 既存データの書き換え
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
  #ofp.print NKF.nkf('-e -c', out_data.join("\n")) # テスト用
  ofp.close
  ifp.close
end

main(ARGV[0])
