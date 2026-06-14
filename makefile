PREFIX = /usr/local

SRC := $(shell find src -name "*.d") \
	$(shell find libdparse/src -name "*.d")
IMPORTS := -Ilibdparse/src -Isrc -Jbin

DC ?= dmd
LDC ?= ldc2
GDC ?= gdc

DMD_COMMON_FLAGS := -w $(IMPORTS)
DMD_DEBUG_FLAGS := -debug -g $(DMD_COMMON_FLAGS)
DMD_FLAGS := -O -inline $(DMD_COMMON_FLAGS)
DMD_TEST_FLAGS := -unittest -g $(DMD_COMMON_FLAGS)
LDC_FLAGS := -g -w -oq $(IMPORTS)
GDC_FLAGS := -g -w -oq $(IMPORTS)
override DMD_FLAGS += $(DFLAGS)
override LDC_FLAGS += $(DFLAGS)
override GDC_FLAGS += $(DFLAGS)

.PHONY: all clean install debug dmd ldc gdc pkg release release-check test

all: bin/adfmt

bin/githash.txt:
	mkdir -p bin
	git describe --tags > bin/githash.txt

dmd: bin/adfmt

ldc: bin/githash.txt
	$(LDC) $(SRC) $(LDC_FLAGS) -ofbin/adfmt
	-rm -f *.o

gdc: bin/githash.txt
	$(GDC) $(SRC) $(GDC_FLAGS) -obin/adfmt

test: debug
	cd tests && ./test.d

bin/adfmt-test: bin/githash.txt $(SRC)
	$(DC) $(DMD_TEST_FLAGS) $(filter %.d,$^) -of$@

bin/adfmt: bin/githash.txt $(SRC)
	$(DC) $(DMD_FLAGS) $(filter %.d,$^) -of$@

debug: bin/githash.txt $(SRC)
	$(DC) $(DMD_DEBUG_FLAGS) $(filter %.d,$^) -ofbin/adfmt

pkg: dmd
	$(MAKE) -f makd/Makd.mak pkg

clean:
	$(RM) bin/adfmt bin/adfmt-test bin/githash.txt

install:
	chmod +x bin/adfmt
	mkdir -p $(DESTDIR)$(PREFIX)/bin
	cp -f bin/adfmt $(DESTDIR)$(PREFIX)/bin/adfmt

release:
	@test -n "$(VERSION)" || { echo "Usage: make release VERSION=0.3.6"; exit 2; }
	./release.sh publish "$(VERSION)"

release-check:
	@test -n "$(VERSION)" || { echo "Usage: make release-check VERSION=0.3.6"; exit 2; }
	./release.sh check "$(VERSION)"
