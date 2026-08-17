#!/usr/bin/env ruby
# wire-libretro-bridge-target.rb
#
# Adds the OpenEmuLibretroBridge.oecoreplugin bundle target to
# OpenEmu.xcodeproj (same project as the OpenEmu app target — mirrors how
# the system plugin bundles are wired so we get implicit dependency
# resolution and no cross-project Copy-Files cycle).
#
# Adds a Copy Files build phase on the OpenEmu app target that drops the
# resulting bundle into OpenEmu.app/Contents/Resources/.
#
# Idempotent: re-running is a no-op if the target/phase already exist.
#
# Usage:
#   ruby Scripts/wire-libretro-bridge-target.rb            # apply
#   ruby Scripts/wire-libretro-bridge-target.rb --dry-run  # report only

require 'xcodeproj'

DRY_RUN = ARGV.include?('--dry-run')
ROOT = File.expand_path('..', __dir__)

APP_PROJ_PATH = File.join(ROOT, 'OpenEmu', 'OpenEmu.xcodeproj')

BRIDGE_TARGET_NAME = 'OpenEmuLibretroBridge'
BRIDGE_PRODUCT     = "#{BRIDGE_TARGET_NAME}.oecoreplugin"
BRIDGE_DIR_REL     = 'LibretroBridge'                              # relative to OpenEmu/ (project dir)
BRIDGE_SOURCE      = "#{BRIDGE_DIR_REL}/OpenEmuLibretroBridgeMain.m"
BRIDGE_PLIST       = "#{BRIDGE_DIR_REL}/OpenEmuLibretroBridge-Info.plist"
COPY_PHASE_NAME    = 'Copy Libretro Bridge to App PlugIns'

def banner(msg) puts "\n=== #{msg} ===" end

proj = Xcodeproj::Project.open(APP_PROJ_PATH)

# ---------------------------------------------------------------------------
# Step 1 — bridge bundle target inside OpenEmu.xcodeproj
# ---------------------------------------------------------------------------

banner "Bridge target"
existing = proj.targets.find { |t| t.respond_to?(:product_type) && t.name == BRIDGE_TARGET_NAME }

if existing
  puts "  target already present — skipping"
  bridge_target = existing
else
  bridge_group = proj.main_group.find_subpath(BRIDGE_DIR_REL, true)
  bridge_group.set_source_tree('<group>')
  bridge_group.path = BRIDGE_DIR_REL

  src_ref = bridge_group.find_file_by_path('OpenEmuLibretroBridgeMain.m') ||
            bridge_group.new_reference('OpenEmuLibretroBridgeMain.m')
  src_ref.last_known_file_type = 'sourcecode.c.objc'

  plist_ref = bridge_group.find_file_by_path('OpenEmuLibretroBridge-Info.plist') ||
              bridge_group.new_reference('OpenEmuLibretroBridge-Info.plist')
  plist_ref.last_known_file_type = 'text.plist.xml'

  bridge_target = proj.new_target(
    :bundle,
    BRIDGE_TARGET_NAME,
    :osx,
    nil,                                  # inherit deployment target from project
    proj.products_group,
    :objc
  )

  # Match the system-plugin pattern: minimal explicit settings, inherit the rest.
  bridge_target.build_configurations.each do |c|
    c.build_settings['PRODUCT_NAME']              = '$(TARGET_NAME)'
    c.build_settings['WRAPPER_EXTENSION']         = 'oecoreplugin'
    c.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'org.openemu.OpenEmuLibretroBridge'
    c.build_settings['INFOPLIST_FILE']            = BRIDGE_PLIST
    # Explicit empty deployment target → fall back to project's
    c.build_settings.delete('MACOSX_DEPLOYMENT_TARGET')
    c.build_settings.delete('CODE_SIGN_IDENTITY')
    c.build_settings.delete('CODE_SIGN_STYLE')
    c.build_settings.delete('SKIP_INSTALL')
    c.build_settings.delete('FRAMEWORK_SEARCH_PATHS')
    c.build_settings.delete('DEFINES_MODULE')
  end

  bridge_target.product_reference.path               = BRIDGE_PRODUCT
  bridge_target.product_reference.explicit_file_type = 'wrapper.cfbundle'
  bridge_target.product_reference.include_in_index   = '0'

  # Sources
  bridge_target.source_build_phase.add_file_reference(src_ref, true)

  # Link OpenEmuBase.framework — find the existing reference used by other targets
  base_ref = proj.files.find { |f| f.path == 'OpenEmuBase.framework' && f.source_tree == 'BUILT_PRODUCTS_DIR' }
  abort "OpenEmuBase.framework reference not found — cannot link bridge target" unless base_ref
  bridge_target.frameworks_build_phase.add_file_reference(base_ref, true)

  puts "  created target #{BRIDGE_TARGET_NAME}"
end

# ---------------------------------------------------------------------------
# Step 2 — Copy Files phase on OpenEmu app target → Contents/Resources/
# ---------------------------------------------------------------------------

banner "App copy phase"
app = proj.targets.find { |t| t.respond_to?(:product_type) && t.name == 'OpenEmu' } or abort "OpenEmu target not found"

bridge_product_ref = bridge_target.product_reference

unless app.dependencies.any? { |d| d.target == bridge_target }
  app.add_dependency(bridge_target)
  puts "  added target dependency: OpenEmu -> #{BRIDGE_TARGET_NAME}"
else
  puts "  target dependency already present"
end

copy_phase = app.copy_files_build_phases.find { |p| p.name == COPY_PHASE_NAME }
if copy_phase
  puts "  copy phase already present"
else
  copy_phase = app.new_copy_files_build_phase(COPY_PHASE_NAME)
  copy_phase.symbol_dst_subfolder_spec = :plug_ins      # Contents/PlugIns/
  copy_phase.dst_path = ''
  puts "  added copy phase: #{COPY_PHASE_NAME} → PlugIns/"
end

# Ensure the copy phase runs *before* the "Update Info.plist" run-script
# phases. Modern Xcode's build system fuses copy phases and creates a cycle
# back through those scripts if our copy lands after them.
phases    = app.build_phases
copy_idx  = phases.index { |p| p == copy_phase }
script_idx = phases.index { |p| p.is_a?(Xcodeproj::Project::Object::PBXShellScriptBuildPhase) }
if script_idx && copy_idx && copy_idx > script_idx
  phases.delete_at(copy_idx)
  phases.insert(script_idx, copy_phase)
  puts "  reordered copy phase to run before script phases"
end

unless copy_phase.files_references.include?(bridge_product_ref)
  bf = copy_phase.add_file_reference(bridge_product_ref, true)
  bf.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
  puts "  added bridge product to copy phase"
else
  puts "  bridge already in copy phase"
end

# ---------------------------------------------------------------------------

if DRY_RUN
  banner "Dry-run — no save"
else
  proj.save
  banner "Saved"
  puts "Review with: git diff -- '*.pbxproj'"
end
