#!/usr/bin/env ruby
# $Revision: 1.14 $
# ����饯���ȥ����ƥ���Ȥ߹�碌�����򤹤롣

require 'libdrama.rb'
require 'libcommon.rb'

ITEM_DATA = [
  ["�ʤ�", ""],

  ["�����ر��ܹ�", "10100000,10100260,10500050,10400000,12200060"],
  ["�����ر���°", "10100130,10200280,10500040,10400000,12200060"],
  ["����⹻    ", "10100010,10200000,10500040,10400000,12200060"],
  ["�С��٥ʳر�", "10100020,10200010,10500030,10400000,12200060"],

  ["���󥿰�����", "10000090,10100550,10300080,10400017,10500200"],
  ["���󥿰�����", "10000091,10100551,10300081,10400016,10500201"],

  ["���",	"10100080,10400070,10500210,12200010"],
  ["�ᥤ�ɹ�",	"10100120,10400090,10500330,11700120"],
  ["�Хˡ�������","10100420,10500130,11700051"],
  ["�ť��",	"10100640,10300100,10400080,10500240"],
  ["�����",	"10100641,10300101,10400081,10500250"],
  #["��������",	"10100650,10200330,10500230"],
  #["����Х��","10100651,10200331,10500231"],
  #["�ѥ󥯹�",	"10100660,10200350,10500280,11600080"],
  #["�ѥ���",	"10100661,10200351,10500281,11600081"],
  ["����ե���", "10100710,10500330,10700090,11500090,11700260"]
]

CHAR_DATA = [
  # ���Х���
  ["�������Х�M", "1002011"],
  # �ɥ����?
  ["ī�Ҳ�ɱ", "2012011"],
  ["ī��ͳ̴", "2012021"],
  ["��Ϥʤʤ�", "2012031"],
  ["�ŲϽ�", "2022011"],
  ["ƣ�Ӱ�", "2022021"],
  ["�������", "2022031"],
  ["�ꥷ���󥵥�", "2032011"],
  ["�ͥ��", "2032021"],
  ["������", "2032031"],
  # �󸶺��NPC
  ["����1", "3002021"],
  ["����2", "3002031"],
  ["����3", "3002041"],
  ["����4", "3002051"],
  ["����5", "3002061"],
  ["����6", "3002071"],
  ["����7", "3002081"],
  # �����NPC
  ["ī�Ҳ�ɱ", "3012011"],
  ["ī��ͳ̴", "3012021"],
  ["��Ϥʤʤ�", "3012031"],
  ["��¼��", "3012041"],
  ["���羮��", "3012051"],
  ["�ŲϽ�", "3022011"],
  ["ƣ�Ӱ�", "3022021"],
  ["�������", "3022031"],
  ["�˿�����", "3022041"],
  ["��������Ȥ�", "3022051"],
  ["�ꥷ���󥵥�", "3032011"],
  ["�ͥ��", "3032021"],
  ["������", "3032031"],
  ["�ץ���", "3032041"],
  ["��������", "3032051"],
  # �����ĥ��奨�륹
  ["��", "3992010"],
  ["��", "3992020"],
  ["����", "3992030"],
  # ���Х���
  ["�������Х�M", "1001011"],
  # �󸶺��NPC
  ["����0", "3001011"],
  ["����1", "3001021"],
  ["����2", "3001031"],
  ["����3", "3001041"],
  ["����4", "3001051"],
  ["����5", "3001061"],
  ["�˥��", "4000011"],
  ["��ˤ�����", "4010011"],
]

EMOTION_LIST = [
  ["�¤�", "sit"],	# ��¤�������Τ�ͭ��
  #["���ʤ���", "nob"],
  #["��򲣤˿���", "no"],
  ["ž��", "tumble"],
  #["���åĥݡ���", "joy"],
  #["�ؤ�ؤ�", "signifier"],
  #["��򿶤�", "bye"],
  #["�ä�", "speak"],
  #["�Ѥ���������", "sheepish"],
  #["�Ȥ��", "bashful"],
  #["���ä��ꤹ��", "disappoint"],
  #["���Ƥ�", "fluster"],
  #["����������", "survey"],
  #["Ƭ��������", "loath"],
  ["�򤷤�", "happy"],
  #["�ᤷ��", "sad"],
  #["�㤯", "cry"],
  ["�ͤ���", "cadge"],
  #["�ä�", "urprised"],
  #["���", "clap"],
  #["�ԡ���", "peace"],
  #["�¤�", "dither"],
  #["ξ��򹭤���", "openarms"],
  #["�ͤ���", "think"],
  #["��ĥ��", "swagger"],
  ["���", "secret"],
  #["��«", "promise"],
  ["�������ȥ⡼�����", "wait1"],
  ["�������ȥ⡼�����2", "wait2"],
  ["�������ȥ⡼�����3", "wait3"],
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

BACK_LINK = "�����Υ�˥塼�����"

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
  # ���⡼�����
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

  # ���
  menu_list = [
    "����ɽ��", "������ѹ�", "������ѹ�", "�����ѹ�",
    "���⡼�����", "��ư", "ɽ������"
  ]
  (0...NR_CHARS).each do |charNr|
    (0...NR_ITEMS).each do |itemNr|
      Drama.selection_menu("�����#{charNr}����#{itemNr}�Υʥ�",
                           get_state(NAVI_MG, charNr, itemNr),
                           menu_list) do |minfo|
        case minfo.selection
        when 0 # ����ɽ��
          x = CHAR_DATA[charNr]; y = ITEM_DATA[itemNr]
          s = "����� ��#{charNr} #{x[0]}(#{x[1]})<br>"
          s = s + "���� ��#{itemNr} #{y[0]}(#{y[1]})"
	  s.gsub!(/,/, ':')
          Drama.amsg(s)
          Drama.close_msg
        when 1 # �����
          Drama.transit_fsm_state(get_state(CHARSEL_MG, 0, itemNr, charNr))
        when 2 # �����
          Drama.transit_fsm_state(get_state(CAMSEL_MG, charNr, itemNr, 0))
        when 3 # ����
          Drama.transit_fsm_state(get_state(ITEMSEL_MG, charNr, 0, itemNr))
        when 4 # ���⡼�����
	  emotion_demo("#{charNr}x#{itemNr}")
        when 5 # ��ư
          drama_move_around("#{charNr}x#{itemNr}", 'walk')
        when 6 # ɽ������
          Drama.close_msg
          Drama.mwait(5000)
        end
      end
    end
  end

  # ����
  (0...NR_CHARS).each do |charNr|
    menu_list = (0...NR_ITEMS).map do |i|
      "������[#{i}:#{ITEM_DATA[i][0]}]���ѹ�)"
    end
    Drama.spinner_menu("�����#{charNr}�������ѹ�",
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

  # �����
  menu_list = [
    "z40", "z80", "z120", "z160",
    "�����Υ�˥塼�����",
  ]
  (0...NR_ITEMS).each do |itemNr|
    (0...NR_CHARS).each do |charNr|
      Drama.selection_menu("����饯��#{charNr},�����ƥ�#{itemNr}�Υ�����������",
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

  # �����
  (0...NR_ITEMS).each do |itemNr|
    menu_list = (0...NR_CHARS).map do |i|
      "������[#{i}:#{CHAR_DATA[i][0]}]���ѹ�"
    end
    Drama.spinner_menu("#{itemNr}�����������������ѹ�",
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
    Drama.amsg("FSM�۾�", "���顼")
  end

  Drama.end_fsm_block
  Drama.page_footer
end

if ARGV[0] == "-data"
  generate_data
else
  generate_drama
end
