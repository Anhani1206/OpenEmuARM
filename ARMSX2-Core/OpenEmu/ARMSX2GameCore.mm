/*
 Copyright (c) 2026

 Minimal OpenEmu wrapper for the ARMSX2 libretro core.
 */

#import "ARMSX2GameCore.h"

#import <OpenEmuBase/OERingBuffer.h>
#import <Metal/Metal.h>

#include <algorithm>
#include <cmath>
#include <cstdarg>
#include <cstdio>
#include <cstring>
#include <dlfcn.h>
#include <sys/stat.h>

#include "../3rdparty/libretro/libretro.h"

@interface ARMSX2GameCore (LibretroCallbacks)
- (BOOL)handleEnvironmentCommand:(unsigned)command data:(void *)data;
- (void)handleVideoFrame:(const void *)data width:(unsigned)width height:(unsigned)height pitch:(size_t)pitch;
- (void)copyMetalFrameToVideoBuffer;
- (int16_t)inputStateForPort:(unsigned)port device:(unsigned)device index:(unsigned)index identifier:(unsigned)identifier;
@end

namespace {

static constexpr NSUInteger ARMSX2PlayerCount = 2;
static constexpr NSUInteger ARMSX2ButtonCount = OEPS2ButtonCount;
static constexpr int16_t ARMSX2AnalogRange = 0x7fff;

typedef void (*retro_set_environment_f)(retro_environment_t);
typedef void (*retro_set_video_refresh_f)(retro_video_refresh_t);
typedef void (*retro_set_audio_sample_f)(retro_audio_sample_t);
typedef void (*retro_set_audio_sample_batch_f)(retro_audio_sample_batch_t);
typedef void (*retro_set_input_poll_f)(retro_input_poll_t);
typedef void (*retro_set_input_state_f)(retro_input_state_t);
typedef void (*retro_init_f)(void);
typedef void (*retro_deinit_f)(void);
typedef unsigned (*retro_api_version_f)(void);
typedef void (*retro_get_system_info_f)(retro_system_info*);
typedef void (*retro_get_system_av_info_f)(retro_system_av_info*);
typedef bool (*retro_load_game_f)(const retro_game_info*);
typedef void (*retro_unload_game_f)(void);
typedef void (*retro_run_f)(void);
typedef void (*retro_reset_f)(void);
typedef size_t (*retro_serialize_size_f)(void);
typedef bool (*retro_serialize_f)(void*, size_t);
typedef bool (*retro_unserialize_f)(const void*, size_t);
typedef void (*retro_set_controller_port_device_f)(unsigned, unsigned);
typedef void *(*armsx2_openemu_metal_object_callback_f)(void *);
typedef void (*armsx2_openemu_metal_notify_callback_f)(void *);
typedef void (*armsx2_openemu_set_metal_callbacks_f)(void *,
                                                     armsx2_openemu_metal_object_callback_f,
                                                     armsx2_openemu_metal_object_callback_f,
                                                     armsx2_openemu_metal_notify_callback_f,
                                                     armsx2_openemu_metal_notify_callback_f);

struct ARMSX2CoreAPI {
    void *handle = nullptr;
    retro_set_environment_f set_environment = nullptr;
    retro_set_video_refresh_f set_video_refresh = nullptr;
    retro_set_audio_sample_f set_audio_sample = nullptr;
    retro_set_audio_sample_batch_f set_audio_sample_batch = nullptr;
    retro_set_input_poll_f set_input_poll = nullptr;
    retro_set_input_state_f set_input_state = nullptr;
    retro_init_f init = nullptr;
    retro_deinit_f deinit = nullptr;
    retro_api_version_f api_version = nullptr;
    retro_get_system_info_f get_system_info = nullptr;
    retro_get_system_av_info_f get_system_av_info = nullptr;
    retro_load_game_f load_game = nullptr;
    retro_unload_game_f unload_game = nullptr;
    retro_run_f run = nullptr;
    retro_reset_f reset = nullptr;
    retro_serialize_size_f serialize_size = nullptr;
    retro_serialize_f serialize = nullptr;
    retro_unserialize_f unserialize = nullptr;
    retro_set_controller_port_device_f set_controller_port_device = nullptr;
    armsx2_openemu_set_metal_callbacks_f set_metal_callbacks = nullptr;
};

static ARMSX2GameCore *currentCore = nil;

static int16_t analogValue(float negative, float positive)
{
    const float value = positive - negative;
    return static_cast<int16_t>(lrintf(std::max(-1.0f, std::min(1.0f, value)) * ARMSX2AnalogRange));
}

static bool loadSymbol(void *handle, const char *name, void **symbol)
{
    *symbol = dlsym(handle, name);
    if (*symbol == nullptr) {
        NSLog(@"[ARMSX2] Missing libretro symbol: %s", name);
        return false;
    }
    return true;
}

static void armsx2_debug_log(NSString *format, ...)
{
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    NSLog(@"%@", message);

    FILE *file = fopen("/tmp/openemu-armsx2-metal.log", "a");
    if (file != nullptr) {
        fputs(message.UTF8String, file);
        fputc('\n', file);
        fclose(file);
    }
}

static void armsx2_log(enum retro_log_level level, const char *fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    NSString *message = [[NSString alloc] initWithFormat:[NSString stringWithUTF8String:fmt ?: ""] arguments:args];
    va_end(args);

    NSString *levelString = @"debug";
    switch (level) {
        case RETRO_LOG_ERROR: levelString = @"error"; break;
        case RETRO_LOG_WARN:  levelString = @"warn";  break;
        case RETRO_LOG_INFO:  levelString = @"info";  break;
        case RETRO_LOG_DEBUG: levelString = @"debug"; break;
        case RETRO_LOG_DUMMY: break;
    }
    NSLog(@"[ARMSX2][%@] %@", levelString, message);
}

static bool armsx2_environment(unsigned command, void *data)
{
    ARMSX2GameCore *core = currentCore;
    if (core == nil) {
        return false;
    }

    return [core handleEnvironmentCommand:command data:data];
}

static void armsx2_video_refresh(const void *data, unsigned width, unsigned height, size_t pitch)
{
    ARMSX2GameCore *core = currentCore;
    if (core == nil) {
        return;
    }

    [core handleVideoFrame:data width:width height:height pitch:pitch];
}

static void armsx2_audio_sample(int16_t left, int16_t right)
{
    int16_t samples[2] = { left, right };
    [[currentCore audioBufferAtIndex:0] write:samples maxLength:sizeof(samples)];
}

static size_t armsx2_audio_sample_batch(const int16_t *data, size_t frames)
{
    if (currentCore == nil || data == nullptr || frames == 0) {
        return 0;
    }

    [[currentCore audioBufferAtIndex:0] write:data maxLength:frames * 2 * sizeof(int16_t)];
    return frames;
}

static void armsx2_input_poll(void)
{
}

static int16_t armsx2_input_state(unsigned port, unsigned device, unsigned index, unsigned id)
{
    ARMSX2GameCore *core = currentCore;
    if (core == nil || port >= ARMSX2PlayerCount) {
        return 0;
    }

    return [core inputStateForPort:port device:device index:index identifier:id];
}

static void *armsx2_openemu_metal_device(void *context)
{
    ARMSX2GameCore *core = (__bridge ARMSX2GameCore *)context;
    if (core.metalDevice == nil) {
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        if (device != nil) {
            [core createMetalTextureWithDevice:device];
            armsx2_debug_log(@"[ARMSX2] Lazily created OpenEmu Metal texture from device callback.");
        }
    }
    armsx2_debug_log(@"[ARMSX2] Metal device callback: device=%d texture=%d",
                     core.metalDevice != nil, core.metalTexture != nil);
    return (__bridge void *)core.metalDevice;
}

static void *armsx2_openemu_metal_texture(void *context)
{
    ARMSX2GameCore *core = (__bridge ARMSX2GameCore *)context;
    if (core.metalTexture == nil) {
        id<MTLDevice> device = core.metalDevice ?: MTLCreateSystemDefaultDevice();
        if (device != nil) {
            [core createMetalTextureWithDevice:device];
            armsx2_debug_log(@"[ARMSX2] Lazily created OpenEmu Metal texture from texture callback.");
        }
    }
    if (core.metalTexture != nil) {
        static uint64_t textureCallbackCount = 0;
        textureCallbackCount++;
        if (textureCallbackCount <= 5 || textureCallbackCount == 30 || textureCallbackCount == 60 || (textureCallbackCount % 300) == 0) {
            armsx2_debug_log(@"[ARMSX2] Metal texture callback #%llu: %lux%lu fmt=%lu",
                             textureCallbackCount,
                             static_cast<unsigned long>(core.metalTexture.width),
                             static_cast<unsigned long>(core.metalTexture.height),
                             static_cast<unsigned long>(core.metalTexture.pixelFormat));
        }
    } else {
        armsx2_debug_log(@"[ARMSX2] Metal texture callback: unavailable.");
    }
    return (__bridge void *)core.metalTexture;
}

static void armsx2_openemu_will_execute(void *context)
{
    ARMSX2GameCore *core = (__bridge ARMSX2GameCore *)context;
    [core.renderDelegate willExecute];
}

static void armsx2_openemu_did_execute(void *context)
{
    ARMSX2GameCore *core = (__bridge ARMSX2GameCore *)context;
    // The OpenEmu host still needs a CPU-visible fallback frame to reliably
    // wake presentation for ARMSX2's alternate GS rendering thread.
    [core copyMetalFrameToVideoBuffer];
    [core.renderDelegate didExecute];
}

}

