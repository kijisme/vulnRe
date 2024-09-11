CFLAGS=-g

all: degrade

degrade: degrade.c degrade.S
	$(CC) -o $@ $^ $(CFLAGS)

clean:
	rm -f degrade *~

.PHONY: clean
