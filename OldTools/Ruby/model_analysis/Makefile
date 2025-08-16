all: xref_vra parse_vra parse_dxg

xref_vra:
	ruby traverse_vra.rb ../../unpacked/item > 0_item_xref.txt
	ruby traverse_vra.rb ../../unpacked/chara > 0_chara_xref.txt

parse_vra:
	#ruby libvra.rb ../../unpacked/chara/2/02201/attr/202201_0_00_000.vra > 202201_0_00_000.vra.txt

parse_dxg:
	./parse_dxg4.rb -test

clean::
	rm -f *.dxg.txt *.dxg
	rm -f *.vra.txt
