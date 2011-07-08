VALAC := valac
FLAGS :=
PKG := --pkg gio-2.0 --pkg gee-1.0
SRC := $(shell find 'src/' -type f -name "*.vala")
EXE := valatra

all: $(EXE)

$(EXE): $(SRC)
	$(VALAC) $(FLAGS) $(PKG) $(SRC) -o $(EXE)

debug:
	@$(MAKE) "FLAGS=$(FLAGS) -g"

genc:
	@$(MAKE) "FLAGS=$(FLAGS) -C"

clean:
	rm -f $(EXE) src/*.c src/*.o

.PHONY= all clean

