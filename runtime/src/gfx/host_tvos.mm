// The Apple TV host (tvOS, WWHD_TVOS): UIKit instead of the AppKit host. One full-screen view whose layer is
// the TV picture's CAMetalLayer (display.mm takes it through host_tvos_layer); the game's own start-up
// (main.cpp's wwhd_main) runs on a thread of its own, as UIKit owns the main thread and its run loop.
// Controllers come through GameController.framework (input.mm), as on the Mac. The Mac's windows, menus,
// dialogs, controls window, text input and mouse have no equivalent here: their entry points below do
// nothing or decline.
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#include <pthread.h>
#include <unistd.h>
#include <functional>
#include <string>
#include <vector>

#include "../input.h"
#include "../overlay/hostui.h"
#include "display_modes.h"
#include "renderer.h"

int wwhd_main(int argc, char** argv);  // main.cpp

@interface WWMetalView : UIView
@end
@implementation WWMetalView
+ (Class)layerClass { return [CAMetalLayer class]; }
- (void)layoutSubviews {
    [super layoutSubviews];
    CAMetalLayer* layer = (CAMetalLayer*)self.layer;
    const CGFloat scale = self.window.screen.nativeScale ?: UIScreen.mainScreen.nativeScale;
    layer.contentsScale = scale;
    layer.drawableSize = CGSizeMake(MAX(1.0, self.bounds.size.width * scale), MAX(1.0, self.bounds.size.height * scale));
}
@end

@interface WWViewController : UIViewController
@end
@implementation WWViewController
- (void)loadView {
    self.view = [WWMetalView new];
    self.view.backgroundColor = UIColor.blackColor;
}
// the controller's Menu button goes to the game (its Home / Settings), not back to the Home screen
- (BOOL)controllerUserInteractionEnabled { return NO; }
@end

static WWMetalView* g_view = nil;
static int g_argc = 0;
static char** g_argv = nullptr;

// Where things are: the game files inside the app (game/, packaged with it), everything the game writes in
// the app's Caches folder (an Apple TV app may write nowhere else that lasts): settings and caches (the
// user folder), saves, and the log (relative to the working directory).
static void* run_game(void*) {
    NSString* caches = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    NSString* user = [caches stringByAppendingPathComponent:@"user"];
    NSString* save = [caches stringByAppendingPathComponent:@"save"];
    for (NSString* d in @[ user, save ])
        [[NSFileManager defaultManager] createDirectoryAtPath:d withIntermediateDirectories:YES attributes:nil error:nil];
    chdir(caches.fileSystemRepresentation);
    setenv("WWHD_USER_DIR", user.fileSystemRepresentation, 0);
    const std::string game = std::string([NSBundle mainBundle].bundlePath.fileSystemRepresentation) + "/game";
    std::vector<std::string> args = {g_argc ? g_argv[0] : "WindWakerHD", "--game", game, "--save", save.fileSystemRepresentation};
    for (int i = 1; i < g_argc; i++) args.push_back(g_argv[i]);  // (devicectl launch arguments come after)
    std::vector<char*> argv;
    for (auto& a : args) argv.push_back(a.data());
    argv.push_back(nullptr);
    wwhd_main(int(args.size()), argv.data());
    return nullptr;
}

@interface WWSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property (strong, nonatomic) UIWindow* window;
@end
@implementation WWSceneDelegate
- (void)scene:(UIScene*)scene willConnectToSession:(UISceneSession*)session options:(UISceneConnectionOptions*)options {
    UIWindowScene* ws = (UIWindowScene*)scene;
    self.window = [[UIWindow alloc] initWithWindowScene:ws];
    WWViewController* vc = [WWViewController new];
    self.window.rootViewController = vc;
    [self.window makeKeyAndVisible];
    g_view = (WWMetalView*)vc.view;
    [g_view layoutIfNeeded];
    static bool started = false;
    if (started) return;
    started = true;
    // the game's start-up and its guest thread want deep stacks, as the Mac's main thread has (8 MB)
    pthread_attr_t attr;
    pthread_attr_init(&attr);
    pthread_attr_setstacksize(&attr, 8u << 20);
    pthread_t t;
    pthread_create(&t, &attr, run_game, nullptr);
    pthread_attr_destroy(&attr);
}
@end

