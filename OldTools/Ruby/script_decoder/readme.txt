�X�N���v�g�f�R�[�_

�_�E�����[�h����ai����[�񂨂�уh���}�̃X�N���v�g�t�@�C����
�f�R�[�h����v���O�����ł��B

<�K�v�Ȃ���>
- Ruby
  http://www.ruby-lang.org/ja/ �Q�ƁB���܂�Â��Ɠ����Ȃ��͂��B
  �茳�ł�Cygwin��Ruby�œ���m�F���Ă܂��B
- �_�E�����[�h���Ă����X�N���v�g�t�@�C��
  ai_sp@ce\user\���[�U�ԍ�\1\dl\drama\�ȉ��ɂ���ai*.txt�t�@�C��������ł��B

<�g����>
1. �X�N���v�g�t�@�C������肵�܂�

2. �f�R�[�_���N�����܂��B��̓I�ɂ̓R�}���h���C������

ruby decoder.rb �X�N���v�g�t�@�C�� [...]

�̂悤�ɋN�����܂��B�X�N���v�g�t�@�C���͕����w��ł��܂��B

�f�R�[�h�����h���}�X�N���v�g��ai����[��X�N���v�g�́A
���̃t�@�C����".txt"�T�t�B�b�N�X��"_drama.txt", "_chara.txt", "_tune.txt"��
���ꂼ��u�����������̂ƂȂ�܂��B

��: ���Ƃ��Ƃ̃X�N���v�g�t�@�C����"foo\bar.txt"�������ꍇ�A
�h���}�X�N���v�g��"foo\bar_drama.txt"�ɁA
�L�����N�^��`�t�@�C����"foo\bar_chara.txt"�ɂ��ꂼ�ꐶ������܂��B
ai����[�񂾂����ꍇ��"foo\bar_tune.txt"�ł��B

<���̑�>
�f�t�H���g�ł͏o�͂��镶���R�[�h��EUC-JP�A���s�R�[�h��LF�ł��B
Windows�p(�����R�[�h��CP932�A���s�R�[�h��CR+LF)�ɕύX�������ꍇ�́A
�f�R�[�_�X�N���v�g�̐擪�t�߂����������Ă��������B

�ύX�O
	NKF_OPT = '-W16L --unix'	# UNIX�p
	#NKF_OPT = '-W16L --windows'	# Windows�p

�ύX��
	#NKF_OPT = '-W16L --unix'	# UNIX�p
	NKF_OPT = '-W16L --windows'	# Windows�p

�܂��Aai sp@ce���p�K�񂨂��ai sp@ce���앨���p�K��͈͓̔��Ŏg�p���Ă��������B