@interface ARMSX2GameCore ()
{
    ARMSX2CoreAPI _api;
    NSString *_loadedGamePath;
    NSString *_systemDirectoryPath;
    NSString *_saveDirectoryPath;
    NSString *_selectedBIOSName;
    NSMutableData *_videoFrame;
    OEIntSize _bufferSize;
    OEIntSize _aspectSize;
    size_t _videoPitch;
    double _frameRate;
    double _sampleRate;
    bool _didLogVideoFormat;
    uint64_t _videoFrameCount;
    id<MTLCommandQueue> _metalReadbackQueue;
    id<MTLBuffer> _metalReadbackBuffer;
    NSUInteger _metalReadbackBufferLength;
    uint64_t _metalReadbackCount;
    bool _didLogFirstNonBlackMetalReadback;
    bool _coreInitialized;
    bool _gameLoaded;
    bool _buttons[ARMSX2PlayerCount][ARMSX2ButtonCount];
    float _analogButtons[ARMSX2PlayerCount][ARMSX2ButtonCount];
}
@end

@implementation ARMSX2GameCore

- (instancetype)init
{
    self = [super init];
    if (self != nil) {
        _bufferSize = OEIntSizeMake(640, 448);
        _aspectSize = OEIntSizeMake(4, 3);
        _videoPitch = _bufferSize.width * sizeof(uint32_t);
        _frameRate = 60.0;
        _sampleRate = 48000.0;
        _videoFrame = [[NSMutableData alloc] initWithLength:_videoPitch * _bufferSize.height];
        _videoFrameCount = 0;
        _metalReadbackBufferLength = 0;
        _metalReadbackCount = 0;
        _didLogFirstNonBlackMetalReadback = false;
        _coreInitialized = false;
        _gameLoaded = false;
    }
    return self;
}

