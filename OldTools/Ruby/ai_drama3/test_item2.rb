#!/usr/bin/env ruby
# $Revision: 1.14 $
# キャラクタとアイテムの組み合わせを選択する。

require 'libdrama.rb'
require 'libcommon.rb'

ITEM_DATA = [
  ["なし", ""],

  ["風見学園本校", "10100000,10100260,10500050,10400000,12200060"],
  ["風見学園付属", "10100130,10200280,10500040,10400000,12200060"],
  ["光坂高校    ", "10100010,10200000,10500040,10400000,12200060"],
  ["バーベナ学園", "10100020,10200010,10500030,10400000,12200060"],

  ["サンタ衣装赤", "10000090,10100550,10300080,10400017,10500200"],
  ["サンタ衣装白", "10000091,10100551,10300081,10400016,10500201"],

  ["巫女",	"10100080,10400070,10500210,12200010"],
  ["メイド黒",	"10100120,10400090,10500330,11700120"],
  ["バニーガール","10100420,10500130,11700051"],
  ["甘ロリ",	"10100640,10300100,10400080,10500240"],
  ["黒ロリ",	"10100641,10300101,10400081,10500250"],
  #["ヴァイス",	"10100650,10200330,10500230"],
  #["シュバルツ","10100651,10200331,10500231"],
  #["パンク黒",	"10100660,10200350,10500280,11600080"],
  #["パンク白",	"10100661,10200351,10500281,11600081"],
  ["喫茶フローラ", "10100710,10500330,10700090,11500090,11700260"]
]

CHAR_DATA = [
  # アバター
  ["女性アバタM", "1002011"],
  # ドラマ用?
  ["朝倉音姫", "2012011"],
  ["朝倉由夢", "2012021"],
  ["白河ななか", "2012031"],
  ["古河渚", "2022011"],
  ["藤林杏", "2022021"],
  ["坂上智代", "2022031"],
  ["リシアンサス", "2032011"],
  ["ネリネ", "2032021"],
  ["芙蓉楓", "2032031"],
  # 非原作系NPC
  ["女性1", "3002021"],
  ["女性2", "3002031"],
  ["女性3", "3002041"],
  ["女性4", "3002051"],
  ["女性5", "3002061"],
  ["女性6", "3002071"],
  ["女性7", "3002081"],
  # 原作系NPC
  ["朝倉音姫", "3012011"],
  ["朝倉由夢", "3012021"],
  ["白河ななか", "3012031"],
  ["雪村杏", "3012041"],
  ["月島小恋", "3012051"],
  ["古河渚", "3022011"],
  ["藤林杏", "3022021"],
  ["坂上智代", "3022031"],
  ["伊吹風子", "3022041"],
  ["一ノ瀬ことみ", "3022051"],
  ["リシアンサス", "3032011"],
  ["ネリネ", "3032021"],
  ["芙蓉楓", "3032031"],
  ["プリムラ", "3032041"],
  ["時雨亜沙", "3032051"],
  # 外神田ジュエルス
  ["燐", "3992010"],
  ["蛍", "3992020"],
  ["真珠", "3992030"],
  # アバター
  ["男性アバタM", "1001011"],
  # 非原作系NPC
  ["男性0", "3001011"],
  ["男性1", "3001021"],
  ["男性2", "3001031"],
  ["男性3", "3001041"],
  ["男性4", "3001051"],
  ["男性5", "3001061"],
  ["ニワンゴ", "4000011"],
  ["南極さくら", "4010011"],
]

EMOTION_LIST = [
  ["座る", "sit"],	# 改造した場合のみ有効
  #["うなずく", "nob"],
  #["首を横に振る", "no"],
  ["転ぶ", "tumble"],
  #["ガッツポーズ", "joy"],
  #["指を指す", "signifier"],
  #["手を振る", "bye"],
  #["話す", "speak"],
  #["恥ずかしがる", "sheepish"],
  #["照れる", "bashful"],
  #["がっかりする", "disappoint"],
  #["慌てる", "fluster"],
  #["キョロキョロする", "survey"],
  #["頭を抱える", "loath"],
  ["嬉しい", "happy"],
  #["悲しい", "sad"],
  #["泣く", "cry"],
  ["ねだる", "cadge"],
  #["驚く", "urprised"],
  #["拍手", "clap"],
  #["ピース", "peace"],
  #["迷う", "dither"],
  #["両手を広げる", "openarms"],
  #["考え事", "think"],
  #["威張る", "swagger"],
  ["内緒", "secret"],
  #["約束", "promise"],
  ["ウェイトモーション", "wait1"],
  ["ウェイトモーション2", "wait2"],
  ["ウェイトモーション3", "wait3"],
]

#----------------------------------------------------------------------

NR_CHARS = CHAR_DATA.length
NR_ITEMS = ITEM_DATA.length
NR_EMOTIONS = EMOTION_LIST.length

def generate_data
  print "[ACTOR]\n"
  print "# $Revision: 1.14 $\n"
  (0...NR_CHARS).each do |i|
    ch = CHAR_DATA[i]
    (0...NR_ITEMS).each do |j|
      item = ITEM_DATA[j]
      print "#{i}x#{j},#{ch[0]}+#{item[0]},doll,#{ch[1]},0,0,#{item[1]}\n"
    end
  end
end

#----------------------------------------------------------------------

NAVI_MG = 0
CHARSEL_MG = 1
CAMSEL_MG = 2
ITEMSEL_MG = 3
EMOSEL_MG = 4

BACK_LINK = "↑元のメニューに戻る"

