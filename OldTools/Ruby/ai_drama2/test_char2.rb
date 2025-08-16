#!/usr/bin/env ruby
# ����饯�������򤷤ơ���ư������ž���������⡼�����򤵤��롣
# �����ȥ���饯���Ϥ��餫����������Ƥ�����
# "sit"�⡼������Ԥʤ��ˤϡ�adv_presetdata.csv�β�¤��ɬ�ס�

require 'libdrama.rb'
require 'libcommon.rb'

CHAR_DATA = [
  # ���Х���
  ["�������Х�M", "1002011", "10600010,10700010"],
  # �ɥ����?
  ["ī�Ҳ�ɱ", "2012011", "10600010,10700010"],
  ["ī��ͳ̴", "2012021", "10600010,10700010"],
  ["��Ϥʤʤ�", "2012031", "10600010,10700010"],
  ["�ŲϽ�", "2022011", "10600010,10700010"],
  ["ƣ�Ӱ�", "2022021", "10600010,10700010"],
  ["�������", "2022031", "10600010,10700010"],
  ["�ꥷ���󥵥�", "2032011", "10600010,10700010"],
  ["�ͥ��", "2032021", "10600010,10700010"],
  ["������", "2032031", "10600010,10700010"],
  # �󸶺��NPC
  ["����1", "3002021", "10600010,10700010"],
  ["����2", "3002031", "10600010,10700010"],
  ["����3", "3002041", "10600010,10700010"],
  ["����4", "3002051", "10600010,10700010"],
  ["����5", "3002061", "10600010,10700010"],
  ["����6", "3002071", "10600010,10700010"],
  ["����7", "3002081", "10600010,10700010"],
  # �����NPC
  ["ī�Ҳ�ɱ", "3012011", "10600010,10700010"],
  ["ī��ͳ̴", "3012021", "10600010,10700010"],
  ["��Ϥʤʤ�", "3012031", "10600010,10700010"],
  ["��¼��", "3012041", "10600010,10700010"],
  ["���羮��", "3012051", "10600010,10700010"],
  ["�ŲϽ�", "3022011", "10600010,10700010"],
  ["ƣ�Ӱ�", "3022021", "10600010,10700010"],
  ["�������", "3022031", "10600010,10700010"],
  ["�˿�����", "3022041", "10600010,10700010"],
  ["��������Ȥ�", "3022051", "10600010,10700010"],
  ["�ꥷ���󥵥�", "3032011", "10600010,10700010"],
  ["�ͥ��", "3032021", "10600010,10700010"],
  ["������", "3032031", "10600010,10700010"],
  ["�ץ���", "3032041", "10600010,10700010"],
  ["��������", "3032051", "10600010,10700010"],
  # �����ĥ��奨�륹
  ["��", "3992010", "10600010,10700010"],
  ["��", "3992020", "10600010,10700010"],
  ["����", "3992030", "10600010,10700010"],
  # ���Х���
  ["�������Х�M", "1001011", ""],
  # �󸶺��NPC
  ["����0", "3001011", ""],
  ["����1", "3001021", ""],
  ["����2", "3001031", ""],
  ["����3", "3001041", ""],
  ["����4", "3001051", ""],
  ["����5", "3001061", ""],
  ["�˥��", "4000011", ""],
  ["��ˤ�����", "4010011", ""],
]

EMOTION_LIST = [
  ["�¤�", "sit"],
  ["���ʤ���", "nob"],
  ["��򲣤˿���", "no"],
  ["ž��", "tumble"],
  ["���åĥݡ���", "joy"],
  ["�ؤ�ؤ�", "signifier"],
  ["��򿶤�", "bye"],
  ["�ä�", "speak"],
  ["�Ѥ���������", "sheepish"],
  ["�Ȥ��", "bashful"],
  ["���ä��ꤹ��", "disappoint"],
  ["���Ƥ�", "fluster"],
  ["����������", "survey"],
  ["Ƭ��������", "loath"],
  ["�򤷤�", "happy"],
  ["�ᤷ��", "sad"],
  ["�㤯", "cry"],
  ["�ͤ���", "cadge"],
  ["�ä�", "urprised"],
  ["���", "clap"],
  ["�ԡ���", "peace"],
  ["�¤�", "dither"],
  ["ξ��򹭤���", "openarms"],
  ["�ͤ���", "think"],
  ["��ĥ��", "swagger"],
  ["���", "secret"],
  ["��«", "promise"],
  ["�������ȥ⡼�����", "wait1"],
  ["�������ȥ⡼�����2", "wait2"],
  ["�������ȥ⡼�����3", "wait3"],
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

  # �ʥ�
  (0 ... NR_CHARS).each do |charNr|
    menu_list = ["����饯������", "������������", "��ư", "��������", "���⡼�����", "��å������Ⱦõ�"]
    Drama.selection_menu("�����#{charNr}�Υʥ�",
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

  # ����饯������
  menu_list = CHAR_DATA.map {|x| x[0]}
  Drama.spinner_menu("����饯������",
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

  # ������������
  menu_list = [
    "z40", "z80", "z120", "z160",
    "�����Υ�˥塼�����",
  ]
  (0 ... NR_CHARS).each do |charNr|
    Drama.selection_menu("����饯��#{charNr}�Υ�����������",
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

  # ��ư
  menu_list = [
    "��ư: �⤯",
    "��ư: ����",
    "�����Υ�˥塼�����",
  ]
  (0 ... NR_CHARS).each do |charNr|
    Drama.selection_menu("����饯��#{charNr}�ΰ�ư��˥塼",
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

  # ����
  menu_list = [
    "�����Ѵ�: ������",
    "�����Ѵ�: ������",
    "�����Ѵ�: ������",
    "�����Ѵ�: ����",
    "�����Υ�˥塼�����",
  ]
  dir_list = %w[right back left front]
  (0 ... NR_CHARS).each do |charNr|
    Drama.selection_menu("����饯��#{charNr}�������Ѵ���˥塼",
			 get_state(DIR_MG, charNr),
			 menu_list) do |minfo|
      if minfo.selection < 4
	Drama.char(charNr, "center", dir_list[minfo.selection])
      else
	Drama.transit_fsm_state(get_state(NAVI_MG, charNr, DIR_MG))
      end
    end
  end

  # ���⡼�����
  menu_list = EMOTION_LIST.map do |x|
    "���⡼�����[#{x[0]}:#{x[1]}]"
  end + ["�����Υ�˥塼�����"]
  (0 ... NR_CHARS).each do |charNr|
    Drama.selection_menu("����饯��#{charNr}�Υ��⡼������˥塼",
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
