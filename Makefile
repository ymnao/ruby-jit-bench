.PHONY: all bench stats hir full

all: bench stats

bench:
	ruby runner.rb

stats:
	ruby stats_compare.rb

hir:
	ruby hir_compare.rb

full: bench stats hir
