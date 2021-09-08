CXXFLAGS=-O3 -g -Ilib/
LDFLAGS=-lpthread

all: amogus

%.o: %.cpp
	$(CXX) -c $(CXXFLAGS) $< -o $@

amogus: main.o Image.o
	$(CXX) $(LDFLAGS) -o $@ $^


.SECONDARY:
