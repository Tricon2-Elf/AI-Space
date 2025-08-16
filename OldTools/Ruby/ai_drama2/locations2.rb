#!/usr/bin/env ruby

require 'libdrama.rb'

LOCATIONS = [
  [
    "�����ر�", "������������\\�����ر�",
    %w[������ ���¤ߣ� ���¤ߣ� ���磱 ���磲 ������ ���� ���� �Ƶ�ϧ �Х��������� �ΰ���� ΢�� �̳�ϩ�� �̳�ϩ�� �̳�ϩ�� ���� ���� �Х���]],
  [
    "����⹻", "����ʥ���\\����⹻",
    %w[�⹻���κ� ���磱 ���磲 ������ ���� �Х��������ȣ� �Х��������ȣ� �ƥ˥������� ���� �ΰ���� �ΰ��΢ʪ�� ���ؾ� ������(����) ����߾� ����(����) ����΢�ݥ�� ����(�Ǽ���) ������(�Ǽ���) ΢�� �⹻΢���� ���� �� ƻ �� ����]],
  [
    "�С��٥ʳر�", "����åե���\\�С��٥ʳر�",
    %w[���� ���� ʮ���� �ס��� �ƥ˥������� �ΰ��΢ʪ�� �ΰ��΢����߾� ���ؾ� �Х��� �ΰ���� �������� ����΢ ���˸����� ���߼Τƾ죱 ���߼Τƾ죲 �̳�ϩ�� �̳�ϩ�� ���𳹣� ���𳹣� �����ȥƥ���]],
  [
    "DC����", "������������\\����",
    %w[ī�Ҳȣ� ī�Ҳȣ� ˧ǵ�ȣ� ˧ǵ�ȣ�]],
  [
    "CL����", "����ʥ���\\����",
    %w[�Ųϥѥ� �Ųϥѥ� ����ȣ� ����ȣ�]],
  [
    "SH����", "����åե���\\����",
    %w[�����ȣ� �����ȣ� �Ⲧ�ȣ� �Ⲧ�ȣ� ���ֲȣ�]],
]


def generate_data
  # ��ʪ���о줷�ʤ�
  print "[ACTOR]\n"
end

def get_map_state(map)
  return 100000 + map * 100
end

def generate_drama
  Drama.page_header('SceneSetting')
  Drama.comment('$RCSfile: locations2.rb,v $, $Revision: 1.9 $')
  Drama.map(LOCATIONS[0][1], 'day')
  Drama.cam(LOCATIONS[0][1], LOCATIONS[0][2][0])
  Drama.goto('MainPage')
  Drama.page_footer

  Drama.page_header('MainPage')
  Drama.begin_fsm_block

  # ����˥塼
  menu_list = LOCATIONS.map {|x| x[0] }
  Drama.selection_menu("����˥塼", 0, menu_list) do |minfo|
    Drama.map(LOCATIONS[minfo.selection][1], 'day')
    Drama.transit_fsm_state(get_map_state(minfo.selection))
  end

  # �ޥåפ��ȤΥ�˥塼
  LOCATIONS.each_index do |loc|
    Drama.spinner_menu(LOCATIONS[loc][0],
                       get_map_state(loc),
                       LOCATIONS[loc][2]) do |minfo|
      case minfo.event_type
      when Drama::ENTRY
        Drama.cam(LOCATIONS[loc][1], LOCATIONS[loc][2][minfo.selection])
      when Drama::RETURN
        Drama.transit_fsm_state(loc)
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