- (void)dealloc
{
    [self stopEmulation];
}

#pragma mark - Loading

- (BOOL)loadFileAtPath:(NSString *)path error:(NSError **)error
{
    if (![self loadLibretroCore:error]) {
        return NO;
    }

    currentCore = self;
    _loadedGamePath = [path copy];
    [self prepareSystemDirectories];

    _api.set_environment(armsx2_environment);
    _api.set_video_refresh(armsx2_video_refresh);
    _api.set_audio_sample(armsx2_audio_sample);
    _api.set_audio_sample_batch(armsx2_audio_sample_batch);
    _api.set_input_poll(armsx2_input_poll);
    _api.set_input_state(armsx2_input_state);
    _api.init();
    _coreInitialized = true;

    // ARMSX2 reads both joypad buttons and analog axes as a DualShock 2.
    // Explicitly declare the two OpenEmu ports instead of relying on a
    // frontend default that may differ between launches.
    if (_api.set_controller_port_device != nullptr) {
        for (unsigned port = 0; port < ARMSX2PlayerCount; port++) {
            _api.set_controller_port_device(port, RETRO_DEVICE_JOYPAD);
        }
    }

    retro_game_info game = {};
    game.path = path.fileSystemRepresentation;
    if (!_api.load_game(&game)) {
        if (error != nullptr) {
            *error = [NSError errorWithDomain:OEGameCoreErrorDomain
                                         code:OEGameCoreCouldNotLoadROMError
                                     userInfo:@{NSLocalizedDescriptionKey: @"ARMSX2 could not load the selected PS2 game."}];
        }
        [self stopEmulation];
        return NO;
    }
    _gameLoaded = true;

    retro_system_av_info avInfo = {};
    _api.get_system_av_info(&avInfo);
    [self updateAVInfo:avInfo];

    return YES;
}

- (void)stopEmulation
{
    // Prevent a late GS callback from retaining this wrapper while the core is
    // shutting down. The core owns the other side of these callback pointers.
    if (_api.set_metal_callbacks != nullptr) {
        _api.set_metal_callbacks(nullptr, nullptr, nullptr, nullptr, nullptr);
    }
    if (_gameLoaded && _api.unload_game != nullptr) {
        _api.unload_game();
    }
    _gameLoaded = false;
    if (_coreInitialized && _api.deinit != nullptr) {
        _api.deinit();
    }
    _coreInitialized = false;
    if (_api.handle != nullptr) {
        dlclose(_api.handle);
    }
    _api = {};
    if (currentCore == self) {
        currentCore = nil;
    }
}

- (void)resetEmulation
{
    if (_api.reset != nullptr) {
        _api.reset();
    }
}

- (void)startEmulation
{
    [super startEmulation];
    [self.renderDelegate willRenderFrameOnAlternateThread];
    [self.renderDelegate suspendFPSLimiting];
}

- (BOOL)loadLibretroCore:(NSError **)error
{
    NSString *corePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"armsx2_libretro" ofType:@"dylib"];
    if (corePath == nil) {
        corePath = [[NSBundle mainBundle] pathForResource:@"armsx2_libretro" ofType:@"dylib"];
    }
    if (corePath == nil) {
        if (error != nullptr) {
            *error = [NSError errorWithDomain:OEGameCoreErrorDomain
                                         code:OEGameCoreCouldNotStartCoreError
                                     userInfo:@{NSLocalizedDescriptionKey: @"armsx2_libretro.dylib was not found in the ARMSX2 core bundle."}];
        }
        return NO;
    }

    _api.handle = dlopen(corePath.fileSystemRepresentation, RTLD_NOW | RTLD_LOCAL);
    if (_api.handle == nullptr) {
        NSString *message = [NSString stringWithFormat:@"Could not load armsx2_libretro.dylib: %s", dlerror()];
        if (error != nullptr) {
            *error = [NSError errorWithDomain:OEGameCoreErrorDomain
                                         code:OEGameCoreCouldNotStartCoreError
                                     userInfo:@{NSLocalizedDescriptionKey: message}];
        }
        return NO;
    }

#define LOAD_REQUIRED(field, symbol) do { \
    if (!loadSymbol(_api.handle, symbol, reinterpret_cast<void **>(&_api.field))) { \
        dlclose(_api.handle); \
        _api = {}; \
        return NO; \
    } \
} while (0)
    LOAD_REQUIRED(set_environment, "retro_set_environment");
    LOAD_REQUIRED(set_video_refresh, "retro_set_video_refresh");
    LOAD_REQUIRED(set_audio_sample, "retro_set_audio_sample");
    LOAD_REQUIRED(set_audio_sample_batch, "retro_set_audio_sample_batch");
    LOAD_REQUIRED(set_input_poll, "retro_set_input_poll");
    LOAD_REQUIRED(set_input_state, "retro_set_input_state");
    LOAD_REQUIRED(init, "retro_init");
    LOAD_REQUIRED(deinit, "retro_deinit");
    LOAD_REQUIRED(api_version, "retro_api_version");
    LOAD_REQUIRED(get_system_info, "retro_get_system_info");
    LOAD_REQUIRED(get_system_av_info, "retro_get_system_av_info");
    LOAD_REQUIRED(load_game, "retro_load_game");
    LOAD_REQUIRED(unload_game, "retro_unload_game");
    LOAD_REQUIRED(run, "retro_run");
    LOAD_REQUIRED(reset, "retro_reset");
    LOAD_REQUIRED(serialize_size, "retro_serialize_size");
    LOAD_REQUIRED(serialize, "retro_serialize");
    LOAD_REQUIRED(unserialize, "retro_unserialize");