# state :=
#  [NAVI_MG,    charNr, itemNr, menuitem=...]
#  [CHARSEL_MG, 0,      itemNr, menuitem=charNr]
#  [CAMSEL_MG,  charNr, itemNr, menuitem=cam]
#  [ITEMSEL_MG, charNr, 0,      menuitem=itemNr]
def get_state(cat, char, item, menuitem = 0)
  return ((cat * 100 + char) * 100 + item) * 100 + menuitem
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

def emotion_demo(charId)
  # エモーション
  EMOTION_LIST.each do |e|
    case e[1]
    when 'sit'
      Drama.emotion(charId, e[1])
      Drama.mwait(4000)
    else
      Drama.emotion(charId, e[1])
      Drama.wait_emotion(charId)
    end
    Drama.mwait(300)
  end
end

def generate_drama
  Drama.page_header('SceneSetting')
  Drama.comment('$RCSfile: test_item2.rb,v $, $Revision: 1.14 $')
  Drama.indent do
    Drama.map(CONFIG_MAP, 'day')
    Drama.cam(CONFIG_MAP, CONFIG_CAM)
    Drama.char('0x0', 'center', 'front')
    Drama.transit_fsm_state(get_state(NAVI_MG, 0, 0))
    Drama.goto('MainPage')
  end
  Drama.page_footer

  Drama.page_header('MainPage')
  Drama.begin_fsm_block

  # 総合
  menu_list = [
    "状態表示", "キャラ変更", "カメラ変更", "装備変更",
    "エモーション", "移動", "表示隠す"
  ]
  (0...NR_CHARS).each do |charNr|
    (0...NR_ITEMS).each do |itemNr|
      Drama.selection_menu("キャラ#{charNr}装備#{itemNr}のナビ",
                           get_state(NAVI_MG, charNr, itemNr),
                           menu_list) do |minfo|
        case minfo.selection
        when 0 # 状態表示
          x = CHAR_DATA[charNr]; y = ITEM_DATA[itemNr]
          s = "キャラ ＃#{charNr} #{x[0]}(#{x[1]})<br>"
          s = s + "装備 ＃#{itemNr} #{y[0]}(#{y[1]})"
	  s.gsub!(/,/, ':')
          Drama.amsg(s)
          Drama.close_msg
        when 1 # キャラ
          Drama.transit_fsm_state(get_state(CHARSEL_MG, 0, itemNr, charNr))
        when 2 # カメラ
          Drama.transit_fsm_state(get_state(CAMSEL_MG, charNr, itemNr, 0))
        when 3 # 装備
          Drama.transit_fsm_state(get_state(ITEMSEL_MG, charNr, 0, itemNr))
        when 4 # エモーション
	  emotion_demo("#{charNr}x#{itemNr}")
        when 5 # 移動
          drama_move_around("#{charNr}x#{itemNr}", 'walk')
        when 6 # 表示隠す
          Drama.close_msg
          Drama.mwait(5000)
        end
      end
    end
  end

  # 装備
  (0...NR_CHARS).each do |charNr|
    menu_list = (0...NR_ITEMS).map do |i|
      "装備を[#{i}:#{ITEM_DATA[i][0]}]に変更)"
    end
    Drama.spinner_menu("キャラ#{charNr}の装備変更",
                       get_state(ITEMSEL_MG, charNr, 0),
                       menu_list) do |minfo|
      case minfo.event_type
      when Drama::ENTRY
        Drama.char("#{charNr}x#{minfo.selection}", 'center', 'front')
      when Drama::EXIT
        Drama.exit("#{charNr}x#{minfo.selection}")
      when Drama::RETURN
        Drama.char("#{charNr}x#{minfo.selection}", 'center', 'front')
        Drama.transit_fsm_state(get_state(NAVI_MG, charNr, minfo.selection, ITEMSEL_MG))
      end
    end
  end

  # カメラ
  menu_list = [
    "z40", "z80", "z120", "z160",
    "↑元のメニューに戻る",
  ]
  (0...NR_ITEMS).each do |itemNr|
    (0...NR_CHARS).each do |charNr|
      Drama.selection_menu("キャラクタ#{charNr},アイテム#{itemNr}のカメラ位置選択",
			   get_state(CAMSEL_MG, charNr, itemNr, 0),
			   menu_list) do |minfo|
	case minfo.selection
	when 0 .. menu_list.length - 2
	  Drama.cam(CONFIG_MAP, menu_list[minfo.selection])
	when menu_list.length - 1
	  Drama.transit_fsm_state(get_state(NAVI_MG, charNr, itemNr, CAMSEL_MG))
	end
      end
    end
  end

  # キャラ
  (0...NR_ITEMS).each do |itemNr|
    menu_list = (0...NR_CHARS).map do |i|
      "キャラを[#{i}:#{CHAR_DATA[i][0]}]に変更"
    end
    Drama.spinner_menu("#{itemNr}を装備したキャラの変更",
                       get_state(CHARSEL_MG, 0, itemNr),
                       menu_list) do |minfo|
      case minfo.event_type
      when Drama::ENTRY
        Drama.char("#{minfo.selection}x#{itemNr}", 'center', 'front')
      when Drama::EXIT
        Drama.exit("#{minfo.selection}x#{itemNr}")
      when Drama::RETURN
        Drama.char("#{minfo.selection}x#{itemNr}", 'center', 'front')
        Drama.transit_fsm_state(get_state(NAVI_MG, minfo.selection, itemNr, CHARSEL_MG))
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
