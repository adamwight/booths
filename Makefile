.PHONY: \
	all \
	changelog \
	clean \
	cmake \
	compile \
	deb \
	gettext \
	gettext_compile \
	gettext_extract \
	install \
	release

# All work is done under the build/ subdirectory.
OBJDIR=build

all: cmake compile gettext_compile

# TODO: Move path cruft to debian/rules.
cmake:
	mkdir -p build
	cd build && cmake \
		-D CMAKE_INSTALL_PREFIX=/usr \
		-D OpenCV_DIR=/usr/share/OpenCV ..

compile:
	make -C build

clean:
	rm -rf build debian/photo-booth

# TODO: Build the upstream changelog, deb, tag and upload.
#release: changelog deb

changelog:
	git2cl > debian/upstream.changelog

deb: clean
	dpkg-source -b .
	debuild

PO_FILES := $(wildcard locale/*/LC_MESSAGES/photo-booth.po)
MO_FILES := $(addprefix $(OBJDIR)/, $(PO_FILES:.po=.mo))

# FIXME: Source paths and version number should come from cmake.
SOURCES := $(wildcard *.cc) $(wildcard *.hpp)
gettext_extract: locale/photo-booth.pot
locale/photo-booth.pot: $(SOURCES)
	xgettext -k_ \
		--copyright-holder="Adam Roses Wight <adamw@ludd.net>" \
		--package-name="photo-booth" \
		--package-version="1.0.0" \
		--msgid-bugs-address=adamw@ludd.net \
		--language=C++ \
		-o photo-booth.po \
		$(SOURCES)
	mkdir -p locale
	# Backwards merge to update the template.
	msgmerge --update locale/photo-booth.pot photo-booth.po

# Keep up to date.
%.po: locale/photo-booth.pot
	msgmerge --update --backup=off $@ $<

gettext_update: $(PO_FILES)

# Compile into a binary.
$(OBJDIR)/%.mo: %.po
	[ -d `dirname $@` ] || mkdir -p `dirname $@`
	msgfmt --use-fuzzy $< -o $@

gettext_compile: $(MO_FILES)

gettext: gettext_extract gettext_update gettext_compile

install:
	make -C build install/strip