#undef LOAD_REQUIRED

    _api.set_controller_port_device = reinterpret_cast<retro_set_controller_port_device_f>(dlsym(_api.handle, "retro_set_controller_port_device"));
    _api.set_metal_callbacks = reinterpret_cast<armsx2_openemu_set_metal_callbacks_f>(dlsym(_api.handle, "armsx2_openemu_set_metal_callbacks"));
    if (_api.set_metal_callbacks != nullptr) {
        _api.set_metal_callbacks((__bridge void *)self,
                                 armsx2_openemu_metal_device,
                                 armsx2_openemu_metal_texture,
                                 armsx2_openemu_will_execute,
                                 armsx2_openemu_did_execute);
        armsx2_debug_log(@"[ARMSX2] Registered OpenEmu Metal callbacks.");
    } else {
        armsx2_debug_log(@"[ARMSX2] OpenEmu Metal callback symbol not found.");
    }

    if (_api.api_version() != RETRO_API_VERSION) {
        NSLog(@"[ARMSX2] Unexpected libretro API version: %u", _api.api_version());
    }

    return YES;
}

- (void)prepareSystemDirectories
{
    NSFileManager *fileManager = NSFileManager.defaultManager;

    _systemDirectoryPath = [self.supportDirectoryPath stringByAppendingPathComponent:@"system"];
    _saveDirectoryPath = [self.supportDirectoryPath stringByAppendingPathComponent:@"saves"];
    _selectedBIOSName = nil;
    NSString *pcsx2Path = [_systemDirectoryPath stringByAppendingPathComponent:@"pcsx2"];
    NSString *biosPath = [pcsx2Path stringByAppendingPathComponent:@"bios"];
    NSString *resourcesPath = [pcsx2Path stringByAppendingPathComponent:@"resources"];

    [fileManager createDirectoryAtPath:biosPath withIntermediateDirectories:YES attributes:nil error:nil];
    [fileManager createDirectoryAtPath:resourcesPath withIntermediateDirectories:YES attributes:nil error:nil];
    [fileManager createDirectoryAtPath:_saveDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];

    NSArray<NSString *> *knownBIOSNames = @[
        @"scph10000.bin",
        @"scph39001.bin",
        @"scph70004.bin",
    ];

    for (NSString *name in knownBIOSNames) {
        NSString *source = [self.biosDirectoryPath stringByAppendingPathComponent:name];
        NSString *destination = [biosPath stringByAppendingPathComponent:name];
        if ([fileManager fileExistsAtPath:source] && ![fileManager fileExistsAtPath:destination]) {
            NSError *linkError = nil;
            if (![fileManager linkItemAtPath:source toPath:destination error:&linkError]) {
                [fileManager copyItemAtPath:source toPath:destination error:nil];
            }
        }
        if (_selectedBIOSName == nil && [fileManager fileExistsAtPath:destination]) {
            _selectedBIOSName = name;
        }
    }

    NSArray<NSString *> *biosDirectoryContents = [fileManager contentsOfDirectoryAtPath:self.biosDirectoryPath error:nil];
    for (NSString *name in biosDirectoryContents) {
        NSString *source = [self.biosDirectoryPath stringByAppendingPathComponent:name];
        BOOL isDirectory = NO;
        if (![fileManager fileExistsAtPath:source isDirectory:&isDirectory] || isDirectory) {
            continue;
        }

        NSDictionary<NSFileAttributeKey, id> *attributes = [fileManager attributesOfItemAtPath:source error:nil];
        unsigned long long fileSize = attributes.fileSize;
        if (fileSize < 4ULL * 1024ULL * 1024ULL || fileSize > 8ULL * 1024ULL * 1024ULL) {
            continue;
        }

        NSString *destination = [biosPath stringByAppendingPathComponent:name];
        if (![fileManager fileExistsAtPath:destination]) {
            NSError *linkError = nil;
            if (![fileManager linkItemAtPath:source toPath:destination error:&linkError]) {
                [fileManager copyItemAtPath:source toPath:destination error:nil];
            }
        }
        if (_selectedBIOSName == nil && [fileManager fileExistsAtPath:destination]) {
            _selectedBIOSName = name;
        }
    }

    NSString *sourceGameIndex = [[NSBundle bundleForClass:[self class]] pathForResource:@"GameIndex" ofType:@"yaml"];
    NSString *destinationGameIndex = [resourcesPath stringByAppendingPathComponent:@"GameIndex.yaml"];
    if (sourceGameIndex != nil &&
        (![fileManager fileExistsAtPath:destinationGameIndex] || ![fileManager contentsEqualAtPath:sourceGameIndex andPath:destinationGameIndex])) {
        [fileManager removeItemAtPath:destinationGameIndex error:nil];
        if ([fileManager copyItemAtPath:sourceGameIndex toPath:destinationGameIndex error:nil]) {
            armsx2_debug_log(@"[ARMSX2] Updated GameIndex.yaml in the system resources.");
        }
    }

    for (NSString *metallibName in @[@"default", @"Metal22", @"Metal23"]) {
        NSString *sourceMetallib = [[NSBundle bundleForClass:[self class]] pathForResource:metallibName ofType:@"metallib" inDirectory:@"resources"];
        NSString *destinationMetallib = [resourcesPath stringByAppendingPathComponent:[metallibName stringByAppendingPathExtension:@"metallib"]];
        if (sourceMetallib != nil &&
            (![fileManager fileExistsAtPath:destinationMetallib] || ![fileManager contentsEqualAtPath:sourceMetallib andPath:destinationMetallib])) {
            [fileManager removeItemAtPath:destinationMetallib error:nil];
            NSError *copyError = nil;
            if ([fileManager copyItemAtPath:sourceMetallib toPath:destinationMetallib error:&copyError]) {
                armsx2_debug_log(@"[ARMSX2] Updated %@.metallib for the Metal renderer.", metallibName);
            } else {
                armsx2_debug_log(@"[ARMSX2] Failed to update %@.metallib: %@", metallibName, copyError);
            }
        }
    }
}

