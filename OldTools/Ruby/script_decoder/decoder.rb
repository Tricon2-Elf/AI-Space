#!/usr/bin/env ruby
# $Revision: 1.2 $

require 'nkf'
NKF_OPT = '-W16L --unix'	# UNIX用
#NKF_OPT = '-W16L --windows'	# Windows用

# スクランブルデータの周期
PERIOD = 20
# シグネチャの長さ
SIGNATURE_SIZE = 4

# スクランブルデータ
jammer = Array.new(20)

ARGV.each do |arg|
  # ベースファイル名を得る
  if arg =~ /^(.*)\.[^.]+$/
    basename = $1
  else
    basename = arg
  end

  # *.txtファイルを読み込み
  fd = open(arg);
  raw = fd.sysread(fd.stat.size)
  fd.close
  uu = raw.unpack('C*')

  # ヘッダ解析
  chardef_size = uu[12] | (uu[13] << 8) | (uu[14] << 16) | (uu[15] << 24)
  drama_size = uu[16] | (uu[17] << 8) | (uu[18] << 16) | (uu[19] << 24)
  header_size = uu[20] | (uu[21] << 8) | (uu[22] << 16) | (uu[23] << 24)

  header_start = SIGNATURE_SIZE
  chardef_start = header_start + header_size
  drama_start = chardef_start + chardef_size

  chardef_end = chardef_start + chardef_size - 4
  drama_end = drama_start + drama_size - 4

  # スクランブルデータを取得
  (0 ... PERIOD).each do |i|
    jammer[i] = uu[uu.length - PERIOD + i]
  end

  # ドラマかちゅーんか判定
  type = (chardef_size > 0) ? 'drama' : 'tune'

  # キャラクタ定義部を出力
  if type == 'drama'
    (chardef_start ... chardef_end).each do |pos|
      uu[pos] = (uu[pos] - jammer[(pos - chardef_start) % PERIOD]) & 0xff
    end
    out = open("#{basename}_chara.txt", "w")
    utf = uu[chardef_start, chardef_end - chardef_start].pack("C*")
    out.print NKF.nkf(NKF_OPT, utf)
    out.close
  end

  # ドラマ部を出力
  (drama_start ... drama_end).each do |pos|
    uu[pos] = (uu[pos] - jammer[(pos - drama_start) % PERIOD]) & 0xff
  end
  if type == 'drama'
    out = open("#{basename}_drama.txt", "w")
  else
    out = open("#{basename}_tune.txt", "w")
  end
  utf = uu[drama_start, drama_end - drama_start].pack("C*")
  out.print NKF.nkf(NKF_OPT, utf)
  out.close
end
