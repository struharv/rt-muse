lib_LIBRARIES = libdl.a
libdl_a_SOURCES = src/libdl/dl_syscalls.h src/libdl/dl_syscalls.c
libjobsignaler_a_CXXFLAGS = -O2

bin_PROGRAMS = application
applicationdir = src/application
application_SOURCES = src/application/rt-bench.c
application_HEADERS = src/libdl/dl_syscalls.h
application_LDADD = libdl.a -lpthread -lrt -lm
include_HEADERS = src/libdl/dl_syscalls.h
