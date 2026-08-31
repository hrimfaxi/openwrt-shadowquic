include $(TOPDIR)/rules.mk

PKG_NAME:=shadowquic
PKG_VERSION:=0.3.13
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/spongebob888/shadowquic.git
PKG_SOURCE_VERSION:=HEAD

PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE

include $(INCLUDE_DIR)/package.mk

ifeq ($(ARCH),aarch64)
  RUST_TARGET:=aarch64-unknown-linux-musl
else ifeq ($(ARCH),x86_64)
  RUST_TARGET:=x86_64-unknown-linux-musl
else ifeq ($(ARCH),mips)
  RUST_TARGET:=mips-unknown-linux-musl
else ifeq ($(ARCH),mipsel)
  RUST_TARGET:=mipsel-unknown-linux-musl
else ifeq ($(ARCH),arm)
  ifneq ($(findstring v7,$(CPU_TYPE)),)
    RUST_TARGET:=armv7-unknown-linux-musleabihf
  else
    RUST_TARGET:=arm-unknown-linux-musleabi
  endif
else
  RUST_TARGET:=$(ARCH)-unknown-linux-musl
endif

CARGO_TARGET_ENV:=CARGO_TARGET_$(shell echo $(RUST_TARGET) | tr 'a-z-' 'A-Z_')_LINKER

define Package/shadowquic
  SECTION:=net
  CATEGORY:=Network
  TITLE:=ShadowQUIC - A 0-RTT QUIC proxy with SNI camouflage
  URL:=https://github.com/spongebob888/shadowquic
  DEPENDS:=+libpthread
endef

define Package/shadowquic/description
  A 0-RTT QUIC proxy with SNI camouflage, UDP friendly,
  full cone NAT support, and user management.
endef

define Package/shadowquic/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || /etc/init.d/shadowquic enable
exit 0
endef

define Build/Configure
	$(call Build/Configure/Default)
	mkdir -p $(PKG_BUILD_DIR)/.cargo
	printf '[target.$(RUST_TARGET)]\nlinker = "$(TARGET_CC)"\n' > $(PKG_BUILD_DIR)/.cargo/config.toml
endef

define Build/Compile
	cd $(PKG_BUILD_DIR) && \
	CARGO_HOME=$(PKG_BUILD_DIR)/.cargo_home \
	CARGO_TARGET_DIR=$(PKG_BUILD_DIR)/target \
	TARGET_CC=$(TARGET_CC) \
	TARGET_CXX=$(TARGET_CXX) \
	TARGET_AR=$(TARGET_AR) \
	$(CARGO_TARGET_ENV)=$(TARGET_CC) \
	cargo build --release --target $(RUST_TARGET)
endef

define Package/shadowquic/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/target/$(RUST_TARGET)/release/shadowquic $(1)/usr/bin/

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./contrib/etc/config/shadowquic $(1)/etc/config/

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./contrib/etc/init.d/shadowquic $(1)/etc/init.d/

	$(INSTALL_DIR) $(1)/etc/capabilities
	$(INSTALL_DATA) ./contrib/etc/capabilities/shadowquic.json $(1)/etc/capabilities/
endef

$(eval $(call BuildPackage,shadowquic))