- (void)updateAVInfo:(const retro_system_av_info &)avInfo
{
    unsigned width = avInfo.geometry.base_width ?: 640;
    unsigned height = avInfo.geometry.base_height ?: 448;
    _bufferSize = OEIntSizeMake(width, height);
    _aspectSize = OEIntSizeMake(static_cast<int>(width * (avInfo.geometry.aspect_ratio ?: (4.0 / 3.0))), height);
    _frameRate = avInfo.timing.fps ?: 60.0;
    _sampleRate = avInfo.timing.sample_rate ?: 48000.0;
    _videoPitch = _bufferSize.width * sizeof(uint32_t);
    [_videoFrame setLength:_videoPitch * _bufferSize.height];
}

- (void)updateGeometry:(const retro_game_geometry &)geometry
{
    unsigned width = geometry.base_width ?: 640;
    unsigned height = geometry.base_height ?: 448;

    _bufferSize = OEIntSizeMake(width, height);
    _aspectSize = OEIntSizeMake(static_cast<int>(width * (geometry.aspect_ratio ?: (4.0 / 3.0))), height);
    _videoPitch = _bufferSize.width * sizeof(uint32_t);
    [_videoFrame setLength:_videoPitch * _bufferSize.height];

    NSLog(@"[ARMSX2] Geometry updated: %ux%u max=%ux%u aspect=%f",
          width, height, geometry.max_width, geometry.max_height, geometry.aspect_ratio);
}

#pragma mark - Libretro callbacks

- (BOOL)handleEnvironmentCommand:(unsigned)command data:(void *)data
{
    switch (command & ~RETRO_ENVIRONMENT_EXPERIMENTAL) {
        case RETRO_ENVIRONMENT_SET_PIXEL_FORMAT:
            return *static_cast<retro_pixel_format *>(data) == RETRO_PIXEL_FORMAT_XRGB8888;

        case RETRO_ENVIRONMENT_GET_SYSTEM_DIRECTORY:
            *static_cast<const char **>(data) = _systemDirectoryPath.fileSystemRepresentation;
            return YES;

        case RETRO_ENVIRONMENT_GET_SAVE_DIRECTORY:
            *static_cast<const char **>(data) = _saveDirectoryPath.fileSystemRepresentation;
            return YES;

        case RETRO_ENVIRONMENT_GET_LOG_INTERFACE: {
            retro_log_callback *callback = static_cast<retro_log_callback *>(data);
            callback->log = armsx2_log;
            return YES;
        }

        case RETRO_ENVIRONMENT_GET_VARIABLE: {
            retro_variable *variable = static_cast<retro_variable *>(data);
            if (variable == nullptr || variable->key == nullptr) {
                return NO;
            }
            if (strcmp(variable->key, "armsx2_renderer") == 0) {
                variable->value = "Metal";
                return YES;
            }
            if (strcmp(variable->key, "armsx2_bios") == 0) {
                variable->value = _selectedBIOSName.fileSystemRepresentation;
                return _selectedBIOSName != nil;
            }
            if (strcmp(variable->key, "armsx2_fast_boot") == 0) {
                variable->value = "enabled";
                return YES;
            }
            variable->value = nullptr;
            return NO;
        }

        case RETRO_ENVIRONMENT_GET_VARIABLE_UPDATE:
            *static_cast<bool *>(data) = false;
            return YES;

        case RETRO_ENVIRONMENT_SET_SYSTEM_AV_INFO: {
            retro_system_av_info *avInfo = static_cast<retro_system_av_info *>(data);
            if (avInfo != nullptr) {
                [self updateAVInfo:*avInfo];
            }
            return YES;
        }

        case RETRO_ENVIRONMENT_SET_GEOMETRY: {
            retro_game_geometry *geometry = static_cast<retro_game_geometry *>(data);
            if (geometry != nullptr) {
                [self updateGeometry:*geometry];
            }
            return YES;
        }

        case RETRO_ENVIRONMENT_SET_CORE_OPTIONS:
        case RETRO_ENVIRONMENT_SET_CORE_OPTIONS_INTL:
        case RETRO_ENVIRONMENT_SET_CORE_OPTIONS_V2:
        case RETRO_ENVIRONMENT_SET_CORE_OPTIONS_V2_INTL:
        case RETRO_ENVIRONMENT_SET_CONTROLLER_INFO:
        case RETRO_ENVIRONMENT_SET_INPUT_DESCRIPTORS:
        case RETRO_ENVIRONMENT_SET_DISK_CONTROL_EXT_INTERFACE:
            return YES;

        case RETRO_ENVIRONMENT_SET_HW_RENDER:
        case RETRO_ENVIRONMENT_SET_HW_RENDER_CONTEXT_NEGOTIATION_INTERFACE:
        case RETRO_ENVIRONMENT_GET_HW_RENDER_INTERFACE:
            return NO;

        default:
            return NO;
    }
}

