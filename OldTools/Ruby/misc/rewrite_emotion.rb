#!/usr/bin/env ruby
# emotion.csvを書き換える
# 実行にはdata/chara/1.hedを展開しておく必要あり
#
# 使い方
#	% ruby rewrite_emotion.rb aisp_root_dir
# 
# 書き換える内容
# 
# 追加するプリセット

require 'nkf'
require 'fileutils'

#----------------------------------------------------------------------
MOTION_ID = 0
START_ANIM = 1
LOOP_ANIM = 2
LOOP_COUNT = 3
END_ANIM = 4
PARAM1 = 5
NAME = 6
CMD_PARAM = 7
MENU_NR = 8
ICON_ID = 9
ICON_SE = 10
CATEGORY = 11

def convert_existing(in_data)
  out_data = []
  in_data.length.times do |i|
    input = in_data[i]
    data = input.split(/,/)
    data << '' # 最後にカンマをつけるため

    # sitモーション
    if data[START_ANIM] == '16011'
      data[CMD_PARAM] = 'sit'
    end
    out_data << data.join(",")
  end
  return out_data
end

def add_extra(dir)
  pat = "#{dir}/../chara/1/00201/anim/*.MRB"
  #pat = "../../unpacked/chara/1/00201/anim/*.MRB" # debug
  alist = Dir::glob(pat).map do |x|
    x.sub!(/\.MRB$/, '')
    x.sub!(/^.*_/, '')
  end
  r = []
  alist.each do |x|
    r << "#{x},#{x},#{x},1,#{x},,#{x},#{x},,,,ACTION,"
  end
  return r
end

def convert(in_data, dir)
  out_data = convert_existing(in_data)
  out_data = out_data + add_extra(dir)
  return out_data
end

def main(dir)
  src = "#{dir}/emotion.csv.dist"
  dst = "#{dir}/emotion.csv"
  if !FileTest.exists?(src) && FileTest.exists?(dst)
    FileUtils.cp(dst, src, {:preserve => true})
  end

  ifp = open("#{dir}/emotion.csv.dist")
  ofp = open("#{dir}/emotion.csv", "wb")

  in_data = NKF.nkf('-S -e -d', ifp.read).split("\n")
  out_data = convert(in_data, dir)
  ofp.print NKF.nkf('-s -E -c', out_data.join("\n") + "\n")
  ofp.close
  ifp.close
end

main(ARGV[0])
