#!/usr/bin/env ruby
# キャラクタを選択して、移動・方向転換・全エモーションをさせる。
# 装備とキャラクタはあらかじめ定義しておく。
# "sit"モーションを行なうには、adv_presetdata.csvの改造が必要。

require 'libdrama.rb'
require 'libcommon.rb'

CHAR_DATA = [
  # アバター
  ["女性アバタM", "1002011", "10600010,10700010"],
  # ドラマ用?
  ["朝倉音姫", "2012011", "10600010,10700010"],
  ["朝倉由夢", "2012021", "10600010,10700010"],
  ["白河ななか", "2012031", "10600010,10700010"],
  ["古河渚", "2022011", "10600010,10700010"],
  ["藤林杏", "2022021", "10600010,10700010"],
  ["坂上智代", "2022031", "10600010,10700010"],
  ["リシアンサス", "2032011", "10600010,10700010"],
  ["ネリネ", "2032021", "10600010,10700010"],
  ["芙蓉楓", "2032031", "10600010,10700010"],
  # 非原作系NPC
  ["女性1", "3002021", "10600010,10700010"],
  ["女性2", "3002031", "10600010,10700010"],
  ["女性3", "3002041", "10600010,10700010"],
  ["女性4", "3002051", "10600010,10700010"],
  ["女性5", "3002061", "10600010,10700010"],
  ["女性6", "3002071", "10600010,10700010"],
  ["女性7", "3002081", "10600010,10700010"],
  # 原作系NPC
  ["朝倉音姫", "3012011", "10600010,10700010"],
  ["朝倉由夢", "3012021", "10600010,10700010"],
  ["白河ななか", "3012031", "10600010,10700010"],
  ["雪村杏", "3012041", "10600010,10700010"],
  ["月島小恋", "3012051", "10600010,10700010"],
  ["古河渚", "3022011", "10600010,10700010"],
  ["藤林杏", "3022021", "10600010,10700010"],
  ["坂上智代", "3022031", "10600010,10700010"],
  ["伊吹風子", "3022041", "10600010,10700010"],
  ["一ノ瀬ことみ", "3022051", "10600010,10700010"],
  ["リシアンサス", "3032011", "10600010,10700010"],
  ["ネリネ", "3032021", "10600010,10700010"],
  ["芙蓉楓", "3032031", "10600010,10700010"],
  ["プリムラ", "3032041", "10600010,10700010"],
  ["時雨亜沙", "3032051", "10600010,10700010"],
  # 外神田ジュエルス
  ["燐", "3992010", "10600010,10700010"],
  ["蛍", "3992020", "10600010,10700010"],
  ["真珠", "3992030", "10600010,10700010"],
  # アバター
  ["男性アバタM", "1001011", ""],
  # 非原作系NPC
  ["男性0", "3001011", ""],
  ["男性1", "3001021", ""],
  ["男性2", "3001031", ""],
  ["男性3", "3001041", ""],
  ["男性4", "3001051", ""],
  ["男性5", "3001061", ""],
  ["ニワンゴ", "4000011", ""],
  ["南極さくら", "4010011", ""],
]

EMOTION_LIST = [
  ["座る", "sit"],
  ["うなずく", "nob"],
  ["首を横に振る", "no"],
  ["転ぶ", "tumble"],
  ["ガッツポーズ", "joy"],
  ["指を指す", "signifier"],
  ["手を振る", "bye"],
  ["話す", "speak"],
  ["恥ずかしがる", "sheepish"],
  ["照れる", "bashful"],
  ["がっかりする", "disappoint"],
  ["慌てる", "fluster"],
  ["キョロキョロする", "survey"],
  ["頭を抱える", "loath"],
  ["嬉しい", "happy"],
  ["悲しい", "sad"],
  ["泣く", "cry"],
  ["ねだる", "cadge"],
  ["驚く", "urprised"],
  ["拍手", "clap"],
  ["ピース", "peace"],
  ["迷う", "dither"],
  ["両手を広げる", "openarms"],
  ["考え事", "think"],
  ["威張る", "swagger"],
  ["内緒", "secret"],
  ["約束", "promise"],
  ["ウェイトモーション", "wait1"],
  ["ウェイトモーション2", "wait2"],
  ["ウェイトモーション3", "wait3"],
]

#----------------------------------------------------------------------

NR_CHARS = CHAR_DATA.length

def generate_data
  print "[ACTOR]\n"
  (0...NR_CHARS).each do |i|
    x = CHAR_DATA[i]
    print "#{i},#{x[0]},doll,#{x[1]},0,0,#{x[2]}\n"
  end
end

#----------------------------------------------------------------------

NAVI_MG = -1
CHAR_MG = 0
CAM_MG = 1
MOVE_MG = 2
DIR_MG = 3
EMO_MG = 4

def get_state(cat, charNr, menuitem = 0)
  return ((cat * 100) + charNr) * 100 + menuitem
end

def drama_move_around(charId, type)
  Drama.move(charId, "left", type)
  Drama.cwait(charId, "all")
  Drama.mwait(200)
  Drama.move(charId, "right", type)
  Drama.cwait(charId, "all")
  Drama.mwait(200)
  Drama.move(charId, "center", type)
  Drama.cwait(charId, "all")
  Drama.char(charId, "center", "front")