- (void)handleVideoFrame:(const void *)data width:(unsigned)width height:(unsigned)height pitch:(size_t)pitch
{
    if (data == nullptr || width == 0 || height == 0) {
        return;
    }

    const size_t bytesPerRow = width * sizeof(uint32_t);
    const size_t destinationPitch = bytesPerRow;

    if (_bufferSize.width != static_cast<int>(width) || _bufferSize.height != static_cast<int>(height) || _videoPitch != destinationPitch) {
        _bufferSize = OEIntSizeMake(width, height);
        _videoPitch = destinationPitch;
        [_videoFrame setLength:_videoPitch * height];
    }

    if (!_didLogVideoFormat) {
        NSLog(@"[ARMSX2] First video frame: %ux%u pitch=%zu bytesPerRow=%zu", width, height, pitch, bytesPerRow);
        _didLogVideoFormat = true;
    }
    _videoFrameCount++;
    if (_videoFrameCount <= 5 || _videoFrameCount == 30 || _videoFrameCount == 60 || _videoFrameCount == 300) {
        const uint32_t firstPixel = *static_cast<const uint32_t *>(data);
        NSLog(@"[ARMSX2] Video frame %llu: %ux%u pitch=%zu firstPixel=0x%08x",
              _videoFrameCount, width, height, pitch, firstPixel);
    }

    uint8_t *destination = static_cast<uint8_t *>(_videoFrame.mutableBytes);
    const uint8_t *source = static_cast<const uint8_t *>(data);

    for (unsigned row = 0; row < height; row++) {
        const uint8_t *sourceRow = source + row * pitch;
        uint8_t *destinationRow = destination + row * _videoPitch;

        for (unsigned column = 0; column < width; column++) {
            const uint8_t *sourcePixel = sourceRow + column * 4;
            uint8_t *destinationPixel = destinationRow + column * 4;

            destinationPixel[0] = sourcePixel[0];
            destinationPixel[1] = sourcePixel[1];
            destinationPixel[2] = sourcePixel[2];
            destinationPixel[3] = 0xFF;
        }
    }
}

