include $(top_srcdir)/build-aux/glib-tap.mk

AM_CFLAGS = -g $(LIBVANUBI_CFLAGS)
LDADD = $(VANUBI_LIBS) $(top_builddir)/libvanubi/libvanubi@PACKAGE_SUFFIX@.la
AM_CPPFLAGS = \
	-DG_LOG_DOMAIN=\"Vanubi\" \
	-I$(top_srcdir)	\
	-I$(top_srcdir)/libvanubi \
	$(NULL)
AM_VALAFLAGS = \
	--pkg vanubi \
	--vapidir $(top_srcdir)/libvanubi \
	$(NULL)

test_programs = \
	testbuffer 	\
	testcharset	\
	testfiles	\
	testindent	\
	testcomment	\
	testmarks	\
	testmatch	\
	testsearch	\
	testvade	\
	$(NULL)

testbuffer_SOURCES = testbuffer.vala
testcharset_SOURCES = testcharset.vala
testfiles_SOURCES = testfiles.vala
testindent_SOURCES = testindent.vala
testcomment_SOURCES = testcomment.vala
testmarks_SOURCES = testmarks.vala
testmatch_SOURCES = testmatch.vala
testsearch_SOURCES = testsearch.vala
testvade_SOURCES = testvade.vala