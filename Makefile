THEOS_PACKAGE_SCHEME ?= rootless
export THEOS ?= $(HOME)/theos

TARGET = iphone:clang:latest:18.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AlwaysShowEmojiKey
AlwaysShowEmojiKey_FILES = Tweak.xm
AlwaysShowEmojiKey_FRAMEWORKS = UIKit Foundation
AlwaysShowEmojiKey_CFLAGS = -fobjc-arc -Wall -Wextra -Wno-unused-parameter
AlwaysShowEmojiKey_LDFLAGS += -Wl,-segalign,4000

include $(THEOS_MAKE_PATH)/tweak.mk