- (void)copyMetalFrameToVideoBuffer
{
    id<MTLTexture> texture = self.metalTexture;
    id<MTLDevice> device = self.metalDevice ?: texture.device;
    if (texture == nil || device == nil || texture.width == 0 || texture.height == 0) {
        return;
    }

    const NSUInteger copyWidth = texture.width;
    const NSUInteger copyHeight = texture.height;
    const NSUInteger bytesPerRow = copyWidth * sizeof(uint32_t);
    const NSUInteger requiredLength = bytesPerRow * copyHeight;
    if (requiredLength == 0) {
        return;
    }

    if (_metalReadbackQueue == nil) {
        _metalReadbackQueue = [device newCommandQueue];
    }
    if (_metalReadbackQueue == nil) {
        return;
    }

    if (_metalReadbackBuffer == nil || _metalReadbackBufferLength < requiredLength) {
        _metalReadbackBuffer = [device newBufferWithLength:requiredLength options:MTLResourceStorageModeShared];
        _metalReadbackBufferLength = requiredLength;
    }
    if (_metalReadbackBuffer == nil) {
        return;
    }

    id<MTLCommandBuffer> commandBuffer = [_metalReadbackQueue commandBuffer];
    id<MTLBlitCommandEncoder> blit = [commandBuffer blitCommandEncoder];
    [blit copyFromTexture:texture
              sourceSlice:0
              sourceLevel:0
             sourceOrigin:MTLOriginMake(0, 0, 0)
               sourceSize:MTLSizeMake(copyWidth, copyHeight, 1)
                 toBuffer:_metalReadbackBuffer
        destinationOffset:0
   destinationBytesPerRow:bytesPerRow
 destinationBytesPerImage:requiredLength];
    [blit endEncoding];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];

    if (_bufferSize.width != static_cast<int>(copyWidth) || _bufferSize.height != static_cast<int>(copyHeight) || _videoPitch != bytesPerRow) {
        _bufferSize = OEIntSizeMake(copyWidth, copyHeight);
        _aspectSize = OEIntSizeMake(4, 3);
        _videoPitch = bytesPerRow;
        [_videoFrame setLength:requiredLength];
    }

    memcpy(_videoFrame.mutableBytes, _metalReadbackBuffer.contents, requiredLength);

    _metalReadbackCount++;
    const uint32_t *pixels = static_cast<const uint32_t *>(_videoFrame.bytes);
    const NSUInteger pixelCount = requiredLength / sizeof(uint32_t);
    NSUInteger nonBlackCount = 0;
    NSUInteger redDominantCount = 0;
    uint64_t totalRed = 0;
    uint64_t totalGreen = 0;
    uint64_t totalBlue = 0;
    NSUInteger sampledPixelCount = 0;
    uint32_t sampleHash = 2166136261u;
    const NSUInteger step = std::max<NSUInteger>(1, pixelCount / 4096);
    for (NSUInteger index = 0; index < pixelCount; index += step) {
        const uint32_t pixel = pixels[index];
        const uint8_t blue = pixel & 0xff;
        const uint8_t green = (pixel >> 8) & 0xff;
        const uint8_t red = (pixel >> 16) & 0xff;
        if ((pixel & 0x00ffffff) != 0) {
            nonBlackCount++;
        }
        if (red > green + 32 && red > blue + 32) {
            redDominantCount++;
        }
        totalRed += red;
        totalGreen += green;
        totalBlue += blue;
        sampledPixelCount++;
        sampleHash ^= pixel;
        sampleHash *= 16777619u;
    }

    // Log every frame around the first GS draw. This is the only interval in
    // which an initialization flash can occur, while retaining low-volume
    // periodic logging during normal gameplay.
    const bool shouldLog = _metalReadbackCount == 1 || _metalReadbackCount == 2 || _metalReadbackCount == 5 ||
                           _metalReadbackCount == 30 ||
                           (_metalReadbackCount >= 60 && _metalReadbackCount <= 90) ||
                           (_metalReadbackCount % 60) == 0;
    const bool isMostlyRed = sampledPixelCount > 0 && redDominantCount * 4 >= sampledPixelCount * 3;
    if (shouldLog || isMostlyRed || (!_didLogFirstNonBlackMetalReadback && nonBlackCount > 0)) {
        armsx2_debug_log(@"[ARMSX2] Metal readback frame #%llu: %lux%lu pitch=%lu nonBlack=%lu avgRGB=(%llu,%llu,%llu) red=%lu/%lu hash=%08x.",
                         _metalReadbackCount,
                         static_cast<unsigned long>(copyWidth),
                         static_cast<unsigned long>(copyHeight),
                         static_cast<unsigned long>(bytesPerRow),
                         static_cast<unsigned long>(nonBlackCount),
                         static_cast<unsigned long long>(totalRed / std::max<NSUInteger>(sampledPixelCount, 1)),
                         static_cast<unsigned long long>(totalGreen / std::max<NSUInteger>(sampledPixelCount, 1)),
                         static_cast<unsigned long long>(totalBlue / std::max<NSUInteger>(sampledPixelCount, 1)),
                         static_cast<unsigned long>(redDominantCount),
                         static_cast<unsigned long>(sampledPixelCount),
                         sampleHash);
        if (nonBlackCount > 0) {
            _didLogFirstNonBlackMetalReadback = true;
        }
    }
}

- (int16_t)inputStateForPort:(unsigned)port device:(unsigned)device index:(unsigned)index identifier:(unsigned)identifier
{
    if (device == RETRO_DEVICE_JOYPAD) {
        switch (identifier) {
            case RETRO_DEVICE_ID_JOYPAD_B:      return _buttons[port][OEPS2ButtonCross] ? 1 : 0;
            case RETRO_DEVICE_ID_JOYPAD_Y:      return _buttons[port][OEPS2ButtonSquare] ? 1 : 0;
            case RETRO_DEVICE_ID_JOYPAD_SELECT: return _buttons[port][OEPS2ButtonSelect] ? 1 : 0;
            case RETRO_DEVICE_ID_JOYPAD_START:  return _buttons[port][OEPS2ButtonStart] ? 1 : 0;
            case RETRO_DEVICE_ID_JOYPAD_UP:     return _buttons[port][OEPS2ButtonUp] ? 1 : 0;
            case RETRO_DEVICE_ID_JOYPAD_DOWN:   return _buttons[port][OEPS2ButtonDown] ? 1 : 0;
            case RETRO_DEVICE_ID_JOYPAD_LEFT:   return _buttons[port][OEPS2ButtonLeft] ? 1 : 0;
            case RETRO_DEVICE_ID_JOYPAD_RIGHT:  return _buttons[port][OEPS2ButtonRight] ? 1 : 0;
            case RETRO_DEVICE_ID_JOYPAD_A:      return _buttons[port][OEPS2ButtonCircle] ? 1 : 0;
            case RETRO_DEVICE_ID_JOYPAD_X:      return _buttons[port][OEPS2ButtonTriangle] ? 1 : 0;
            case RETRO_DEVICE_ID_JOYPAD_L:      return _buttons[port][OEPS2ButtonL1] ? 1 : 0;
            case RETRO_DEVICE_ID_JOYPAD_R:      return _buttons[port][OEPS2ButtonR1] ? 1 : 0;
            case RETRO_DEVICE_ID_JOYPAD_L2:     return _buttons[port][OEPS2ButtonL2] ? 1 : 0;
            case RETRO_DEVICE_ID_JOYPAD_R2:     return _buttons[port][OEPS2ButtonR2] ? 1 : 0;
            case RETRO_DEVICE_ID_JOYPAD_L3:     return _buttons[port][OEPS2ButtonL3] ? 1 : 0;
            case RETRO_DEVICE_ID_JOYPAD_R3:     return _buttons[port][OEPS2ButtonR3] ? 1 : 0;
        }
    }

    if (device == RETRO_DEVICE_ANALOG) {
        if (index == RETRO_DEVICE_INDEX_ANALOG_LEFT) {
            if (identifier == RETRO_DEVICE_ID_ANALOG_X) {
                return analogValue(_analogButtons[port][OEPS2LeftAnalogLeft], _analogButtons[port][OEPS2LeftAnalogRight]);
            }
            if (identifier == RETRO_DEVICE_ID_ANALOG_Y) {
                return analogValue(_analogButtons[port][OEPS2LeftAnalogUp], _analogButtons[port][OEPS2LeftAnalogDown]);
            }
        } else if (index == RETRO_DEVICE_INDEX_ANALOG_RIGHT) {
            if (identifier == RETRO_DEVICE_ID_ANALOG_X) {
                return analogValue(_analogButtons[port][OEPS2RightAnalogLeft], _analogButtons[port][OEPS2RightAnalogRight]);
            }
            if (identifier == RETRO_DEVICE_ID_ANALOG_Y) {
                return analogValue(_analogButtons[port][OEPS2RightAnalogUp], _analogButtons[port][OEPS2RightAnalogDown]);
            }
        }
    }

    return 0;
}

