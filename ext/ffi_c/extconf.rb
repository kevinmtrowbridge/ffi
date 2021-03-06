#!/usr/bin/env ruby

if !defined?(RUBY_ENGINE) || RUBY_ENGINE == "ruby"
  require 'mkmf'
  require 'rbconfig'
  dir_config("ffi_c")

  if ENV['RUBY_CC_VERSION'].nil? && (pkg_config("libffi") ||
     have_header("ffi.h") ||
     find_header("ffi.h", "/usr/local/include"))

    # We need at least ffi_call and ffi_prep_closure
    libffi_ok = have_library("ffi", "ffi_call", [ "ffi.h" ]) ||
                have_library("libffi", "ffi_call", [ "ffi.h" ])
    libffi_ok &&= have_func("ffi_prep_closure")

    # Check if the raw api is available.
    $defs << "-DHAVE_RAW_API" if have_func("ffi_raw_call") && have_func("ffi_prep_raw_closure")
  end

  have_func('rb_thread_blocking_region')
  # Kevin says: Need a big hammer to fix Heroku ruby versions issue.
  # ... have a ticket filed with them.
  # have_func('ruby_thread_has_gvl_p') unless RUBY_VERSION >= "1.9.3"
  have_func('ruby_native_thread_p')
  have_func('rb_thread_call_with_gvl')

  $defs << "-DHAVE_EXTCONF_H" if $defs.empty? # needed so create_header works
  $defs << "-DUSE_INTERNAL_LIBFFI" unless libffi_ok
  $defs << "-DRUBY_1_9" if RUBY_VERSION >= "1.9.0"

  create_header

  $CFLAGS << " -mwin32 " if RbConfig::CONFIG['host_os'] =~ /cygwin/
  $LOCAL_LIBS << " ./libffi/.libs/libffi_convenience.lib" if RbConfig::CONFIG['host_os'] =~ /mswin/
  #$CFLAGS << " -Werror -Wunused -Wformat -Wimplicit -Wreturn-type "
  if (ENV['CC'] || RbConfig::MAKEFILE_CONFIG['CC'])  =~ /gcc/
#    $CFLAGS << " -Wno-declaration-after-statement "
  end

  create_makefile("ffi_c")
  unless libffi_ok
    File.open("Makefile", "a") do |mf|
      mf.puts "LIBFFI_HOST=--host=#{RbConfig::CONFIG['host_alias']}" if RbConfig::CONFIG.has_key?("host_alias")
      if RbConfig::CONFIG['host_os'].downcase =~ /darwin/
        mf.puts "include ${srcdir}/libffi.darwin.mk"
      elsif RbConfig::CONFIG['host_os'].downcase =~ /bsd/
        mf.puts '.include "${srcdir}/libffi.bsd.mk"'
      elsif RbConfig::CONFIG['host_os'].downcase =~ /mswin64/
        mf.puts '!include $(srcdir)/libffi.vc64.mk'
      elsif RbConfig::CONFIG['host_os'].downcase =~ /mswin32/
        mf.puts '!include $(srcdir)/libffi.vc.mk'
      else
        mf.puts "include ${srcdir}/libffi.mk"
      end
    end
  end

else
  File.open("Makefile", "w") do |mf|
    mf.puts "# Dummy makefile for non-mri rubies"
    mf.puts "all install::\n"
  end
end