@interface WWAppDelegate : UIResponder <UIApplicationDelegate>
@end
@implementation WWAppDelegate
- (UISceneConfiguration*)application:(UIApplication*)application
    configurationForConnectingSceneSession:(UISceneSession*)session options:(UISceneConnectionOptions*)options {
    UISceneConfiguration* c = [[UISceneConfiguration alloc] initWithName:nil sessionRole:session.role];
    c.delegateClass = [WWSceneDelegate class];
    return c;
}
- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)options {
    application.idleTimerDisabled = YES;  // a game: no screen saver while it is played with a controller
    return YES;
}
@end

namespace gfx {
// display.mm: the TV picture's layer (main thread; the view exists once the scene connected)
CAMetalLayer* host_tvos_layer() { return g_view ? (CAMetalLayer*)g_view.layer : nil; }

// display.mm
bool host_setting(const char* key, std::string& value);
void set_host_setting(const char* key, const std::string& value);
int display_filter();
void display_set_filter(int f);
int display_drc_mode();
void set_drc_mode(int m);
void display_set_pip(int corner, float size, float opacity);
bool drc_window_available();
bool drc_window_shown();
void show_drc_window(bool on);

// player_question.h: no native alert here; main.cpp's ask_player takes its default
int ask_player_alert(const std::string&, const std::string&, const std::vector<std::string>&) { return -1; }
}  // namespace gfx

// mods/mouse.mm: no mouse on an Apple TV
namespace mods {
bool mouse_captured() { return false; }
void mouse_release() {}
void update_gyro_mouse() {}
}  // namespace mods

// main.cpp's crash handler asks the Vulkan renderer's compile journal (not built here)
extern "C" void wwhd_compile_journal_on_crash() {}

// ---------------------------------------------------------------- the settings overlay's host (hostui.h)
// As the AppKit host's (overlay_appkit.mm) for what display.mm keeps; no file panels, folders or clipboard.
namespace hostui {
void post(std::function<void()> fn) {
    dispatch_async(dispatch_get_main_queue(), ^{ fn(); });
}
void choose_game_source(bool, std::function<void(std::string)>) {}
void choose_mod_source(bool, std::function<void(std::string)>) {}
void choose_save_folder(std::function<void(std::string)>) {}
void choose_file(const char*, const char*, bool, std::function<void(std::string)>) {}
bool get(const char* key, std::string& value) { return gfx::host_setting(key, value); }
void set(const char* key, const std::string& value) { gfx::set_host_setting(key, value); }
float res_scale() { return render::res_scale(); }
void set_res_scale(float s) {
    render::set_res_scale(s);
    gfx::set_host_setting("resScale", std::to_string(s));
}
void graphics_changed() {}
int scale_filter() { return gfx::display_filter(); }
void set_scale_filter(int f) { gfx::display_set_filter(f); }
bool scale_filter_available() { return true; }
bool fullscreen() { return true; }
void set_fullscreen(bool) {}
int drc_modes() { return gfx::kDrcModeCount; }
bool drc_mode_offered(int m) { return m >= 0 && m < gfx::kDrcModeCount && m != gfx::kDrcWindow; }  // (no second window)
int drc_mode() { return gfx::display_drc_mode(); }
void set_drc_mode(int m) { gfx::set_drc_mode(m); }
void save_pip_position() { gfx::display_set_pip(gfx::g_pip_anchor, gfx::g_pip_size, gfx::g_pip_opacity); }
int pip_anchor() { return gfx::g_pip_anchor; }
void set_pip_anchor(int c) { gfx::display_set_pip(c, gfx::g_pip_size, gfx::g_pip_opacity); }
float pip_size() { return gfx::g_pip_size; }
void set_pip_size(float s) { gfx::display_set_pip(gfx::g_pip_anchor, s, gfx::g_pip_opacity); }
float pip_opacity() { return gfx::g_pip_opacity; }
void set_pip_opacity(float o) { gfx::display_set_pip(gfx::g_pip_anchor, gfx::g_pip_size, o); }
bool drc_available() { return gfx::drc_window_available(); }
bool drc_shown() { return gfx::drc_window_shown(); }
void show_drc(bool on) { gfx::show_drc_window(on); }
void set_pro_controller(bool on) {
    input::set_pro_controller(on);
    gfx::show_drc_window(!on);
}
const char* name() { return "tvOS"; }
void set_clipboard(const std::string&) {}
bool can_open_folder() { return false; }
void open_folder(const std::string&) {}
// Settings > Quit Game: an Apple TV app does not quit itself; back to the Home screen keeps it as it is
void quit() {}
}  // namespace hostui

int main(int argc, char** argv) {
    g_argc = argc;
    g_argv = argv;
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([WWAppDelegate class]));
    }
}