#pragma mark - Execution

- (void)executeFrame
{
    if (_api.run != nullptr) {
        _api.run();
    }
}

- (NSTimeInterval)frameInterval
{
    return _frameRate;
}

#pragma mark - Video

- (const void *)getVideoBufferWithHint:(void *)hint
{
    return _videoFrame.bytes;
}

- (OEIntSize)bufferSize
{
    return _bufferSize;
}

- (OEIntRect)screenRect
{
    return OEIntRectMake(0, 0, _bufferSize.width, _bufferSize.height);
}

- (OEIntSize)aspectSize
{
    return _aspectSize;
}

- (uint32_t)pixelFormat
{
    return OEPixelFormat_BGRA;
}

- (uint32_t)pixelType
{
    return OEPixelType_UNSIGNED_INT_8_8_8_8_REV;
}

- (OEGameCoreRendering)gameCoreRendering
{
    return OEGameCoreRenderingMetal2;
}

- (BOOL)hasAlternateRenderingThread
{
    return YES;
}

- (BOOL)tryToResizeVideoTo:(OEIntSize)size
{
    return YES;
}

- (NSInteger)bytesPerRow
{
    return static_cast<NSInteger>(_videoPitch);
}

#pragma mark - Audio

- (NSUInteger)channelCount
{
    return 2;
}

- (NSUInteger)audioBitDepth
{
    return 16;
}

- (double)audioSampleRate
{
    return _sampleRate;
}

- (NSUInteger)audioBufferSizeForBuffer:(NSUInteger)buffer
{
    return static_cast<NSUInteger>(_sampleRate / std::max(1.0, _frameRate));
}

#pragma mark - Save States

- (NSData *)serializeStateWithError:(NSError **)outError
{
    if (!_gameLoaded || _api.serialize_size == nullptr || _api.serialize == nullptr) {
        if (outError != nullptr) {
            *outError = [NSError errorWithDomain:OEGameCoreErrorDomain
                                            code:OEGameCoreCouldNotSaveStateError
                                        userInfo:@{NSLocalizedDescriptionKey: @"ARMSX2 is not running a game."}];
        }
        return nil;
    }

    const size_t size = _api.serialize_size();
    if (size == 0) {
        if (outError != nullptr) {
            *outError = [NSError errorWithDomain:OEGameCoreErrorDomain
                                            code:OEGameCoreCouldNotSaveStateError
                                        userInfo:@{NSLocalizedDescriptionKey: @"ARMSX2 did not provide a save-state buffer."}];
        }
        return nil;
    }
    NSMutableData *data = [NSMutableData dataWithLength:size];
    if (!_api.serialize(data.mutableBytes, size)) {
        if (outError != nullptr) {
            *outError = [NSError errorWithDomain:OEGameCoreErrorDomain
                                            code:OEGameCoreCouldNotSaveStateError
                                        userInfo:nil];
        }
        return nil;
    }
    return data;
}

- (BOOL)deserializeState:(NSData *)state withError:(NSError **)outError
{
    if (!_gameLoaded || state.length == 0 || _api.unserialize == nullptr || !_api.unserialize(state.bytes, state.length)) {
        if (outError != nullptr) {
            *outError = [NSError errorWithDomain:OEGameCoreErrorDomain
                                            code:OEGameCoreCouldNotLoadStateError
                                        userInfo:nil];
        }
        return NO;
    }
    return YES;
}

#pragma mark - Input

- (oneway void)didMovePS2JoystickDirection:(OEPS2Button)button withValue:(CGFloat)value forPlayer:(NSUInteger)player
{
    if (player == 0 || player > ARMSX2PlayerCount || button >= OEPS2ButtonCount) {
        return;
    }
    _analogButtons[player - 1][button] = value;
}

- (oneway void)didPushPS2Button:(OEPS2Button)button forPlayer:(NSUInteger)player
{
    if (player == 0 || player > ARMSX2PlayerCount || button >= OEPS2ButtonCount) {
        return;
    }
    _buttons[player - 1][button] = true;
    _analogButtons[player - 1][button] = 1.0f;
}

- (oneway void)didReleasePS2Button:(OEPS2Button)button forPlayer:(NSUInteger)player
{
    if (player == 0 || player > ARMSX2PlayerCount || button >= OEPS2ButtonCount) {
        return;
    }
    _buttons[player - 1][button] = false;
    _analogButtons[player - 1][button] = 0.0f;
}

@end