end

def generate_drama
  Drama.page_header('SceneSetting')
  Drama.comment('$RCSfile: test_char2.rb,v $, $Revision: 1.7 $')
  Drama.indent do
    Drama.map(CONFIG_MAP, 'day')
    Drama.cam(CONFIG_MAP, CONFIG_CAM)
    Drama.char(0, 'center', 'front')
    Drama.transit_fsm_state(get_state(NAVI_MG, 0))
    Drama.goto('MainPage')
  end
  Drama.page_footer

  Drama.page_header('MainPage')
  Drama.begin_fsm_block

  # ナビ
  (0 ... NR_CHARS).each do |charNr|
    menu_list = ["キャラクタ選択", "カメラ位置選択", "移動", "方向選択", "エモーション", "メッセージ枠消去"]
    Drama.selection_menu("キャラ#{charNr}のナビ",
			 get_state(NAVI_MG, charNr),
			 menu_list) do |minfo|
      case minfo.selection
      when CHAR_MG
	Drama.transit_fsm_state(get_state(CHAR_MG, 0, charNr))
      when CAM_MG .. EMO_MG
	Drama.transit_fsm_state(get_state(minfo.selection, charNr))
      when EMO_MG + 1
	Drama.close_msg
	Drama.mwait(5000)
      end
    end
  end

  # キャラクタ選択
  menu_list = CHAR_DATA.map {|x| x[0]}
  Drama.spinner_menu("キャラクタ選択",
		     get_state(CHAR_MG, 0),
		     menu_list) do |minfo|
    case minfo.event_type
    when Drama::ENTRY
      Drama.char(minfo.selection, "center", "front")
    when Drama::EXIT
      Drama.exit(minfo.selection)
    when Drama::RETURN
      Drama.char(minfo.selection, "center", "front")
      Drama.transit_fsm_state(get_state(NAVI_MG, minfo.selection))
    end
  end

  # カメラ位置選択
  menu_list = [
    "z40", "z80", "z120", "z160",
    "↑元のメニューに戻る",
  ]
  (0 ... NR_CHARS).each do |charNr|
    Drama.selection_menu("キャラクタ#{charNr}のカメラ位置選択",
			 get_state(CAM_MG, charNr),
			 menu_list) do |minfo|
      case minfo.selection
      when 0 .. menu_list.length - 2
	Drama.cam(CONFIG_MAP, menu_list[minfo.selection])
      when menu_list.length - 1
	Drama.transit_fsm_state(get_state(NAVI_MG, charNr))
      end
    end
  end

  # 移動
  menu_list = [
    "移動: 歩く",
    "移動: 走る",
    "↑元のメニューに戻る",
  ]
  (0 ... NR_CHARS).each do |charNr|
    Drama.selection_menu("キャラクタ#{charNr}の移動メニュー",
			 get_state(MOVE_MG, charNr),
			 menu_list) do |minfo|
      case minfo.selection
      when 0
	drama_move_around(charNr, "walk")
      when 1
	drama_move_around(charNr, "run")
      when 2
	Drama.transit_fsm_state(get_state(NAVI_MG, charNr, MOVE_MG))
      end
    end
  end

  # 方向
  menu_list = [
    "方向変換: 左向き",
    "方向変換: 後ろ向き",
    "方向変換: 右向き",
    "方向変換: 正面",
    "↑元のメニューに戻る",
  ]
  dir_list = %w[right back left front]
  (0 ... NR_CHARS).each do |charNr|
    Drama.selection_menu("キャラクタ#{charNr}の方向変換メニュー",
			 get_state(DIR_MG, charNr),
			 menu_list) do |minfo|
      if minfo.selection < 4
	Drama.char(charNr, "center", dir_list[minfo.selection])
      else
	Drama.transit_fsm_state(get_state(NAVI_MG, charNr, DIR_MG))
      end
    end
  end

  # エモーション
  menu_list = EMOTION_LIST.map do |x|
    "エモーション[#{x[0]}:#{x[1]}]"
  end + ["↑元のメニューに戻る"]
  (0 ... NR_CHARS).each do |charNr|
    Drama.selection_menu("キャラクタ#{charNr}のエモーションメニュー",
			 get_state(EMO_MG, charNr),
			 menu_list) do |minfo|
      if minfo.selection == 0
	Drama.emotion(charNr, EMOTION_LIST[minfo.selection][1])
	Drama.mwait(4000)
      elsif minfo.selection < EMOTION_LIST.length
	Drama.emotion(charNr, EMOTION_LIST[minfo.selection][1])
	Drama.wait_emotion(charNr)
      else
	Drama.transit_fsm_state(get_state(NAVI_MG, charNr, EMO_MG))
      end
    end
  end

  Drama.catch_all do
    Drama.amsg("FSM異常", "エラー")
  end

  Drama.end_fsm_block

  Drama.page_footer
end

if ARGV[0] == "-data"
  generate_data
else
  generate_drama
end
