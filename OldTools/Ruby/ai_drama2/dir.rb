#!/usr/bin/env ruby
# ������ɸ��yaw���ǧ���롣
# dirN�Ȥ����ץꥻ�å��ͤ�ɬ��(rewrite_adv_presets.rb����)

require 'libdrama.rb'

MAP_LIST = [
  "������������\\�����ر�",
  "����ʥ���\\����⹻",
  "����åե���\\�С��٥ʳر�",
]

def generate_data
  print "[ACTOR]\n"
end

NAVI_MG = 0
AXIS_MG = 1
DIR_MAX = 30

def get_state(cat, map, dir, menuitem = 0)
  return ((cat * 100 + map) * 100 + dir) * 10 + menuitem
end

def get_navi_state(menuitem = 0)
  return get_state(-1, 0, 0, menuitem)
end

def get_dir_state(map, dir, menuitem = 0)
  return get_state(0, map, dir, menuitem)
end

def generate_drama

  Drama.page_header('SceneSetting')
  Drama.comment('$RCSfile: dir.rb,v $, $Revision: 1.3 $')
  Drama.indent do
    # �ޥåץǡ����Ϥ�����ˤ����ɤ�ľ���Τǡ������ǤϷڤ��ޥåפ�����
    Drama.map('����¾\\���Х����ᥤ��', 'day')
    Drama.cam('����¾\\���Х����ᥤ��', 'z120')
    Drama.transit_fsm_state(get_navi_state())
    Drama.goto('MainPage')
  end
  Drama.page_footer

  Drama.page_header('MainPage')
  Drama.begin_fsm_block

  # �ʥ�
  nrStates = 0
  Drama.selection_menu("�ޥå�����",
		       get_navi_state(),
		       MAP_LIST.map{|x| x.sub(/\\/,'/')}) do |minfo|
    Drama.map(MAP_LIST[minfo.selection], 'day')
    Drama.cam(MAP_LIST[minfo.selection], 'dir15')
    Drama.transit_fsm_state(get_dir_state(minfo.selection, 15))
  end

  # ����
  MAP_LIST.each_index do |map_index|
    map = MAP_LIST[map_index]
    (0..DIR_MAX).each do |dir|
      rotr = (dir + 1 + DIR_MAX) % DIR_MAX
      rotl = (dir - 1 + DIR_MAX) % DIR_MAX
      menu_list = [
	"�������: #{dir}��#{rotr}",
	"�������: #{dir}��#{rotl}",
	"�ޥå���������"]

      Drama.selection_menu("#{map}/dir#{dir}",
			   get_dir_state(map_index, dir),
			   menu_list) do |minfo|
	    case minfo.selection
	    when 0 # ��
	      Drama.cam(map, "dir#{rotr}")
	      state = get_dir_state(map_index, rotr, minfo.selection)
	      Drama.transit_fsm_state(state)

	    when 1 # ��
	      Drama.cam(map, "dir#{rotl}")
	      state = get_dir_state(map_index, rotl, minfo.selection)
	      Drama.transit_fsm_state(state)

	    else 
	      Drama.transit_fsm_state(get_navi_state(map_index))
	    end
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
