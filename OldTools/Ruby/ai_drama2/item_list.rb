#!/usr/bin/env ruby
# ../../unpacked/settings/equipment.csv と
# ../codes/@items.csv からアイテムのリストを読み取り、
# それらの着せ替えを行なうドラマを作成する。
# adv_presetdata.csvにzNという位置が必要。

require 'nkf'
require 'libdrama.rb'
require 'libcommon.rb'

EQUIP_FILE = '../../unpacked/settings/equipment.csv'
ICON_DIR = '../../unpacked/item/icon'
DESC_FILE = '../codes/@items.csv'

CATEGORY = {
  # カテゴリコード => [説明, カメラ位置]
  100 => [ '帽子', 'z160' ],
  101 => [ 'トップス', 'z120' ],
  102 => [ 'ボトムス', 'z120' ],
  103 => [ '手袋', 'z120' ],
  104 => [ '靴下', 'z40' ],
  105 => [ '靴', 'z40' ],
  106 => [ 'ブラ', 'z120' ],
  107 => [ 'パンツ', 'z80' ],
  108 => [ '眼鏡', 'z160' ],
  109 => [ 'ウィッグ', 'z160' ],
  114 => [ 'アクセ/背中', 'z120' ],
  115 => [ 'アクセ/腕', 'z120' ],
  116 => [ 'アクセ/首', 'z160' ],
  117 => [ 'アクセ/頭', 'z160' ],
  118 => [ 'かぶり物', 'z160' ],
  122 => [ '持ち物', 'z120' ],
}

#CHARID = '1002011' # アバター
CHARID = '2022010' # 渚(ドラマ用キャラクタ)
#CHARID = '3001021' # NPC1 男性1(腰に手ポーズ)
#CHARID = '3992010' # 燐

def load_equip(file)
  r = []
  ifp = open(file)
  NKF.nkf('-S -e -d', ifp.read).split("\n").each do |line|
    if line =~ /^(\d+),/
      item = $1.to_i
      if item >= 10000000 && item <= 89999999
	r << item
      end
    end
  end
  ifp.close
  return r
end

def load_icon(dir)
  r = []
  Dir::entries(dir).each do |file|
    if file =~ /(.*).dds/
      r << $1.to_i
    end
  end
  return r
end

def load_desc(file)
  r = {}
  ifp = open(file)
  ifp.read.split("\n").each do |line|
    if line =~ /^(\d+),(.*)$/
      r[$1.to_i] = $2.gsub(/,/, ' ')
    end
  end
  ifp.close
  return r
end

EQUIP_LIST_0 = load_equip(EQUIP_FILE)
ICON_LIST = load_icon(ICON_DIR)
DESC_HASH = load_desc(DESC_FILE)
EQUIP_LIST = (EQUIP_LIST_0 | ICON_LIST | DESC_HASH.keys).sort

#----------------------------------------------------------------------
def generate_data
  print "[ACTOR]\n"
  EQUIP_LIST.each do |eq|
    print "#{eq},#{eq},doll,#{CHARID},0,0,#{eq}\n"
  end
end

NAVI_MG = 0
ITEMCAT_MG = 1

def get_state(cat, itemcat, menuitem = 0)
  return (cat * 1000 + itemcat) * 1000 + menuitem
end

def generate_drama
  Drama.page_header('SceneSetting')
  Drama.comment('$RCSfile: item_list.rb,v $, $Revision: 1.11 $')
  Drama.indent do
    Drama.map(CONFIG_MAP, 'day')
    Drama.cam(CONFIG_MAP, CONFIG_CAM)
    Drama.transit_fsm_state(get_state(NAVI_MG, 0))
    Drama.goto('MainPage')
  end
  Drama.page_footer

  Drama.page_header('MainPage')
  Drama.begin_fsm_block

  # ナビ
  cat_code_list = CATEGORY.keys.sort
  menu_list = cat_code_list.map {|i| "#{i}:#{CATEGORY[i][0]}"}
  Drama.selection_menu("ナビ",
                       get_state(NAVI_MG, 0),
                       menu_list) do |minfo|
    cat_index = minfo.selection
    Drama.cam(CONFIG_MAP, CATEGORY[cat_code_list[cat_index]][1])
    Drama.transit_fsm_state(get_state(ITEMCAT_MG, cat_index))
  end

  # アイテム(カテゴリごとに)
  cat_code_list.each_index do |cat_index|
    cat_code = cat_code_list[cat_index]

    item_list = EQUIP_LIST.clone
    item_list.delete_if {|item| (item / 100000).to_i != cat_code}

    menu_list = item_list.map do |item|
      if DESC_HASH.has_key?(item)
        "#{item}:#{DESC_HASH[item]}"
      else
        "#{item}:記述なし"
      end
    end

    Drama.spinner_menu("カテゴリ#{cat_code}:#{CATEGORY[cat_code][0]}",
		       get_state(ITEMCAT_MG, cat_index),
		       menu_list) do |minfo|
      case minfo.event_type
      when Drama::ENTRY
	Drama.char(item_list[minfo.selection], 'center', 'front')
      when Drama::EXIT
	Drama.exit(item_list[minfo.selection])
      when Drama::RETURN
	Drama.transit_fsm_state(get_state(NAVI_MG, 0, cat_index))
      end
    end
  end

  Drama.catch_all do
    Drama.amsg("FSM異常", "エラー")
  end

  Drama.end_fsm_block

  Drama.page_footer
end

#----------------------------------------------------------------------

if ARGV[0] == "-data"
  generate_data
else
  generate_drama
end
